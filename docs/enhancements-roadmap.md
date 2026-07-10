# Kujo SSG — Enhancements Roadmap (next session)

**Date:** 2026-06-20
**Baseline:** `build.kujo` 1.2.0 (after the `--drafts`, absolute-path, and doc-correctness work).
**Goal:** make Kujo SSG a flagship, enterprise-grade showcase of what the Kujo
language can do — robust, secure, and universally useful — so adopters are funneled
into the language itself.

This is a prioritized worklist. Each item: **severity**, **what/why**, a concrete
**action**, and the **surface** to touch. Land every change with a contract
assertion (`scripts/test-cli-contract.sh` or `scripts/test-generated-contract.sh`)
and a clean `bash scripts/run_release_gate.sh`.

> Scope note: the per-page render hot path (`render_markdown`, `render_layout_native`,
> `escape_xml`, `render_listing_card`) lives in the Kujo **runtime** (Rust), not in
> `build.kujo`. Items marked `[RUNTIME]` require changes in `../kujo`, not this repo.

---

## P0 — Robustness & security hardening

### P0-1. Featured-image path resolution can escape the content/asset roots — Complete (2026-07-10)
- **Severity:** Medium (path traversal with attacker-influenced frontmatter)
- **What:** `resolve_local_featured_image_source` (`build.kujo`) joins
  `featured_image` against `content/`, `assets/`, and the source file dir, then
  reads/copies whatever resolves — including `../../etc/...` style escapes. Safe
  for trusted authors; unsafe when content is user-contributed.
- **Resolution:** Existing candidates are canonicalized and accepted only when
  they remain inside an approved content/assets/source-directory root. Escapes
  are omitted and produce a source-file warning.
- **Contract:** `scripts/test-generated-contract.sh` rejects an escaping fixture
  while retaining ordinary local featured-image processing.

### P0-2. Remote image / font download has no destination policy by default
- **Severity:** Medium (SSRF surface when `--download-remote-images` is on)
- **What:** `process_remote_featured_image` and `try_download_google_font`
  `http_get`/`http_request` arbitrary URLs from frontmatter/config. The runtime
  exposes `apply_untrusted_network_destination_policy_defaults` (deny-private
  when unset) but the default trusted build does not engage it.
- **Action:** Document the SSRF consideration in the README; add an optional
  `--deny-private-net` (or honor an outbound policy env) that blocks RFC1918 /
  loopback / link-local destinations for remote fetches. Keep CI deterministic.
- **Test:** remote fetch of a `127.0.0.1` URL is refused when the guard is on.

### P0-3. Frontmatter split is fragile when values contain `---` — Complete (2026-07-10)
- **Severity:** Low/Medium (silent mis-parse)
- **What:** `parse_frontmatter` does `split(content, "---")`. A frontmatter value
  containing `---` (or a body that starts before a clean delimiter) can split the
  document incorrectly.
- **Resolution:** `parse_frontmatter` now accepts only complete delimiter lines
  and preserves literal dashes in quoted YAML and Markdown bodies. Unclosed
  delimiter warnings include the source file and line.
- **Contract:** `scripts/test-generated-contract.sh` covers quoted literal dashes,
  body literal dashes, and an unclosed delimiter diagnostic.

---

## P1 — Functionality that adopters expect

### P1-1. Future-dated posts publish immediately (no scheduling)
- **What:** Only `draft` is filtered; a post dated in the future is published now.
  Most SSGs hide future posts unless asked.
- **Action:** Skip posts whose parsed `date` is after build time by default; add
  `--future` to include them (mirrors the `--drafts` pattern just added).
- **Surface:** `build.kujo` post loop + `parse_post_date`; new flag wired through
  `apply_cli_overrides` / `normalize_settings` / `print_help` / README.

### P1-2. Implement `--watch` (currently reserved/no-op)
- **What:** README and `--help` list `--watch` as "reserved, not implemented"; it
  prints a warning and exits to a single build.
- **Action:** Add a watch loop that rebuilds on `content/`, `templates/`, `assets/`
  changes (poll mtimes if no native fs-notify). Gate behind capability docs.
- **Surface:** tail of `build.kujo` (`if settings["watch"]`), README.

### P1-3. Reading time + word count in post/item context
- **What:** No `reading_time` / `word_count` placeholders for templates.
- **Action:** Compute from the rendered body, expose `{{reading_time}}` /
  `{{word_count}}`; document in Template Overrides.

### P1-4. Heading anchors + optional table of contents
- **What:** Rendered headings have no `id`s; no `{{toc}}`.
- **Action:** Slugify headings to `id`s and offer a `{{toc}}` placeholder for posts.
  Likely cleanest as a `[RUNTIME]` markdown-renderer option.

### P1-5. Sitemap index for large sites
- **Severity:** correctness at scale (sitemaps.org caps a sitemap at 50,000 URLs)
- **Action:** When URL count exceeds the cap, emit `sitemap-N.xml` shards plus a
  `sitemap.xml` index. Ties into the parallel/large-site story.

---

## P2 — Cleanliness & presentation (showcase quality)

### P2-1. Remove the dead singular `category` frontmatter key
- `parse_frontmatter` declares `"category": ""` but nothing consumes it (only
  `categories`). Drop it (or document it) to avoid implying support.

### P2-2. Decide the fate of the `*_interpreted` reference functions
- `render_layout_interpreted`, `listing_card_html_interpreted`, and the
  interpreted `inline_markdown` are kept as labeled reference twins of native
  builtins. They inflate the file (~3,990 lines). Either (a) keep with a single
  top-of-file note explaining the convention, or (b) move them to
  `docs/reference-render-path.md` so `build.kujo` is lean. Pick one and apply.

### P2-3. README polish pass
- Add a short "Runtime Capabilities" cross-link from Quick Start; add a
  one-paragraph "Why Kujo" funnel line that points readers to the language repo;
  consider a generated-output screenshot/gif. Keep brand naming consistent
  (`Kujo SSG`).

---

## P3 — Performance at scale `[RUNTIME]`

Per `docs/performance-findings.md`, Kujo wins ≤ ~500 pages and the reference
generator wins at 2k–10k (≈13.5× at 10k). Closing the large-site gap requires:

1. **Native frontmatter parsing** — biggest remaining interpreted hot spot.
2. **Finalize-phase parallelism** — the serial finalize is the current floor after
   render sharding (see the shard-count sweep notes).
3. **Native file-walk / manifest** for the post listing.

These are language/runtime investments; track them against the `../kujo` repo, not
`build.kujo`. They are the highest-leverage way to make the SSG a credible "fast at
any scale" showcase.

---

## Suggested order

1. P0-2 remote-fetch destination policy (the remaining P0 security item).
2. P1-1 future posts, P1-3 reading time (small, high adopter value).
3. P1-2 `--watch` (developer-experience win).
4. P2-1, P2-2, P2-3 (presentation; do before any "1.x launch").
5. P1-5 sitemap index, then P3 runtime perf for the large-site narrative.
