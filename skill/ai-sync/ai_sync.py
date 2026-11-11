#!/usr/bin/env python3
"""ai-sync: haelt Skills, Slash-Command-Wrapper, MCP-Server und Claude-Plugins
auf mehreren Macs fuer Claude Code und ChatGPT Codex aus EINER Manifest-Datei gleich.

Nur Python-Standardbibliothek, kompatibel mit Python 3.9 (macOS /usr/bin/python3).
Unterbefehle: plan (Standard, Trockenlauf), apply, export, report, install-agent,
uninstall-agent (agent-run wird nur vom LaunchAgent benutzt).

Exit-Codes:
  0  alles aktuell, nichts zu tun
  1  Abweichungen, offene Aktionen oder Warnungen (z. B. github-neuer, lokal-geaendert, blockiert);
     der Status "offen" (nicht unterstuetzte Aktion) zaehlt nicht
  2  Fehler (ungueltiges Manifest/Konfig, Netzwerk- oder CLI-Fehler, ungueltiger Eintrag)
  4  ein anderer ai-sync-Lauf ist aktiv (Lock-Datei)

Sicherheit: Secrets stehen nie im Manifest, nur als Verweis (keychain:<dienst> oder
env:<VAR>); aufgeloeste Werte landen nur im Aufruf der offiziellen CLIs und werden aus
allen Ausgaben, Berichten und Logs entfernt. Subprozesse laufen immer mit Argumentliste.
"""
from __future__ import annotations

import argparse
import ast
import datetime
import fcntl
import hashlib
import json
import os
import platform
import plistlib
import posixpath
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import time
from pathlib import Path

VERSION = "0.1.0"
SCHEMA_VERSION = 1
LABEL = "de.michael-gahn.devos.ai-sync"
STAMP = ".mgd-ai-sync.json"
DEFAULT_OWNER = "MichaelGahnDESIGN"
DEFAULT_MARKETPLACES = ["anthropics/claude-plugins-official"]
DEFAULT_MCP_COMMANDS = ["npx", "uvx", "node"]
KEEP_BACKUPS = 5

EXIT_OK, EXIT_DEVIATION, EXIT_ERROR, EXIT_LOCKED = 0, 1, 2, 4

SKILL_ROOTS = {"claude": ".claude/skills", "codex": ".codex/skills", "agents": ".agents/skills"}
NAME_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,99}$")
OWNER_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9-]{0,99}$")
REPO_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,99}$")
REF_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._/-]{0,99}$")
SHA_RE = re.compile(r"^[0-9a-fA-F]{40}$")
DAY_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
ENVKEY_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]{0,99}$")
SERVICE_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._ -]{0,99}$")
MARKET_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*/[A-Za-z0-9][A-Za-z0-9._-]*$")

# Status-Werte (Skills und Wrapper)
S_OK, S_NEW, S_CHANGED, S_MISSING = "aktuell", "github-neuer", "lokal-geaendert", "fehlt"
S_UNKNOWN, S_ADOPT = "unbekannt", "adoptierbar"
S_DIFF, S_ERR, S_INVALID, S_OPEN, S_WARN = "abweichend", "fehler", "ungueltig", "offen", "warnung"
S_BLOCKED = "blockiert"
NEEDS_ATTENTION = {S_NEW, S_CHANGED, S_MISSING, S_UNKNOWN, S_ADOPT, S_DIFF, S_ERR, S_INVALID, S_WARN, S_BLOCKED}

SYSTEM_TOOLS = {"security": "/usr/bin/security", "osascript": "/usr/bin/osascript", "launchctl": "/bin/launchctl"}


class SyncError(Exception):
    pass


# --------------------------------------------------------------------------- Pfade

def home() -> Path:
    return Path(os.path.expanduser("~"))


def state_dir() -> Path:
    override = os.environ.get("MGD_AI_SYNC_HOME")
    if override:
        return Path(override)
    return home() / "Library" / "Application Support" / "MGD-DevOS" / "ai-sync"


def cache_dir() -> Path:
    override = os.environ.get("MGD_AI_SYNC_HOME")
    if override:
        return Path(override) / "cache"
    return home() / "Library" / "Caches" / "MGD-DevOS" / "ai-sync"


def config_path() -> Path:
    return state_dir() / "config.json"


def tool(name: str) -> str:
    """Absoluter Pfad eines Systemprogramms. Nur mit MGD_AI_SYNC_TESTING=1 darf MGD_AI_SYNC_TEST_BIN
    (Ordner mit Fakes) davor greifen."""
    fake_dir = os.environ.get("MGD_AI_SYNC_TEST_BIN")
    if fake_dir and os.environ.get("MGD_AI_SYNC_TESTING") == "1" and os.path.exists(os.path.join(fake_dir, name)):
        return os.path.join(fake_dir, name)
    return SYSTEM_TOOLS[name]


def private_mkdir(path) -> None:
    """Legt path an; Ordner im Status-Ordner (inklusive diesem) bekommen Rechte 0700."""
    path = Path(path)
    base = state_dir()
    try:
        rel = path.relative_to(base)
        chain = [base] + [base.joinpath(*rel.parts[:i + 1]) for i in range(len(rel.parts))]
    except ValueError:
        path.mkdir(parents=True, exist_ok=True)
        return
    for folder in chain:
        folder.mkdir(parents=True, exist_ok=True)
        os.chmod(str(folder), 0o700)


def write_private(path: Path, data) -> None:
    private_mkdir(Path(path).parent)
    write_atomic(path, data, mode=0o600)


def now_iso() -> str:
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


# --------------------------------------------------------------------------- Secrets-Schutz

_SECRETS = set()


def register_secret(value: str) -> None:
    if value and len(value) >= 3:
        _SECRETS.add(value)


def scrub(text) -> str:
    text = "" if text is None else str(text)
    for secret in sorted(_SECRETS, key=len, reverse=True):
        text = text.replace(secret, "***")
    return text


def short(text, limit: int = 300) -> str:
    text = scrub(text).strip()
    return text if len(text) <= limit else text[:limit] + "..."


# --------------------------------------------------------------------------- Dateien

def write_atomic(path: Path, data, mode: int = 0o644) -> None:
    path = Path(os.path.realpath(str(path)))  # Symlink-Ziele bleiben Symlinks
    path.parent.mkdir(parents=True, exist_ok=True)
    raw = data if isinstance(data, bytes) else data.encode("utf-8", "surrogateescape")
    fd, tmp = tempfile.mkstemp(prefix="." + path.name + ".", dir=str(path.parent))
    try:
        with os.fdopen(fd, "wb") as handle:
            handle.write(raw)
            handle.flush()
            os.fsync(handle.fileno())
        os.chmod(tmp, mode)
        os.replace(tmp, str(path))
        dir_fd = os.open(str(path.parent), os.O_RDONLY)
        try:
            os.fsync(dir_fd)
        finally:
            os.close(dir_fd)
    except BaseException:
        with_suppress_remove(tmp)
        raise


def with_suppress_remove(path) -> None:
    try:
        os.remove(path)
    except OSError:
        pass


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


SKIP_DIRS = {".git", "__pycache__"}
SKIP_FILES = {".DS_Store", STAMP}


def iter_files(root: Path):
    """Regulaere Dateien unter root (ohne .git, __pycache__, *.pyc, .DS_Store, Stempel; Symlinks werden nicht verfolgt)."""
    for current, dirs, files in os.walk(str(root), followlinks=False):
        dirs[:] = sorted(d for d in dirs if d not in SKIP_DIRS and not os.path.islink(os.path.join(current, d)))
        for name in sorted(files):
            full = Path(current) / name
            if name in SKIP_FILES or name.endswith(".pyc") or full.is_symlink() or not full.is_file():
                continue
            yield full


def hash_tree(root: Path) -> dict:
    return {f.relative_to(root).as_posix(): sha256_file(f) for f in iter_files(root)}


def safe_relpath(value, label: str) -> str:
    """Relativer POSIX-Pfad ohne '..', ohne absolute Anteile, ohne Steuerzeichen."""
    if not isinstance(value, str) or "\x00" in value or "\\" in value:
        raise SyncError("%s: ungueltiger Pfad" % label)
    value = value.strip() or "."
    if value.startswith("/") or value.startswith("~"):
        raise SyncError("%s: absolute Pfade sind nicht erlaubt" % label)
    norm = posixpath.normpath(value)
    if norm == ".." or norm.startswith("../") or ".." in value.split("/"):
        raise SyncError("%s: '..' im Pfad ist nicht erlaubt" % label)
    return norm


def inside(base: Path, candidate: Path) -> bool:
    base_real = os.path.realpath(str(base))
    cand_real = os.path.realpath(str(candidate))
    return cand_real == base_real or cand_real.startswith(base_real + os.sep)


# --------------------------------------------------------------------------- Subprozesse

def run(args, timeout: int = 120, cwd=None, env=None):
    """Fuehrt einen Befehl mit Argumentliste aus. Gibt (rc, stdout, stderr) zurueck (roh)."""
    full_env = dict(os.environ)
    if env:
        full_env.update(env)
    try:
        proc = subprocess.run(list(args), stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              universal_newlines=True, timeout=timeout, cwd=cwd, env=full_env,
                              stdin=subprocess.DEVNULL)
    except FileNotFoundError:
        return 127, "", "Befehl nicht gefunden: %s" % args[0]
    except subprocess.TimeoutExpired:
        return 124, "", "Zeitueberschreitung bei %s" % args[0]
    return proc.returncode, proc.stdout, proc.stderr


def git(args, cwd=None, timeout: int = 300):
    return run(["git"] + list(args), timeout=timeout, cwd=cwd, env={"GIT_TERMINAL_PROMPT": "0"})


# --------------------------------------------------------------------------- Konfig

def load_config(path=None) -> dict:
    path = Path(path) if path else config_path()
    cfg = {"manifest": None, "allowedOwners": [DEFAULT_OWNER], "allowedMarketplaces": list(DEFAULT_MARKETPLACES),
           "allowedMcpCommands": list(DEFAULT_MCP_COMMANDS), "allowedSecretRefs": {},
           "autoApply": False, "notify": True}
    if path.exists():
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, ValueError) as exc:
            raise SyncError("Konfig %s nicht lesbar: %s" % (path, exc))
        if not isinstance(data, dict):
            raise SyncError("Konfig muss ein JSON-Objekt sein")
        for key in cfg:
            if key in data:
                cfg[key] = data[key]
    if not isinstance(cfg["allowedOwners"], list) or not all(isinstance(o, str) for o in cfg["allowedOwners"]):
        raise SyncError("Konfig: allowedOwners muss eine Liste von Texten sein")
    if not isinstance(cfg["allowedMarketplaces"], list):
        raise SyncError("Konfig: allowedMarketplaces muss eine Liste sein")
    if not isinstance(cfg["allowedMcpCommands"], list) or not all(isinstance(c, str) for c in cfg["allowedMcpCommands"]):
        raise SyncError("Konfig: allowedMcpCommands muss eine Liste von Texten sein")
    refs = cfg["allowedSecretRefs"]
    if not isinstance(refs, dict) or not all(isinstance(k, str) and isinstance(v, list) and all(isinstance(n, str) for n in v)
                                             for k, v in refs.items()):
        raise SyncError("Konfig: allowedSecretRefs muss ein Objekt Verweis -> Liste von MCP-Namen sein")
    return cfg


# --------------------------------------------------------------------------- Git-Repos

def source_url(owner: str, repo: str) -> str:
    base = os.environ.get("MGD_AI_SYNC_TEST_SOURCE_BASE")
    if base and os.environ.get("MGD_AI_SYNC_TESTING") == "1":  # nur in Tests erlaubt
        return "%s/%s/%s" % (base.rstrip("/"), owner, repo)
    return "https://github.com/%s/%s" % (owner, repo)


class Repos:
    """Geklonte Repos im Cache, je Lauf nur einmal aktualisiert."""

    def __init__(self, cfg: dict):
        self.cfg = cfg
        self.memo = {}

    def check_owner(self, owner: str) -> None:
        allowed = [o.lower() for o in self.cfg["allowedOwners"]]
        if owner.lower() not in allowed:
            raise SyncError("Owner '%s' steht nicht in allowedOwners" % owner)

    def ensure(self, owner: str, repo: str, ref=None):
        """Gibt (pfad, commit, warnung) zurueck."""
        self.check_owner(owner)
        key = (owner.lower(), repo, ref)
        if key in self.memo:
            return self.memo[key]
        dirname = repo + ("@" + ref.replace("/", "_") if ref else "")
        if owner.lower() != DEFAULT_OWNER.lower():
            dirname = owner + "__" + dirname
        path = cache_dir() / "repos" / dirname
        url = source_url(owner, repo)
        warning = ""
        if (path / ".git").is_dir():
            rc, _, err = git(["-C", str(path), "fetch", "--quiet", "--depth", "1", "origin", ref or "HEAD"])
            if rc == 0:
                rc, _, err = git(["-C", str(path), "reset", "--quiet", "--hard", "FETCH_HEAD"])
            if rc != 0:
                warning = "GitHub nicht erreichbar, Stand aus Cache (%s)" % short(err, 120)
        else:
            private_mkdir(path.parent)
            if ref and SHA_RE.match(ref):  # 'git clone --branch' kennt keine SHAs
                rc, _, err = git(["init", "--quiet", str(path)])
                if rc == 0:
                    rc, _, err = git(["-C", str(path), "remote", "add", "origin", url])
                if rc == 0:
                    rc, _, err = git(["-C", str(path), "fetch", "--quiet", "--depth", "1", "origin", ref])
                if rc == 0:
                    rc, _, err = git(["-C", str(path), "checkout", "--quiet", "--detach", "FETCH_HEAD"])
            else:
                cmd = ["clone", "--quiet", "--depth", "1"] + (["--branch", ref] if ref else []) + ["--", url, str(path)]
                rc, _, err = git(cmd)
            if rc != 0:
                shutil.rmtree(str(path), ignore_errors=True)
                raise SyncError("Klonen von %s/%s fehlgeschlagen: %s" % (owner, repo, short(err, 200)))
        rc, out, _ = git(["-C", str(path), "rev-parse", "HEAD"])
        if rc != 0:
            raise SyncError("Repo-Cache %s ist unbrauchbar" % dirname)
        result = (path, out.strip(), warning)
        self.memo[key] = result
        return result


# --------------------------------------------------------------------------- Manifest

def parse_repo(value, cfg: dict):
    if not isinstance(value, str):
        raise SyncError("repo fehlt")
    owner, _, name = value.rpartition("/")
    owner = owner or DEFAULT_OWNER
    if not OWNER_RE.match(owner) or not REPO_RE.match(name) or name in (".", ".."):
        raise SyncError("repo '%s' ist ungueltig" % value)
    if owner.lower() not in [o.lower() for o in cfg["allowedOwners"]]:
        raise SyncError("Owner '%s' steht nicht in allowedOwners" % owner)
    return owner, name


def check_targets(raw, allowed) -> list:
    if not isinstance(raw, list) or not raw:
        raise SyncError("targets muss eine nicht leere Liste sein")
    for t in raw:
        if t not in allowed:
            raise SyncError("Ziel '%s' nicht erlaubt (erlaubt: %s)" % (t, ", ".join(allowed)))
    return list(dict.fromkeys(raw))


def check_name(value, label="name") -> str:
    if not isinstance(value, str) or not NAME_RE.match(value):
        raise SyncError("%s '%s' ist ungueltig (erlaubt: Buchstaben, Ziffern, . _ -)" % (label, value))
    return value


def validate_skill(raw, cfg, is_command=False) -> dict:
    if not isinstance(raw, dict):
        raise SyncError("Eintrag muss ein Objekt sein")
    name = check_name(raw.get("name"))
    out = {"name": name}
    out["owner"], out["repo"] = parse_repo(raw.get("repo"), cfg)
    out["path"] = safe_relpath(raw.get("path", "."), "path")
    ref = raw.get("ref")
    if ref is not None:
        if not isinstance(ref, str) or not REF_RE.match(ref) or ".." in ref:
            raise SyncError("ref ungueltig")
    out["ref"] = ref
    allowed = ("claude", "codex") if is_command else ("claude", "codex", "agents")
    out["targets"] = check_targets(raw.get("targets"), allowed)
    install = raw.get("installName", name)
    out["installName"] = check_name(install, "installName")
    if is_command and not out["path"].endswith(".md"):
        raise SyncError("path muss auf eine .md-Datei zeigen")
    return out


def validate_env(raw) -> dict:
    env = raw if raw is not None else {}
    if not isinstance(env, dict):
        raise SyncError("env muss ein Objekt sein")
    for key, ref in env.items():
        if not ENVKEY_RE.match(key):
            raise SyncError("env-Name '%s' ungueltig" % key)
        if not isinstance(ref, str):
            raise SyncError("env %s: nur Verweise erlaubt" % key)
        kind, _, rest = ref.partition(":")
        if kind == "keychain" and SERVICE_RE.match(rest):
            continue
        if kind == "env" and ENVKEY_RE.match(rest):
            continue
        raise SyncError("env %s: nur 'keychain:<dienst>' oder 'env:<VAR>' erlaubt (keine Klartext-Secrets im Manifest)" % key)
    return dict(env)


def validate_mcp(raw) -> dict:
    if not isinstance(raw, dict):
        raise SyncError("Eintrag muss ein Objekt sein")
    name = check_name(raw.get("name"))
    if not NAME_RE.match(name) or not re.match(r"^[A-Za-z0-9_-]+$", name):
        raise SyncError("MCP-Name '%s' darf nur Buchstaben, Ziffern, _ und - enthalten" % name)
    command = raw.get("command")
    if not isinstance(command, str) or not command or "\x00" in command:
        raise SyncError("command fehlt")
    args = raw.get("args", [])
    if not isinstance(args, list) or not all(isinstance(a, str) and "\x00" not in a for a in args):
        raise SyncError("args muss eine Liste von Texten sein")
    return {"name": name, "command": command, "args": args, "env": validate_env(raw.get("env")),
            "targets": check_targets(raw.get("targets"), ("claude", "codex"))}


def validate_plugin(raw, cfg) -> dict:
    if not isinstance(raw, dict):
        raise SyncError("Eintrag muss ein Objekt sein")
    market = raw.get("marketplace")
    if not isinstance(market, str) or not MARKET_RE.match(market):
        raise SyncError("marketplace muss 'owner/repo' sein")
    allowed = [m.lower() for m in cfg["allowedMarketplaces"]]
    if market.lower() not in allowed:
        raise SyncError("Marketplace '%s' steht nicht in allowedMarketplaces" % market)
    name = check_name(raw.get("name"))
    mname = raw.get("marketplaceName")
    if mname is not None:
        mname = check_name(mname, "marketplaceName")
    return {"name": name, "marketplace": market, "marketplaceName": mname}


def parse_manifest(data, cfg) -> dict:
    """Gibt {'skills': [...], 'commands': [...], 'mcp': [...], 'plugins': [...]} zurueck;
    ungueltige Eintraege tragen den Schluessel 'error'."""
    if not isinstance(data, dict):
        raise SyncError("Manifest muss ein JSON-Objekt sein")
    result = {"skills": [], "commands": [], "mcp": [], "plugins": []}
    sections = [("skills", data.get("skills", []), lambda r: validate_skill(r, cfg)),
                ("commands", data.get("commands", []), lambda r: validate_skill(r, cfg, True)),
                ("mcp", data.get("mcp", []), validate_mcp)]
    plugins = data.get("plugins", {})
    if not isinstance(plugins, dict):
        raise SyncError("plugins muss ein Objekt sein")
    sections.append(("plugins", plugins.get("claude", []), lambda r: validate_plugin(r, cfg)))
    for key, entries, validator in sections:
        if not isinstance(entries, list):
            raise SyncError("Abschnitt '%s' muss eine Liste sein" % key)
        for raw in entries:
            try:
                result[key].append(validator(raw))
            except SyncError as exc:
                label = raw.get("name", "?") if isinstance(raw, dict) else "?"
                result[key].append({"error": str(exc), "name": str(label)})
    seen = set()
    for key, kind in (("skills", "skill"), ("commands", "command")):
        for i, e in enumerate(result[key]):
            if "error" in e:
                continue
            keys = [(kind, e["installName"], t) for t in e["targets"]]
            clash = [k for k in keys if k in seen]
            if clash:
                result[key][i] = {"error": "doppelter Eintrag: %s '%s' fuer Ziel %s ist schon vergeben" % (
                    kind, e["installName"], clash[0][2]), "name": e["name"]}
            else:
                seen.update(keys)
    return result


def resolve_manifest_file(args, cfg, repos: Repos):
    """Gibt (pfad, beschreibung) zurueck."""
    if args.manifest:
        return Path(args.manifest).expanduser(), str(args.manifest)
    source = cfg.get("manifest")
    if isinstance(source, str) and source:
        return Path(source).expanduser(), source
    if isinstance(source, dict):
        owner, name = parse_repo(source.get("repo"), cfg)
        ref = source.get("branch")
        if ref is not None and (not isinstance(ref, str) or not REF_RE.match(ref) or ".." in ref):
            raise SyncError("Konfig: manifest.branch ungueltig")
        commit = source.get("commit")
        if commit is not None:
            if not isinstance(commit, str) or not SHA_RE.match(commit):
                raise SyncError("Konfig: manifest.commit muss ein vollstaendiger SHA sein (40 Hex-Zeichen)")
            commit = commit.lower()
            ref = commit
        rel = safe_relpath(source.get("path", "manifest.json"), "manifest.path")
        repo_path, head, _ = repos.ensure(owner, name, ref)
        if commit is not None and head != commit:
            raise SyncError("Manifest-Pin %s nicht erreichbar (Stand ist %s); Abbruch" % (commit[:12], head[:12]))
        file = repo_path / rel
        if not inside(repo_path, file):
            raise SyncError("Konfig: manifest.path verlaesst das Repo")
        return file, "git:%s/%s:%s" % (owner, name, rel)
    raise SyncError("Kein Manifest: --manifest <datei> angeben oder 'manifest' in %s setzen" % config_path())


# --------------------------------------------------------------------------- Stempel

def read_stamp(path: Path):
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None
    files = data.get("files") if isinstance(data, dict) else None
    if not isinstance(files, dict) or not all(isinstance(k, str) and isinstance(v, str) for k, v in files.items()):
        return None
    return data


def stamp_data(entry: dict, commit: str, files: dict) -> dict:
    return {"schemaVersion": 1, "tool": "ai-sync", "toolVersion": VERSION,
            "repo": "%s/%s" % (entry["owner"], entry["repo"]), "path": entry["path"], "ref": entry.get("ref"),
            "commit": commit, "installedAt": now_iso(), "files": files}


def command_stamps_path() -> Path:
    return state_dir() / "command-stamps.json"


def load_command_stamps() -> dict:
    """Fehlende Datei ergibt {}; eine vorhandene, aber kaputte Datei bricht ab (wird nie ueberschrieben)."""
    path = command_stamps_path()
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return {}
    except (OSError, ValueError) as exc:
        raise SyncError("command-stamps.json nicht lesbar (%s); Datei pruefen oder entfernen" % exc.__class__.__name__)
    if not isinstance(data, dict):
        raise SyncError("command-stamps.json hat ein unerwartetes Format; Datei pruefen oder entfernen")
    return data


def save_command_stamp(target: Path, stamp: dict) -> None:
    stamps = load_command_stamps()
    stamps[str(target)] = stamp
    write_private(command_stamps_path(), json.dumps(stamps, indent=2, sort_keys=True) + "\n")


def classify(local, stamp_files, source) -> str:
    if local is None:
        return S_MISSING
    if stamp_files is not None:
        if local != stamp_files:
            return S_CHANGED
        return S_OK if source == local else S_NEW
    return S_ADOPT if source == local else S_UNKNOWN


# --------------------------------------------------------------------------- Berichtseintraege

def item(kind, name, target, status, aktion, details="", **extra) -> dict:
    entry = {"kind": kind, "name": name, "target": target, "status": status, "aktion": aktion,
             "details": short(details), "ausgefuehrt": False}
    entry.update(extra)
    return entry


def public(entry: dict) -> dict:
    return {k: v for k, v in entry.items() if not k.startswith("_")}


def planned_action(status: str, name: str) -> str:
    return {S_MISSING: "installieren", S_NEW: "aktualisieren", S_OK: "keine"}.get(status, "manuell")


def hint_for(status: str, name: str) -> str:
    if status == S_CHANGED:
        return "lokale Aenderungen werden nicht ueberschrieben; --overwrite %s (mit Backup)" % name
    if status == S_UNKNOWN:
        return "kein Stempel, Inhalt weicht ab; --overwrite %s (mit Backup)" % name
    if status == S_ADOPT:
        return "Inhalt identisch, nur Stempel fehlt; --adopt %s" % name
    if status == S_DIFF:
        return "Server weicht ab; --overwrite %s" % name
    return ""


# --------------------------------------------------------------------------- Skills und Wrapper (Plan)

def build_skill_items(entries, repos: Repos) -> list:
    items = []
    h = home()
    for e in entries:
        if "error" in e:
            items.append(item("skill", e["name"], "-", S_INVALID, "keine", e["error"]))
            continue
        try:
            repo_path, commit, warn = repos.ensure(e["owner"], e["repo"], e["ref"])
            src = repo_path / e["path"]
            if not inside(repo_path, src) or not src.is_dir():
                raise SyncError("Pfad '%s' im Repo nicht gefunden" % e["path"])
            src_hashes = hash_tree(src)
        except SyncError as exc:
            for t in e["targets"]:
                items.append(item("skill", e["name"], t, S_ERR, "keine", str(exc)))
            continue
        for t in e["targets"]:
            target = h / SKILL_ROOTS[t] / e["installName"]
            op = {"type": "skill", "entry": e, "src": src, "target": target, "commit": commit,
                  "hashes": src_hashes, "targetKey": t}
            if target.is_symlink() or (target.exists() and not target.is_dir()):
                items.append(item("skill", e["name"], t, S_UNKNOWN, "manuell",
                                  "Ziel ist ein Symlink oder keine Ordner; ai-sync fasst es nicht an", commit=commit[:12]))
                continue
            local = hash_tree(target) if target.is_dir() else None
            stamp = read_stamp(target / STAMP) if target.is_dir() else None
            status = classify(local, stamp["files"] if stamp else None, src_hashes)
            details = " ".join(x for x in (warn, hint_for(status, e["name"])) if x)
            items.append(item("skill", e["name"], t, status, planned_action(status, e["name"]), details,
                              commit=commit[:12], _op=op))
    return items


def build_command_items(entries, repos: Repos) -> list:
    items = []
    h = home()
    stamps = load_command_stamps() if entries else {}
    for e in entries:
        if "error" in e:
            items.append(item("command", e["name"], "-", S_INVALID, "keine", e["error"]))
            continue
        try:
            repo_path, commit, warn = repos.ensure(e["owner"], e["repo"], e["ref"])
            src = repo_path / e["path"]
            if not inside(repo_path, src) or not src.is_file():
                raise SyncError("Datei '%s' im Repo nicht gefunden" % e["path"])
            src_hash = {"file": sha256_file(src)}
        except SyncError as exc:
            for t in e["targets"]:
                items.append(item("command", e["name"], t, S_ERR, "keine", str(exc)))
            continue
        for t in e["targets"]:
            if t == "codex":
                items.append(item("command", e["name"], "codex", S_OPEN, "keine",
                                  "Codex-Prompt-Ort ist nicht verifiziert; ai-sync unterstuetzt Wrapper derzeit nur fuer Claude"))
                continue
            target = h / ".claude" / "commands" / (e["installName"] + ".md")
            op = {"type": "command", "entry": e, "src": src, "target": target, "commit": commit,
                  "hashes": src_hash, "targetKey": "claude-commands"}
            if target.is_symlink() or (target.exists() and not target.is_file()):
                items.append(item("command", e["name"], t, S_UNKNOWN, "manuell", "Ziel ist ein Symlink oder keine Datei"))
                continue
            local = {"file": sha256_file(target)} if target.is_file() else None
            st = stamps.get(str(target))
            stamp_files = {"file": st["sha256"]} if isinstance(st, dict) and isinstance(st.get("sha256"), str) else None
            status = classify(local, stamp_files, src_hash)
            details = " ".join(x for x in (warn, hint_for(status, e["name"])) if x)
            items.append(item("command", e["name"], t, status, planned_action(status, e["name"]), details,
                              commit=commit[:12], _op=op))
    return items


def frontmatter_name(skill_dir: Path):
    try:
        with open(str(skill_dir / "SKILL.md"), "r", encoding="utf-8", errors="replace") as handle:
            head = handle.read(4096)
    except OSError:
        return None
    if not head.startswith("---"):
        return None
    block = head.split("---", 2)
    if len(block) < 3:
        return None
    m = re.search(r"^name:\s*[\"']?([^\"'\n]+?)[\"']?\s*$", block[1], re.M)
    return m.group(1) if m else None


def duplicate_warnings() -> list:
    warns = []
    h = home()
    for key, rel in SKILL_ROOTS.items():
        root = h / rel
        if not root.is_dir():
            continue
        names = {}
        for child in sorted(root.iterdir()):
            if child.name.startswith(".") or not child.is_dir():
                continue
            fm = frontmatter_name(child)
            if fm:
                names.setdefault(fm, {})[os.path.realpath(str(child))] = child.name
        for fm, paths in sorted(names.items()):
            if len(paths) > 1:
                warns.append(item("warnung", fm, key, S_WARN, "manuell",
                                  "Doppelter Skill-Name '%s' in ~/%s: %s" % (fm, rel, ", ".join(sorted(paths.values())))))
    return warns


WRAPPER_REFS = [re.compile(r"skills/([A-Za-z0-9][A-Za-z0-9._-]*)/SKILL\.md"),
                re.compile(r"Skills? `([A-Za-z0-9][A-Za-z0-9._-]*)`")]


def stale_wrapper_warnings() -> list:
    warns = []
    h = home()
    cmd_dir = h / ".claude" / "commands"
    skills = h / ".claude" / "skills"
    if not cmd_dir.is_dir():
        return warns
    for f in sorted(cmd_dir.glob("*.md")):
        if f.name.startswith(".") or not f.is_file():
            continue
        try:
            text = f.read_text(encoding="utf-8", errors="replace")[:65536]
        except OSError:
            continue
        refs = []
        for rx in WRAPPER_REFS:
            for name in rx.findall(text):
                if name not in refs:
                    refs.append(name)
        for name in refs:
            skill_dir = skills / name
            if not (skill_dir / "SKILL.md").is_file():
                warns.append(item("warnung", f.stem, "claude", S_WARN, "manuell",
                                  "Wrapper /%s verweist auf Skill '%s', der in ~/.claude/skills fehlt" % (f.stem, name)))
            elif (skill_dir / "SKILL.md").stat().st_mtime > f.stat().st_mtime + 1:
                warns.append(item("warnung", f.stem, "claude", S_WARN, "manuell",
                                  "Skill '%s' ist neuer als der Wrapper /%s; Wrapper pruefen" % (name, f.stem)))
    return warns


# --------------------------------------------------------------------------- MCP: lokale Sicht

def read_claude_mcp() -> dict:
    path = home() / ".claude.json"
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return {}
    except (OSError, ValueError) as exc:
        raise SyncError("~/.claude.json nicht lesbar (%s); ai-sync fasst die Datei nicht an" % exc.__class__.__name__)
    servers = data.get("mcpServers") if isinstance(data, dict) else None
    out = {}
    if isinstance(servers, dict):
        for name, conf in servers.items():
            if isinstance(conf, dict) and isinstance(conf.get("command"), str):
                env = conf.get("env") if isinstance(conf.get("env"), dict) else {}
                out[name] = {"command": conf["command"], "args": [str(a) for a in conf.get("args", []) or []],
                             "envKeys": sorted(env.keys()),
                             "env": {k: v for k, v in env.items() if isinstance(v, str)}}
    return out


def codex_config_path() -> Path:
    return home() / ".codex" / "config.toml"


HEADER_RE = re.compile(r"^\s*\[([^\[\]]+)\]\s*(#.*)?$")


def _toml_value(raw: str):
    raw = raw.strip()
    try:
        return json.loads(raw)
    except ValueError:
        pass
    try:
        return ast.literal_eval(raw)
    except (ValueError, SyntaxError):
        return None


def _strip_comment(line: str) -> str:
    """Schneidet einen '#'-Kommentar ab, ausser er steht in einem String."""
    out, quote, i = [], None, 0
    while i < len(line):
        c = line[i]
        if quote:
            out.append(c)
            if quote == '"' and c == "\\" and i + 1 < len(line):
                out.append(line[i + 1])
                i += 2
                continue
            if c == quote:
                quote = None
        elif c in "\"'":
            quote = c
            out.append(c)
        elif c == "#":
            break
        else:
            out.append(c)
        i += 1
    return "".join(out).rstrip()


def _depth(text: str) -> int:
    """Klammertiefe ([ und {) ausserhalb von Strings."""
    depth, quote, i = 0, None, 0
    while i < len(text):
        c = text[i]
        if quote:
            if quote == '"' and c == "\\":
                i += 2
                continue
            if c == quote:
                quote = None
        elif c in "\"'":
            quote = c
        elif c in "[{":
            depth += 1
        elif c in "]}":
            depth -= 1
        i += 1
    return depth


def _split_key(text: str):
    """Zerlegt einen (gepunkteten, ggf. gequoteten) TOML-Schluessel in Teile; None bei Unlesbarem."""
    parts, i, n = [], 0, len(text)
    while True:
        while i < n and text[i] in " \t":
            i += 1
        if i >= n:
            return None
        if text[i] in "\"'":
            quote, j, buf = text[i], i + 1, []
            while j < n and text[j] != quote:
                if quote == '"' and text[j] == "\\" and j + 1 < n:
                    buf.append(text[j + 1])
                    j += 2
                    continue
                buf.append(text[j])
                j += 1
            if j >= n:
                return None
            parts.append("".join(buf))
            i = j + 1
        else:
            j = i
            while j < n and (text[j].isalnum() or text[j] in "_-"):
                j += 1
            if j == i:
                return None
            parts.append(text[i:j])
            i = j
        while i < n and text[i] in " \t":
            i += 1
        if i >= n:
            return parts
        if text[i] != ".":
            return None
        i += 1


def _header_parts(line: str):
    m = HEADER_RE.match(line)
    return _split_key(m.group(1)) if m else None


def _line_key(line: str):
    """Schluessel einer 'key = value'-Zeile (Kommentar schon entfernt) oder None."""
    if "=" not in line or line.lstrip().startswith("["):
        return None
    parts = _split_key(line.partition("=")[0])
    return parts[0] if parts and len(parts) == 1 else None


def _inline_table(raw: str):
    raw = raw.strip()
    if not (raw.startswith("{") and raw.endswith("}")):
        return None
    items, cur, depth, quote, i = [], [], 0, None, 0
    body = raw[1:-1]
    while i < len(body):
        c = body[i]
        if quote:
            cur.append(c)
            if quote == '"' and c == "\\" and i + 1 < len(body):
                cur.append(body[i + 1])
                i += 2
                continue
            if c == quote:
                quote = None
        elif c in "\"'":
            quote = c
            cur.append(c)
        elif c in "[{":
            depth += 1
            cur.append(c)
        elif c in "]}":
            depth -= 1
            cur.append(c)
        elif c == "," and depth == 0:
            items.append("".join(cur))
            cur = []
        else:
            cur.append(c)
        i += 1
    items.append("".join(cur))
    out = {}
    for it in items:
        if not it.strip():
            continue
        key, eq, value = it.partition("=")
        parts = _split_key(key) if eq else None
        val = _toml_value(value) if parts and len(parts) == 1 else None
        if val is None:
            return None
        out[parts[0]] = val
    return out


def parse_codex_mcp(text: str) -> dict:
    """Minimaler Leser fuer [mcp_servers.<name>] und [mcp_servers.<name>.env] (auch Inline-env, Kommentare,
    gequotete Header). Nicht lesbare Server erhalten 'unreadable': True (nie 'fehlt')."""
    servers = {}
    section = None  # (Zieldict, Serverdict)
    pending = None
    for raw_line in text.splitlines():
        line = _strip_comment(raw_line)
        if pending is not None:
            pending[1].append(line.strip())
            joined = " ".join(pending[1])
            if _depth(joined) <= 0:
                _put_value(pending[2], pending[0], joined)
                pending = None
            continue
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("[["):
            section = None
            continue
        if stripped.startswith("["):
            parts = _header_parts(stripped)
            section = None
            if parts and parts[0] == "mcp_servers" and re.match(r"^[A-Za-z0-9_-]+$", parts[1] if len(parts) > 1 else ""):
                if len(parts) == 2:
                    server = servers.setdefault(parts[1], {"_env": {}, "_bad": False})
                    section = (server, server)
                elif len(parts) == 3 and parts[2] == "env":
                    server = servers.setdefault(parts[1], {"_env": {}, "_bad": False})
                    section = (server["_env"], server)
            continue
        if section is None or "=" not in stripped:
            continue
        key, _, value = stripped.partition("=")
        names = _split_key(key)
        if not names or len(names) != 1:
            continue
        value = value.strip()
        if _depth(value) > 0:
            pending = (names[0], [value], section)
            continue
        _put_value(section, names[0], value)
    out = {}
    for name, conf in servers.items():
        command, args, env = conf.get("command"), conf.get("args", []), conf["_env"]
        ok = (not conf["_bad"] and isinstance(command, str) and isinstance(args, list)
              and all(isinstance(a, str) for a in args) and all(isinstance(v, str) for v in env.values()))
        if ok:
            out[name] = {"command": command, "args": list(args), "envKeys": sorted(env), "env": dict(env)}
        else:
            out[name] = {"command": None, "args": [], "envKeys": sorted(env), "env": {}, "unreadable": True}
    return out


def _put_value(section, key: str, raw: str) -> None:
    target, server = section
    if target is server and key == "env":
        table = _inline_table(raw)
        if table is None:
            server["_bad"] = True
        else:
            server["_env"].update(table)
        return
    value = _toml_value(raw)
    if value is None:
        if target is not server or key in ("command", "args"):
            server["_bad"] = True
        return
    target[key] = value


def read_codex_mcp() -> dict:
    try:
        return parse_codex_mcp(codex_config_path().read_text(encoding="utf-8"))
    except FileNotFoundError:
        return {}
    except UnicodeDecodeError:
        raise SyncError("~/.codex/config.toml ist nicht als UTF-8 lesbar; ai-sync fasst die Datei nicht an")
    except OSError as exc:
        raise SyncError("~/.codex/config.toml nicht lesbar (%s)" % exc.__class__.__name__)


# --------------------------------------------------------------------------- Codex-TOML-Editor (Fallback)

def toml_str(value: str) -> str:
    """TOML-Basisstring: Steuerzeichen und DEL als \\uXXXX, Zeichen ausserhalb der BMP als \\UXXXXXXXX."""
    esc = {'"': '\\"', "\\": "\\\\", "\b": "\\b", "\t": "\\t", "\n": "\\n", "\f": "\\f", "\r": "\\r"}
    out = ['"']
    for ch in value:
        code = ord(ch)
        if ch in esc:
            out.append(esc[ch])
        elif code < 0x20 or code == 0x7F:
            out.append("\\u%04x" % code)
        elif 0xD800 <= code <= 0xDFFF:
            raise SyncError("Zeichen ist in TOML nicht darstellbar")
        elif code > 0xFFFF:
            out.append("\\U%08X" % code)
        else:
            out.append(ch)
    out.append('"')
    return "".join(out)


def toml_key(key: str) -> str:
    return key if re.match(r"^[A-Za-z0-9_-]+$", key) else toml_str(key)


def toml_remove_blocks(text: str, name: str):
    """Entfernt [mcp_servers.<name>] und dessen .env-Untertabelle (Header normalisiert erkannt).
    Rest bleibt bytegleich. Gibt (neuer_text, einfuegeposition_in_zeilen oder None) zurueck."""
    lines = text.splitlines(keepends=True)
    owned = (["mcp_servers", name], ["mcp_servers", name, "env"])
    keep, insert_at, in_block = [], None, False
    for line in lines:
        bare = line.rstrip("\r\n")
        if HEADER_RE.match(bare):
            in_block = _header_parts(bare) in owned
        elif line.lstrip().startswith("[["):
            in_block = False
        if in_block:
            if insert_at is None:
                insert_at = len(keep)
            continue
        keep.append(line)
    return "".join(keep), insert_at


def toml_render_block(name: str, command: str, args, env: dict) -> str:
    out = ["[mcp_servers.%s]\n" % name, "command = %s\n" % toml_str(command),
           "args = [%s]\n" % ", ".join(toml_str(a) for a in args)]
    if env:
        out.append("\n[mcp_servers.%s.env]\n" % name)
        for key in sorted(env):
            out.append("%s = %s\n" % (toml_key(key), toml_str(env[key])))
    return "".join(out)


def _with_newline(lines):
    if lines and not lines[-1].endswith("\n"):
        lines = lines[:-1] + [lines[-1] + "\n"]
    return lines


def _drop_assignments(body, drop):
    """Entfernt Zuweisungen (auch mehrzeilige Arrays) fuer die Schluessel in drop. Gibt (Rest, Position, Treffer) zurueck."""
    kept, pos, hit, i = [], None, [], 0
    while i < len(body):
        line = body[i]
        clean = _strip_comment(line)
        key = _line_key(clean)
        if key is not None and key in drop:
            if pos is None:
                pos = len(kept)
            hit.append(key)
            depth = _depth(clean.partition("=")[2])
            while depth > 0 and i + 1 < len(body):
                i += 1
                depth += _depth(_strip_comment(body[i]))
            i += 1
            continue
        kept.append(line)
        i += 1
    return kept, pos, hit


def toml_set_mcp(text: str, name: str, command: str, args, env: dict) -> str:
    """Setzt den MCP-Server. Ein vorhandener Block wird an Ort und Stelle angepasst (unbekannte Schluessel und
    Kommentare bleiben); fehlt er, wird ein neuer Block angehaengt."""
    lines = text.splitlines(keepends=True)
    heads = []
    for i, line in enumerate(lines):
        bare = line.rstrip("\r\n")
        if HEADER_RE.match(bare):
            heads.append((i, _header_parts(bare)))
        elif line.lstrip().startswith("[["):
            heads.append((i, None))
    spans = {}
    for k, (start, parts) in enumerate(heads):
        end = heads[k + 1][0] if k + 1 < len(heads) else len(lines)
        if parts == ["mcp_servers", name] and "main" not in spans:
            spans["main"] = (start, end)
        elif parts == ["mcp_servers", name, "env"] and "env" not in spans:
            spans["env"] = (start, end)
    block = toml_render_block(name, command, args, env)
    if "main" not in spans:
        stripped, insert_at = toml_remove_blocks(text, name)
        if insert_at is None:
            sep = "" if (not stripped or stripped.endswith("\n\n")) else ("\n" if stripped.endswith("\n") else "\n\n")
            return stripped + sep + block
        keep = stripped.splitlines(keepends=True)
        tail = "".join(keep[insert_at:])
        return "".join(keep[:insert_at]) + block + ("\n" if tail and not tail.startswith("\n") else "") + tail
    a, b = spans["main"]
    kept, pos, _ = _drop_assignments(lines[a + 1:b], ("command", "args", "env"))
    pos = 0 if pos is None else pos
    new_main = [lines[a] if lines[a].endswith("\n") else lines[a] + "\n"] + kept[:pos] + [
        "command = %s\n" % toml_str(command), "args = [%s]\n" % ", ".join(toml_str(x) for x in args)] + kept[pos:]
    new_main = _with_newline(new_main)
    edits = []
    if "env" in spans:
        c, d = spans["env"]
        if env:
            body = lines[c + 1:d]
            new_env, done, i = [], set(), 0
            while i < len(body):
                clean = _strip_comment(body[i])
                key = _line_key(clean)
                if key is None:
                    new_env.append(body[i])
                    i += 1
                    continue
                depth = _depth(clean.partition("=")[2])
                while depth > 0 and i + 1 < len(body):
                    i += 1
                    depth += _depth(_strip_comment(body[i]))
                i += 1
                if key in env and key not in done:
                    new_env.append("%s = %s\n" % (toml_key(key), toml_str(env[key])))
                    done.add(key)
            tail_blank = 0
            while new_env and not new_env[-1].strip():
                new_env.pop()
                tail_blank += 1
            new_env = _with_newline(new_env)
            new_env += ["%s = %s\n" % (toml_key(k), toml_str(env[k])) for k in sorted(env) if k not in done]
            new_env += ["\n"] * tail_blank
            edits.append((c, d, _with_newline([lines[c]]) + new_env))
        else:
            edits.append((c, d, []))
    elif env:
        if new_main and new_main[-1].strip():
            new_main.append("\n")
        new_main += ["[mcp_servers.%s.env]\n" % name] + ["%s = %s\n" % (toml_key(k), toml_str(env[k])) for k in sorted(env)]
    edits.append((a, b, new_main))
    for start, end, repl in sorted(edits, key=lambda x: x[0], reverse=True):
        lines[start:end] = repl
    return "".join(lines)


def toml_remove_mcp(text: str, name: str) -> str:
    return toml_remove_blocks(text, name)[0]


def private_tree(path) -> None:
    """Ordner 0700, Dateien 0600 (Symlinks bleiben unberuehrt)."""
    path = str(path)
    if os.path.isfile(path) and not os.path.islink(path):
        os.chmod(path, 0o600)
        return
    for cur, _, files in os.walk(path, followlinks=False):
        os.chmod(cur, 0o700)
        for name in files:
            full = os.path.join(cur, name)
            if not os.path.islink(full):
                os.chmod(full, 0o600)


def prune_backups(target_key: str, name: str, suffix: str = r"(-\d{6}(-\d+)?)?") -> None:
    """Behaelt je Ziel nur die letzten KEEP_BACKUPS Backups. Angefasst werden ausschliesslich Eintraege, die dem
    Namensschema von ai-sync entsprechen (backups/<Datum>/<Ziel>/<name><suffix>); Symlinks bleiben liegen."""
    root = state_dir() / "backups"
    pattern = re.compile("^%s%s$" % (re.escape(name), suffix))
    found = []
    try:
        for day in sorted(root.iterdir()):
            folder = day / target_key
            if not DAY_RE.match(day.name) or day.is_symlink() or not folder.is_dir() or folder.is_symlink():
                continue
            for entry in folder.iterdir():
                if pattern.match(entry.name) and not entry.is_symlink():
                    found.append((day.name, entry.lstat().st_mtime_ns, entry))
        found.sort(key=lambda x: (x[0], x[1]))
        for _, _, entry in found[:-KEEP_BACKUPS]:
            if entry.is_dir():
                shutil.rmtree(str(entry), ignore_errors=True)
            else:
                entry.unlink()
            for folder in (entry.parent, entry.parent.parent):
                try:
                    folder.rmdir()
                except OSError:
                    break
    except OSError:
        pass


def backup_file(path: Path, label: str) -> Path:
    day = datetime.date.today().isoformat()
    dest = state_dir() / "backups" / day / label
    private_mkdir(dest)
    target = dest / (path.name + time.strftime(".%H%M%S"))
    shutil.copyfile(str(path), str(target))
    private_tree(target)
    prune_backups(label, path.name, r"\.\d{6}")
    return target


# --------------------------------------------------------------------------- MCP und Plugins (Plan)

def secret_available(ref: str) -> bool:
    kind, _, rest = ref.partition(":")
    if kind == "env":
        return rest in os.environ
    rc, _, _ = run([tool("security"), "find-generic-password", "-s", rest], timeout=20)
    return rc == 0


def resolve_secret(ref: str):
    kind, _, rest = ref.partition(":")
    if kind == "env":
        value = os.environ.get(rest)
    else:
        rc, out, _ = run([tool("security"), "find-generic-password", "-s", rest, "-w"], timeout=60)
        value = out.rstrip("\n") if rc == 0 and out.strip() else None
    if value:
        register_secret(value)
    return value


def mcp_block_reason(e: dict, cfg: dict):
    """Gibt den Grund zurueck, warum ein Eintrag blockiert ist (sonst None). Liest keine Secrets."""
    if e["command"] not in cfg["allowedMcpCommands"]:
        return "Befehl '%s' steht nicht in allowedMcpCommands (nur lokale Konfig)" % e["command"]
    allowed = cfg["allowedSecretRefs"]
    bad = sorted({ref for ref in e["env"].values() if e["name"] not in allowed.get(ref, [])})
    if bad:
        return "Secret-Verweis nicht freigegeben fuer '%s' (allowedSecretRefs): %s" % (e["name"], ", ".join(bad))
    return None


def build_mcp_items(entries, cfg, agent: bool = False) -> list:
    items = []
    local = {}
    for e in entries:
        if "error" in e:
            items.append(item("mcp", e["name"], "-", S_INVALID, "keine", e["error"]))
            continue
        reason = mcp_block_reason(e, cfg)
        if reason:
            for t in e["targets"]:
                items.append(item("mcp", e["name"], t, S_BLOCKED, "blockiert", reason))
            continue
        unavailable = [k for k, ref in sorted(e["env"].items()) if agent and ref.startswith("env:")]
        missing = [k for k, ref in sorted(e["env"].items()) if k not in unavailable and not secret_available(ref)]
        for t in e["targets"]:
            if t not in local:
                try:
                    local[t] = read_claude_mcp() if t == "claude" else read_codex_mcp()
                except SyncError as exc:
                    local[t] = exc
            if isinstance(local[t], SyncError):
                items.append(item("mcp", e["name"], t, S_ERR, "keine", str(local[t])))
                continue
            have = local[t].get(e["name"])
            if have is None:
                status = S_MISSING
            elif have.get("unreadable"):
                status = S_UNKNOWN
            elif have["command"] == e["command"] and have["args"] == e["args"] and set(e["env"]) <= set(have["envKeys"]):
                status = S_OK
            else:
                status = S_DIFF
            details = hint_for(status, e["name"])
            action = planned_action(status, e["name"])
            if status == S_UNKNOWN:
                details = "Eintrag in der Konfig nicht lesbar; ai-sync ersetzt ihn nie automatisch"
            if status == S_MISSING and (missing or unavailable):
                action = "blockiert"
                notes = []
                if unavailable:
                    notes.append("env:-Verweise sind im Agent-Lauf nicht verfuegbar: %s" % ", ".join(unavailable))
                if missing:
                    notes.append("Secret fehlt fuer: %s (Schluesselbund/Umgebung pruefen)" % ", ".join(missing))
                details = "; ".join(notes)
            items.append(item("mcp", e["name"], t, status, action, details,
                              _op={"type": "mcp", "entry": e, "targetKey": t, "blocked": bool(missing or unavailable)}))
    return items


def claude_plugins():
    rc, out, err = run(["claude", "plugin", "list", "--json"], timeout=60)
    if rc != 0:
        raise SyncError("claude plugin list fehlgeschlagen: %s" % short(err, 150))
    try:
        return [p.get("id", "") for p in json.loads(out) if isinstance(p, dict)]
    except ValueError:
        raise SyncError("claude plugin list lieferte kein JSON")


def claude_marketplaces():
    rc, out, err = run(["claude", "plugin", "marketplace", "list", "--json"], timeout=60)
    if rc != 0:
        raise SyncError("claude plugin marketplace list fehlgeschlagen: %s" % short(err, 150))
    try:
        return [m for m in json.loads(out) if isinstance(m, dict)]
    except ValueError:
        raise SyncError("claude plugin marketplace list lieferte kein JSON")


MARKET_URL_RE = re.compile(r"^(?:https?://(?:[^/@]+@)?|ssh://git@|git@)github\.com[:/]+([^/]+)/([^/]+?)(?:\.git)?/?$")


def market_repo(m) -> str:
    """'owner/repo' eines Marketplace aus der echten Ausgabe (source 'git' mit url, oder 'github' mit repo); sonst ''."""
    if not isinstance(m, dict):
        return ""
    repo = m.get("repo")
    if isinstance(repo, str) and MARKET_RE.match(repo):
        return repo
    url = m.get("url")
    match = MARKET_URL_RE.match(url.strip()) if isinstance(url, str) else None
    return "%s/%s" % (match.group(1), match.group(2)) if match else ""


def build_plugin_items(entries) -> list:
    items = []
    installed = None
    markets = None
    added = set()  # Marketplaces, die in diesem Lauf schon hinzugefuegt wurden
    for e in entries:
        if "error" in e:
            items.append(item("plugin", e["name"], "-", S_INVALID, "keine", e["error"]))
            continue
        try:
            if installed is None:
                got_installed = claude_plugins()
                got_markets = claude_marketplaces()
                installed, markets = got_installed, got_markets
        except SyncError as exc:
            items.append(item("plugin", e["name"], "claude", S_ERR, "keine", str(exc)))
            continue
        want = e["marketplace"].lower()
        repo_of = {m.get("name"): market_repo(m) for m in markets}
        mname = e.get("marketplaceName")
        cands = [i for i in installed if i.partition("@")[0] == e["name"] and (not mname or i.partition("@")[2] == mname)]
        verified = [i for i in cands if repo_of.get(i.partition("@")[2], "").lower() == want]
        has_market = any(r.lower() == want for r in repo_of.values())
        details = ""
        if verified:
            status, action = S_OK, "keine"
        elif cands:
            status, action = S_DIFF, "manuell"
            details = "Plugin ist ueber einen Marketplace installiert, der nicht auf %s zeigt" % e["marketplace"]
        elif mname and mname in repo_of and repo_of[mname].lower() != want:
            status, action = S_BLOCKED, "blockiert"
            details = "Marketplace-Name '%s' zeigt nicht auf %s; nichts wird installiert" % (mname, e["marketplace"])
        else:
            status, action = S_MISSING, "installieren"
            if not has_market:
                details = "Marketplace %s wird zuerst hinzugefuegt" % e["marketplace"]
        items.append(item("plugin", e["name"], "claude", status, action, details,
                          _op={"type": "plugin", "entry": e, "hasMarket": has_market, "added": added}))
    return items


# --------------------------------------------------------------------------- Plan

OLD_RE = re.compile(r"^\.(.+)\.old-\d+$")


def orphan_old_items(restore: bool) -> list:
    """Verwaiste '.<name>.old-<pid>'-Ordner einer abgebrochenen Aktualisierung: melden, bei fehlendem Ziel
    (nur im apply-Lauf) wiederherstellen."""
    items = []
    h = home()
    for key, rel in SKILL_ROOTS.items():
        root = h / rel
        if not root.is_dir():
            continue
        for child in sorted(root.iterdir()):
            m = OLD_RE.match(child.name)
            if not m or child.is_symlink() or not child.is_dir():
                continue
            target = root / m.group(1)
            if os.path.lexists(str(target)):
                items.append(item("warnung", child.name, key, S_WARN, "manuell",
                                  "verwaiste Sicherung %s neben vorhandenem Ziel %s; bitte pruefen und entfernen" % (child.name, target.name)))
            elif restore:
                os.rename(str(child), str(target))
                items.append(item("warnung", child.name, key, S_WARN, "manuell",
                                  "verwaiste Sicherung %s wiederhergestellt als %s; Skill pruefen" % (child.name, target.name)))
            else:
                items.append(item("warnung", child.name, key, S_WARN, "manuell",
                                  "verwaiste Sicherung %s, Ziel %s fehlt; apply stellt sie wieder her" % (child.name, target.name)))
    return items


def build_items(manifest: dict, cfg: dict, repos: Repos, restore: bool = False, agent: bool = False) -> list:
    items = []
    orphans = orphan_old_items(restore)  # vor den Skills: ein wiederhergestelltes Ziel zaehlt als vorhanden
    items += build_skill_items(manifest["skills"], repos)
    items += build_command_items(manifest["commands"], repos)
    items += build_mcp_items(manifest["mcp"], cfg, agent)
    items += build_plugin_items(manifest["plugins"])
    items += duplicate_warnings()
    items += stale_wrapper_warnings()
    items += orphans
    return items


def device_name() -> str:
    return platform.node() or "unbekannt"


def build_report(items, mode, manifest_desc, manifest_sha) -> dict:
    counts = {}
    for it in items:
        counts[it["status"]] = counts.get(it["status"], 0) + 1
    open_actions = sum(1 for it in items if it["aktion"] in ("installieren", "aktualisieren") and not it["ausgefuehrt"])
    return {"schemaVersion": SCHEMA_VERSION, "tool": "ai-sync", "toolVersion": VERSION,
            "device": device_name(), "generatedAt": now_iso(), "mode": mode,
            "manifest": {"source": manifest_desc, "sha256": manifest_sha},
            "summary": {"counts": counts, "openActions": open_actions,
                        "warnings": sum(1 for it in items if it["kind"] == "warnung"),
                        "errors": sum(1 for it in items if it["status"] in (S_ERR, S_INVALID))},
            "entries": [public(it) for it in items]}


def exit_code_for(items) -> int:
    if any(it["status"] in (S_ERR, S_INVALID) for it in items):
        return EXIT_ERROR
    for it in items:
        if it.get("statusNachher", it["status"]) in NEEDS_ATTENTION and it["status"] != S_OPEN:
            return EXIT_DEVIATION
    return EXIT_OK


def render_text(report: dict) -> str:
    lines = ["ai-sync %s auf %s (Manifest: %s)" % (report["mode"], report["device"], report["manifest"]["source"])]
    for e in report["entries"]:
        tail = " | %s" % e["details"] if e["details"] else ""
        lines.append("[%s] %s -> %s: %s -> %s%s" % (e["kind"], e["name"], e["target"], e["status"], e["aktion"], tail))
    s = report["summary"]
    lines.append("Zusammenfassung: %s; offene Aktionen: %d, Warnungen: %d, Fehler: %d" % (
        ", ".join("%s=%d" % kv for kv in sorted(s["counts"].items())) or "keine Eintraege",
        s["openActions"], s["warnings"], s["errors"]))
    return scrub("\n".join(lines))


def load_manifest_for_run(args, cfg, repos):
    path, desc = resolve_manifest_file(args, cfg, repos)
    try:
        raw = path.read_bytes()
        data = json.loads(raw.decode("utf-8"))
    except (OSError, ValueError) as exc:
        raise SyncError("Manifest %s nicht lesbar: %s" % (path, exc))
    return parse_manifest(data, cfg), desc, hashlib.sha256(raw).hexdigest()


# --------------------------------------------------------------------------- Apply

def copy_tree(src: Path, dest: Path) -> None:
    for f in iter_files(src):
        out = dest / f.relative_to(src)
        out.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(str(f), str(out))
        shutil.copymode(str(f), str(out))


def backup_path_for(target_key: str, name: str) -> Path:
    folder = state_dir() / "backups" / datetime.date.today().isoformat() / target_key
    base = folder / name
    if base.exists():
        stamp, n = time.strftime("-%H%M%S"), 1
        base = folder / (name + stamp)
        while base.exists():
            n += 1
            base = folder / ("%s%s-%d" % (name, stamp, n))
    return base


def install_skill(op: dict) -> str:
    target: Path = op["target"]
    e = op["entry"]
    parent = target.parent
    parent.mkdir(parents=True, exist_ok=True)
    stage = Path(tempfile.mkdtemp(prefix=".%s.ai-sync-" % target.name, dir=str(parent)))
    backup = None
    old = parent / (".%s.old-%d" % (target.name, os.getpid()))
    try:
        os.chmod(str(stage), 0o755)
        copy_tree(op["src"], stage)
        files = hash_tree(stage)
        write_atomic(stage / STAMP, json.dumps(stamp_data(e, op["commit"], files), indent=2, sort_keys=True) + "\n", mode=0o600)
        if os.path.lexists(str(target)):
            backup = backup_path_for(op["targetKey"], target.name)
            private_mkdir(backup.parent)
            shutil.copytree(str(target), str(backup), symlinks=True)
            private_tree(backup)
            os.utime(str(backup), None)
            os.rename(str(target), str(old))
            os.rename(str(stage), str(target))
            shutil.rmtree(str(old), ignore_errors=True)
        else:
            os.rename(str(stage), str(target))
    except BaseException:
        if os.path.lexists(str(old)) and not os.path.lexists(str(target)):
            os.rename(str(old), str(target))  # altes Ziel zurueck
        shutil.rmtree(str(stage), ignore_errors=True)
        raise
    if backup:
        prune_backups(op["targetKey"], target.name)
    return "Backup: %s" % backup if backup else ""


def install_command(op: dict) -> str:
    target: Path = op["target"]
    backup_note = ""
    if target.exists():
        backup = backup_path_for(op["targetKey"], target.name)
        private_mkdir(backup.parent)
        shutil.copyfile(str(target), str(backup))
        private_tree(backup)
        backup_note = "Backup: %s" % backup
    write_atomic(target, op["src"].read_bytes())
    save_command_stamp(target, {"repo": "%s/%s" % (op["entry"]["owner"], op["entry"]["repo"]), "path": op["entry"]["path"],
                                "commit": op["commit"], "installedAt": now_iso(), "sha256": sha256_file(target)})
    if backup_note:
        prune_backups(op["targetKey"], target.name)
    return backup_note


def adopt_skill(op: dict) -> None:
    write_atomic(op["target"] / STAMP, json.dumps(
        stamp_data(op["entry"], op["commit"], hash_tree(op["target"])), indent=2, sort_keys=True) + "\n", mode=0o600)


def adopt_command(op: dict) -> None:
    save_command_stamp(op["target"], {"repo": "%s/%s" % (op["entry"]["owner"], op["entry"]["repo"]),
                                      "path": op["entry"]["path"], "commit": op["commit"], "installedAt": now_iso(),
                                      "sha256": sha256_file(op["target"])})


def mcp_cli_commands(target: str, e: dict, env_values: dict):
    """Baut die CLI-Aufrufe (Argumentlisten). Enthaelt Secrets nur hier."""
    pairs = ["%s=%s" % (k, v) for k, v in sorted(env_values.items())]
    if target == "claude":
        cmd = ["claude", "mcp", "add", "-s", "user", e["name"]]
        if pairs:
            cmd += ["-e"] + pairs
        return cmd + ["--", e["command"]] + e["args"]
    cmd = ["codex", "mcp", "add", e["name"]]
    for p in pairs:
        cmd += ["--env", p]
    return cmd + ["--", e["command"]] + e["args"]


def restore_mcp(target: str, name: str, old) -> str:
    """Stellt einen vorher gesicherten Eintrag ueber die CLI wieder her."""
    if not old or old.get("unreadable"):
        return "alter Eintrag nicht lesbar, bitte manuell pruefen"
    rc, _, _ = run(mcp_cli_commands(target, {"name": name, "command": old["command"], "args": old["args"]}, old.get("env", {})),
                   timeout=120)
    return "alter Eintrag wiederhergestellt" if rc == 0 else "alter Eintrag NICHT wiederhergestellt, bitte manuell pruefen"


def verify_codex_config(path: Path, e: dict, values: dict) -> bool:
    try:
        text = path.read_bytes().decode("utf-8")
    except (OSError, ValueError):
        return False
    try:
        import tomllib  # ab Python 3.11; sonst nur der eigene Leser
        try:
            tomllib.loads(text)
        except ValueError:
            return False
    except ImportError:
        pass
    got = parse_codex_mcp(text).get(e["name"])
    return bool(got) and not got.get("unreadable") and got["command"] == e["command"] and got["args"] == e["args"] \
        and set(values) <= set(got["envKeys"])


def apply_mcp(op: dict, overwrite: bool) -> str:
    e, target = op["entry"], op["targetKey"]
    values = {}
    for key, ref in e["env"].items():
        value = resolve_secret(ref)
        if value is None:
            raise SyncError("Secret fuer %s nicht aufloesbar (%s)" % (key, ref.split(":", 1)[0]))
        values[key] = value
    if shutil.which(target) is None:
        raise SyncError("%s-CLI nicht gefunden" % target)
    print(scrub("MCP-Server %s (%s): %s %s" % (e["name"], target, e["command"], " ".join(e["args"]))).rstrip())
    old = None
    if overwrite:
        old = (read_claude_mcp() if target == "claude" else read_codex_mcp()).get(e["name"])
        for v in (old or {}).get("env", {}).values():
            register_secret(v)
    if target == "claude" or run(["codex", "mcp", "add", "--help"], timeout=30)[0] == 0:
        if overwrite:
            remove = ["claude", "mcp", "remove", "-s", "user", e["name"]] if target == "claude" else ["codex", "mcp", "remove", e["name"]]
            rc, _, err = run(remove, timeout=60)
            if rc != 0:
                raise SyncError("%s mcp remove fehlgeschlagen, nichts geaendert: %s" % (target, short(err, 150)))
        rc, _, err = run(mcp_cli_commands(target, e, values), timeout=120)
        if rc != 0:
            note = "; " + restore_mcp(target, e["name"], old) if overwrite else ""
            raise SyncError("%s mcp add fehlgeschlagen: %s%s" % (target, short(err, 150), note))
        return ""
    path = codex_config_path()
    existed = path.exists()
    original = path.read_bytes() if existed else None
    old_mode = stat.S_IMODE(os.stat(str(path)).st_mode) if existed else 0o600
    text = original.decode("utf-8", "surrogateescape") if existed else ""
    backup = backup_file(path, "codex-config") if existed else None
    write_atomic(path, toml_set_mcp(text, e["name"], e["command"], e["args"], values), mode=0o600)
    if not verify_codex_config(path, e, values):
        if existed:
            write_atomic(path, original, mode=old_mode)
        else:
            with_suppress_remove(os.path.realpath(str(path)))
        raise SyncError("config.toml nach dem Schreiben nicht lesbar; Ausgangsstand zurueckgespielt (Backup: %s)" % backup)
    return "Codex-CLI ohne 'mcp add': ~/.codex/config.toml ueber Fallback-Editor geaendert (Backup: %s)" % backup


def apply_plugin(op: dict) -> None:
    e = op["entry"]
    want = e["marketplace"].lower()
    if not op["hasMarket"] and want not in op["added"]:
        rc, _, err = run(["claude", "plugin", "marketplace", "add", e["marketplace"]], timeout=180)
        if rc != 0:
            raise SyncError("marketplace add fehlgeschlagen: %s" % short(err, 150))
        op["added"].add(want)
    ident = e["name"] + ("@" + e["marketplaceName"] if e.get("marketplaceName") else "")
    rc, _, err = run(["claude", "plugin", "install", ident], timeout=300)
    if rc != 0:
        raise SyncError("plugin install fehlgeschlagen: %s" % short(err, 150))


KINDS = ("skill", "command", "mcp", "plugin")


def parse_selectors(values, flag: str) -> list:
    """Selektoren 'name' oder 'kind:name[:target]' -> [(roh, kind oder None, name, target oder None)]."""
    out = []
    for raw in values or []:
        parts = raw.split(":")
        kind, name, tgt = (None, parts[0], None) if len(parts) == 1 else (
            (parts[0], parts[1], None) if len(parts) == 2 else (parts[0], parts[1], parts[2]) if len(parts) == 3 else (None, "", None))
        if not name or (kind is not None and kind not in KINDS):
            raise SyncError("%s '%s': ungueltiger Selektor (erlaubt: name oder kind:name[:target], kind %s)" % (
                flag, raw, "/".join(KINDS)))
        out.append((raw, kind, name, tgt))
    return out


def selector_matches(sel, it) -> bool:
    _, kind, name, tgt = sel
    return it["kind"] in KINDS and it["name"] == name and (kind is None or it["kind"] == kind) and (tgt is None or it["target"] == tgt)


def check_selectors(sels, items, flag: str) -> None:
    for sel in sels:
        hit = [it for it in items if selector_matches(sel, it)]
        if not hit:
            raise SyncError("%s '%s': kein Manifest-Eintrag passt" % (flag, sel[0]))
        kinds = sorted({it["kind"] for it in hit})
        if sel[1] is None and len(kinds) > 1:
            raise SyncError("%s '%s' ist mehrdeutig (passt auf %s); kind:name[:target] angeben" % (flag, sel[0], ", ".join(kinds)))


def chosen(sels, it) -> bool:
    return any(selector_matches(sel, it) for sel in sels)


def check_config_permissions(items, extras: list, seen: set) -> None:
    """Meldet zu offene Rechte der von den CLIs geschriebenen Konfigdateien (ai-sync aendert sie nicht)."""
    for it in items:
        op = it.get("_op")
        if not op or op["type"] != "mcp" or not it["ausgefuehrt"]:
            continue
        path = home() / ".claude.json" if op["targetKey"] == "claude" else codex_config_path()
        if str(path) in seen or not path.exists():
            continue
        seen.add(str(path))
        mode = stat.S_IMODE(os.stat(str(path)).st_mode)
        if mode & 0o077:
            extras.append(item("warnung", path.name, op["targetKey"], S_WARN, "manuell",
                               "~/%s hat Rechte %04o (erwartet 0600) und kann Secrets im Klartext enthalten; Rechte pruefen" % (
                                   path.relative_to(home()), mode)))


def apply_items(items, overwrite, adopt, kinds=None) -> None:
    check_selectors(overwrite, items, "--overwrite")
    check_selectors(adopt, items, "--adopt")
    for it in items:
        op = it.get("_op")
        if not op:
            continue
        status = it["status"]
        if kinds is not None and op["type"] not in kinds:
            it["details"] = short((it["details"] + " " if it["details"] else "") + "autoApply fuehrt das nicht aus; manuell: apply")
            continue
        try:
            if op["type"] in ("skill", "command"):
                installer = install_skill if op["type"] == "skill" else install_command
                adopter = adopt_skill if op["type"] == "skill" else adopt_command
                if chosen(adopt, it):
                    if status == S_ADOPT:
                        adopter(op)
                        _done(it, "adoptiert", "Stempel gesetzt")
                    elif status != S_OK:
                        it["aktion"], it["details"] = "uebersprungen", "--adopt abgelehnt: Inhalt nicht identisch"
                    continue
                if status in (S_MISSING, S_NEW):
                    note = installer(op)
                    _done(it, "installiert" if status == S_MISSING else "aktualisiert", note)
                elif status in (S_CHANGED, S_UNKNOWN) and chosen(overwrite, it):
                    note = installer(op)
                    _done(it, "ueberschrieben", note)
                elif status in (S_CHANGED, S_UNKNOWN, S_ADOPT):
                    it["aktion"] = "uebersprungen"
            elif op["type"] == "mcp":
                if status == S_MISSING and op["blocked"] is False:
                    note = apply_mcp(op, False)
                    _done(it, "installiert", note)
                elif status == S_MISSING:
                    it["aktion"] = "blockiert"
                elif status == S_DIFF and chosen(overwrite, it):
                    note = apply_mcp(op, True)
                    _done(it, "ueberschrieben", note)
                elif status == S_DIFF:
                    it["aktion"] = "uebersprungen"
            elif op["type"] == "plugin" and status == S_MISSING:
                apply_plugin(op)
                _done(it, "installiert", "")
        except (SyncError, OSError) as exc:
            it["status"], it["aktion"], it["details"] = S_ERR, "fehlgeschlagen", short(exc)
    extras = []
    check_config_permissions(items, extras, set())
    items.extend(extras)


def _done(it, aktion, details):
    it["aktion"], it["ausgefuehrt"], it["statusNachher"] = aktion, True, S_OK
    if details:
        it["details"] = short(details)


# --------------------------------------------------------------------------- Lock

class Lock:
    def __init__(self):
        self.fd = None

    def __enter__(self):
        path = state_dir() / "ai-sync.lock"
        private_mkdir(path.parent)
        self.fd = os.open(str(path), os.O_CREAT | os.O_RDWR, 0o600)
        try:
            fcntl.flock(self.fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            os.close(self.fd)
            self.fd = None
            raise LockBusy()
        return self

    def __exit__(self, *exc):
        if self.fd is not None:
            fcntl.flock(self.fd, fcntl.LOCK_UN)
            os.close(self.fd)


class LockBusy(Exception):
    pass


# --------------------------------------------------------------------------- Export

GITHUB_RE = re.compile(r"github\.com[:/]+([^/]+)/([^/]+?)(?:\.git)?/?$")


def git_origin(directory: Path):
    real = os.path.realpath(str(directory))
    rc, top, _ = git(["-C", real, "rev-parse", "--show-toplevel"], timeout=20)
    if rc != 0:
        return None
    rc, url, _ = git(["-C", real, "remote", "get-url", "origin"], timeout=20)
    m = GITHUB_RE.search(url.strip()) if rc == 0 else None
    if not m:
        return None
    rel = os.path.relpath(real, os.path.realpath(top.strip()))
    return m.group(1), m.group(2), "." if rel == "." else Path(rel).as_posix()


def export_skills(unassigned: list) -> list:
    found = {}
    h = home()
    for key, rel in SKILL_ROOTS.items():
        root = h / rel
        if not root.is_dir():
            continue
        for child in sorted(root.iterdir()):
            if child.name.startswith(".") or not child.is_dir() or not (child / "SKILL.md").is_file():
                continue
            origin = None
            stamp = read_stamp(child / STAMP)
            if stamp and isinstance(stamp.get("repo"), str) and isinstance(stamp.get("path"), str):
                owner, _, repo = stamp["repo"].rpartition("/")
                origin = (owner, repo, stamp["path"])
            else:
                origin = git_origin(child)
            if not origin:
                unassigned.append("skill:%s (%s, Herkunft nicht erkennbar)" % (child.name, key))
                continue
            k = (child.name, origin)
            found.setdefault(k, []).append(key)
    out = []
    for (name, (owner, repo, path)), targets in sorted(found.items()):
        entry = {"name": name, "repo": "%s/%s" % (owner, repo), "path": path, "targets": targets}
        out.append(entry)
    return out


SECRET_ARG_RE = re.compile(r"key|token|secret|password|bearer", re.I)
HEX_RE = re.compile(r"[0-9a-fA-F]{32,}")
B64_RE = re.compile(r"[A-Za-z0-9+/_-]{32,}={0,2}")
URLPW_RE = re.compile(r"://[^/\s@:]+:[^/\s@]+@")


def looks_secret(arg: str) -> bool:
    if SECRET_ARG_RE.search(arg) or HEX_RE.search(arg) or URLPW_RE.search(arg):
        return True
    for m in B64_RE.finditer(arg):
        v = m.group(0)
        if any(c.isdigit() for c in v) and any(c.isupper() for c in v) and any(c.islower() for c in v):
            return True
    return False


def export_mcp(unassigned: list) -> list:
    merged = {}
    tainted = set()
    sources = []
    for target, reader in (("claude", read_claude_mcp), ("codex", read_codex_mcp)):
        try:
            sources.append((target, reader()))
        except SyncError as exc:
            unassigned.append("mcp (%s: %s)" % (target, exc))
    for target, servers in sources:
        for name, conf in servers.items():
            if conf.get("unreadable"):
                unassigned.append("mcp:%s (%s: Eintrag nicht lesbar)" % (name, target))
                continue
            if name in tainted:
                continue
            if any(looks_secret(a) for a in conf["args"]):
                tainted.add(name)
                merged.pop(name, None)
                unassigned.append("mcp:%s (%s: Argument enthaelt moegliches Secret, nicht exportiert)" % (name, target))
                continue
            cur = merged.get(name)
            if cur is None:
                merged[name] = {"name": name, "command": conf["command"], "args": conf["args"],
                                "env": {k: "env:%s" % k for k in conf["envKeys"]}, "targets": [target]}
            elif cur["command"] == conf["command"] and cur["args"] == conf["args"]:
                cur["targets"].append(target)
                for k in conf["envKeys"]:
                    cur["env"].setdefault(k, "env:%s" % k)
            else:
                unassigned.append("mcp:%s (%s: anderer Befehl/Argumente als in %s)" % (name, target, cur["targets"][0]))
    return [merged[k] for k in sorted(merged)]


def export_plugins(unassigned: list) -> list:
    out = []
    try:
        ids = claude_plugins()
        markets = claude_marketplaces()
    except SyncError as exc:
        unassigned.append("plugins (%s)" % exc)
        return out
    by_name = {m.get("name"): m for m in markets}
    for ident in sorted(ids):
        name, _, mname = ident.partition("@")
        m = by_name.get(mname)
        if m and market_repo(m):
            out.append({"marketplace": market_repo(m), "marketplaceName": mname, "name": name})
        else:
            unassigned.append("plugin:%s (Marketplace nicht GitHub/unbekannt)" % ident)
    return out


def do_export(args) -> int:
    unassigned = []
    draft = {"_hinweis": "Entwurf von ai-sync export, ohne Secrets. env-Verweise (env:<VAR>) und Pfade vor Gebrauch pruefen; "
                         "Eintraege entfernen, die nicht synchronisiert werden sollen.",
             "_erzeugtAm": now_iso(),
             "skills": export_skills(unassigned), "commands": [],
             "mcp": export_mcp(unassigned), "plugins": {"claude": export_plugins(unassigned)}}
    draft["_nichtZugeordnet"] = unassigned
    text = scrub(json.dumps(draft, indent=2, ensure_ascii=False) + "\n")
    if args.output:
        write_atomic(Path(args.output), text, mode=0o600)
        print("Manifest-Entwurf geschrieben: %s (%d Skills, %d MCP, %d Plugins, %d nicht zugeordnet)" % (
            args.output, len(draft["skills"]), len(draft["mcp"]), len(draft["plugins"]["claude"]), len(unassigned)))
    else:
        sys.stdout.write(text)
    return EXIT_OK


# --------------------------------------------------------------------------- LaunchAgent

def plist_path() -> Path:
    return home() / "Library" / "LaunchAgents" / (LABEL + ".plist")


def check_script_location() -> None:
    """Der LaunchAgent darf nicht auf ein Skript zeigen, das in einem Skill-Ordner liegt (wird von ai-sync selbst
    ueberschrieben)."""
    candidates = {os.path.abspath(__file__), os.path.realpath(__file__)}
    for rel in SKILL_ROOTS.values():
        root = home() / rel
        for base in {os.path.abspath(str(root)), os.path.realpath(str(root))}:
            if any(c.startswith(base + os.sep) for c in candidates):
                raise SyncError("install-agent verweigert: ai_sync.py liegt unter ~/%s. Skript zuerst an einen festen Ort "
                                "ausserhalb der Skill-Ordner kopieren und von dort installieren (siehe README)." % rel)


def agent_path() -> str:
    """Fester PATH fuer den LaunchAgent aus den Ordnern von git, claude, codex; Ordner duerfen fuer Gruppe/Welt nicht
    beschreibbar sein."""
    dirs = []
    for name in ("git", "claude", "codex"):
        found = shutil.which(name)
        if not found:
            if name == "git":
                raise SyncError("git nicht gefunden")
            print("Hinweis: %s nicht gefunden, nicht im PATH des LaunchAgents" % name)
            continue
        found = os.path.abspath(found)
        for folder in {os.path.dirname(found), os.path.dirname(os.path.realpath(found))}:
            if os.stat(folder).st_mode & 0o022:
                raise SyncError("%s liegt in %s, das fuer Gruppe oder Welt beschreibbar ist; Installation abgebrochen" % (name, folder))
        if os.path.dirname(found) not in dirs:
            dirs.append(os.path.dirname(found))
    for folder in ("/usr/bin", "/bin"):
        if folder not in dirs:
            dirs.append(folder)
    return ":".join(dirs)


def do_install_agent(args) -> int:
    check_script_location()
    script = os.path.realpath(__file__)
    env = {"PATH": agent_path()}
    if os.environ.get("MGD_AI_SYNC_HOME"):
        env["MGD_AI_SYNC_HOME"] = os.environ["MGD_AI_SYNC_HOME"]
    logs = state_dir() / "logs"
    private_mkdir(logs)
    fd = os.open(str(logs / "agent.log"), os.O_WRONLY | os.O_APPEND | os.O_CREAT, 0o600)
    os.fchmod(fd, 0o600)
    os.close(fd)
    prog = [sys.executable, script, "agent-run"]
    if args.manifest:
        prog += ["--manifest", os.path.abspath(args.manifest)]
    if args.config:
        prog += ["--config", os.path.abspath(args.config)]
    data = {"Label": LABEL, "ProgramArguments": prog, "RunAtLoad": True,
            "StartCalendarInterval": {"Hour": 9, "Minute": 30}, "EnvironmentVariables": env,
            "StandardOutPath": str(logs / "agent.log"), "StandardErrorPath": str(logs / "agent.log"),
            "ProcessType": "Background"}
    write_atomic(plist_path(), plistlib.dumps(data))
    print("LaunchAgent geschrieben: %s" % plist_path())
    if not args.no_load:
        uid = str(os.getuid())
        run([tool("launchctl"), "bootout", "gui/%s/%s" % (uid, LABEL)], timeout=30)
        rc, _, err = run([tool("launchctl"), "bootstrap", "gui/%s" % uid, str(plist_path())], timeout=30)
        if rc != 0:
            print("Warnung: launchctl bootstrap fehlgeschlagen: %s" % short(err, 150), file=sys.stderr)
            return EXIT_ERROR
        print("LaunchAgent geladen (taeglich 09:30 und bei Anmeldung; fuehrt nur 'plan' aus, ausser autoApply=true).")
    return EXIT_OK


def do_uninstall_agent(args) -> int:
    run([tool("launchctl"), "bootout", "gui/%s/%s" % (os.getuid(), LABEL)], timeout=30)
    if plist_path().exists():
        plist_path().unlink()
        print("LaunchAgent entfernt.")
    else:
        print("LaunchAgent war nicht installiert.")
    return EXIT_OK


def notify(text: str) -> None:
    # Text besteht ausschliesslich aus festen Woertern und Zahlen.
    run([tool("osascript"), "-e", 'display notification "%s" with title "MGD ai-sync"' % text], timeout=20)


def log_line(text: str) -> None:
    logs = state_dir() / "logs"
    private_mkdir(logs)
    fd = os.open(str(logs / "ai-sync.log"), os.O_WRONLY | os.O_APPEND | os.O_CREAT, 0o600)
    with os.fdopen(fd, "a", encoding="utf-8") as handle:
        os.fchmod(handle.fileno(), 0o600)
        handle.write("%s %s\n" % (now_iso(), scrub(text)))


# --------------------------------------------------------------------------- Kommandos

def run_plan_like(args, apply_mode: bool, mode_label=None, kinds=None, agent: bool = False):
    cfg = load_config(args.config)
    repos = Repos(cfg)
    manifest, desc, sha = load_manifest_for_run(args, cfg, repos)
    overwrite = parse_selectors(getattr(args, "overwrite", None), "--overwrite")
    adopt = parse_selectors(getattr(args, "adopt", None), "--adopt")
    items = build_items(manifest, cfg, repos, restore=apply_mode, agent=agent)
    if apply_mode:
        apply_items(items, overwrite, adopt, kinds)
    return cfg, items, build_report(items, mode_label or ("apply" if apply_mode else "plan"), desc, sha)


def finish(items, report) -> int:
    print(render_text(report))
    return exit_code_for(items)


def do_report(args) -> int:
    _, items, report = run_plan_like(args, False)
    write_atomic(Path(args.json), scrub(json.dumps(report, indent=2, ensure_ascii=False) + "\n"), mode=0o600)
    print("Bericht geschrieben: %s" % args.json)
    return exit_code_for(items)


def do_agent_run(args) -> int:
    notify_on = True
    try:
        cfg = load_config(args.config)
        notify_on = cfg.get("notify", True)
        auto = cfg.get("autoApply") is True
        # autoApply wendet nur Skills und Commands an; MCP und Plugins bleiben offene Aktionen
        _, items, report = run_plan_like(args, auto, "apply" if auto else "plan",
                                         kinds=("skill", "command") if auto else None, agent=True)
    except (SyncError, OSError, ValueError) as exc:
        message = short(exc)
        report = {"schemaVersion": SCHEMA_VERSION, "tool": "ai-sync", "toolVersion": VERSION, "device": device_name(),
                  "generatedAt": now_iso(), "mode": "error", "error": message,
                  "summary": {"counts": {}, "openActions": 0, "warnings": 0, "errors": 1}, "entries": []}
        try:
            write_private(state_dir() / "last-report.json", scrub(json.dumps(report, indent=2, ensure_ascii=False) + "\n"))
        except OSError:
            pass
        log_line("agent-run error: exit %d, %s" % (EXIT_ERROR, message))
        if notify_on:
            notify("Fehler beim Abgleich. Details: ai-sync plan")
        return EXIT_ERROR
    write_private(state_dir() / "last-report.json", scrub(json.dumps(report, indent=2, ensure_ascii=False) + "\n"))
    code = exit_code_for(items)
    log_line("agent-run %s: exit %d, %s" % (report["mode"], code, json.dumps(report["summary"]["counts"], sort_keys=True)))
    if code != EXIT_OK and cfg.get("notify", True):
        new = sum(1 for i in items if i.get("statusNachher", i["status"]) in (S_NEW, S_MISSING))
        manual = sum(1 for i in items if i.get("statusNachher", i["status"]) in (S_CHANGED, S_UNKNOWN, S_DIFF, S_ADOPT, S_WARN, S_BLOCKED))
        errors = report["summary"]["errors"]
        notify("%d neu oder fehlend, %d manuell pruefen, %d Fehler. Details: ai-sync plan" % (new, manual, errors))
    return code


def build_parser():
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--manifest", help="Pfad zur Manifest-Datei (sonst aus der Konfig)")
    common.add_argument("--config", help="Pfad zur Konfig-Datei (Standard: <Status-Ordner>/config.json)")
    parser = argparse.ArgumentParser(prog="ai_sync.py", description=__doc__.split("\n")[0])
    sub = parser.add_subparsers(dest="command")
    sub.add_parser("plan", parents=[common], help="Trockenlauf (Standard): zeigt Status und geplante Aktion")
    ap = sub.add_parser("apply", parents=[common], help="fuehrt nur sichere Aktionen aus")
    ap.add_argument("--overwrite", action="append", metavar="NAME", help="lokal geaenderten Eintrag NAME mit Backup ueberschreiben")
    ap.add_argument("--adopt", action="append", metavar="NAME", help="Stempel fuer identischen Eintrag NAME setzen")
    ex = sub.add_parser("export", parents=[common], help="Manifest-Entwurf aus dieser Installation")
    ex.add_argument("--output", help="Datei fuer den Entwurf (sonst Standardausgabe)")
    rp = sub.add_parser("report", parents=[common], help="maschinenlesbarer Bericht")
    rp.add_argument("--json", required=True, metavar="DATEI", help="Zieldatei fuer den JSON-Bericht")
    ia = sub.add_parser("install-agent", parents=[common], help="LaunchAgent anlegen")
    ia.add_argument("--no-load", action="store_true", help="nur die plist schreiben, nicht laden")
    sub.add_parser("uninstall-agent", parents=[common], help="LaunchAgent entfernen")
    sub.add_parser("agent-run", parents=[common], help=argparse.SUPPRESS)
    return parser


def main(argv=None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    if not argv or (argv[0].startswith("-") and argv[0] not in ("-h", "--help")):
        argv.insert(0, "plan")
    args = build_parser().parse_args(argv)
    try:
        if args.command == "export":
            return do_export(args)
        if args.command == "uninstall-agent":
            return do_uninstall_agent(args)
        if args.command == "install-agent":
            return do_install_agent(args)
        with Lock():
            if args.command == "plan":
                _, items, report = run_plan_like(args, False)
                return finish(items, report)
            if args.command == "apply":
                _, items, report = run_plan_like(args, True)
                return finish(items, report)
            if args.command == "report":
                return do_report(args)
            if args.command == "agent-run":
                return do_agent_run(args)
    except LockBusy:
        print("Ein anderer ai-sync-Lauf ist aktiv (Lock-Datei).", file=sys.stderr)
        return EXIT_LOCKED
    except SyncError as exc:
        print("Fehler: %s" % scrub(exc), file=sys.stderr)
        return EXIT_ERROR
    except (OSError, ValueError) as exc:
        print("Fehler: %s (%s)" % (exc.__class__.__name__, short(exc, 200)), file=sys.stderr)
        return EXIT_ERROR
    except Exception as exc:  # bewusst ohne Meldungstext: koennte Secrets enthalten
        print("Fehler: unerwarteter interner Fehler (%s)" % exc.__class__.__name__, file=sys.stderr)
        return EXIT_ERROR
    return EXIT_ERROR


if __name__ == "__main__":
    sys.exit(main())
