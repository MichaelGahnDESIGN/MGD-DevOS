#!/usr/bin/env bash
set -euo pipefail

# Erstellt ein reproduzierbares Release-Paket nur aus getrackten Dateien.
version="${1:-dev}"
output_dir="${2:-dist}"
root="$(git rev-parse --show-toplevel)"
if [[ "$output_dir" = /* ]]; then target="$output_dir"; else target="$root/$output_dir"; fi
archive="$target/MGD-DevOS-$version.zip"
mkdir -p "$target"
git -C "$root" archive --format=zip --prefix="MGD-DevOS-$version/" HEAD > "$archive"
shasum -a 256 "$archive" > "$archive.sha256"
printf 'Paket erstellt: %s\nPrüfsumme: %s.sha256\n' "$archive" "$archive"
