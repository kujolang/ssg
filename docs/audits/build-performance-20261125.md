# Kujo SSG build performance hardening

November 25, 2026. Scope is build throughput in `kujolang/ssg` at clean
`main` baseline `e0e909f1b08f43cbffea7899992a3a13fc2cc27d`.

## Findings and changes

| Priority | Finding | Evidence | Resolution |
| --- | --- | --- | --- |
| P1 | Large Markdown documents repeatedly copied the growing body-line array while extracting frontmatter. | `parse_frontmatter` rebuilt both subarrays with one VM `push` per line after splitting the source. | Use native slices and the same native join. The existing delimiter scan and YAML parser still handle metadata and warnings. |
| P1 | Custom collections sorted with interpreted insertion sort. | `sort_posts` repeatedly lowercased text keys and shifted dictionary entries. Reverse-ordered input required a quadratic number of comparisons and shifts. | Compute one key per item, sort the keys in the VM's native string sort, and recover the original records by position. |

Collection sorting preserves signed numeric order, newest-first dates,
case-insensitive titles and authors, and discovery order for ties. The key
terminator preserves lexical prefix order, including when a key contains a
NUL. Collection cards and `llms.txt` share the same sorted records. The comparators
also cover absent dates and default order values through the existing metadata
normalization. The native sort bounds key comparisons by O(n log n). Collection
discovery, item accumulation and HTML assembly still have their existing costs.

## Audit coverage

Excluded generated `output/`, `tmp/`, dependency and cache directories,
minified Tailwind and Alpine, fonts, images, and bulk `static/` assets from the
source sweep. Generated trees were inspected only for output verification.

| Checklist phases | Scope and evidence |
| --- | --- |
| 0–2 | Traced the CLI entrypoint through config, content discovery, Markdown and layouts, listing pagination, collection finalization, and WebMCP emission. Inspected the benchmark generator, regression contracts, CI, release gate, and earlier audit evidence. |
| 3–4 | Checked repeated parsing, growing arrays, native calls and temporary record lifetimes. Optimized two in-process hot paths without adding caches, temporary files, or subprocesses. |
| 5–6, 15 | Reviewed bounded WebMCP results, read-only config inspection, Ability idempotency, and build receipts. These retain existing schema registration, disclosure, retry and handoff behavior. |
| 7–10 | Checked delimiter diagnostics, YAML handling, established collection ordering, sharded finalization, and shared post-order encoding. The changes operate on in-memory data under the existing entrypoints and permission model. |
| 11 | Inspected the pinned esbuild and Ability dependencies. Neither is on the changed hot paths. |
| 12–13 | Extended generated-output contracts for CRLF, Unicode, EOF, all four custom-collection sort modes and tie order. Retained frozen outputs and left timings outside CI. |
| 14, 16 | Linked the new benchmark from the historical performance notes. Removed the superseded insertion sorter. |
| 17–18 | Verified on the standard Kujo VM with the commands below. |

## Measurements

Both revisions ran on the same Intel i7-9750H Mac with the prebuilt Kujo 1.10.0
VM and Node 26.12.1. The focused benchmark ran each original and updated routine
in the same VM process after checking equal results. Three alternating pairs
measured elapsed time with `performance_now()`. The host had concurrent builds
and test activity.

| Workload | Before median (range) | After median (range) | Speedup |
| --- | ---: | ---: | ---: |
| Parse a Markdown document with 1,200 Unicode body lines, 12 times per sample | 3,998 ms (3,432–4,408) | 219 ms (152–262) | 18.3× |
| Sort 100 collection items by descending date, with ascending input dates and tied pairs | 8,843 ms (6,636–11,591) | 143 ms (134–217) | 62.0× |

End-to-end samples used `scripts/generate-benchmark-content.py` and the same
templates, bundled font settings, WebMCP, auxiliary outputs, and 25 posts per
listing page. The collection workload moved the generated `posts/` directory
to `products/`. Each long document added 1,000 Unicode Markdown lines. Asset
input was an empty directory to isolate content work. CPU totals include child
processes. The compared trees matched byte-for-byte, including WebMCP and
auxiliary files. Wall times varied as host load changed.

| Workload | Before wall / CPU | After wall / CPU | Matching files |
| --- | ---: | ---: | ---: |
| 60 collection items and 2 pages | 29.930 s / 9.406 s | 42.032 s / 9.400 s | 140 |
| 12 long posts and 2 pages | 16.948 s / 5.817 s | 19.145 s / 5.379 s | 42 |
| 150 collection items and 2 pages | 83.815 s / 27.973 s | 47.342 s / 19.148 s | 320 |

The 150-item collection build used 31.5% less CPU and finished 43.5% sooner
in its paired run. The 60-item build used about the same CPU. The long-post
build used 7.5% less CPU and took longer in elapsed time. These single-pair
wall times reflect changing host load. The 300-item exploratory baseline
reached its 480-second limit, so it supplies no completed comparison.

The 320-file output fingerprint is
`dcee2e6a66c2a06a17ab770f93df183e18bf0e27ec505d87e9d2ad57a4f6bad5`.
The fingerprint hashes a sorted JSON mapping from each relative path to
its file's SHA-256.

The full-build invocation was:

```bash
"$KUJO_BIN" run "$builder" -- --content "$fixture" --output "$output" \
  --assets "$empty_assets" --site-url https://bench.example.test --posts-per-page 25
```

The baseline builder came from `git show e0e909f:build.kujo`. Local fixture,
benchmark and verification artifacts are under `tmp/hardening-20261125/`.

## Verification

Both source changes were tested together on the standard VM. Code commits are
`2122aa2` (frontmatter) and `01622b3` (collection sort).

| Command | Result |
| --- | --- |
| `npm ci --ignore-scripts` | Passed. |
| Baseline `bash scripts/run_ci_checks.sh` | Sibling runtime compilation ran out of disk space. |
| Baseline `KUJO_BIN="$(command -v kujo)" bash scripts/run_release_gate.sh` | Kujo 1.5.0 timed out in publication setup after 120 s during heavy host load. |
| `KUJO_BIN="$PWD/../kujo/target/debug/kujo" bash scripts/test-generated-contract.sh` | Passed. |
| `KUJO_BIN="$PWD/../kujo/target/debug/kujo" bash scripts/run_release_gate.sh` | Passed through the DocGen bridge. A packaged docs fixture ran out of disk space during asset copy. |
| Same binary, `bash scripts/test-docs-template.sh`, `bash scripts/test-docs-contract.sh`, `bash scripts/test-ability-contract.sh`, and `bash scripts/test-ability-pack-integration.sh` | Passed on continuation after disk space recovered. |
| Same binary, `kujo run ./build.kujo -- --site-url https://example.com` and `./scripts/validate-generated-output.sh output` | Passed on continuation. Validated 42 HTML files. |
| Same binary, `bash scripts/verify-webmcp-disabled-baseline.sh` | Passed. All six frozen output variants matched. |
| `git diff e0e909f..HEAD --check` and `bash -n scripts/test-generated-contract.sh` | Passed. |

The initial and continuation runs cover all release checks on identical source.
The baseline failures above limit cross-runtime verification.

Both optimizations use the existing CLI, output schemas, configuration,
environment variables, and dependency pins. They operate entirely in SSG.
The prior large-docs scalability item remains tracked under
`cap_61b680d6-c127-441d-ab7d-18e3269aded0`. The measurements here cover the two
changed paths. The historical 10,000-page comparison was outside the scope
of this pass.
