#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="$repo_root/output-ability-conformance"

cleanup() {
	rm -rf -- "$output_dir"
}
trap cleanup EXIT

if [[ -z "${KUJO_BIN:-}" || ! -x "$KUJO_BIN" ]]; then
	echo "ERROR: KUJO_BIN must point to an executable Kujo runtime"
	exit 1
fi

cleanup
cd "$repo_root"
SSG_ABILITY_REAL_BUILD=1 "$KUJO_BIN" run tests/ability_pack_tests.kujo --interpreter
bash scripts/validate-generated-output.sh output-ability-conformance
echo "SSG Ability fixture integration passed"
