#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="$repo_root/output-ability-conformance"
helper_tmp=""

cleanup() {
	rm -rf -- "$output_dir"
	if [[ -n "$helper_tmp" ]]; then
		rm -rf -- "$helper_tmp"
	fi
}
trap cleanup EXIT

if [[ -z "${KUJO_BIN:-}" || ! -x "$KUJO_BIN" ]]; then
	echo "ERROR: KUJO_BIN must point to an executable Kujo runtime"
	exit 1
fi

rm -rf -- "$output_dir"
helper_tmp="$(mktemp -d "$repo_root/tmp/ability-helper-test.XXXXXX")"
cd "$repo_root"
SSG_ABILITY_REAL_BUILD=1 "$KUJO_BIN" run tests/ability_pack_tests.kujo --interpreter
bash scripts/validate-generated-output.sh output-ability-conformance
artifact_path="${helper_tmp#$repo_root/}/site.tar"
python3 scripts/ability-inspect.py export output-ability-conformance "$artifact_path" >"$helper_tmp/export-1.json"
first_digest="$(shasum -a 256 "$repo_root/$artifact_path" | cut -d ' ' -f 1)"
python3 scripts/ability-inspect.py export output-ability-conformance "$artifact_path" >"$helper_tmp/export-2.json"
second_digest="$(shasum -a 256 "$repo_root/$artifact_path" | cut -d ' ' -f 1)"
test "$first_digest" = "$second_digest"
ln -s "$output_dir" "$helper_tmp/output-link"
if python3 scripts/ability-inspect.py output-inspect "${helper_tmp#$repo_root/}/output-link" >/dev/null 2>&1; then
	echo "ERROR: SSG Ability helper followed a symbolic-link output root"
	exit 1
fi
echo "SSG Ability fixture integration passed"
