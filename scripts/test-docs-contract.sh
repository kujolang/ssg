#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$REPO_ROOT/scripts/test_helpers.sh"

assert_file_contains "$REPO_ROOT/docs/current-capability-matrix.md" '# Kujo SSG current capability matrix'
assert_file_contains "$REPO_ROOT/docs/current-capability-matrix.md" '| Local featured-image containment | Supported |'
assert_file_contains "$REPO_ROOT/docs/current-capability-matrix.md" '| Delimiter-aware frontmatter | Supported |'
assert_file_contains "$REPO_ROOT/docs/current-capability-matrix.md" '| DocGen-to-SSG Markdown bridge | Supported |'
assert_file_contains "$REPO_ROOT/docs/current-capability-matrix.md" '| Reusable docs-site starter package | Supported |'
assert_file_contains "$REPO_ROOT/docs/current-capability-matrix.md" '| Remote featured-image/font destination policy | Planned (P0) |'
assert_file_contains "$REPO_ROOT/README.md" 'scripts/docgen_ssg_bridge.kujo'
assert_file_contains "$REPO_ROOT/README.md" 'scripts/update_docs.kujo'
assert_file_contains "$REPO_ROOT/README.md" 'scripts/package-docs-template.sh'
assert_file_contains "$REPO_ROOT/docs/parity-audit.md" 'Status: historical snapshot'
assert_file_contains "$REPO_ROOT/docs/enhancements-roadmap.md" 'P0-1. Featured-image path resolution can escape the content/asset roots — Complete (2026-07-10)'
assert_file_contains "$REPO_ROOT/docs/enhancements-roadmap.md" 'P0-3. Frontmatter split is fragile when values contain `---` — Complete (2026-07-10)'
assert_file_contains "$REPO_ROOT/ROADMAP.md" 'SSG-002 remote-fetch destination policy remains open'

echo "Documentation contract passed"
