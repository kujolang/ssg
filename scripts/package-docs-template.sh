#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${1:-$REPO_ROOT/dist}"
PACKAGE_NAME="${2:-kujo-ssg-docs-template}"
PACKAGE_ROOT="$OUT_DIR/$PACKAGE_NAME"
ARCHIVE="$OUT_DIR/$PACKAGE_NAME.tar.gz"

rm -rf "$PACKAGE_ROOT"
mkdir -p "$PACKAGE_ROOT/scripts" "$OUT_DIR"

cp -R "$REPO_ROOT/starters/docs-site/." "$PACKAGE_ROOT/"
cp "$REPO_ROOT/build.kujo" "$PACKAGE_ROOT/build.kujo"
cp "$REPO_ROOT/scripts/docgen_ssg_bridge.kujo" "$PACKAGE_ROOT/scripts/docgen_ssg_bridge.kujo"
cp "$REPO_ROOT/scripts/docgen_reduce.py" "$PACKAGE_ROOT/scripts/docgen_reduce.py"
cp "$REPO_ROOT/scripts/docs_search_index.kujo" "$PACKAGE_ROOT/scripts/docs_search_index.kujo"
cp "$REPO_ROOT/scripts/docs_search_index.py" "$PACKAGE_ROOT/scripts/docs_search_index.py"
cp "$REPO_ROOT/scripts/update_docs.kujo" "$PACKAGE_ROOT/scripts/update_docs.kujo"
cp "$REPO_ROOT/scripts/validate-generated-output.sh" "$PACKAGE_ROOT/scripts/validate-generated-output.sh"
cp "$REPO_ROOT/scripts/test_helpers.sh" "$PACKAGE_ROOT/scripts/test_helpers.sh"

tar -C "$OUT_DIR" -czf "$ARCHIVE" "$PACKAGE_NAME"
printf 'Docs template package: %s\n' "$ARCHIVE"
