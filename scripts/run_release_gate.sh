#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

extract_version() {
	local version_line
	version_line="$(grep -E '^VERSION := "' "$REPO_ROOT/build.kujo" | head -n 1 || true)"
	if [[ -z "$version_line" ]]; then
		echo "ERROR: could not find VERSION declaration in build.kujo"
		exit 1
	fi
	printf '%s\n' "$version_line" | cut -d '"' -f 2
}

main() {
	local version
	version="$(extract_version)"

	cd "$REPO_ROOT"

	if [[ ! -f CHANGELOG.md ]]; then
		echo "ERROR: CHANGELOG.md is missing"
		exit 1
	fi

	if ! grep -Fq "## $version" CHANGELOG.md; then
		echo "ERROR: CHANGELOG.md does not contain an entry for version $version"
		exit 1
	fi

	bash scripts/run_ci_checks.sh
	echo "Release gate passed for version $version"
}

main "$@"