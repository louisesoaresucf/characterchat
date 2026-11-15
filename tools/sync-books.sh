#!/usr/bin/env bash
# Copy Libby's book database from the gameofbooks project into books/fantasy_novels.json.
#
#   tools/sync-books.sh                      # fetch the latest from GitHub
#   tools/sync-books.sh ../gameofbooks       # or copy from a local checkout
#
# gameofbooks stays the source of truth: edit books there, then run this to update Libby.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
src="${1:-}"
if [ -z "$src" ]; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  git clone -q --depth 1 https://github.com/louisesoaresucf/gameofbooks "$tmp/gameofbooks"
  src="$tmp/gameofbooks"
fi
python3 - "$src/fantasy_novels.json" <<'PY'
import json, sys
db = json.load(open(sys.argv[1], encoding="utf-8"))
books = db["books"]
assert books and all({"title", "authors", "type", "tags"} <= set(b) for b in books), "unexpected database format"
print(f"{len(books)} books look good")
PY
cp "$src/fantasy_novels.json" "$here/books/fantasy_novels.json"
echo "Copied to books/fantasy_novels.json"
