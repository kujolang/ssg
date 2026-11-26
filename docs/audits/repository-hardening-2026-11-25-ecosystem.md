# SSG ecosystem hardening pass

## Repository and baseline

- Repository `kujolang/ssg`, branch `main`
- Starting commit `dcca4a62866c054ae218ff07f27b4ebc51a95e0c`
- Verified implementation commit `df44f51ce955594eb3658cd20956210631e2525c`
- SSG renders Markdown and metadata through Kujo and optionally generates a public WebMCP index and adapter. esbuild handles static minification and a pinned Ability package exposes local build operations. Reviewed the [build performance pass](build-performance-20261125.md) and earlier repository hardening reports as baseline evidence.

## Findings

| ID | Priority | Area | Evidence and change | Status |
| --- | --- | --- | --- | --- |
| SSG-01 | P1 | Shared WebMCP fetch | The caller that started the cached index request owned its signal. The new concurrent regression failed against the baseline when the first caller cancelled. The page now owns the fetch, while each caller observes its own cancellation. Failed requests clear only their own cache slot. | Fixed |
| SSG-02 | P1 | Browser lifecycle | The adapter aborted its only registration on page exit. A browser back/forward restore could retain the script with all tools gone. Re-register on a persisted `pageshow` and restart index loading lazily. | Fixed |
| SSG-03 | P2 | Transfer budget | The release fixture used a bare shell assertion for adapter size. A traced macOS run continued after a 6,483-byte result failed the 6,144-byte condition. Use explicit failure handling and full minification for the generated adapter. Preserve whitespace-only transformations for site-owned assets. | Fixed |
| SSG-04 | P2 | Parallel failure reporting | Worker status aggregation needed a writable temporary directory, and unexpected parent exit could leave unreaped workers. Aggregate bounded shard status in memory and retain only unreaped worker IDs for exit cleanup. | Fixed |
| SSG-05 | P1 | WebMCP origin boundary | The initial URL was checked, while the default Fetch mode could follow redirects across origins. Request the index in same-origin mode. [Fetch Standard](https://fetch.spec.whatwg.org/#concept-request-mode) | Fixed |

## Coverage and compatibility

| Phases | Evidence |
| --- | --- |
| 0–2 | Read the canonical Kujo builder, starter config and content, generated and CLI contracts, GitHub release gate, parallel wrapper and WebMCP docs. Traced the opt-in shard and default single-process entrypoints. |
| 3–4 | Reviewed recent frontmatter and sorting measurements, bounded listing pagination, lazy index fetch and job cleanup. This pass changes fetch ownership and removes a temporary status file. It does not claim build-time or memory improvements. |
| 5–6, 15 | Inspected index publication, bounded result projections, registration schema, response size and the local Ability handoff contract. The four read-only tools and their schemas are preserved. The same index bytes are emitted. One cancelled caller no longer aborts the fetch for a peer. |
| 7–9 | Checked CLI phase ownership, output/source overlap guards, the trusted esbuild process, draft filtering, subpath URLs, page and per-call cancellation, failed cache eviction and worker shutdown. |
| 10–11 | CLI flags, configuration, index schema, command status, dependencies and environment variables are preserved. Normal source and generated route layouts are preserved. Only the generated adapter uses full minification. |
| 12–13 | Regression coverage exercises cancellation before a request, during a shared request and after caching, and navigation with old requests still active. Existing failure and interruption suites exercise the parallel wrapper, including failure reporting with an unavailable temporary directory. The existing adapter budget is enforced. |
| 14–16 | Updated release notes and documentation. Kept generated evidence, vendor assets, historical compat modes and Ability boundaries. Excluded bulk images, fonts, vendor JS/CSS and generated artifacts from source inspection. |
| 17–18 | See the verification receipt below. |

## Verification

- `KUJO_BIN=/path/to/kujo bash scripts/run_release_gate.sh` passed on the baseline and lifecycle/parallel candidate in an isolated worktree on macOS with the existing Kujo 1.10.0 binary, Node 26.12.1, esbuild 0.28.2 and pinned Ability package. The gate covered CLI precedence, generated output, web publishing boundaries, minification, DocGen, starter packaging, Ability integration and all six frozen WebMCP-disabled modes. The first baseline attempts lacked the scratch worktree's dependency links. With the links in place the gate passed.
- `KUJO_BIN=/path/to/kujo bash scripts/test-webmcp-contract.sh` passed after the final same-origin change. This verifies raw and minified runtime behavior, compact budget, public projection, duplicate rejection, subpaths and byte-identical sharded artifacts. `python3 scripts/test-hardening-contract.py Parallel`, `bash scripts/test-bug-regressions.sh` and `git diff --check` passed.
- `kujo run build.kujo -- --output "$output" --site-url https://example.test` and `node scripts/test-webmcp-runtime.js "$runtime" "$index"` passed on the final artifact for both emitted adapter forms. Of 85 starter output files, 83 matched the baseline byte for byte. The raw adapter grew from 5,883 to 6,548 bytes. The minified adapter grew from 5,932 to 6,125 bytes, within the 6,144-byte cap.
- Browser lifecycle and redirects are covered by the emitted script's Node VM contract and the Fetch specification. An experimental WebMCP browser session was outside this verification.

## Cross-repository follow-up

The template function `webmcp_runtime_source` is also vendored in `kujolang.ai` and `agents.kujolang.ai`. Promote the verified adapter there and run each site's generated runtime checks.
