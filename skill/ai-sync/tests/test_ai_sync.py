"""Offline-Tests fuer ai-sync: temporaeres HOME, lokale Git-Repos als Fake-GitHub,
Fake-CLIs (claude, codex, security, launchctl, osascript) im PATH."""
import contextlib
import fcntl
import io
import json
import os
import plistlib
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path
from unittest import mock

HERE = Path(__file__).resolve().parent
TOOL = HERE.parent / "ai_sync.py"
sys.path.insert(0, str(HERE.parent))
import ai_sync  # noqa: E402

SECRET = "s3cr3t-T0ken-4711"

FAKE_CLAUDE = r'''
import json, os, sys
os.umask(0o077)  # wie die echte CLI: ~/.claude.json bekommt 0600
a = sys.argv[1:]
open(os.environ["FAKE_LOG"], "a").write(json.dumps(["claude"] + a) + "\n")
home = os.environ["HOME"]
cj = home + "/.claude.json"
pj = home + "/fake-plugins.json"
def load(p, d):
    return json.load(open(p)) if os.path.exists(p) else d
if a[:2] == ["mcp", "add"]:
    if "FAILME" in a:
        sys.stderr.write("add kaputt\n")
        sys.exit(1)
    rest = a[2:]
    sep = rest.index("--")
    before, cmd = rest[:sep], rest[sep + 1:]
    name, env, i = None, {}, 0
    while i < len(before):
        if before[i] == "-s":
            i += 2
        elif before[i] == "-e":
            for pair in before[i + 1:]:
                k, _, v = pair.partition("=")
                env[k] = v
            break
        else:
            name = before[i]; i += 1
    d = load(cj, {})
    d.setdefault("mcpServers", {})[name] = {"type": "stdio", "command": cmd[0], "args": cmd[1:], "env": env}
    json.dump(d, open(cj, "w"))
elif a[:2] == ["mcp", "remove"]:
    if os.environ.get("FAKE_REMOVE_FAIL"):
        sys.stderr.write("remove kaputt\n")
        sys.exit(1)
    d = load(cj, {})
    d.get("mcpServers", {}).pop(a[-1], None)
    json.dump(d, open(cj, "w"))
elif a[:2] == ["plugin", "list"]:
    print(json.dumps([{"id": i} for i in load(pj, {}).get("plugins", [])]))
elif a[:3] == ["plugin", "marketplace", "list"]:
    if os.environ.get("FAKE_MARKET_FAIL"):
        sys.exit(1)
    print(json.dumps(load(pj, {}).get("markets", [])))
elif a[:3] == ["plugin", "marketplace", "add"]:
    d = load(pj, {})
    d.setdefault("markets", []).append({"name": a[3].split("/")[1].lower(), "source": "git", "url": "https://github.com/%s.git" % a[3]})
    json.dump(d, open(pj, "w"))
elif a[:2] == ["plugin", "install"]:
    d = load(pj, {})
    d.setdefault("plugins", []).append(a[2])
    json.dump(d, open(pj, "w"))
'''

FAKE_CODEX = r'''
import json, os, sys
os.umask(0o077)
a = sys.argv[1:]
open(os.environ["FAKE_LOG"], "a").write(json.dumps(["codex"] + a) + "\n")
if a[:3] == ["mcp", "add", "--help"]:
    sys.exit(2 if os.environ.get("FAKE_CODEX_NOMCP") else 0)
if a[:2] == ["mcp", "remove"]:
    p = os.environ["HOME"] + "/.codex/config.toml"
    if os.path.exists(p):
        out, skip = [], False
        for line in open(p).read().splitlines(True):
            if line.startswith("["):
                skip = line.strip() in ("[mcp_servers.%s]" % a[2], "[mcp_servers.%s.env]" % a[2])
            if not skip:
                out.append(line)
        open(p, "w").write("".join(out))
if a[:2] == ["mcp", "add"]:
    if "FAILME" in a:
        sys.stderr.write("add kaputt\n")
        sys.exit(1)
    rest = a[2:]
    sep = rest.index("--")
    p = os.environ["HOME"] + "/.codex/config.toml"
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "a") as f:
        f.write("\n[mcp_servers.%s]\ncommand = %s\nargs = %s\n" % (rest[0], json.dumps(rest[sep + 1]), json.dumps(rest[sep + 2:])))
        env = [rest[i + 1] for i in range(sep) if rest[i] == "--env"]
        if env:
            f.write("\n[mcp_servers.%s.env]\n" % rest[0])
            for pair in env:
                k, _, v = pair.partition("=")
                f.write("%s = %s\n" % (k, json.dumps(v)))
'''

FAKE_SECURITY = r'''
import json, os, sys
a = sys.argv[1:]
open(os.environ["FAKE_LOG"], "a").write(json.dumps(["security"] + [x for x in a]) + "\n")
p = os.environ["HOME"] + "/keychain.json"
kc = json.load(open(p)) if os.path.exists(p) else {}
svc = a[a.index("-s") + 1]
if svc not in kc:
    sys.exit(44)
if "-w" in a:
    print(kc[svc])
'''

FAKE_LOGONLY = r'''
import json, os, sys
open(os.environ["FAKE_LOG"], "a").write(json.dumps([os.path.basename(sys.argv[0])] + sys.argv[1:]) + "\n")
'''

SKILL_MD = "---\nname: %s\ndescription: Test\n---\n# %s\n"


def tree(root):
    out = {}
    for cur, dirs, files in os.walk(str(root)):
        for f in files:
            p = Path(cur) / f
            out[str(p.relative_to(root))] = p.read_bytes()
    return out


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="aisync-test-")).resolve()
        self.addCleanup(shutil.rmtree, str(self.tmp), True)
        self.home = self.tmp / "home"
        self.home.mkdir()
        self.state = self.tmp / "state"
        self.gh = self.tmp / "gh"
        self.fakebin = self.tmp / "bin"
        self.fakebin.mkdir()
        self.log = self.tmp / "fake.log"
        self.log.write_text("")
        for name, body in (("claude", FAKE_CLAUDE), ("codex", FAKE_CODEX), ("security", FAKE_SECURITY),
                           ("launchctl", FAKE_LOGONLY), ("osascript", FAKE_LOGONLY)):
            p = self.fakebin / name
            p.write_text("#!%s\n%s" % (sys.executable, body))
            p.chmod(0o755)
        self.env = {"HOME": str(self.home), "PATH": "%s:/usr/bin:/bin" % self.fakebin,
                    "MGD_AI_SYNC_HOME": str(self.state), "MGD_AI_SYNC_TESTING": "1",
                    "MGD_AI_SYNC_TEST_SOURCE_BASE": "file://%s" % self.gh, "FAKE_LOG": str(self.log),
                    "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t", "GIT_COMMITTER_NAME": "t",
                    "GIT_COMMITTER_EMAIL": "t@t", "PYTHONDONTWRITEBYTECODE": "1", "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_NOSYSTEM": "1",
                    "MGD_AI_SYNC_TEST_BIN": str(self.fakebin)}

    # -- Fake-GitHub
    def repo_dir(self, name, owner="MichaelGahnDESIGN"):
        return self.gh / owner / name

    def make_repo(self, name, files, owner="MichaelGahnDESIGN"):
        d = self.repo_dir(name, owner)
        d.mkdir(parents=True)
        subprocess.run(["git", "init", "-q", "-b", "main", str(d)], check=True, env=dict(os.environ, **self.env))
        self.commit(name, files, owner)

    def commit(self, name, files, owner="MichaelGahnDESIGN"):
        d = self.repo_dir(name, owner)
        for rel, content in files.items():
            p = d / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(content)
        env = dict(os.environ, **self.env)
        subprocess.run(["git", "-C", str(d), "add", "-A"], check=True, env=env)
        subprocess.run(["git", "-C", str(d), "commit", "-q", "-m", "x"], check=True, env=env)

    # -- Aufrufe
    def manifest(self, data, name="manifest.json"):
        p = self.tmp / name
        p.write_text(json.dumps(data))
        return str(p)

    def cli(self, *args, env=None):
        e = dict(self.env)
        e.update(env or {})
        return subprocess.run([sys.executable, str(TOOL)] + list(args), capture_output=True, text=True, env=e)

    def skill_manifest(self, targets=("claude", "codex"), name="alpha", repo="skill-alpha", path="skills/alpha", **extra):
        entry = {"name": name, "repo": repo, "path": path, "targets": list(targets)}
        entry.update(extra)
        return self.manifest({"skills": [entry]})

    def setup_alpha(self):
        self.make_repo("skill-alpha", {"skills/alpha/SKILL.md": SKILL_MD % ("alpha", "v1"),
                                       "skills/alpha/ref/a.txt": "eins\n"})

    def report(self, manifest, *extra):
        out = self.tmp / "report.json"
        res = self.cli("report", "--json", str(out), "--manifest", manifest, *extra)
        return res, json.loads(out.read_text())

    def statuses(self, manifest):
        _, rep = self.report(manifest)
        return {(e["kind"], e["name"], e["target"]): e["status"] for e in rep["entries"]}

    def skill(self, target="claude", name="alpha"):
        return self.home / (".%s" % target) / "skills" / name

    def write_config(self, data):
        self.state.mkdir(parents=True, exist_ok=True)
        (self.state / "config.json").write_text(json.dumps(data))

    def head(self, name, owner="MichaelGahnDESIGN"):
        return subprocess.run(["git", "-C", str(self.repo_dir(name, owner)), "rev-parse", "HEAD"],
                              capture_output=True, text=True, check=True).stdout.strip()

    def calls(self):
        return [json.loads(l) for l in self.log.read_text().splitlines()]

    def mode(self, path):
        return stat.S_IMODE(os.stat(str(path)).st_mode)

    def inproc_env(self):
        return mock.patch.dict(os.environ, dict(self.env))


class SkillTests(Base):
    def test_plan_changes_nothing(self):
        self.setup_alpha()
        before = tree(self.home)
        res = self.cli("plan", "--manifest", self.skill_manifest())
        self.assertEqual(res.returncode, 1, res.stderr)
        self.assertIn("fehlt", res.stdout)
        self.assertIn("installieren", res.stdout)
        self.assertEqual(tree(self.home), before)
        self.assertFalse((self.home / ".claude").exists())

    def test_default_command_is_plan(self):
        self.setup_alpha()
        res = self.cli("--manifest", self.skill_manifest())
        self.assertIn("ai-sync plan", res.stdout)
        self.assertFalse((self.home / ".claude").exists())

    def test_apply_installs_missing_with_stamp(self):
        self.setup_alpha()
        m = self.skill_manifest()
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        for t in ("claude", "codex"):
            d = self.skill(t)
            self.assertEqual((d / "SKILL.md").read_text(), SKILL_MD % ("alpha", "v1"))
            stamp = json.loads((d / ".mgd-ai-sync.json").read_text())
            self.assertEqual(stamp["repo"], "MichaelGahnDESIGN/skill-alpha")
            self.assertEqual(stamp["path"], "skills/alpha")
            self.assertEqual(len(stamp["commit"]), 40)
            self.assertEqual(set(stamp["files"]), {"SKILL.md", "ref/a.txt"})
            self.assertEqual(stamp["files"]["ref/a.txt"], ai_sync.sha256_file(d / "ref/a.txt"))
            self.assertEqual(len(stamp["files"]["SKILL.md"]), 64)
        self.assertEqual(self.cli("plan", "--manifest", m).returncode, 0)
        self.assertEqual(self.statuses(m)[("skill", "alpha", "claude")], "aktuell")

    def test_github_newer_is_updated_with_backup(self):
        self.setup_alpha()
        m = self.skill_manifest(targets=("claude",))
        self.cli("apply", "--manifest", m)
        self.commit("skill-alpha", {"skills/alpha/ref/a.txt": "zwei\n"})
        self.assertEqual(self.statuses(m)[("skill", "alpha", "claude")], "github-neuer")
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 0, res.stdout)
        self.assertEqual((self.skill() / "ref/a.txt").read_text(), "zwei\n")
        backups = list((self.state / "backups").glob("*/claude/alpha/ref/a.txt"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), "eins\n")

    def test_locally_changed_is_not_overwritten(self):
        self.setup_alpha()
        m = self.skill_manifest(targets=("claude",))
        self.cli("apply", "--manifest", m)
        (self.skill() / "ref/a.txt").write_text("lokal\n")
        self.commit("skill-alpha", {"skills/alpha/ref/a.txt": "neu\n"})
        self.assertEqual(self.statuses(m)[("skill", "alpha", "claude")], "lokal-geaendert")
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 1)
        self.assertEqual((self.skill() / "ref/a.txt").read_text(), "lokal\n")

    def test_extra_local_file_counts_as_changed(self):
        self.setup_alpha()
        m = self.skill_manifest(targets=("claude",))
        self.cli("apply", "--manifest", m)
        (self.skill() / "notiz.md").write_text("x")
        self.assertEqual(self.statuses(m)[("skill", "alpha", "claude")], "lokal-geaendert")

    def test_overwrite_makes_backup(self):
        self.setup_alpha()
        m = self.skill_manifest(targets=("claude",))
        self.cli("apply", "--manifest", m)
        (self.skill() / "ref/a.txt").write_text("lokal\n")
        res = self.cli("apply", "--manifest", m, "--overwrite", "alpha")
        self.assertEqual(res.returncode, 0, res.stdout)
        self.assertEqual((self.skill() / "ref/a.txt").read_text(), "eins\n")
        backups = list((self.state / "backups").glob("*/claude/alpha/ref/a.txt"))
        self.assertEqual([b.read_text() for b in backups], ["lokal\n"])

    def test_unknown_is_never_overwritten_without_flag(self):
        self.setup_alpha()
        d = self.skill()
        d.mkdir(parents=True)
        (d / "SKILL.md").write_text("fremd")
        m = self.skill_manifest(targets=("claude",))
        self.assertEqual(self.statuses(m)[("skill", "alpha", "claude")], "unbekannt")
        self.cli("apply", "--manifest", m)
        self.assertEqual((d / "SKILL.md").read_text(), "fremd")
        self.assertFalse((d / ".mgd-ai-sync.json").exists())
        res = self.cli("apply", "--manifest", m, "--adopt", "alpha")
        self.assertIn("abgelehnt", res.stdout)
        self.assertEqual((d / "SKILL.md").read_text(), "fremd")

    def test_adopt_sets_stamp_only_when_identical(self):
        self.setup_alpha()
        d = self.skill()
        (d / "ref").mkdir(parents=True)
        (d / "SKILL.md").write_text(SKILL_MD % ("alpha", "v1"))
        (d / "ref/a.txt").write_text("eins\n")
        m = self.skill_manifest(targets=("claude",))
        self.assertEqual(self.statuses(m)[("skill", "alpha", "claude")], "adoptierbar")
        self.cli("apply", "--manifest", m)
        self.assertFalse((d / ".mgd-ai-sync.json").exists())
        res = self.cli("apply", "--manifest", m, "--adopt", "alpha")
        self.assertEqual(res.returncode, 0, res.stdout)
        self.assertTrue((d / ".mgd-ai-sync.json").exists())
        self.assertEqual(self.statuses(m)[("skill", "alpha", "claude")], "aktuell")
        self.assertEqual(not list((self.state / "backups").glob("*")), True)

    def test_install_name_and_agents_target(self):
        self.setup_alpha()
        m = self.skill_manifest(targets=("agents",), installName="alpha-x")
        self.cli("apply", "--manifest", m)
        self.assertTrue((self.home / ".agents/skills/alpha-x/SKILL.md").exists())

    def test_duplicate_names_warning(self):
        for d in ("dev", "MGD-DEV-Skill"):
            p = self.home / ".codex/skills" / d
            p.mkdir(parents=True)
            (p / "SKILL.md").write_text(SKILL_MD % ("dev", d))
        res, rep = self.report(self.manifest({}))
        warns = [e for e in rep["entries"] if e["kind"] == "warnung"]
        self.assertEqual(len(warns), 1)
        self.assertIn("Doppelter Skill-Name 'dev'", warns[0]["details"])
        self.assertEqual(res.returncode, 1)

    def test_stale_wrapper_warnings(self):
        cmds = self.home / ".claude/commands"
        cmds.mkdir(parents=True)
        (cmds / "weg.md").write_text("Lies `~/.claude/skills/fehlt/SKILL.md`.")
        (cmds / "alt.md").write_text("Lies `~/.claude/skills/neu/SKILL.md`.")
        sk = self.home / ".claude/skills/neu"
        sk.mkdir(parents=True)
        (sk / "SKILL.md").write_text(SKILL_MD % ("neu", "x"))
        old = time.time() - 1000
        os.utime(str(cmds / "alt.md"), (old, old))
        _, rep = self.report(self.manifest({}))
        details = " | ".join(e["details"] for e in rep["entries"] if e["kind"] == "warnung")
        self.assertIn("Skill 'fehlt'", details)
        self.assertIn("neuer als der Wrapper /alt", details)

    def test_report_schema(self):
        self.setup_alpha()
        res, rep = self.report(self.skill_manifest(targets=("claude",)))
        for key in ("schemaVersion", "device", "generatedAt", "entries", "summary", "manifest", "mode", "tool"):
            self.assertIn(key, rep)
        self.assertEqual(rep["schemaVersion"], 1)
        e = rep["entries"][0]
        for key in ("kind", "name", "target", "status", "aktion", "details"):
            self.assertIn(key, e)
        self.assertNotIn("_op", e)
        self.assertEqual(rep["summary"]["openActions"], 1)


class SafetyTests(Base):
    def test_path_traversal_rejected(self):
        self.setup_alpha()
        for extra in ({"path": "../skill-alpha"}, {"path": "/etc"}, {"installName": "../evil"},
                      {"name": "../evil"}, {"path": "skills/../../x"}):
            entry = {"name": "alpha", "repo": "skill-alpha", "path": "skills/alpha", "targets": ["claude"]}
            entry.update(extra)
            m = self.manifest({"skills": [entry]})
            res = self.cli("apply", "--manifest", m)
            self.assertEqual(res.returncode, 2, (extra, res.stdout))
            self.assertIn("ungueltig", res.stdout)
        self.assertFalse((self.home / ".claude").exists())
        self.assertFalse((self.tmp / "evil").exists())

    def test_owner_allowlist(self):
        self.make_repo("fremd", {"SKILL.md": SKILL_MD % ("fremd", "x")}, owner="Evil")
        m = self.manifest({"skills": [{"name": "fremd", "repo": "Evil/fremd", "path": ".", "targets": ["claude"]}]})
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 2)
        self.assertIn("allowedOwners", res.stdout)
        self.assertFalse(self.skill(name="fremd").exists())
        cfg = self.tmp / "config.json"
        cfg.write_text(json.dumps({"allowedOwners": ["MichaelGahnDESIGN", "Evil"]}))
        res = self.cli("apply", "--manifest", m, "--config", str(cfg))
        self.assertEqual(res.returncode, 0, res.stdout)
        self.assertTrue(self.skill(name="fremd").exists())

    def test_lock_blocks_parallel_run(self):
        self.setup_alpha()
        self.state.mkdir(parents=True, exist_ok=True)
        fd = os.open(str(self.state / "ai-sync.lock"), os.O_CREAT | os.O_RDWR)
        fcntl.flock(fd, fcntl.LOCK_EX)
        try:
            res = self.cli("apply", "--manifest", self.skill_manifest())
        finally:
            os.close(fd)
        self.assertEqual(res.returncode, 4)
        self.assertFalse((self.home / ".claude").exists())
        self.assertEqual(self.cli("plan", "--manifest", self.skill_manifest()).returncode, 1)

    def test_no_plaintext_secret_in_manifest(self):
        m = self.manifest({"mcp": [{"name": "x", "command": "npx", "args": [], "env": {"API_KEY": SECRET},
                                    "targets": ["claude"]}]})
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 2)
        self.assertNotIn(SECRET, res.stdout + res.stderr)
        self.assertNotIn("add", self.log.read_text())

    def test_symlink_target_is_not_touched(self):
        self.setup_alpha()
        real = self.tmp / "real"
        real.mkdir()
        (real / "x").write_text("x")
        (self.home / ".claude/skills").mkdir(parents=True)
        os.symlink(str(real), str(self.skill()))
        self.cli("apply", "--manifest", self.skill_manifest(targets=("claude",)), "--overwrite", "alpha")
        self.assertTrue(os.path.islink(str(self.skill())))
        self.assertEqual(os.listdir(str(real)), ["x"])


class CommandTests(Base):
    def test_command_install_and_codex_open(self):
        self.make_repo("cmds", {"c/hello.md": "# hallo\n"})
        m = self.manifest({"commands": [{"name": "hello", "repo": "cmds", "path": "c/hello.md",
                                         "targets": ["claude", "codex"]}]})
        res = self.cli("apply", "--manifest", m)
        self.assertEqual((self.home / ".claude/commands/hello.md").read_text(), "# hallo\n")
        st = self.statuses(m)
        self.assertEqual(st[("command", "hello", "claude")], "aktuell")
        self.assertEqual(st[("command", "hello", "codex")], "offen")
        self.assertFalse((self.home / ".codex/prompts").exists())
        (self.home / ".claude/commands/hello.md").write_text("lokal")
        self.commit("cmds", {"c/hello.md": "# neu\n"})
        self.cli("apply", "--manifest", m)
        self.assertEqual((self.home / ".claude/commands/hello.md").read_text(), "lokal")
        self.assertEqual(self.statuses(m)[("command", "hello", "claude")], "lokal-geaendert")


class McpTests(Base):
    def setUp(self):
        super().setUp()
        self.write_config({"allowedSecretRefs": {"keychain:my-dienst": ["svc"], "env:MY_VAR": ["svc"]}})

    def mcp_manifest(self, targets=("claude",), env=None):
        return self.manifest({"mcp": [{"name": "svc", "command": "npx", "args": ["-y", "svc-mcp"],
                                       "env": env if env is not None else {"API_KEY": "keychain:my-dienst"},
                                       "targets": list(targets)}]})

    def test_secret_only_in_cli_call(self):
        (self.home / "keychain.json").write_text(json.dumps({"my-dienst": SECRET}))
        m = self.mcp_manifest(targets=("claude", "codex"))
        out_report = self.tmp / "r.json"
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        calls = [json.loads(l) for l in self.log.read_text().splitlines()]
        adds = [c for c in calls if c[1:3] == ["mcp", "add"] and "--help" not in c]
        self.assertEqual(len(adds), 2)
        self.assertTrue(all("API_KEY=%s" % SECRET in c for c in adds))
        self.assertIn("-s", adds[0])
        self.assertEqual(adds[0][adds[0].index("-s") + 1], "user")
        # Plan-Pruefung fragt Schluesselbund nie mit -w
        self.assertTrue(any(c[0] == "security" and "-w" not in c for c in calls))
        self.cli("report", "--json", str(out_report), "--manifest", m)
        blobs = [res.stdout, res.stderr, out_report.read_text()]
        for f in self.state.rglob("*"):
            if f.is_file() and f.suffix in (".json", ".log"):
                blobs.append(f.read_text())
        for blob in blobs:
            self.assertNotIn(SECRET, blob)
        self.assertEqual(self.statuses(m)[("mcp", "svc", "claude")], "aktuell")

    def test_secret_from_env_var(self):
        m = self.mcp_manifest(env={"API_KEY": "env:MY_VAR"})
        res = self.cli("apply", "--manifest", m, env={"MY_VAR": SECRET})
        self.assertEqual(res.returncode, 0, res.stdout)
        self.assertNotIn(SECRET, res.stdout + res.stderr)
        self.assertIn("API_KEY=%s" % SECRET, self.log.read_text())

    def test_missing_secret_blocks(self):
        m = self.mcp_manifest()
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 1)
        self.assertIn("blockiert", res.stdout)
        self.assertNotIn('"mcp", "add"', self.log.read_text())

    def test_no_env_and_overwrite(self):
        m = self.mcp_manifest(env={})
        self.cli("apply", "--manifest", m)
        data = json.loads((self.home / ".claude.json").read_text())
        self.assertEqual(data["mcpServers"]["svc"]["args"], ["-y", "svc-mcp"])
        data["mcpServers"]["svc"]["args"] = ["anders"]
        (self.home / ".claude.json").write_text(json.dumps(data))
        self.assertEqual(self.statuses(m)[("mcp", "svc", "claude")], "abweichend")
        self.cli("apply", "--manifest", m)
        self.assertEqual(json.loads((self.home / ".claude.json").read_text())["mcpServers"]["svc"]["args"], ["anders"])
        self.cli("apply", "--manifest", m, "--overwrite", "svc")
        self.assertEqual(json.loads((self.home / ".claude.json").read_text())["mcpServers"]["svc"]["args"], ["-y", "svc-mcp"])

    def test_codex_fallback_editor_keeps_rest_bytegleich(self):
        cfg = self.home / ".codex/config.toml"
        cfg.parent.mkdir(parents=True)
        original = ('model = "x"\r\n# Kommentar  \n\n[mcp_servers.other]\ncommand = "a"\n\n'
                    '[mcp_servers.other.tools.t]\napproval_mode = "approve"\n').encode()
        cfg.write_bytes(original)
        m = self.mcp_manifest(targets=("codex",), env={})
        res = self.cli("apply", "--manifest", m, env={"FAKE_CODEX_NOMCP": "1"})
        self.assertEqual(res.returncode, 0, res.stdout)
        self.assertIn("Fallback-Editor", res.stdout)
        new = cfg.read_bytes()
        self.assertTrue(new.startswith(original))
        self.assertIn(b'[mcp_servers.svc]\ncommand = "npx"', new)
        backups = list((self.state / "backups").glob("*/codex-config/config.toml.*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_bytes(), original)
        self.assertEqual(self.statuses(m)[("mcp", "svc", "codex")], "aktuell")
        self.assertNotIn('"mcp", "add", "svc"', self.log.read_text())

    def test_codex_cli_used_when_available(self):
        m = self.mcp_manifest(targets=("codex",), env={})
        self.cli("apply", "--manifest", m)
        self.assertIn('["codex", "mcp", "add", "svc", "--", "npx", "-y", "svc-mcp"]', self.log.read_text())
        self.assertEqual(self.statuses(m)[("mcp", "svc", "codex")], "aktuell")

    def test_toml_editor_unit(self):
        base = 'a = 1\n\n[x]\ny = 2\n'
        added = ai_sync.toml_set_mcp(base, "n", "cmd", ["a b"], {"K": "v\"q"})
        self.assertTrue(added.startswith(base))
        again = ai_sync.toml_set_mcp(added, "n", "cmd2", [], {})
        self.assertTrue(again.startswith(base))
        self.assertIn('command = "cmd2"', again)
        self.assertNotIn("cmd\"", again)
        self.assertNotIn("K =", again)
        self.assertEqual(ai_sync.toml_remove_mcp(again, "n"), base + "\n" if not base.endswith("\n\n") else base)
        # Block in der Mitte: Rest davor und danach unveraendert
        mid = 'a = 1\n[mcp_servers.n]\ncommand = "old"\n[z]\nq = 3\n'
        res = ai_sync.toml_set_mcp(mid, "n", "new", [], {})
        self.assertTrue(res.startswith("a = 1\n"))
        self.assertTrue(res.endswith("[z]\nq = 3\n"))
        parsed = ai_sync.parse_codex_mcp(res)
        self.assertEqual(parsed["n"]["command"], "new")


class PluginExportAgentTests(Base):
    def test_plugin_apply(self):
        self.write_config({"allowedMarketplaces": ["affaan-m/ECC"]})
        m = self.manifest({"plugins": {"claude": [{"marketplace": "affaan-m/ECC", "marketplaceName": "ecc", "name": "ecc"}]}})
        self.assertEqual(self.statuses(m)[("plugin", "ecc", "claude")], "fehlt")
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 0, res.stdout)
        log = self.log.read_text()
        self.assertIn('["claude", "plugin", "marketplace", "add", "affaan-m/ECC"]', log)
        self.assertIn('["claude", "plugin", "install", "ecc@ecc"]', log)
        self.assertEqual(self.statuses(m)[("plugin", "ecc", "claude")], "aktuell")

    def test_plugin_marketplace_allowlist(self):
        m = self.manifest({"plugins": {"claude": [{"marketplace": "evil/x", "name": "p"}]}})
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 2)
        self.assertNotIn("install", self.log.read_text())

    def test_export_has_no_secret_values(self):
        self.write_config({"allowedMarketplaces": ["affaan-m/ECC"]})
        self.setup_alpha()
        self.cli("apply", "--manifest", self.skill_manifest(targets=("claude",)))
        (self.home / ".claude.json").write_text(json.dumps({"mcpServers": {
            "svc": {"type": "stdio", "command": "npx", "args": ["-y", "x"], "env": {"API_KEY": SECRET}},
            "web": {"type": "http", "url": "https://x.example/mcp?token=%s" % SECRET}}}))
        (self.home / ".codex").mkdir()
        (self.home / ".codex/config.toml").write_text(
            '[mcp_servers.svc]\ncommand = "npx"\nargs = ["-y", "x"]\n\n[mcp_servers.svc.env]\nAPI_KEY = "%s"\n' % SECRET)
        (self.home / "fake-plugins.json").write_text(json.dumps({
            "plugins": ["ecc@ecc"], "markets": [{"name": "ecc", "source": "git", "url": "https://github.com/affaan-m/ECC.git"}]}))
        out = self.tmp / "export.json"
        res = self.cli("export", "--output", str(out))
        self.assertEqual(res.returncode, 0, res.stderr)
        text = out.read_text()
        self.assertNotIn(SECRET, text + res.stdout)
        data = json.loads(text)
        self.assertEqual(data["skills"][0]["repo"], "MichaelGahnDESIGN/skill-alpha")
        self.assertEqual(data["skills"][0]["path"], "skills/alpha")
        self.assertEqual(data["mcp"][0]["targets"], ["claude", "codex"])
        self.assertEqual(data["mcp"][0]["env"], {"API_KEY": "env:API_KEY"})
        self.assertEqual(data["plugins"]["claude"][0]["name"], "ecc")
        # Entwurf ist als Manifest wieder lesbar
        res = self.cli("plan", "--manifest", str(out))
        self.assertNotIn("ungueltig", res.stdout)

    def test_install_and_uninstall_agent(self):
        res = self.cli("install-agent", "--no-load")
        self.assertEqual(res.returncode, 0, res.stderr)
        plist = plistlib.loads((self.home / "Library/LaunchAgents/de.michael-gahn.devos.ai-sync.plist").read_bytes())
        self.assertEqual(plist["Label"], "de.michael-gahn.devos.ai-sync")
        self.assertIn("agent-run", plist["ProgramArguments"])
        self.assertNotIn("apply", plist["ProgramArguments"])
        self.assertTrue(plist["RunAtLoad"])
        self.assertIn("StartCalendarInterval", plist)
        self.cli("uninstall-agent")
        self.assertFalse((self.home / "Library/LaunchAgents/de.michael-gahn.devos.ai-sync.plist").exists())

    def test_agent_run_plans_and_notifies_without_autoapply(self):
        self.setup_alpha()
        m = self.skill_manifest(targets=("claude",))
        res = self.cli("agent-run", "--manifest", m)
        self.assertEqual(res.returncode, 1)
        self.assertFalse((self.home / ".claude").exists())
        self.assertIn("display notification", self.log.read_text())
        self.assertTrue((self.state / "last-report.json").exists())

    def test_agent_run_autoapply(self):
        self.setup_alpha()
        m = self.skill_manifest(targets=("claude",))
        cfg = self.tmp / "config.json"
        cfg.write_text(json.dumps({"autoApply": True}))
        res = self.cli("agent-run", "--manifest", m, "--config", str(cfg))
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertTrue(self.skill().exists())

    def test_manifest_from_git_source_in_config(self):
        self.setup_alpha()
        self.make_repo("private-manifest", {"m/manifest.json": json.dumps(
            {"skills": [{"name": "alpha", "repo": "skill-alpha", "path": "skills/alpha", "targets": ["claude"]}]})})
        cfg = self.tmp / "config.json"
        cfg.write_text(json.dumps({"manifest": {"repo": "private-manifest", "branch": "main", "path": "m/manifest.json"}}))
        res = self.cli("apply", "--config", str(cfg))
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertTrue(self.skill().exists())
        cfg.write_text(json.dumps({"manifest": {"repo": "private-manifest", "path": "../x.json"}}))
        self.assertEqual(self.cli("plan", "--config", str(cfg)).returncode, 2)


# =========================================================================== Sicherheit (S1-S10)

class SecurityTests(Base):
    def mcp_manifest(self, command="npx", env=None, name="svc"):
        return self.manifest({"mcp": [{"name": name, "command": command, "args": ["-y", "x"],
                                       "env": env if env is not None else {}, "targets": ["claude"]}]})

    # S1
    def test_s1_autoapply_only_skills_and_commands(self):
        self.setup_alpha()
        self.make_repo("cmds", {"c/hello.md": "# hallo\n"})
        m = self.manifest({
            "skills": [{"name": "alpha", "repo": "skill-alpha", "path": "skills/alpha", "targets": ["claude"]}],
            "commands": [{"name": "hello", "repo": "cmds", "path": "c/hello.md", "targets": ["claude"]}],
            "mcp": [{"name": "svc", "command": "npx", "args": ["-y", "x"], "env": {}, "targets": ["claude"]}],
            "plugins": {"claude": [{"marketplace": "affaan-m/ECC", "marketplaceName": "ecc", "name": "ecc"}]}})
        cfg = self.tmp / "config.json"
        cfg.write_text(json.dumps({"autoApply": True, "allowedMarketplaces": ["affaan-m/ECC"]}))
        res = self.cli("agent-run", "--manifest", m, "--config", str(cfg))
        self.assertEqual(res.returncode, 1, res.stdout + res.stderr)
        self.assertTrue(self.skill().exists())
        self.assertTrue((self.home / ".claude/commands/hello.md").exists())
        log = self.log.read_text()
        self.assertNotIn('"mcp", "add"', log)
        self.assertNotIn('"install"', log)
        self.assertNotIn('"marketplace", "add"', log)
        rep = json.loads((self.state / "last-report.json").read_text())
        seen = 0
        for e in rep["entries"]:
            if e["kind"] in ("mcp", "plugin"):
                seen += 1
                self.assertFalse(e["ausgefuehrt"])
                self.assertEqual(e["aktion"], "installieren")
        self.assertEqual(seen, 2)

    def test_s1_autoapply_default_is_false(self):
        self.assertIs(ai_sync.load_config(self.tmp / "gibt-es-nicht.json")["autoApply"], False)

    # S2
    def test_s2_default_allowed_mcp_commands(self):
        self.assertEqual(ai_sync.load_config(self.tmp / "gibt-es-nicht.json")["allowedMcpCommands"], ["npx", "uvx", "node"])

    def test_s2_other_command_is_blocked(self):
        m = self.mcp_manifest(command="bash")
        for sub in ("plan", "apply"):
            res = self.cli(sub, "--manifest", m)
            self.assertEqual(res.returncode, 1, res.stdout + res.stderr)
        self.assertEqual(self.statuses(m)[("mcp", "svc", "claude")], "blockiert")
        self.assertNotIn('"mcp", "add"', self.log.read_text())
        self.assertFalse((self.home / ".claude.json").exists())

    def test_s2_manifest_cannot_extend_allowlist(self):
        m = self.manifest({"allowedMcpCommands": ["bash"], "mcp": [
            {"name": "svc", "command": "bash", "args": [], "env": {}, "targets": ["claude"],
             "allowedMcpCommands": ["bash"]}]})
        self.cli("apply", "--manifest", m)
        self.assertEqual(self.statuses(m)[("mcp", "svc", "claude")], "blockiert")
        self.assertFalse((self.home / ".claude.json").exists())

    def test_s2_config_can_extend_allowlist(self):
        self.write_config({"allowedMcpCommands": ["bash"]})
        m = self.mcp_manifest(command="bash")
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertEqual(self.statuses(m)[("mcp", "svc", "claude")], "aktuell")

    def test_s2_apply_announces_command_and_args_never_secret(self):
        self.write_config({"allowedSecretRefs": {"env:MY_VAR": ["svc"]}})
        m = self.mcp_manifest(env={"API_KEY": "env:MY_VAR"})
        res = self.cli("apply", "--manifest", m, env={"MY_VAR": SECRET})
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertIn("npx -y x", res.stdout)
        self.assertNotIn(SECRET, res.stdout + res.stderr)

    # S3
    def test_s3_unlisted_secret_ref_blocked_and_never_read(self):
        (self.home / "keychain.json").write_text(json.dumps({"my-dienst": SECRET}))
        m = self.mcp_manifest(env={"API_KEY": "keychain:my-dienst"})
        res = self.cli("apply", "--manifest", m, env={"MY_VAR": SECRET})
        self.assertEqual(res.returncode, 1, res.stdout + res.stderr)
        self.assertEqual(self.statuses(m)[("mcp", "svc", "claude")], "blockiert")
        self.assertNotIn("security", self.log.read_text())
        self.assertNotIn('"mcp", "add"', self.log.read_text())
        self.assertNotIn(SECRET, res.stdout + res.stderr)

    def test_s3_ref_allowed_only_for_listed_mcp_names(self):
        (self.home / "keychain.json").write_text(json.dumps({"my-dienst": SECRET}))
        self.write_config({"allowedSecretRefs": {"keychain:my-dienst": ["anderer"]}})
        m = self.mcp_manifest(env={"API_KEY": "keychain:my-dienst"})
        self.assertEqual(self.statuses(m)[("mcp", "svc", "claude")], "blockiert")
        self.assertNotIn("security", self.log.read_text())
        self.write_config({"allowedSecretRefs": {"keychain:my-dienst": ["svc"]}})
        self.assertEqual(self.statuses(m)[("mcp", "svc", "claude")], "fehlt")
        self.assertIn("security", self.log.read_text())

    def test_s3_config_validation(self):
        cfg = self.tmp / "bad.json"
        for bad in ({"allowedSecretRefs": ["x"]}, {"allowedSecretRefs": {"a": "b"}}, {"allowedMcpCommands": "npx"}):
            cfg.write_text(json.dumps(bad))
            res = self.cli("plan", "--manifest", self.manifest({}), "--config", str(cfg))
            self.assertEqual(res.returncode, 2, bad)

    # S4
    def test_s4_pin_uses_exact_commit(self):
        self.setup_alpha()
        one = {"skills": [{"name": "alpha", "repo": "skill-alpha", "path": "skills/alpha", "targets": ["claude"]}]}
        self.make_repo("private-manifest", {"m.json": json.dumps(one)})
        sha1 = self.head("private-manifest")
        two = {"skills": one["skills"] + [{"name": "beta", "repo": "skill-alpha", "path": "skills/alpha",
                                          "targets": ["claude"]}]}
        self.commit("private-manifest", {"m.json": json.dumps(two)})
        cfg = self.tmp / "config.json"
        cfg.write_text(json.dumps({"manifest": {"repo": "private-manifest", "path": "m.json"}}))
        out = self.tmp / "r.json"
        self.cli("report", "--json", str(out), "--config", str(cfg))
        self.assertEqual(len(json.loads(out.read_text())["entries"]), 2)
        cfg.write_text(json.dumps({"manifest": {"repo": "private-manifest", "path": "m.json", "commit": sha1}}))
        res = self.cli("report", "--json", str(out), "--config", str(cfg))
        self.assertIn(res.returncode, (0, 1), res.stdout + res.stderr)
        self.assertEqual([e["name"] for e in json.loads(out.read_text())["entries"]], ["alpha"])

    def test_s4_pin_missing_commit_aborts(self):
        self.make_repo("private-manifest", {"m.json": "{}"})
        cfg = self.tmp / "config.json"
        cfg.write_text(json.dumps({"manifest": {"repo": "private-manifest", "path": "m.json", "commit": "0" * 40}}))
        res = self.cli("plan", "--config", str(cfg))
        self.assertEqual(res.returncode, 2, res.stdout + res.stderr)
        self.assertNotIn("Traceback", res.stderr)

    def test_s4_pin_must_be_full_sha(self):
        self.make_repo("private-manifest", {"m.json": "{}"})
        cfg = self.tmp / "config.json"
        cfg.write_text(json.dumps({"manifest": {"repo": "private-manifest", "path": "m.json", "commit": "abc123"}}))
        res = self.cli("plan", "--config", str(cfg))
        self.assertEqual(res.returncode, 2)

    def test_s4_ref_with_full_sha_in_entry_works(self):
        self.setup_alpha()
        sha1 = self.head("skill-alpha")
        self.commit("skill-alpha", {"skills/alpha/ref/a.txt": "zwei\n"})
        m = self.skill_manifest(targets=("claude",), ref=sha1)
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertEqual((self.skill() / "ref/a.txt").read_text(), "eins\n")
        stamp = json.loads((self.skill() / ".mgd-ai-sync.json").read_text())
        self.assertEqual(stamp["commit"], sha1)

    def test_s4_ecc_not_in_default_marketplaces(self):
        self.assertEqual(ai_sync.load_config(self.tmp / "gibt-es-nicht.json")["allowedMarketplaces"],
                         ["anthropics/claude-plugins-official"])
        m = self.manifest({"plugins": {"claude": [{"marketplace": "affaan-m/ECC", "marketplaceName": "ecc", "name": "ecc"}]}})
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 2)
        self.assertNotIn("install", self.log.read_text())

    # S5
    def export_with_args(self, args):
        (self.home / ".claude.json").write_text(json.dumps({"mcpServers": {
            "svc": {"type": "stdio", "command": "npx", "args": args, "env": {}},
            "gut": {"type": "stdio", "command": "npx", "args": ["-y", "paket"], "env": {}}}}))
        out = self.tmp / "export.json"
        res = self.cli("export", "--output", str(out))
        self.assertEqual(res.returncode, 0, res.stderr)
        return res, out

    def test_s5_secret_like_args_go_to_unassigned_without_value(self):
        cases = ["--token=GEHEIMWERT123", "--api-key", "https://user:pw0rd@host.example/x",
                 "a" * 10 + "0123456789abcdef0123456789abcdef", "Abcdefghijklmnop0123456789ABCDEFGHIJKLMNOP==",
                 "--password=zzz", "Bearer abc", "--client-secret=zzz"]
        for arg in cases:
            res, out = self.export_with_args(["-y", arg])
            text = out.read_text() + res.stdout
            self.assertNotIn(arg, text, arg)
            data = json.loads(out.read_text())
            self.assertEqual([e["name"] for e in data["mcp"]], ["gut"], arg)
            self.assertTrue(any(u.startswith("mcp:svc") for u in data["_nichtZugeordnet"]), arg)

    def test_s5_harmless_args_stay(self):
        res, out = self.export_with_args(["-y", "@upstash/context7-mcp", "--port", "8080"])
        self.assertEqual(sorted(e["name"] for e in json.loads(out.read_text())["mcp"]), ["gut", "svc"])

    def test_s5_draft_is_0600_and_has_no_device(self):
        res, out = self.export_with_args(["-y"])
        self.assertEqual(self.mode(out), 0o600)
        self.assertNotIn("_geraet", json.loads(out.read_text()))

    # S6
    def test_s6_state_permissions(self):
        self.setup_alpha()
        self.make_repo("cmds", {"c/hello.md": "# hallo\n"})
        m = self.manifest({
            "skills": [{"name": "alpha", "repo": "skill-alpha", "path": "skills/alpha", "targets": ["claude"]}],
            "commands": [{"name": "hello", "repo": "cmds", "path": "c/hello.md", "targets": ["claude"]}]})
        self.cli("apply", "--manifest", m)
        (self.skill() / "ref/a.txt").write_text("lokal\n")
        (self.home / ".claude/commands/hello.md").write_text("lokal")
        self.cli("apply", "--manifest", m, "--overwrite", "alpha", "--overwrite", "hello")
        self.cli("agent-run", "--manifest", m)
        self.cli("report", "--json", str(self.tmp / "r.json"), "--manifest", m)
        self.assertEqual(self.mode(self.tmp / "r.json"), 0o600)
        self.assertEqual(self.mode(self.skill() / ".mgd-ai-sync.json"), 0o600)
        bad = []
        for cur, dirs, files in os.walk(str(self.state)):
            if Path(cur) == self.state / "cache":
                dirs[:] = []
                continue
            if self.mode(cur) != 0o700:
                bad.append((cur, oct(self.mode(cur))))
            for f in files:
                if self.mode(Path(cur) / f) != 0o600:
                    bad.append((f, oct(self.mode(Path(cur) / f))))
        self.assertEqual(bad, [])
        names = {p.name for p in self.state.rglob("*") if p.is_file()}
        for needed in ("command-stamps.json", "last-report.json", "ai-sync.log", "a.txt", "hello.md"):
            self.assertIn(needed, names)

    def test_s6_prune_keeps_last_five_own_backups_only(self):
        with self.inproc_env():
            root = ai_sync.state_dir() / "backups"
            for i in range(1, 8):
                d = root / ("2026-01-%02d" % i) / "claude" / "alpha"
                d.mkdir(parents=True)
                (d / "f").write_text(str(i))
                os.utime(str(d), (1000 + i, 1000 + i))
            foreign = [root / "2026-01-01" / "claude" / "alpha-notizen", root / "notiz.txt",
                       root / "2026-01-02" / "claude" / "beta"]
            for f in foreign:
                f.parent.mkdir(parents=True, exist_ok=True)
                f.mkdir() if f.suffix == "" else f.write_text("x")
            ai_sync.prune_backups("claude", "alpha")
            left = sorted(p.parent.parent.name for p in root.glob("*/claude/alpha"))
            self.assertEqual(left, ["2026-01-03", "2026-01-04", "2026-01-05", "2026-01-06", "2026-01-07"])
            for f in foreign:
                self.assertTrue(f.exists(), f)

    def test_s6_repeated_overwrite_keeps_five(self):
        self.setup_alpha()
        m = self.skill_manifest(targets=("claude",))
        self.cli("apply", "--manifest", m)
        for i in range(7):
            (self.skill() / "ref/a.txt").write_text("lokal%d\n" % i)
            res = self.cli("apply", "--manifest", m, "--overwrite", "alpha")
            self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        backups = [p for p in (self.state / "backups").glob("*/claude/*") if p.name.startswith("alpha")]
        self.assertEqual(len(backups), 5)

    def test_s6_plist_stays_0644_and_log_is_0600(self):
        res = self.cli("install-agent", "--no-load")
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertEqual(self.mode(self.home / "Library/LaunchAgents/de.michael-gahn.devos.ai-sync.plist"), 0o644)
        self.assertEqual(self.mode(self.state / "logs/agent.log"), 0o600)

    # S7
    def test_s7_tool_paths(self):
        clean = {k: v for k, v in os.environ.items() if not k.startswith("MGD_AI_SYNC_")}
        with mock.patch.dict(os.environ, clean, clear=True):
            self.assertEqual(ai_sync.tool("security"), "/usr/bin/security")
            self.assertEqual(ai_sync.tool("osascript"), "/usr/bin/osascript")
            self.assertEqual(ai_sync.tool("launchctl"), "/bin/launchctl")
        with mock.patch.dict(os.environ, dict(clean, MGD_AI_SYNC_TEST_BIN=str(self.fakebin)), clear=True):
            self.assertEqual(ai_sync.tool("security"), "/usr/bin/security")  # ohne TESTING=1 wirkungslos
        with mock.patch.dict(os.environ, dict(clean, MGD_AI_SYNC_TEST_BIN=str(self.fakebin),
                                              MGD_AI_SYNC_TESTING="1"), clear=True):
            self.assertEqual(ai_sync.tool("security"), str(self.fakebin / "security"))

    def test_s7_install_agent_plist_path_and_config(self):
        cfg = self.tmp / "cfg.json"
        cfg.write_text("{}")
        res = self.cli("install-agent", "--no-load", "--config", str(cfg))
        self.assertEqual(res.returncode, 0, res.stderr)
        plist = plistlib.loads((self.home / "Library/LaunchAgents/de.michael-gahn.devos.ai-sync.plist").read_bytes())
        prog = plist["ProgramArguments"]
        self.assertEqual(prog[prog.index("--config") + 1], str(cfg))
        parts = plist["EnvironmentVariables"]["PATH"].split(":")
        self.assertTrue(all(p.startswith("/") for p in parts), parts)
        self.assertIn(str(self.fakebin), parts)
        self.assertIn("/usr/bin", parts)
        self.assertNotIn(os.environ.get("HOME", "/nope") + "/bin", parts)

    def test_s7_install_agent_rejects_writable_tool_dir(self):
        os.chmod(str(self.fakebin), 0o777)
        res = self.cli("install-agent", "--no-load")
        self.assertEqual(res.returncode, 2, res.stdout + res.stderr)
        self.assertFalse((self.home / "Library/LaunchAgents/de.michael-gahn.devos.ai-sync.plist").exists())
        os.chmod(str(self.fakebin), 0o770)
        res = self.cli("install-agent", "--no-load")
        self.assertEqual(res.returncode, 2, res.stdout + res.stderr)

    def test_s7_launchctl_and_osascript_via_tool(self):
        res = self.cli("install-agent")
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertTrue(any(c[0] == "launchctl" and "bootstrap" in c for c in self.calls()))

    # S8
    def test_s8_install_agent_refuses_inside_skill_dirs(self):
        for rel in (".claude/skills", ".codex/skills", ".agents/skills"):
            d = self.home / rel / "ai-sync"
            d.mkdir(parents=True)
            copy = d / "ai_sync.py"
            shutil.copyfile(str(TOOL), str(copy))
            res = subprocess.run([sys.executable, str(copy), "install-agent", "--no-load"],
                                 capture_output=True, text=True, env=dict(self.env))
            self.assertEqual(res.returncode, 2, (rel, res.stdout, res.stderr))
            self.assertIn("README", res.stderr)
            self.assertFalse((self.home / "Library/LaunchAgents/de.michael-gahn.devos.ai-sync.plist").exists())

    def test_s8_symlinked_skill_dir_is_also_refused(self):
        real = self.tmp / "real"
        real.mkdir()
        shutil.copyfile(str(TOOL), str(real / "ai_sync.py"))
        (self.home / ".claude/skills").mkdir(parents=True)
        os.symlink(str(real), str(self.home / ".claude/skills/ai-sync"))
        res = subprocess.run([sys.executable, str(self.home / ".claude/skills/ai-sync/ai_sync.py"), "install-agent", "--no-load"],
                             capture_output=True, text=True, env=dict(self.env))
        self.assertEqual(res.returncode, 2, res.stdout + res.stderr)

    # S9
    def plugin_manifest(self):
        self.write_config({"allowedMarketplaces": ["affaan-m/ECC"]})
        return self.manifest({"plugins": {"claude": [{"marketplace": "affaan-m/ECC", "marketplaceName": "ecc", "name": "ecc"}]}})

    def test_s9_plugin_counts_only_with_expected_marketplace_repo(self):
        m = self.plugin_manifest()
        (self.home / "fake-plugins.json").write_text(json.dumps({
            "plugins": ["ecc@ecc"], "markets": [{"name": "ecc", "source": "git", "url": "https://github.com/evil/ecc.git"}]}))
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 1, res.stdout + res.stderr)
        self.assertNotEqual(self.statuses(m)[("plugin", "ecc", "claude")], "aktuell")
        self.assertNotIn('"install"', self.log.read_text())
        (self.home / "fake-plugins.json").write_text(json.dumps({
            "plugins": ["ecc@ecc"], "markets": [{"name": "ecc", "source": "git", "url": "https://github.com/affaan-m/ECC.git"}]}))
        self.assertEqual(self.statuses(m)[("plugin", "ecc", "claude")], "aktuell")

    def test_s9_marketplace_name_pointing_elsewhere_blocks_install(self):
        m = self.plugin_manifest()
        (self.home / "fake-plugins.json").write_text(json.dumps({
            "plugins": [], "markets": [{"name": "ecc", "source": "git", "url": "https://github.com/evil/ecc.git"}]}))
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 1, res.stdout + res.stderr)
        self.assertEqual(self.statuses(m)[("plugin", "ecc", "claude")], "blockiert")
        self.assertNotIn('"install"', self.log.read_text())

    # S10
    def test_s10_config_file_permissions_are_reported(self):
        m = self.manifest({"mcp": [{"name": "svc", "command": "npx", "args": ["x"], "env": {}, "targets": ["claude"]}]})
        cj = self.home / ".claude.json"
        cj.write_text("{}")
        os.chmod(str(cj), 0o644)
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 1, res.stdout + res.stderr)
        self.assertIn(".claude.json", res.stdout)
        self.assertIn("0644", res.stdout)
        self.assertIn("0600", res.stdout)
        self.assertEqual(self.mode(cj), 0o644)  # nur melden, nicht aendern

    def test_s10_no_warning_when_0600(self):
        m = self.manifest({"mcp": [{"name": "svc", "command": "npx", "args": ["x"], "env": {}, "targets": ["claude"]}]})
        cj = self.home / ".claude.json"
        cj.write_text("{}")
        os.chmod(str(cj), 0o600)
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertNotIn("Rechte", res.stdout)

    def test_s10_codex_config_permissions_reported(self):
        cfg = self.home / ".codex/config.toml"
        cfg.parent.mkdir(parents=True)
        cfg.write_text("")
        m = self.manifest({"mcp": [{"name": "svc", "command": "npx", "args": ["x"], "env": {}, "targets": ["codex"]}]})
        os.chmod(str(cfg), 0o644)
        res = self.cli("apply", "--manifest", m)  # Fake-Codex haengt an die vorhandene Datei an (Rechte bleiben 0644)
        self.assertIn("config.toml", res.stdout)
        self.assertIn("0644", res.stdout)

    def test_readme_documents_new_keys(self):
        text = (HERE.parent / "README.md").read_text(encoding="utf-8")
        for needle in ("allowedMcpCommands", "allowedSecretRefs", "manifest.commit", "Bekannte Grenzen", "autoApply",
                       "kind:name", "~/.claude/skills"):
            self.assertIn(needle, text)


# =========================================================================== Robustheit (R1-R12)

class RobustnessTests(Base):
    def setUp(self):
        super().setUp()
        self.write_config({"allowedSecretRefs": {"keychain:my-dienst": ["svc"]}})

    def mcp_manifest(self, targets=("claude",), args=("-y", "svc-mcp"), name="svc"):
        return self.manifest({"mcp": [{"name": name, "command": "npx", "args": list(args), "env": {}, "targets": list(targets)}]})

    def installed_args(self):
        return json.loads((self.home / ".claude.json").read_text())["mcpServers"]["svc"]["args"]

    # R1
    def test_r1_overwrite_restores_old_entry_when_add_fails_claude(self):
        self.cli("apply", "--manifest", self.mcp_manifest())
        res = self.cli("apply", "--manifest", self.mcp_manifest(args=("-y", "FAILME")), "--overwrite", "svc")
        self.assertEqual(res.returncode, 2, res.stdout + res.stderr)
        self.assertIn("wiederhergestellt", res.stdout)
        self.assertEqual(self.installed_args(), ["-y", "svc-mcp"])

    def test_r1_overwrite_restores_env_values_of_old_entry(self):
        (self.home / ".claude.json").write_text(json.dumps({"mcpServers": {"svc": {
            "type": "stdio", "command": "npx", "args": ["alt"], "env": {"API_KEY": SECRET}}}}))
        res = self.cli("apply", "--manifest", self.mcp_manifest(args=("-y", "FAILME")), "--overwrite", "svc")
        self.assertEqual(res.returncode, 2, res.stdout + res.stderr)
        conf = json.loads((self.home / ".claude.json").read_text())["mcpServers"]["svc"]
        self.assertEqual((conf["args"], conf["env"]), (["alt"], {"API_KEY": SECRET}))
        self.assertNotIn(SECRET, res.stdout + res.stderr)

    def test_r1_overwrite_aborts_when_remove_fails(self):
        self.cli("apply", "--manifest", self.mcp_manifest())
        res = self.cli("apply", "--manifest", self.mcp_manifest(args=("neu",)), "--overwrite", "svc",
                       env={"FAKE_REMOVE_FAIL": "1"})
        self.assertEqual(res.returncode, 2, res.stdout + res.stderr)
        self.assertEqual(self.installed_args(), ["-y", "svc-mcp"])
        adds = [c for c in self.calls() if c[1:3] == ["mcp", "add"]]
        self.assertEqual(len(adds), 1)  # nur das erste Anlegen

    def test_r1_overwrite_restores_old_entry_when_add_fails_codex(self):
        cfg = self.home / ".codex/config.toml"
        cfg.parent.mkdir(parents=True)
        cfg.write_text('[mcp_servers.svc]\ncommand = "npx"\nargs = ["alt"]\n')
        res = self.cli("apply", "--manifest", self.mcp_manifest(targets=("codex",), args=("-y", "FAILME")),
                       "--overwrite", "svc")
        self.assertEqual(res.returncode, 2, res.stdout + res.stderr)
        self.assertIn("wiederhergestellt", res.stdout)
        parsed = ai_sync.parse_codex_mcp(cfg.read_text())
        self.assertEqual(parsed["svc"]["args"], ["alt"])

    # R2
    CODEX_TOML = (
        '[mcp_servers.multi]\ncommand = "npx" # trailing\nargs = [\n  "-y",   # first\n  # whole line\n  "pkg",  # second\n]\n\n'
        '[mcp_servers."quoted"]\ncommand = "uvx"\nargs = ["a#b"]\nenv = { API_KEY = "x", OTHER = "y#z" }\n\n'
        '[ mcp_servers . spaced . env ]\nK = "v"\n\n[mcp_servers.spaced]\ncommand = "node"\n\n'
        '[mcp_servers.bad]\ncommand = """multi\nline"""\n')

    def test_r2_codex_parser(self):
        p = ai_sync.parse_codex_mcp(self.CODEX_TOML)
        self.assertEqual((p["multi"]["command"], p["multi"]["args"]), ("npx", ["-y", "pkg"]))
        self.assertEqual((p["quoted"]["command"], p["quoted"]["args"], p["quoted"]["envKeys"]),
                         ("uvx", ["a#b"], ["API_KEY", "OTHER"]))
        self.assertEqual((p["spaced"]["command"], p["spaced"]["envKeys"]), ("node", ["K"]))
        self.assertTrue(p["bad"].get("unreadable"))
        self.assertFalse(p["multi"].get("unreadable"))

    def test_r2_unreadable_server_is_unbekannt_and_never_replaced(self):
        cfg = self.home / ".codex/config.toml"
        cfg.parent.mkdir(parents=True)
        original = '[mcp_servers.svc]\ncommand = """multi\nline"""\n'
        cfg.write_text(original)
        m = self.mcp_manifest(targets=("codex",))
        self.assertEqual(self.statuses(m)[("mcp", "svc", "codex")], "unbekannt")
        for extra in ((), ("--overwrite", "svc")):
            self.cli("apply", "--manifest", m, *extra)
            self.assertEqual(cfg.read_text(), original)
        self.assertNotIn('"mcp", "add"', self.log.read_text())

    # R3
    def test_r3_oserror_gives_exit_2_without_traceback(self):
        blocker = self.tmp / "datei"
        blocker.write_text("x")
        res = self.cli("report", "--json", str(blocker / "unter" / "r.json"), "--manifest", self.manifest({}))
        self.assertEqual(res.returncode, 2, res.stdout + res.stderr)
        self.assertNotIn("Traceback", res.stderr)

    def test_r3_catch_all_exit_2_without_secret(self):
        err = io.StringIO()
        with self.inproc_env(), mock.patch.object(ai_sync, "run_plan_like",
                                                   side_effect=RuntimeError("boom " + SECRET)), \
                contextlib.redirect_stderr(err), contextlib.redirect_stdout(io.StringIO()):
            ai_sync.register_secret(SECRET)
            code = ai_sync.main(["plan", "--manifest", self.manifest({})])
        self.assertEqual(code, 2)
        self.assertNotIn(SECRET, err.getvalue())
        self.assertNotIn("Traceback", err.getvalue())

    def test_r3_value_error_exit_2(self):
        err = io.StringIO()
        with self.inproc_env(), mock.patch.object(ai_sync, "run_plan_like", side_effect=ValueError("kaputt")), \
                contextlib.redirect_stderr(err), contextlib.redirect_stdout(io.StringIO()):
            code = ai_sync.main(["plan", "--manifest", self.manifest({})])
        self.assertEqual(code, 2)

    def test_r3_non_utf8_codex_config_does_not_crash(self):
        cfg = self.home / ".codex/config.toml"
        cfg.parent.mkdir(parents=True)
        cfg.write_bytes(b'[mcp_servers.x]\ncommand = "\xff\xfe"\n')
        with self.inproc_env():
            with self.assertRaises(ai_sync.SyncError):
                ai_sync.read_codex_mcp()
        m = self.mcp_manifest(targets=("codex",))
        for sub in ("plan", "apply"):
            res = self.cli(sub, "--manifest", m)
            self.assertEqual(res.returncode, 2, res.stdout + res.stderr)
            self.assertNotIn("Traceback", res.stderr)
        self.assertEqual(cfg.read_bytes(), b'[mcp_servers.x]\ncommand = "\xff\xfe"\n')
        self.assertNotIn('"mcp", "add"', self.log.read_text())

    # R4
    def test_r4_market_repo_formats(self):
        f = ai_sync.market_repo
        self.assertEqual(f({"name": "ecc", "source": "git", "url": "https://github.com/affaan-m/ECC.git"}), "affaan-m/ECC")
        self.assertEqual(f({"name": "x", "source": "git", "url": "https://github.com/o/r"}), "o/r")
        self.assertEqual(f({"name": "x", "source": "git", "url": "git@github.com:o/r.git"}), "o/r")
        self.assertEqual(f({"name": "x", "source": "github", "repo": "O/R"}), "O/R")
        self.assertEqual(f({"name": "x", "source": "git", "url": "https://example.com/o/r.git"}), "")
        self.assertEqual(f({"name": "x"}), "")

    def test_r4_existing_marketplace_in_real_format_is_not_added_again(self):
        self.write_config({"allowedMarketplaces": ["affaan-m/ECC"]})
        (self.home / "fake-plugins.json").write_text(json.dumps({
            "plugins": [], "markets": [{"name": "ecc", "source": "git", "url": "https://github.com/affaan-m/ECC.git"}]}))
        m = self.manifest({"plugins": {"claude": [{"marketplace": "affaan-m/ECC", "marketplaceName": "ecc", "name": "ecc"}]}})
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertNotIn('"marketplace", "add"', self.log.read_text())
        self.assertIn('["claude", "plugin", "install", "ecc@ecc"]', self.log.read_text())

    def test_r4_marketplace_added_only_once_per_run(self):
        self.write_config({"allowedMarketplaces": ["affaan-m/ECC"]})
        m = self.manifest({"plugins": {"claude": [
            {"marketplace": "affaan-m/ECC", "marketplaceName": "ecc", "name": "one"},
            {"marketplace": "affaan-m/ECC", "marketplaceName": "ecc", "name": "two"}]}})
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        adds = [c for c in self.calls() if c[1:4] == ["plugin", "marketplace", "add"]]
        self.assertEqual(len(adds), 1)
        self.assertEqual(len([c for c in self.calls() if c[1:3] == ["plugin", "install"]]), 2)

    def test_r4_export_understands_git_url_format(self):
        (self.home / "fake-plugins.json").write_text(json.dumps({
            "plugins": ["ecc@ecc"], "markets": [{"name": "ecc", "source": "git", "url": "https://github.com/affaan-m/ECC.git"}]}))
        res = self.cli("export")
        data = json.loads(res.stdout)
        self.assertEqual(data["plugins"]["claude"], [{"marketplace": "affaan-m/ECC", "marketplaceName": "ecc", "name": "ecc"}])

    # R5
    def test_r5_install_skill_restores_old_on_failure(self):
        with self.inproc_env():
            target = ai_sync.home() / ".claude/skills/alpha"
            target.mkdir(parents=True)
            (target / "SKILL.md").write_text("alt")
            src = self.tmp / "src"
            src.mkdir()
            (src / "SKILL.md").write_text("neu")
            op = {"type": "skill", "entry": {"owner": "o", "repo": "r", "path": ".", "ref": None}, "src": src,
                  "target": target, "commit": "c" * 40, "hashes": {}, "targetKey": "claude"}
            real, seen = os.rename, []

            def flaky(a, b):
                seen.append((a, b))
                if len(seen) == 2:
                    raise OSError("boom")
                return real(a, b)
            with mock.patch.object(ai_sync.os, "rename", flaky):
                with self.assertRaises(OSError):
                    ai_sync.install_skill(op)
            self.assertEqual((target / "SKILL.md").read_text(), "alt")
            self.assertEqual([p.name for p in target.parent.iterdir()], ["alpha"])

    def make_orphan(self, with_target):
        root = self.home / ".claude/skills"
        orphan = root / ".alpha.old-4242"
        orphan.mkdir(parents=True)
        (orphan / "SKILL.md").write_text("alt")
        if with_target:
            (root / "alpha").mkdir()
            (root / "alpha/SKILL.md").write_text("neu")
        return root, orphan

    def test_r5_orphan_old_is_reported_in_plan_and_not_touched(self):
        root, orphan = self.make_orphan(False)
        res = self.cli("plan", "--manifest", self.manifest({}))
        self.assertEqual(res.returncode, 1, res.stdout + res.stderr)
        self.assertIn(".alpha.old-4242", res.stdout)
        self.assertTrue(orphan.exists())
        self.assertFalse((root / "alpha").exists())

    def test_r5_orphan_old_is_restored_by_apply_when_target_missing(self):
        root, orphan = self.make_orphan(False)
        res = self.cli("apply", "--manifest", self.manifest({}))
        self.assertIn("wiederhergestellt", res.stdout)
        self.assertEqual((root / "alpha/SKILL.md").read_text(), "alt")
        self.assertFalse(orphan.exists())

    def test_r5_orphan_old_with_existing_target_is_only_reported(self):
        root, orphan = self.make_orphan(True)
        res = self.cli("apply", "--manifest", self.manifest({}))
        self.assertEqual(res.returncode, 1, res.stdout + res.stderr)
        self.assertIn(".alpha.old-4242", res.stdout)
        self.assertTrue(orphan.exists())
        self.assertEqual((root / "alpha/SKILL.md").read_text(), "neu")

    # R6
    def test_r6_pycache_and_pyc_are_ignored(self):
        d = self.tmp / "tree"
        (d / "__pycache__").mkdir(parents=True)
        (d / "__pycache__/x.cpython-39.pyc").write_bytes(b"x")
        (d / "a.pyc").write_bytes(b"x")
        (d / "a.py").write_text("x")
        self.assertEqual(set(ai_sync.hash_tree(d)), {"a.py"})

    def test_r6_local_pycache_does_not_make_skill_changed(self):
        self.setup_alpha()
        m = self.skill_manifest(targets=("claude",))
        self.cli("apply", "--manifest", m)
        (self.skill() / "__pycache__").mkdir()
        (self.skill() / "__pycache__/m.pyc").write_bytes(b"x")
        self.assertEqual(self.statuses(m)[("skill", "alpha", "claude")], "aktuell")

    # R7
    def test_r7_header_normalized_and_unknown_keys_and_comments_kept(self):
        text = ('[mcp_servers."svc"]\n# mein Kommentar\ncommand = "old"\nargs = [\n  "a", # c\n  "b",\n]\n'
                'startup_timeout_sec = 20\n\n[ mcp_servers . svc . env ]\n# env-Kommentar\nOLD = "1"\nKEEP = "2"\n\n[other]\nx = 1\n')
        out = ai_sync.toml_set_mcp(text, "svc", "new", ["z"], {"KEEP": "3", "NEW": "4"})
        for kept in ("# mein Kommentar", "startup_timeout_sec = 20", "# env-Kommentar", "[other]\nx = 1\n"):
            self.assertIn(kept, out)
        self.assertNotIn("OLD", out)
        self.assertNotIn('"a"', out)
        self.assertEqual(out.count("command ="), 1)
        self.assertIn('KEEP = "3"', out)
        self.assertIn('NEW = "4"', out)
        parsed = ai_sync.parse_codex_mcp(out)
        self.assertEqual((parsed["svc"]["command"], parsed["svc"]["args"], parsed["svc"]["envKeys"]),
                         ("new", ["z"], ["KEEP", "NEW"]))
        try:
            import tomllib
        except ImportError:
            return
        tomllib.loads(out)

    def test_r7_non_bmp_and_del_are_escaped(self):
        out = ai_sync.toml_set_mcp("", "svc", "cmd", ["\U0001F600", "a\x7fb", 'q"\\'], {})
        self.assertIn("\\U0001F600", out)
        self.assertIn("\\u007f", out)
        self.assertNotIn("\x7f", out)
        self.assertEqual(ai_sync.parse_codex_mcp(out)["svc"]["args"], ["\U0001F600", "a\x7fb", 'q"\\'])
        try:
            import tomllib
        except ImportError:
            return
        self.assertEqual(tomllib.loads(out)["mcp_servers"]["svc"]["args"], ["\U0001F600", "a\x7fb", 'q"\\'])

    def apply_codex_fallback(self, original):
        cfg = self.home / ".codex/config.toml"
        cfg.parent.mkdir(parents=True)
        if original is not None:
            cfg.write_bytes(original)
        op = {"type": "mcp", "targetKey": "codex", "blocked": False,
              "entry": {"name": "svc", "command": "npx", "args": ["x"], "env": {}, "targets": ["codex"]}}
        return cfg, op

    def test_r7_broken_result_restores_backup(self):
        original = b'model = "x"\n'
        cfg, op = self.apply_codex_fallback(original)
        with self.inproc_env(), mock.patch.dict(os.environ, {"FAKE_CODEX_NOMCP": "1"}), \
                mock.patch.object(ai_sync, "toml_set_mcp", return_value='model = "x"\n[mcp_servers.svc\ncommand = \n'):
            with self.assertRaises(ai_sync.SyncError):
                ai_sync.apply_mcp(op, False)
        self.assertEqual(cfg.read_bytes(), original)

    def test_r7_broken_result_without_original_removes_file(self):
        cfg, op = self.apply_codex_fallback(None)
        with self.inproc_env(), mock.patch.dict(os.environ, {"FAKE_CODEX_NOMCP": "1"}), \
                mock.patch.object(ai_sync, "toml_set_mcp", return_value='[mcp_servers.svc\ncommand = \n'):
            with self.assertRaises(ai_sync.SyncError):
                ai_sync.apply_mcp(op, False)
        self.assertFalse(cfg.exists())

    # R8
    def test_r8_write_atomic_fsyncs(self):
        with mock.patch.object(ai_sync.os, "fsync", wraps=os.fsync) as fs:
            ai_sync.write_atomic(self.tmp / "f.txt", "x")
        self.assertTrue(fs.called)

    def test_r8_write_atomic_keeps_symlink(self):
        real = self.tmp / "real.txt"
        real.write_text("alt")
        link = self.tmp / "link.txt"
        os.symlink(str(real), str(link))
        ai_sync.write_atomic(link, "neu")
        self.assertTrue(os.path.islink(str(link)))
        self.assertEqual(real.read_text(), "neu")

    def test_r8_symlinked_codex_config_stays_symlink(self):
        dot = self.tmp / "dotfiles"
        dot.mkdir()
        (dot / "config.toml").write_text('model = "x"\n')
        (self.home / ".codex").mkdir()
        os.symlink(str(dot / "config.toml"), str(self.home / ".codex/config.toml"))
        res = self.cli("apply", "--manifest", self.mcp_manifest(targets=("codex",)), env={"FAKE_CODEX_NOMCP": "1"})
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertTrue(os.path.islink(str(self.home / ".codex/config.toml")))
        self.assertIn("[mcp_servers.svc]", (dot / "config.toml").read_text())

    # R9
    def alpha_beta_manifest(self):
        self.setup_alpha()
        entries = [{"name": "alpha", "repo": "skill-alpha", "path": "skills/alpha", "targets": ["claude", "codex"]}]
        return self.manifest({"skills": entries, "mcp": [
            {"name": "alpha", "command": "npx", "args": [], "env": {}, "targets": ["claude"]}]})

    def test_r9_unknown_name_is_error_and_nothing_happens(self):
        self.setup_alpha()
        m = self.skill_manifest(targets=("claude",))
        for flag in ("--overwrite", "--adopt"):
            res = self.cli("apply", "--manifest", m, flag, "gibtsnicht")
            self.assertEqual(res.returncode, 2, res.stdout + res.stderr)
        self.assertFalse((self.home / ".claude").exists())

    def test_r9_ambiguous_plain_name_is_error(self):
        m = self.alpha_beta_manifest()
        res = self.cli("apply", "--manifest", m, "--overwrite", "alpha")
        self.assertEqual(res.returncode, 2, res.stdout + res.stderr)
        self.assertIn("mehrdeutig", res.stderr)
        self.assertFalse((self.home / ".claude").exists())

    def test_r9_selector_kind_name_and_target(self):
        m = self.alpha_beta_manifest()
        self.cli("apply", "--manifest", m)
        for t in ("claude", "codex"):
            (self.skill(t) / "ref/a.txt").write_text("lokal\n")
        res = self.cli("apply", "--manifest", m, "--overwrite", "skill:alpha:claude")
        self.assertEqual(res.returncode, 1, res.stdout + res.stderr)
        self.assertEqual((self.skill("claude") / "ref/a.txt").read_text(), "eins\n")
        self.assertEqual((self.skill("codex") / "ref/a.txt").read_text(), "lokal\n")
        res = self.cli("apply", "--manifest", m, "--overwrite", "skill:alpha")
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertEqual((self.skill("codex") / "ref/a.txt").read_text(), "eins\n")

    def test_r9_bad_selectors(self):
        m = self.alpha_beta_manifest()
        for bad in ("foo:alpha", "skill:nope", "skill:alpha:agents", "skill:alpha:claude:x", "mcp:alpha:codex"):
            res = self.cli("apply", "--manifest", m, "--overwrite", bad)
            self.assertEqual(res.returncode, 2, (bad, res.stdout, res.stderr))

    # R10
    def test_r10_agent_run_reports_sync_error(self):
        res = self.cli("agent-run", "--manifest", str(self.tmp / "gibts-nicht.json"))
        self.assertEqual(res.returncode, 2, res.stdout + res.stderr)
        rep = json.loads((self.state / "last-report.json").read_text())
        self.assertIn("error", rep)
        self.assertEqual(rep["mode"], "error")
        self.assertIn("display notification", self.log.read_text())
        self.assertIn("exit 2", (self.state / "logs/ai-sync.log").read_text())
        self.assertNotIn("Traceback", res.stderr)

    def test_r10_env_refs_not_available_in_agent_run(self):
        self.write_config({"allowedSecretRefs": {"env:MY_VAR": ["svc"]}})
        m = self.manifest({"mcp": [{"name": "svc", "command": "npx", "args": [], "env": {"K": "env:MY_VAR"}, "targets": ["claude"]}]})
        res = self.cli("agent-run", "--manifest", m, env={"MY_VAR": SECRET})
        rep = json.loads((self.state / "last-report.json").read_text())
        entry = [e for e in rep["entries"] if e["kind"] == "mcp"][0]
        self.assertEqual(entry["aktion"], "blockiert")
        self.assertIn("Agent-Lauf", entry["details"])
        self.assertNotIn(SECRET, res.stdout + res.stderr + json.dumps(rep))
        # im normalen Lauf dagegen verfuegbar
        self.assertEqual(self.statuses(m)[("mcp", "svc", "claude")], "fehlt")
        res = self.cli("plan", "--manifest", m, env={"MY_VAR": SECRET})
        self.assertNotIn("blockiert", res.stdout)

    # R11
    def test_r11_failed_marketplace_list_does_not_crash_second_plugin(self):
        self.write_config({"allowedMarketplaces": ["affaan-m/ECC"]})
        m = self.manifest({"plugins": {"claude": [
            {"marketplace": "affaan-m/ECC", "marketplaceName": "ecc", "name": "one"},
            {"marketplace": "affaan-m/ECC", "marketplaceName": "ecc", "name": "two"}]}})
        res = self.cli("plan", "--manifest", m, env={"FAKE_MARKET_FAIL": "1"})
        self.assertEqual(res.returncode, 2, res.stdout + res.stderr)
        self.assertNotIn("Traceback", res.stderr)
        self.assertIn("[plugin] one -> claude: fehler", res.stdout)
        self.assertIn("[plugin] two -> claude: fehler", res.stdout)

    # R12
    def test_r12_broken_command_stamps_abort(self):
        self.make_repo("cmds", {"c/hello.md": "# hallo\n"})
        m = self.manifest({"commands": [{"name": "hello", "repo": "cmds", "path": "c/hello.md", "targets": ["claude"]}]})
        self.state.mkdir(parents=True, exist_ok=True)
        stamps = self.state / "command-stamps.json"
        stamps.write_text("{kaputt")
        for sub in ("plan", "apply"):
            res = self.cli(sub, "--manifest", m)
            self.assertEqual(res.returncode, 2, res.stdout + res.stderr)
            self.assertNotIn("Traceback", res.stderr)
        self.assertEqual(stamps.read_text(), "{kaputt")
        self.assertFalse((self.home / ".claude/commands/hello.md").exists())
        stamps.write_bytes(b"\xff\xfe")
        self.assertEqual(self.cli("plan", "--manifest", m).returncode, 2)
        self.assertEqual(stamps.read_bytes(), b"\xff\xfe")

    def test_r12_duplicate_entries_are_invalid(self):
        self.setup_alpha()
        a = {"repo": "skill-alpha", "path": "skills/alpha", "targets": ["claude"]}
        m = self.manifest({"skills": [dict(a, name="a1", installName="alpha"), dict(a, name="a2", installName="alpha")]})
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 2, res.stdout + res.stderr)
        self.assertIn("doppelt", res.stdout)
        # gleicher installName in anderem Ziel oder anderer Art ist erlaubt
        self.make_repo("cmds", {"c/alpha.md": "# x\n"})
        ok = self.manifest({"skills": [dict(a, name="a1", installName="alpha"), dict(a, name="a2", installName="alpha", targets=["codex"])],
                            "commands": [{"name": "alpha", "repo": "cmds", "path": "c/alpha.md", "targets": ["claude"]}]})
        self.assertEqual(self.cli("apply", "--manifest", ok).returncode, 0)

    def test_r12_offen_does_not_raise_exit_code_as_documented(self):
        self.make_repo("cmds", {"c/hello.md": "# hallo\n"})
        m = self.manifest({"commands": [{"name": "hello", "repo": "cmds", "path": "c/hello.md", "targets": ["claude", "codex"]}]})
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertIn("offen", res.stdout)
        readme = (HERE.parent / "README.md").read_text(encoding="utf-8")
        self.assertIn("`offen` zählt nicht", readme)


# =========================================================================== Luecken: Symlinks, kaputte Dateien

class GapTests(Base):
    def test_symlink_file_inside_skill_pointing_out_of_repo_is_not_copied(self):
        self.setup_alpha()
        secret = self.tmp / "geheim.txt"
        secret.write_text("geheim")
        os.symlink(str(secret), str(self.repo_dir("skill-alpha") / "skills/alpha/link.txt"))
        os.symlink(str(self.tmp), str(self.repo_dir("skill-alpha") / "skills/alpha/linkdir"))
        self.commit("skill-alpha", {"skills/alpha/ref/a.txt": "eins\n"})
        m = self.skill_manifest(targets=("claude",))
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertEqual(sorted(tree(self.skill())), [".mgd-ai-sync.json", "SKILL.md", "ref/a.txt"])
        self.assertFalse(os.path.lexists(str(self.skill() / "link.txt")))

    def test_skill_path_symlink_out_of_repo_is_error(self):
        self.setup_alpha()
        os.symlink(str(self.tmp), str(self.repo_dir("skill-alpha") / "evil"))
        self.commit("skill-alpha", {"x.txt": "x"})
        m = self.skill_manifest(targets=("claude",), path="evil")
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 2, res.stdout + res.stderr)
        self.assertFalse(self.skill().exists())

    def test_command_source_symlink_out_of_repo_is_error(self):
        outside = self.tmp / "aussen.md"
        outside.write_text("# aussen\n")
        self.make_repo("cmds", {"c/ok.md": "# ok\n"})
        os.symlink(str(outside), str(self.repo_dir("cmds") / "c/link.md"))
        self.commit("cmds", {"c/ok.md": "# ok\n"})
        m = self.manifest({"commands": [{"name": "l", "repo": "cmds", "path": "c/link.md", "targets": ["claude"]}]})
        res = self.cli("apply", "--manifest", m)
        self.assertEqual(res.returncode, 2, res.stdout + res.stderr)
        self.assertFalse((self.home / ".claude/commands/l.md").exists())

    def test_manifest_path_symlink_out_of_repo_is_error(self):
        outside = self.tmp / "aussen.json"
        outside.write_text("{}")
        self.make_repo("private-manifest", {"x": "x"})
        os.symlink(str(outside), str(self.repo_dir("private-manifest") / "m.json"))
        self.commit("private-manifest", {"x": "y"})
        cfg = self.tmp / "config.json"
        cfg.write_text(json.dumps({"manifest": {"repo": "private-manifest", "path": "m.json"}}))
        res = self.cli("plan", "--config", str(cfg))
        self.assertEqual(res.returncode, 2, res.stdout + res.stderr)

    def test_non_utf8_manifest_and_config(self):
        bad = self.tmp / "m.json"
        bad.write_bytes(b'{"skills": "\xff"}')
        res = self.cli("plan", "--manifest", str(bad))
        self.assertEqual(res.returncode, 2, res.stdout + res.stderr)
        self.assertNotIn("Traceback", res.stderr)
        cfg = self.tmp / "c.json"
        cfg.write_bytes(b"\xff\xfe")
        res = self.cli("plan", "--manifest", self.manifest({}), "--config", str(cfg))
        self.assertEqual(res.returncode, 2, res.stdout + res.stderr)
        self.assertNotIn("Traceback", res.stderr)

    def test_broken_claude_json_is_error_not_missing(self):
        (self.home / ".claude.json").write_text("{kaputt")
        m = self.manifest({"mcp": [{"name": "svc", "command": "npx", "args": [], "env": {}, "targets": ["claude"]}]})
        for sub in ("plan", "apply"):
            res = self.cli(sub, "--manifest", m)
            self.assertEqual(res.returncode, 2, res.stdout + res.stderr)
            self.assertNotIn("Traceback", res.stderr)
        self.assertNotIn('"mcp", "add"', self.log.read_text())
        self.assertEqual((self.home / ".claude.json").read_text(), "{kaputt")

    def test_non_utf8_skill_stamp_means_unknown(self):
        self.setup_alpha()
        m = self.skill_manifest(targets=("claude",))
        self.cli("apply", "--manifest", m)
        (self.skill() / ".mgd-ai-sync.json").write_bytes(b"\xff\xfe")
        self.assertEqual(self.statuses(m)[("skill", "alpha", "claude")], "adoptierbar")

    def test_symlinked_config_is_read(self):
        real = self.tmp / "dot-config.json"
        real.write_text(json.dumps({"allowedMcpCommands": ["bash"]}))
        self.state.mkdir(parents=True)
        os.symlink(str(real), str(self.state / "config.json"))
        m = self.manifest({"mcp": [{"name": "svc", "command": "bash", "args": [], "env": {}, "targets": ["claude"]}]})
        self.assertEqual(self.statuses(m)[("mcp", "svc", "claude")], "fehlt")

    def test_symlinked_claude_json_is_read_and_kept(self):
        real = self.tmp / "dot-claude.json"
        real.write_text(json.dumps({"mcpServers": {"svc": {"type": "stdio", "command": "npx", "args": [], "env": {}}}}))
        os.symlink(str(real), str(self.home / ".claude.json"))
        m = self.manifest({"mcp": [{"name": "svc", "command": "npx", "args": [], "env": {}, "targets": ["claude"]}]})
        self.assertEqual(self.statuses(m)[("mcp", "svc", "claude")], "aktuell")
        self.assertTrue(os.path.islink(str(self.home / ".claude.json")))


if __name__ == "__main__":
    unittest.main()
