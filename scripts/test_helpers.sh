#!/usr/bin/env bash

LAST_OUTPUT=""

run_expect_success() {
	local output
	if ! output=$("$@" 2>&1); then
		echo "FAIL command should have succeeded: $*"
		printf '%s\n' "$output"
		exit 1
	fi
	LAST_OUTPUT="$output"
}

run_expect_failure() {
	local output
	if output=$("$@" 2>&1); then
		echo "FAIL command should have failed: $*"
		printf '%s\n' "$output"
		exit 1
	fi
	LAST_OUTPUT="$output"
}

assert_output_contains() {
	local needle="$1"
	if ! printf '%s\n' "$LAST_OUTPUT" | grep -Fq "$needle"; then
		echo "FAIL expected output to contain: $needle"
		printf '%s\n' "$LAST_OUTPUT"
		exit 1
	fi
}

assert_path_exists() {
	local target_path="$1"
	if [[ ! -e "$target_path" ]]; then
		echo "FAIL expected path to exist: $target_path"
		exit 1
	fi
}

assert_path_missing() {
	local target_path="$1"
	if [[ -e "$target_path" ]]; then
		echo "FAIL expected path to be missing: $target_path"
		exit 1
	fi
}

assert_file_contains() {
	local target_path="$1"
	local needle="$2"
	if ! grep -Fq "$needle" "$target_path"; then
		echo "FAIL expected file to contain: $needle"
		echo "FILE: $target_path"
		exit 1
	fi
}

setup_temp_site() {
	local repo_root="$1"
	local site_dir="$2"
	cp "$repo_root/kujo-ssg.yml" "$site_dir/kujo-ssg.yml"
	cp -R "$repo_root/assets" "$site_dir/assets"
	cp -R "$repo_root/content" "$site_dir/content"
	cp -R "$repo_root/templates" "$site_dir/templates"
}
