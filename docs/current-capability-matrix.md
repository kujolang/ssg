# Kujo SSG current capability matrix

This is the current implementation-status reference. Historical audits and
roadmaps retain their original findings, but must point here when their status
has been superseded.

| Capability | Current status | Contract coverage |
|---|---|---|
| CLI parsing, config precedence, and supported flags | Validated | `scripts/test-cli-contract.sh` |
| Pages, posts, collections, drafts, pagination, metadata, and auxiliary outputs | Validated | `scripts/test-generated-contract.sh` and `scripts/validate-generated-output.sh` |
| Local featured-image containment | Supported | `scripts/test-generated-contract.sh` rejects an escaping path and retains normal local-image processing |
| Delimiter-aware frontmatter | Supported | `scripts/test-generated-contract.sh` covers quoted/body literal dashes and unclosed-delimiter diagnostics |
| Taxonomy lookup/rendering | Supported | `scripts/test-generated-contract.sh` asserts rendered custom taxonomy labels |
| DocGen-to-SSG Markdown bridge | Supported | `scripts/test-docgen-ssg-bridge.sh` covers deterministic Markdown conversion, frontmatter, gates, stale cleanup, and path containment |
| Remote featured-image/font destination policy | Planned (P0) | No policy contract yet; this is SSG-002 and remains outside the trusted-build default |
| `--watch` rebuild loop | Planned (P1) | Current CLI contract verifies the documented no-op warning |

Run the supported checks with:

```bash
KUJO_BIN=kujo bash scripts/run_ci_checks.sh
```

The CI script runs the CLI, generated-output, documentation, starter-build, and
generated-output validation contracts. Do not infer release approval from a
green local check; use `scripts/run_release_gate.sh` for the release checklist.
