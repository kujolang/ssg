# the reference SSG Feature-Parity Audit — Kujo SSG

**Date:** 2026-06-18
**Audited build:** `build.kujo` (3303 lines) at repo root
**Reference:** [the reference SSG project](the reference SSG project repository) — `the reference SSG core module` (2449 lines), `cli.py`, `settings.py`, and the bundled Jinja2 templates (`base.html`, `post.html`, `page.html`, `index.html`, `tag.html`, `category.html`, `404.html`).

This document is a one-by-one implementation worklist. Each item has a **severity**, the **the reference SSG behavior**, the **current Kujo behavior** (with `build.kujo` line refs), and a concrete **action**. Work top to bottom within each priority band.

> **Scope note.** The goal is "all the reference SSG features present in Kujo SSG." Where Kujo already *exceeds* the reference SSG, that is recorded in the final section so an implementer does not accidentally "fix" it back down. A few items below are improvements that go *beyond* the reference SSG for real-world SEO — they are explicitly marked `[BEYOND-PARITY]` and are optional.

---

## Executive Summary

Kujo SSG is at or above the reference SSG parity for the **core pipeline**: pages, posts, custom collections, drafts, slugs/`custom_url`, pagination, sort modes, robots/sitemap/llms/404, config precedence (yml/yaml/json + CLI), Open Graph + Twitter Card meta, and featured-image WebP processing. The CLI flag set is a **superset** of the reference SSG's.

The real gaps fall into three buckets:

1. **Functional bugs / dead features in Kujo** — the documented `taxonomies:` custom-taxonomy system is parsed away and never rendered; a large block of taxonomy helper code is dead.
2. **Genuine parity gaps** — human-readable date formatting, RSS `pubDate`/`lastBuildDate`, and arbitrary Google Fonts download.
3. **Shared SEO weaknesses** — both projects emit *relative* `og:image`/`twitter:image` URLs (broken for social scrapers) and neither emits JSON-LD, favicon, or RSS autodiscovery. Listed as optional `[BEYOND-PARITY]` upgrades.

---

## P0 — Functional bugs (documented behavior that does not work)

### P0-1. `taxonomies:` frontmatter is discarded; custom taxonomies never render
- **Severity:** High (documented feature is a no-op)
- **README claim:** `README.md` §"Taxonomies And Lookups" documents `taxonomies:` as "the right place for free-text custom taxonomy values," and shows `taxonomies: { district: downtown }`.
- **Current behavior:**
  - `parse_frontmatter` builds `meta`, then at **`build.kujo:660`** hard-resets it: `meta["taxonomies"] = {}` — overwriting whatever the author wrote.
  - In `build_site`, the custom-taxonomy HTML slot is hard-coded to empty in **all three** content loops:
    - pages: `page_custom_taxonomies_html := ""` (`build.kujo:2492`)
    - posts: `post_custom_taxonomies_html := ""` (`build.kujo:2603`)
    - collection items: `item_custom_taxonomies_html := ""` (`build.kujo:2775`)
  - The `{{taxonomies_html}}` placeholder in `templates/post.html:8` (and page/item templates) therefore always renders nothing.
- **Dead code that was *meant* to drive this** (currently never called from `build_site`):
  - `normalize_taxonomies_map` (`:467`), `resolve_taxonomy_groups` (`:936`), `taxonomy_terms_from_groups` (`:968`), `taxonomy_groups_html` (`:1017`), `load_taxonomy_lookups` (`:1063`), `taxonomy_lookup_for` (`:825`), `taxonomy_names_from_meta` (`:889`), `taxonomy_terms_from_meta` (`:864`).
- **Action:**
  1. In `parse_frontmatter`, replace `meta["taxonomies"] = {}` (`:660`) with `meta["taxonomies"] = normalize_taxonomies_map(meta["taxonomies"])` so author values survive.
  2. In each of the three content loops, call `load_taxonomy_lookups(content_root)` once (before the loops) and replace the `_custom_taxonomies_html := ""` stubs with `taxonomy_groups_html(resolve_taxonomy_groups(meta, content_type, taxonomy_lookups), excluded)` — excluding `categories`/`tags`/`color`/`location` which already have dedicated slots.
  3. Add a generated-output contract test asserting a `taxonomies:` value (e.g. `district: downtown`) appears in the rendered item HTML.

### P0-2. Primary nav hard-codes `/blog/` even when `--blog-slug` differs
- **Severity:** Medium (broken link when blog slug is customized)
- **the reference SSG behavior:** Nav is built from pages; the blog listing route follows `blog_slug`.
- **Current behavior:** `build_navigation` always emits `navigation_item("/blog/", "Blog", …)` (`build.kujo:719`), ignoring `settings["blog_slug"]`. With `--blog-slug updates`, the nav "Blog" link points at `/blog/` which is never generated (posts live under `/updates/`).
- **Action:** Pass `blog_slug` into `build_navigation` and build the link/label from it (`"/" + blog_slug + "/"`). Skip the link entirely when `blog_slug` is empty (posts then live at root and are reachable via Home).

---

## P1 — Genuine parity gaps (the reference SSG does it, Kujo does not)

### P1-1. No human-readable date formatting; raw frontmatter string is emitted
- **Severity:** High for visible polish + correctness
- **the reference SSG behavior:** `parse_date()` accepts **16 date formats** and `format_date()` renders display dates as `"%B %d, %Y"` (e.g. `June 18, 2026`). Sorting uses the *parsed* datetime, and the RSS/sitemap use real timestamps.
- **Current behavior:** Kujo passes the **raw** frontmatter string straight through:
  - post template context: `"date": trim(to_string(meta["date"]))` (`build.kujo:2653`, also `:2691`, `:2797`, `:2837`).
  - `post.html:5` renders `{{date}}` verbatim — so a post with `date: 2026-04-12` shows `2026-04-12`, not `April 12, 2026`.
  - Sorting (`sort_posts`, `:1925`) compares the raw string; this only works for already-ISO `YYYY-MM-DD` values and silently mis-sorts anything else (e.g. `04/12/2026`, `April 12, 2026`).
- **Action:**
  1. Add `parse_date(value)` → normalized `{year,month,day}` (or epoch) supporting at least: `YYYY-MM-DD`, `YYYY/MM/DD`, `MM/DD/YYYY`, `Month DD, YYYY`, `DD Month YYYY`, and ISO datetime. Fall back to "min date" for unparseable values (the reference SSG uses `datetime.min`).
  2. Add `format_date(value)` → `"Month DD, YYYY"` and feed it into the `"date"` template field everywhere (4 sites above).
  3. Switch `sort_posts` date comparison to compare parsed dates, not raw strings.
  4. Keep the raw ISO value for `sitemap <lastmod>` (already handled at `:3154`) and RSS `pubDate` (see P1-2).

### P1-2. RSS feed missing `<pubDate>` (per item) and `<lastBuildDate>` (channel)
- **Severity:** Medium (valid RSS readers expect these; affects feed freshness)
- **the reference SSG behavior** (`core.py:2186` `generate_rss_feed`): channel includes `<lastBuildDate>{formatdate()}</lastBuildDate>`; each `<item>` includes `<pubDate>{RFC-822 date}</pubDate>` plus `title`/`link`/`description`/`guid`. Limited to 20 most-recent posts.
- **Current behavior** (`build.kujo:3064`–3088): each `<item>` has only `title`/`link`/`guid`/`description`. No `pubDate`, no channel `lastBuildDate`. 20-item cap and `/feed/index.xml` path already match.
- **Action:**
  1. Add `<lastBuildDate>` to the channel using an RFC-822 formatter (build time).
  2. Add `<pubDate>` per item derived from the post `date` (RFC-822). Requires the date parser from P1-1.
  3. Consider adding `<lastBuildDate>`/`<pubDate>` only when a valid date exists; otherwise omit (don't emit empty tags).

### P1-3. `--fonts` only supports 4 bundled fonts; no Google Fonts download
- **Severity:** Medium (feature is advertised but largely inert)
- **the reference SSG behavior:** `download_google_fonts()` (`core.py:1272`) hits the Google Fonts CSS2 API for **any** family named in `--fonts`, downloads the woff2 files into `output/assets/fonts/`, and generates a real `fonts.css` with `@font-face` for each weight. Default `['Quicksand', 'Open Sans']`.
- **Current behavior:** `generate_fonts_css` (`build.kujo:1684`) recognizes **only** `Bree Serif`, `Inter`, `Quicksand`, `Open Sans` and silently rewrites anything else back to `Bree Serif`/`Inter` (`:1704`–1711). It references pre-bundled `assets/fonts/*.woff2`; there is no download path.
- **Decision required from owner:** Kujo's offline/deterministic build is a deliberate design choice (see `AGENTS.md`/ROADMAP determinism goals). Two viable paths:
  - **(a) Parity:** add an opt-in Google Fonts download (gated like `--download-remote-images`, off by default) that fetches arbitrary families when network use is explicitly allowed.
  - **(b) Documented divergence (recommended for determinism):** keep bundled-only, but make `--fonts` **fail loudly** on an unsupported family instead of silently substituting, and document the supported set in `README.md` + `--help`.
- **Action:** Pick (a) or (b); either way remove the *silent* substitution at `:1704`–1711.

### P1-4. Auto-generated excerpt is not wrapped in `<p>`
- **Severity:** Low (cosmetic / markup consistency)
- **the reference SSG behavior:** `generate_excerpt` (`core.py:889`) returns `f"<p>{excerpt_text}</p>"`; metadata `excerpt:` is run through the markdown filter.
- **Current behavior:** `excerpt_from_markdown` (`build.kujo:566`) returns bare text (first 30 words + `...`), no wrapping element. Word-count logic (30) matches the reference SSG. Listing cards inject it raw into card markup, so visual impact is minor, but feed/description and any `{{excerpt}}` consumer differ.
- **Action:** Decide whether excerpts should carry `<p>`. If matching the reference SSG, wrap the generated excerpt and run metadata `excerpt:` through `markdown_to_html`. (Note: RSS `<description>` should remain *stripped* plain text — the reference SSG strips tags there — so wrap at the listing layer, not in the shared helper, or strip again for RSS.)

---

## P2 — SEO / metadata hardening

### P2-1. `og:image` / `twitter:image` are relative URLs `[BEYOND-PARITY]`
- **Severity:** Medium for real-world social sharing (but **the reference SSG has the same bug**, so not required for strict parity)
- **the reference SSG behavior:** `base.html` emits `content="{{ relative_path }}{{ featured_image }}"` — a *relative* path. Facebook/X/LinkedIn scrapers require **absolute** URLs, so the reference SSG's social images do not resolve when shared.
- **Current behavior:** `render_layout` builds `featured_image := resolve_media_url(…, prefix)` (`build.kujo:1499`) — also relative — and injects it into `og:image`/`twitter:image` (`:1508`–1509).
- **Action (optional upgrade past the reference SSG):** When `site_url` is set, emit **absolute** `og:image`/`twitter:image` by joining `site_url` + the processed `/images/...` path. Keep the relative form only as a fallback when `site_url` is empty. This is a clean way for Kujo to legitimately exceed the reference SSG.

### P2-2. Missing supplementary OG/Twitter tags `[BEYOND-PARITY]`
- **Severity:** Low
- **Neither project emits:** `og:site_name`, `og:locale`, `article:published_time`/`article:author` (for posts), `twitter:site`/`twitter:creator`.
- **Action (optional):** Add `og:site_name` (from `site_title`), `og:locale` (from `lang`), and for posts switch `og:type` to `article` with `article:published_time` from the parsed date. Kujo already plumbs `lang` and author through `render_layout`, so this is low-cost.

### P2-3. No JSON-LD structured data `[BEYOND-PARITY]`
- **Severity:** Low
- **Neither project emits** JSON-LD. Action (optional): add a `WebSite`/`BlogPosting` JSON-LD `<script type="application/ld+json">` block in `layout.html` driven by existing `render_layout` fields.

### P2-4. No favicon link and no RSS autodiscovery `<link>` `[BEYOND-PARITY]`
- **Severity:** Low
- **the reference SSG `base.html`** has neither a `<link rel="icon">` nor `<link rel="alternate" type="application/rss+xml">`. Kujo's `layout.html` also omits both.
- **Action (optional):** Add `<link rel="alternate" type="application/rss+xml" href="{{relative_path}}feed/index.xml">` (only meaningful when aux outputs are generated) and an optional favicon link.

---

## Parity Confirmations (already at/above the reference SSG — do NOT regress)

| Feature | the reference SSG | Kujo | Notes |
|---|---|---|---|
| Pages `/<slug>/`, posts `/<blog_slug>/<slug>/` | ✅ | ✅ | `build.kujo:2566`, `:2684` |
| `custom_url` slug override | ✅ | ✅ | `custom_slug_override` `:352` |
| `draft: true` exclusion | ✅ | ✅ | `:2460`, `:2583`, `:2732` |
| Open Graph (`og:title/description/url/type/image`) | ✅ | ✅ | `layout.html:11–15` |
| Twitter Card (`summary_large_image` + title/desc/image) | ✅ | ✅ | `layout.html:16–19` |
| Canonical URL (frontmatter + computed) | ✅ | ✅ | `render_layout:1479` — Kujo also resolves relative→absolute |
| `keywords` / `author` / `lang` meta | ✅ | ✅ | `layout.html:8,9,2` |
| `seo_title` / `seo_description` fallbacks | ✅ | ✅ (superset: adds explicit `seo_description`) | `render_layout:1466` |
| Featured image: local + remote, WebP, `/images/` | ✅ | ✅ | `process_featured_image_path:1420` |
| Pagination: `/page/N/`, `/blog/page/N/` | ✅ | ✅ | `:2942`, `:3018` |
| Sort modes `date/title/author/order` | ✅ | ✅ | `sort_posts:1925` (stable) |
| `tags` / `categories` ID→name lookup | ✅ | ✅ | `meta_terms:1153`, lookups `:2403` |
| `nav_hide` | ✅ | ✅ | `build_navigation:729` |
| `robots.txt` public/private + Sitemap line | ✅ | ✅ | `:3174` |
| `sitemap.xml` (sitemaps.org schema, absolute URLs) | ✅ | ✅ (superset: adds `changefreq`/`priority`) | `:3090` |
| `llms.txt` (title, posts, pages, custom collections, sitemap ref) | ✅ | ✅ (superset: adds custom collection indexes and items) | `build.kujo` aux-output finalization (Kujo omits the reference SSG's hash IDs — see note) |
| RSS `/feed/index.xml`, 20-item cap | ✅ | ⚠️ partial | missing `pubDate`/`lastBuildDate` — see P1-2 |
| 404 page | ✅ | ✅ | `:3222` |
| Config yml/yaml/json + CLI precedence | ✅ | ✅ | `load_config:2039`, `apply_cli_overrides:2090` |
| `--init yml/yaml/json` scaffold | ✅ | ✅ | `init_project:1990` |
| Asset copy + `--minify` | ✅ | ✅ | `copy_assets:2323`, `minify_assets_recursive:1651` |

**llms.txt note:** the reference SSG appends a synthetic `: ID <hash>` to each entry (`core.py:2359`). Kujo omits it. This is arguably cleaner; treat as an intentional divergence unless strict byte-parity is desired.

---

## Where Kujo SSG EXCEEDS the reference SSG (preserve these)

1. **Custom content collections with listing pages.** the reference SSG has only `posts` + `pages`; its `template:` field merely selects `post-X.html`/`page-X.html`. Kujo auto-discovers `content/<type>/` dirs, generates item routes `/<type>/<slug>/` **and** collection listing pages `/<type>/` (`build.kujo:2703`–2917). This is a major superset (storefronts/tshirts/pants/shorts in the starter).
2. **Per-content-type taxonomy lookups** (`content/<type>-<taxonomy>.yml` overriding global) — `README.md` §Taxonomies; helper `taxonomy_lookup_for:825`. (Note: gated behind the P0-1 fix to actually render.)
3. **Extra CLI flags:** `--download-remote-images` (the reference SSG *always* downloads remote images — Kujo makes it opt-in for deterministic CI), `--no-index`, `--no-aux`. (`apply_cli_overrides:2127`–2141.)
4. **Redirect aliases** — flat `.html` aliases for every clean route (`write_route_alias:1561`).
5. **Sitemap `changefreq` + `priority`** per route class (`:3132`–3149); the reference SSG emits only `loc`+`lastmod`.
6. **Canonical relative→absolute resolution** (`render_layout:1482`).
7. **Deterministic, offline-by-default builds** — the central design goal; do not introduce mandatory network I/O (constrains the P1-3 decision toward option (b)).
8. **Strict CLI failure model** — unknown flags / missing values / invalid enums fail fast (`:2212`).

---

## Quick reference — frontmatter field coverage

| Field | the reference SSG | Kujo | Kujo location |
|---|---|---|---|
| `title` | ✅ | ✅ | parse_frontmatter defaults `:593` |
| `description` | ✅ | ✅ | `:597` |
| `keywords` | ✅ | ✅ | `:598` |
| `seo_title` | ✅ | ✅ | `:599` |
| `seo_description` | ➖ (uses `description`) | ✅ explicit | `:600` |
| `author` | ✅ | ✅ | `:594` |
| `lang` | ✅ | ✅ | `:601` |
| `canonical` | ✅ | ✅ | `:602` |
| `featured_image` | ✅ | ✅ | `:603` |
| `custom_url` | ✅ | ✅ | `:604` |
| `template` | ✅ | ✅ | `:605` |
| `draft` | ✅ | ✅ | `:606` |
| `order` | ✅ | ✅ | `:607` |
| `excerpt` | ✅ | ✅ | `:608` |
| `nav_hide` | ✅ | ✅ | `:609` |
| `tags` | ✅ | ✅ | `:610` |
| `categories` | ✅ | ✅ | `:611` |
| `date` | ✅ (parsed/formatted) | ⚠️ raw passthrough | `:595` — see P1-1 |
| `taxonomies` | ➖ (n/a) | ⚠️ parsed-away | `:612`, wiped `:660` — see P0-1 |
| `category` (singular) | ➖ | ⚠️ default declared, unused | `:596` — dead key, consider removing |

---

## Suggested implementation order

1. **P0-1** taxonomies (restore documented feature; unblocks dead code).
2. **P1-1** date parse/format (also unblocks P1-2 `pubDate`).
3. **P1-2** RSS `pubDate`/`lastBuildDate`.
4. **P0-2** blog-slug nav link.
5. **P1-3** fonts decision (parity download vs. fail-loud + docs).
6. **P1-4** excerpt `<p>` decision.
7. **P2-1** absolute social image URLs (cheap win, exceeds the reference SSG).
8. **P2-2 … P2-4** optional SEO extras.

Each change should land with a generated-output contract assertion (`scripts/test-generated-contract.sh`) and pass `bash scripts/run_ci_checks.sh` before the release gate.
