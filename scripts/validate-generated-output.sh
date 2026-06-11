#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-output}"

if [[ ! -d "$OUT_DIR" ]]; then
  echo "ERROR: output directory not found: $OUT_DIR"
  exit 1
fi

failures=0
html_count=0

while IFS= read -r html_file; do
  html_count=$((html_count + 1))

  if ! grep -Eqi '^<!doctype html>' "$html_file"; then
    echo "FAIL doctype: $html_file"
    failures=$((failures + 1))
  fi

  if ! grep -Eqi '<html[^>]* lang="[^"]+"' "$html_file"; then
    echo "FAIL html-lang: $html_file"
    failures=$((failures + 1))
  fi

  if ! grep -Eqi '<main[ >]' "$html_file"; then
    echo "FAIL main-landmark: $html_file"
    failures=$((failures + 1))
  fi

  if grep -Eqi '<a[^>]*></a>' "$html_file"; then
    echo "FAIL empty-link: $html_file"
    failures=$((failures + 1))
  fi

  if grep -Eqi '<img[[:space:]][^>]*>' "$html_file"; then
    if grep -Eio '<img[[:space:]][^>]*>' "$html_file" | grep -Eiv ' alt="' >/dev/null; then
      echo "FAIL image-alt: $html_file"
      failures=$((failures + 1))
    fi
  fi

  if grep -qi 'class="skip-link"' "$html_file"; then
    if ! grep -qi 'id="main-content"' "$html_file"; then
      echo "FAIL skip-link-target: $html_file"
      failures=$((failures + 1))
    fi
  fi

done < <(find "$OUT_DIR" -name '*.html' -type f | sort)

if [[ "$html_count" -eq 0 ]]; then
  echo "FAIL no-html: no HTML files found in $OUT_DIR"
  failures=$((failures + 1))
fi

if [[ -f "$OUT_DIR/sitemap.xml" ]]; then
  if ! grep -q '<urlset' "$OUT_DIR/sitemap.xml"; then
    echo "FAIL sitemap-format: $OUT_DIR/sitemap.xml"
    failures=$((failures + 1))
  fi
fi

if [[ -f "$OUT_DIR/feed/index.xml" ]]; then
  if ! grep -q '<rss' "$OUT_DIR/feed/index.xml"; then
    echo "FAIL rss-format: $OUT_DIR/feed/index.xml"
    failures=$((failures + 1))
  fi
fi

echo "Checked HTML files: $html_count"

if [[ "$failures" -gt 0 ]]; then
  echo "Validation failed: $failures issue(s)"
  exit 1
fi

echo "Validation passed"
