# SSG security hardening

## Repository and baseline

- Repository `kujolang/ssg`, branch `main`.
- Starting commit `544f5cfa0f6be047fc25b87fa67d2cbba210e816`.
- Implementation commits `f90126a0df29bf9b942d887af6c36d91bfeea4c8` and `32a0799781e17ecfb1b19fa68920f457c40fc021`.
- SSG builds static HTML, discovery artifacts, and optional public WebMCP output. It uses the Kujo VM, the pinned esbuild minifier, Bash/Python tooling, and a commit-pinned Kujo Ability package.
- The baseline had passing hosted CI. A local Cargo build hit disk exhaustion, and the pre-existing development binary disappeared during follow-up checks. For the final comparison, both revisions used the checksum-verified Kujo 1.10.0 macOS x64 release with Node 26.12.1, esbuild 0.28.2, and the same local Ability dependency. The baseline worktree was on a scratch volume, with temporary test files on that same volume so its hardlink fixture could run. [Baseline hosted CI](https://github.com/kujolang/ssg/actions/runs/45747339801), [Kujo 1.10.0 release](https://github.com/kujolang/kujo/releases/tag/v1.10.0).

## Findings

| ID | Priority | Area | Evidence and change | Status |
| --- | --- | --- | --- | --- |
| SSG-SEC-01 | P0 | Destructive output cleanup | Builder validation covered the working directory itself and configured source roots. It now also protects ancestors of the working directory, Git metadata and the active `static/` fallback, and recognizes a final output symlink with trailing directory syntax. Read-only config regressions cover the rejected paths. | Fixed |
| SSG-SEC-02 | P0 | Source publication | Content and template root paths could follow a final symlink. Template reads and the fallback stylesheet copy could also follow linked leaves. Reject linked content and template roots, use template fallbacks for linked files, and omit symlinks and Git metadata from asset copying. Regression fixtures verify that linked content stays out of output and regular fallback assets still build. | Fixed |
| SSG-SEC-03 | P0 | Parallel source manifest | The internal manifest split filenames on newlines, and workers trusted each resulting path. Serialize the list as JSON and check each assigned entry for a regular Markdown file under the posts root before reading. Finalize skips the manifest read. A newline filename fixture compares serial and sharded HTML and index bytes. | Fixed |
| SSG-SEC-04 | P0 | Ability and output validation | Build and validation handlers checked path spelling without checking ancestor links. The shell validator used recursive link-following grep for markers, and Python output inspection and export accepted Git metadata. Reject linked components before process launch, keep HTML validation inside the selected output tree, and protect Git metadata in helper operations. Regression coverage exercises canonical Ability receipts for linked and dangling parents, literal validator paths, and protected inspection and artifact destinations. | Fixed |
| SSG-SEC-05 | P2 | Workflow supply chain | CI left token permissions at the configured default, checkout persisted credentials, and Rust setup used a floating action ref. Set read-only contents permission, disable checkout credential persistence in both workflows, and pin the Rust setup action with an explicit stable toolchain input. [GitHub secure use reference](https://docs.github.com/en/actions/reference/security/secure-use), [Pinned Rust setup definition](https://raw.githubusercontent.com/dtolnay/rust-toolchain/df2a88e9fe4098bad09cb42c3dec7187f15861fc/action.yml). | Fixed |

## Coverage and compatibility

| Phases | Evidence |
| --- | --- |
| 0–2 | Read the public CLI, builder, config, starter templates and content, scripts, workflow definitions, and preceding hardening evidence. Excluded bulk images, fonts, minified vendor files, `static/` bulk content, `output/`, `tmp/`, and dependency trees from the broad source sweep. Reviewed the `static/` fallback's copy and cleanup code directly. |
| 3–4 | Traced worker setup, selective post reads, finalization, stream fragments, download limits, and bounded Ability traversal. The JSON handoff still lists once at setup and checks only a worker's own stripe. No speed or memory improvement is claimed. |
| 5–6, 15 | Reviewed the bounded four-tool WebMCP projection, the same-origin index fetch, local Ability schemas, bounded receipts, approval/idempotency, and worker retry behavior. The only change to sharded handoff data is internal to the builder. |
| 7–9 | Reviewed destructive cleanup, path resolution, asset copying, local and remote media, template substitution, generated output validation, sharded reads, and artifact export. Trusted operator configuration and a trusted build workspace remain prerequisites. Filesystem prechecks address stable paths. |
| 10–11 | Existing flags, Ability schemas, generated-site schema, config keys and environment variables are preserved. Invalid paths are rejected earlier. Manual phase users must restart interrupted builds with setup to regenerate the manifest. Runtime dependencies are unchanged. CI continues to use stable Rust and the current Kujo checkout for compatibility coverage. |
| 12–13 | Regression coverage is in the existing CLI, WebMCP, Ability, and filesystem suites used by CI. Both workflow files were parsed and checked for exact action pins, permissions and disabled checkout credential persistence. |
| 14–16 | Updated the public CLI, Ability and changelog documentation. Preserved historical and compatibility evidence. No dependency or unsupported surface removals were justified by the security scope. |
| 17–18 | Implemented and verified the changes listed above. |

No cross-repository code change is required for these fixes. The snapshot covers repository-owned behavior and existing VM contracts. Deliberate concurrent filesystem modification by another process with workspace write access and live browser coverage were outside the verification scope.

## Verification receipt

- `npm ci --ignore-scripts` passed. `npm audit --json` reported zero known vulnerabilities in the npm dependency set.
- Baseline `KUJO_BIN=<development Kujo 1.10.0> bash scripts/run_ci_checks.sh` passed before the binary became unavailable. The checksum-verified release binary passed `KUJO_BIN=<Kujo 1.10.0> bash scripts/verify-webmcp-disabled-baseline.sh` and built the baseline starter with `kujo run ./build.kujo -- --site-url https://example.com`.
- Candidate `KUJO_BIN=<Kujo 1.10.0> bash scripts/run_release_gate.sh` passed. It exercised the full CI suite, validated 42 HTML files, and matched all six frozen WebMCP-disabled modes.
- `diff -rq <baseline>/output <candidate>/output` matched all 85 starter output files byte for byte. The WebMCP contract also matched the HTML and discovery index between single-process and sharded builds with a newline in a Markdown filename.
- Shell syntax checks, workflow YAML checks, and `git diff --check` passed. Local command logs are under the ignored `tmp/security-hardening/` directory.
