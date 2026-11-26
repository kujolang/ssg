# SSG DocGen security hardening

## Repository and baseline

- `kujolang/ssg`, branch `main`, starting commit `f1e6d9edc8613c02b7ae3afda97f9be2dd8fdc6d`, verified implementation commit `1716167d9ace1c38693d9498f743423d81b2a7db`.
- The SSG builds static output and optional WebMCP discovery artifacts. Its DocGen bridge converts machine-readable DocGen output into Markdown using the Kujo VM for ordinary inputs and the Python reducer for large inputs. The release gate also exercises esbuild, the pinned Ability runtime, shell wrappers, and the reusable docs starter.
- Baseline and candidate used the same Kujo 1.10.0 macOS x64 release, Node 26.12.1, and lockfile dependencies. The initial local runtime build and initial gate attempts hit host disk exhaustion. Verification used isolated source copies on a scratch volume with fixture temporary directories on that volume.

## Findings and changes

| ID | Priority | Finding | Change and evidence | Status |
| --- | --- | --- | --- | --- |
| DOCGEN-SEC-01 | P0 | Both DocGen backends treated an old manifest entry as sufficient authority to delete an existing file. A generated filename could also overwrite a handwritten page. | Require a regular Markdown file with `docgen_generated: true` in its frontmatter before mutating existing pages. Preflight all stale and planned destinations before changing any files. The bridge contract verifies that both backends preserve handwritten pages and all pending cleanup when preflight fails, and still remove owned stale pages on a successful refresh. | Fixed |
| DOCGEN-SEC-02 | P0 | The bridge's contained-path policy included Git metadata, and stale paths could point into nested Git metadata. | Reject Git metadata in resolved bridge write roots and in manifest descendant components. The content-boundary suite verifies early rejection for content, DocGen output, and cache destinations. Both backends also reject nonregular manifest files before reading them. | Fixed |

## Coverage and compatibility

- Phases 0–2 and 7–9 covered CLI/config intake, Markdown publication, template and asset paths, DocGen manifest and search paths, temporary outputs, parallel builder handoff, subprocess dispatch, and failure ordering. The source sweep excluded generated output, dependency trees, scratch files, and bulk/vendor fonts, images, scripts, and `static/` assets. The previous security report provides the baseline for builder, Ability, and CI boundaries.
- Phases 3–6 and 15 covered resource bounds on fetches and inspection, the small-input/large-input DocGen split, bounded Ability receipts, the four-tool public WebMCP projection, and sharded worker retries. Verification focused on filesystem integrity. No runtime, memory, token, or throughput improvement is claimed.
- Phases 10–11 and 14–16 covered CLI/config, manifest schemas, dependencies, workflow permissions, docs starter behavior, and documentation. The bridge uses its existing CLI, manifest schema, and generated ownership field. Handwritten filename collisions now fail before mutation. Use the docs starter's dedicated `content/reference/generated` directory for a direct bridge run if the parent contains a handwritten overview. No runtime dependency or environment variable changes were required.
- Phases 12–13 and 17–18 added coverage to the existing bridge and boundary suites and used the existing release gate. Generated site and browser-tool behavior were covered through the existing contract tests. Live browser coverage and concurrent workspace mutations by another local writer were outside this run's verification scope.

No cross-repository code change is required. No open P0–P3 action was admitted in the verified scope.

## Verification

- `npm ci --ignore-scripts` passed on both source copies. `npm audit --json` reported zero known vulnerabilities in the npm dependency set.
- `KUJO_BIN=<Kujo 1.10.0> bash scripts/test-docgen-ssg-bridge.sh` passed locally with both ownership regression backends. The hardening, content-boundary, docs pipeline, and minification suites passed during the local candidate run.
- `KUJO_BIN=<Kujo 1.10.0> bash scripts/verify-webmcp-disabled-baseline.sh` passed all six frozen variants. Paired `kujo run ./build.kujo -- --site-url https://example.com --output <path>` builds matched all 85 starter output files byte for byte with `diff -rq`. `bash scripts/validate-generated-output.sh <candidate-output>` passed all 42 HTML files.
- `bash -n scripts/test-docgen-ssg-bridge.sh`, `git diff f1e6d9e HEAD --check`, and the local tool-artifact guard passed.
- The local full release gate stopped when the macOS host ran out of space creating shell here-documents. The exact baseline and implementation commits both passed the full `bash scripts/run_ci_checks.sh` hosted workflow. The implementation also passed the hosted artifact guard. Local command logs are in ignored `tmp/docgen-security-20261126/`. [Baseline CI](https://github.com/kujolang/ssg/actions/runs/45902015224), [Implementation CI](https://github.com/kujolang/ssg/actions/runs/45906787809), [Implementation artifact guard](https://github.com/kujolang/ssg/actions/runs/45906787821).
