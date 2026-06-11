# Accessibility, Web Standards, and Performance Audit

## Summary
This audit reviewed Kujo SSG source and template defaults with a focus on accessibility semantics, standards compliance, and output safety. High-impact source-level improvements were implemented in layout rendering, navigation generation, card rendering, pagination semantics, and baseline CSS accessibility behavior.

At audit time, full generated-output verification was blocked by pre-existing Kujo runtime/compiler issues. That repo-local VM blocker has now been removed by replacing loop-lowering hotspots in `build.kujo`, and the standard Kujo VM CI/release path now passes with generated-output contract validation.

## Scope
Reviewed:
- build pipeline and output generation logic in `build.kujo`
- shared layout and page/post templates in `templates/`
- default stylesheet in `assets/css/style.css`
- generated output directory state in `output/`
- project docs and available commands in `README.md`

Current repo validation assets:
- shell-based contract tests in `scripts/`
- generated-output validator in `scripts/validate-generated-output.sh`
- CI workflow in `.github/workflows/ci.yml`
- release gate in `scripts/run_release_gate.sh`

## Status Update

Current verified state:
- Kujo VM build and generated-output validation pass through `scripts/run_ci_checks.sh`
- CLI contract tests pass
- generated-output contract tests pass
- release gate passes after changelog/version verification
- the prior `__iter_2` duplicate declaration VM compile failure is resolved in this repository

## Standards Target
- WCAG 2.2 AA practical target
- semantic HTML and landmark correctness
- keyboard/focus visibility and reduced-motion support
- safer generated HTML escaping
- output validation guardrails for regressions

## Baseline
Build and runtime baseline:
- VM mode build command:
  - `/path/to/kujo/target/debug/kujo run ./build.kujo -- --site-url https://example.com`
  - Result: passed
- Interpreter mode build command:
  - `/path/to/kujo/target/debug/kujo run --interpreter ./build.kujo -- --site-url https://example.com`
  - Result: no longer required for repo-local release validation

Generated output baseline at audit time:
- `output/` contained assets only
- no generated HTML files were present

## High-Impact Findings
| ID | Severity | Category | Location | Finding | Status | Verification |
|---|---|---|---|---|---|---|
| A11Y-001 | High | A11Y-HTML | `build.kujo` | Navigation lacked `aria-current` on active route links | Fixed | Source review + diagnostics panel clean |
| A11Y-002 | High | A11Y-HTML | `build.kujo` | Pagination emitted non-landmark wrapper and lacked current-page semantics | Fixed | Source review + diagnostics panel clean |
| A11Y-003 | High | A11Y-JS | `templates/layout.html` | Mobile menu toggle lacked dynamic expanded state/controls wiring | Fixed | Template review + diagnostics panel clean |
| A11Y-004 | High | A11Y-CSS | `assets/css/style.css` | Missing robust `:focus-visible` defaults | Fixed | Source review + diagnostics panel clean |
| A11Y-005 | Medium | A11Y-CSS | `assets/css/style.css` | No global reduced-motion fallback | Fixed | Source review + diagnostics panel clean |
| HTML-001 | High | HTML-STANDARDS | `build.kujo` | Generated nav/listing text inserted without escaping | Fixed | Source review + diagnostics panel clean |
| HTML-002 | Medium | HTML-STANDARDS | `build.kujo` | Featured image tag used XHTML-style self-close and lacked loading hints | Fixed | Source review + diagnostics panel clean |
| BUILD-001 | Critical | BUILD-CORRECTNESS | `build.kujo` runtime via Kujo | VM compile blocker prevented reliable full build verification until loop-heavy lowering hotspots were rewritten without `for` iterators | Fixed | Direct VM build, `scripts/run_ci_checks.sh`, and `scripts/run_release_gate.sh` |
| TEST-001 | High | TESTING | project root | No reusable generated-output validation harness | Fixed | `scripts/validate-generated-output.sh` added |

## Fixes Completed
### Source hardening (`build.kujo`)
- Added `html_escape` helper and applied escaping to generated navigation/list card text.
- Added route-aware navigation builder:
  - `build_navigation(...)`
  - `navigation_item(...)`
  - `route_to_path(...)`
- Added `aria-current="page"` to active nav links.
- Updated pagination output to semantic nav:
  - `<nav class="pagination" aria-label="Pagination">`
  - `rel="prev"` and `rel="next"`
  - `aria-current="page"` on current page number.
- Updated featured image tag output:
  - non-self-closing `<img ...>`
  - `loading="lazy"` and `decoding="async"`
- Escaped route alias HTML redirect targets.
- Added fallback listing H1 content in default index/blog fallback rendering paths.

### Layout accessibility (`templates/layout.html`)
- Added keyboard escape handling for mobile menu (`@keydown.escape.window`).
- Added desktop and mobile nav landmark labels.
- Added mobile menu state wiring:
  - `aria-controls="mobile-navigation"`
  - dynamic `:aria-expanded`
- Added `x-cloak` to avoid initial menu flash.
- Changed header site-title wrapper from heading element to paragraph to reduce heading hierarchy conflicts.

### CSS accessibility defaults (`assets/css/style.css`)
- Added shared `:focus-visible` outline styles for links/buttons/form controls.
- Added active-page nav styling via `[aria-current="page"]`.
- Added `prefers-reduced-motion: reduce` fallback.

### Validation tooling
- Added `scripts/validate-generated-output.sh` to validate:
  - doctype
  - `html[lang]`
  - presence of `main`
  - image `alt` presence
  - empty links
  - skip-link target presence
  - sitemap/feed minimal structure checks (if present)
  - fails when zero HTML files are generated.

### Documentation
- Updated `README.md` with generated-output validation command in a dedicated `Validation` section.

## Generated Output Improvements
When build blockers are resolved, the generator now emits safer/more accessible defaults through:
- escaped nav/listing text content
- route-aware current-page nav semantics
- improved pagination semantics
- improved image tag semantics

## Accessibility Improvements
- Keyboard and focus visibility support improved in default CSS.
- Mobile menu accessibility state wiring strengthened.
- Current-page context now represented in navigation.
- Reduced-motion fallback added.

## HTML Standards Improvements
- Escaping coverage improved in nav/list-card generation and alias redirect output.
- Pagination and image output now more standards-consistent.

## CSS Improvements
- Added explicit focus-visible styling.
- Added reduced-motion safety net.
- Added active-link styling tied to semantic `aria-current` state.

## JavaScript Improvements
- Improved progressive enhancement behavior for mobile menu state attributes in `templates/layout.html` (via Alpine bindings).

## Performance Improvements
- Added non-critical image loading hints (`loading="lazy"`, `decoding="async"`).
- Kept changes deterministic and lightweight in generator code paths.

## Tests and Fixtures Added
- Added validation script:
  - `scripts/validate-generated-output.sh`

No existing project test harness was detected in this repo snapshot, so no unit/integration test framework updates were made.

## Validation Commands
```bash
# Build attempt (VM mode; validated release path)
/path/to/kujo/target/debug/kujo run ./build.kujo -- --site-url https://example.com

# Full CI gate
bash scripts/run_ci_checks.sh

# Release gate
bash scripts/run_release_gate.sh

# Generated-output validation
./scripts/validate-generated-output.sh output
```

## Results
- Source-level accessibility and standards hardening changes applied successfully.
- Editor diagnostics report no errors in modified files.
- Kujo VM generated-output rebuild verification now passes through the repo CI and release gate.
- Validation and contract scripts now protect against structural HTML/output regressions on the validated VM release path.

## Remaining Issues
- No repo-local VM/interpreter blocker remains for the validated release path.
- Future Kujo runtime changes should still be spot-checked against this repo because the original failure was runtime-specific.

## Future Recommendations
1. Keep lightweight spot checks for both Kujo execution paths when upgrading the runtime.
2. Add lightweight fixture-based snapshot checks if Kujo-native or shell snapshots become practical for stable outputs.
3. Extend validator coverage with duplicate-id and heading-order checks on the existing VM release path.
