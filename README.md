# SSG

[![Version](https://img.shields.io/badge/version-1.0.0-black)](https://github.com/kujolang/ssg)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)
[![built with Kujo](https://img.shields.io/badge/built%20with-Kujo-white.svg)](https://github.com/kujolang/kujo)

Local static-site generation showcase for Kujo projects, built around a single entrypoint: [build.kujo](build.kujo).

`SSG` is designed for teams that want deterministic builds, straightforward template overrides, and a transparent content pipeline. Content, templates, assets, metadata, feeds, and validation stay visible in the repository instead of disappearing behind framework abstractions.

It fits the Clarity / Context / Control story by keeping content models, routes, feeds, and validation predictable, surfacing generated artifacts and metadata as context, and making builds and release checks local and reviewable.

## Highlights

- Builds Markdown pages, blog posts, and custom content collections (with per-type taxonomies)
- Renders full SEO metadata from frontmatter: canonical, Open Graph, Twitter Card, JSON-LD, absolute social images, and `article:*` tags
- Parses and formats dates, with RFC-822 RSS `pubDate`/`lastBuildDate` and sitemap `lastmod`
- Generates paginated home/blog listings with configurable sort order
- Produces `sitemap.xml`, `robots.txt`, `feed/index.xml`, `llms.txt`, `404.html`, and `favicon.svg`
- Downloads and self-hosts any Google Font as cached `woff2`, with an offline bundled fallback
- Supports local and remote featured-image processing with deterministic output names
- Validates CLI behavior, config precedence, generated output, and release-gate checks with dedicated project scripts
- Ships with starter content, templates, assets, and lookup files for a real first-run build

## Why SSG

- Deterministic content routing for pages, posts, and custom collections
- Config-file support for `yml`, `yaml`, and `json` with tested CLI override precedence
- Simple override model based on files you can inspect and replace directly
- Release workflow backed by contract tests and generated-output validation
- Suitable for teams that want an auditable static-site pipeline rather than a black-box generator

## How It Fits

- CMS demonstrates a server-first content application.
- CRUD API Showcase demonstrates a smaller API pattern.
- SSG demonstrates static publishing and docs-site generation.
- Lens and ShipCheck can help review and gate generated results.

## What This Repo Is Not

- Not a production-certified docs platform
- Not an automatic deployment or hosted publishing service
- Not a guarantee of SEO, accessibility, or performance outcomes
- Not a replacement for manual review
- Not a hosted-service or paid-API dependency by default

## Requirements

- Kujo CLI available on your `PATH`

## Runtime Capabilities

Kujo gates host effects (filesystem, network, processes) behind explicit runtime
capabilities. The default `kujo run ./build.kujo` runs in **trusted mode**, where
every capability — including outbound network for font and remote-image downloads
— is granted. No extra flags are needed for normal builds.

If you build in hardened **`--untrusted`** mode, capabilities are denied by
default and you opt in per effect. A full build needs at least:

```bash
kujo run --untrusted \
  --allow-fs-read --allow-fs-write --allow-fs-delete \
  --allow-clock --allow-net-client \
  ./build.kujo -- --site-url https://example.com --fonts "Roboto,Lato"
```

(`--allow-net-client` is only needed when the build downloads Google Fonts or
remote images; `--allow-fs-*` and `--allow-clock` are needed for every build.)

Note: passing any single `--allow-*` flag switches the runtime out of trusted
mode, so you must then enumerate every capability the build uses (filesystem
included). For most users the default trusted path is the right choice.

## Quick Start

Build the bundled starter site from the project root:

```bash
kujo run ./build.kujo -- --site-url https://example.com
```

Expected final lines include:

```text
Build complete
  Output directory: output
```

Preview the generated site locally on `127.0.0.1`:

```bash
kujo serve output --port 8080
```

### Parallel builds for large sites

For large sites, render post shards across CPU cores with the parallel
orchestrator (mirrors how multiprocessing SSGs scale). Output is byte-identical
to the single-process build (sitemap URL order aside):

```bash
# bash scripts/build-parallel.sh <shards|auto> <concurrency|auto> [build args...]
# `auto` sizes shards (~120 posts each) and concurrency (= CPU cores) for you:
bash scripts/build-parallel.sh auto auto \
  --content content --output output --site-url https://example.com --posts-per-page 25
```

Use many small shards (~120–300 posts each) and a concurrency near your core
count. Internally this drives `build.kujo`'s `--phase setup|posts|finalize` and
`--shard i --shards N` flags; the default `kujo run ./build.kujo` remains a normal
single-process build. (The per-page render cost is interpreter-bound, so the
speedup is real but memory-bandwidth-limited — see
[docs/performance-findings.md](docs/performance-findings.md).)

Scaffold a starter config file when bootstrapping a new project:

```bash
kujo run ./build.kujo -- --init yml
```

For a typical release workflow:

```bash
kujo run ./build.kujo -- --site-url https://example.com
bash scripts/validate-generated-output.sh output
bash scripts/run_ci_checks.sh
```

The validated execution path for development, CI, and release checks is the standard Kujo VM path: `kujo run ./build.kujo -- ...`

## Validation And Release

Validate generated output after a build:

```bash
bash scripts/validate-generated-output.sh output
```

Run the local CI gate:

```bash
bash scripts/run_ci_checks.sh
```

Run the release gate:

```bash
bash scripts/run_release_gate.sh
```

The release gate checks changelog/version alignment first, then runs the full CI gate on the same standard Kujo VM path used for normal builds.

If Kujo is not on your `PATH`, set a non-default runtime before running the gates:

- `KUJO_RUNTIME_DIR=/path/to/local-kujo-source-checkout`

## Project Layout

Core directories in a standard project:

- `content/`: Markdown source content and taxonomy lookup files
- `templates/`: page, listing, and item template overrides
- `assets/`: static assets copied or processed into output
- `output/`: generated site artifacts; do not edit by hand
- `scripts/`: validation and release automation

## Configuration

`build.kujo` loads config from the first file found in this order:

1. `kujo-ssg.yml`
2. `kujo-ssg.yaml`
3. `kujo-ssg.json`

CLI flags always override config values.

Example `kujo-ssg.yml`:

```yaml
site_url: https://example.com
site_title: My Site
site_tagline: Built with Kujo SSG

output: output
content: content
templates: templates
assets: assets

blog_slug: blog
posts_at_root: false
posts_per_page: 5
sort_by: date

robots: public
llms: public
watch: false
minify: false
download_remote_images: false
no_index: false
no_aux: false
```

Example one-off override build:

```bash
kujo run ./build.kujo -- \
	--site-url https://staging.example.com \
	--output preview-output \
	--blog-slug updates \
	--posts-per-page 1 \
	--sort-by date
```

That keeps file-based defaults in place while applying the CLI values for the current run only.

## CLI Flags

- `--output <dir>`: output directory
- `--content <dir>`: content directory
- `--templates <dir>`: templates directory
- `--assets <dir>`: assets directory
- `--posts-per-page <n>`: listing pagination size
- `--sort-by <date|title|author|order>`: blog listing sort mode
- `--fonts <comma,list>`: heading/body font families (first = headings, second = body). Bundled families (`Bree Serif`, `Inter`, `Quicksand`, `Open Sans`) render offline; any other family is downloaded from Google Fonts as `woff2` and cached under `.cache/fonts/`. See [Fonts](#fonts).
- `--site-title <text>`
- `--site-tagline <text>`
- `--site-url <url>`
- `--robots <public|private>`
- `--llms <public|private>`
- `--watch`: reserved, currently not implemented
- `--minify`: emit minified CSS/JS assets
- `--download-remote-images`: mirror remote `featured_image` URLs into output (needs outbound network — see [Runtime Capabilities](#runtime-capabilities))
- `--drafts`: include `draft: true` content in the build (preview/staging workflow); omitted by default
- `--blog-slug <slug>`: blog route base
- `--posts-at-root`: keep post permalinks at `/<slug>/` while retaining the blog listing under `/<blog_slug>/`
- `--init <yml|yaml|json>`: scaffold starter config
- `--no-index`: skip index and blog listing pages
- `--no-aux`: skip feed, sitemap, robots, and llms outputs
- `--no-aliases`: skip flat `.html` redirect aliases (emit clean `dir/index.html` only); halves per-page write I/O on large sites
- `--version`
- `--help`

Unknown flags, missing option values, malformed YAML/JSON config, invalid booleans, and invalid enum values fail fast with a nonzero exit.

## Content Model

- `content/pages/*.md`: standalone pages
- `content/posts/*.md`: blog posts
- `content/<type>/*.md`: custom content collection items

Routes are generated like this:

- Pages: `/<slug>/`
- Posts: `/<blog_slug>/<slug>/` by default, or `/<slug>/` with `posts_at_root: true`
- Custom collections: `/<type>/<slug>/`
- Collection listing pages: `/<type>/`

Frontmatter keys supported across pages, posts, and custom types:

- `title`
- `description`
- `keywords`
- `seo_title`
- `seo_description`
- `author`
- `lang`
- `canonical`
- `featured_image`
- `custom_url`
- `template`
- `draft`
- `order`
- `excerpt`
- `nav_hide`
- `tags`
- `categories`
- `taxonomies`

Frontmatter opens and closes only with a line containing `---`. Literal `---`
text in a quoted value or Markdown body is preserved. An unclosed or malformed
frontmatter block is left out of metadata processing and produces a warning with
the source file and delimiter line.

`draft: true` excludes content from generated public outputs. Pass `--drafts` to
include draft content in a build for preview/staging without publishing it by
default.

## Taxonomies And Lookups

Lookup files live in `content/`.

- Global lookup: `content/<taxonomy>.yml`
- Content-type-specific lookup: `content/<content_type>-<taxonomy>.yml`

Resolution precedence:

1. Content-type-specific lookup
2. Global lookup

That lets you reuse shared taxonomies globally while still overriding them for a single content type when needed.

Example:

```yaml
# content/storefronts-location.yml
1:
	name: Austin
2:
	name: Denver
```

```yaml
---
title: Main Street Storefront
location: [1, 2]
taxonomies:
	district: downtown
tags: [flagship, retail]
---
```

Top-level shorthand such as `location: [1, 2]` is lookup-aware. `taxonomies:` is the right place for free-text custom taxonomy values.

## Starter Project

The repository starter content is meant to be immediately useful, not empty.

- Pages: `about`, `contact`, `getting-started`
- Posts: multiple sample blog entries
- Custom content types: storefronts, tshirts, pants, shorts
- Lookup files: authors, categories, tags, color, and a type-specific storefront location lookup
- Template overrides: dedicated home, blog, storefront listing, storefront item, and custom post templates

Recommended first customization points:

- `kujo-ssg.yml`
- `templates/`
- `content/`

For most teams, the fastest path to a working site is:

1. Set `site_url`, `site_title`, and `site_tagline`
2. Replace starter content in `content/`
3. Override the templates you actually need in `templates/`
4. Run the validation and release gates before publishing changes

## Featured Images

`featured_image` supports both local and remote sources.

- Local paths are resolved relative to the content file, `content/`, and `assets/`
- Each existing local candidate is canonicalized and must remain under the
  content root, assets root, or the content file's directory; traversal and
  symlink escapes are rejected with a source-file warning
- Processed assets are written to `output/images/` with deterministic names
- Raster images are converted to WebP when possible
- If conversion fails, Kujo SSG falls back to the original extension
- Remote images are only downloaded when `download_remote_images: true` or `--download-remote-images` is enabled

For deterministic CI and release builds, leave remote downloads disabled unless the build explicitly needs mirrored remote assets.

An unresolved or rejected local image is omitted rather than emitted as a raw
path in generated HTML.

## Fonts

`--fonts "Headings,Body"` (or `fonts:` in config) selects the heading and body
type families. There are two provisioning paths:

- **Bundled families** — `Bree Serif`, `Inter`, `Quicksand`, `Open Sans` ship as
  local `woff2` and render fully offline with zero network access. These are the
  defaults (`Bree Serif` headings, `Inter` body), so a stock build is always
  deterministic and offline.
- **Any Google Font** — request any family by name (e.g. `--fonts "Roboto,Lato"`)
  and Kujo SSG fetches the `latin` `woff2` files for weights 400/700 directly
  from Google Fonts, writes them to `output/assets/fonts/`, generates the
  matching `@font-face` rules in `output/assets/css/fonts.css`, and caches the
  downloads under `.cache/fonts/` (git-ignored). Subsequent builds reuse the
  cache and stay offline.

Google Font downloads need outbound network access. The default
`kujo run ./build.kujo` path runs in trusted mode (all runtime capabilities
granted), so downloads work with no extra flags. Only if you run the build in
hardened `--untrusted` mode do you need to opt in — see
[Runtime Capabilities](#runtime-capabilities).

If a requested Google Font cannot be provisioned (no network, missing capability
in `--untrusted` mode, or an unknown family name), the build prints a warning and
falls back to the bundled default without failing — so CI never breaks on a font
typo.

This keeps the project decentralized: you are never locked into a small curated
font list, but the default path remains fully self-contained.

## SEO And Social Metadata

Every generated page includes, derived from frontmatter and config:

- `<title>`, `description`, `keywords`, `author`, and `lang`
- Canonical URL (explicit `canonical:` or computed from `site_url` + route)
- Open Graph: `og:title`, `og:description`, `og:url`, `og:type`
  (`article` for posts/items, `website` otherwise), `og:site_name`, `og:locale`,
  and an **absolute** `og:image`
- Twitter Card: `summary_large_image` with title, description, and an
  **absolute** `twitter:image`
- `article:published_time` / `article:author` for posts and collection items
- JSON-LD structured data (`BlogPosting` for articles, `WebSite` otherwise)
- An SVG favicon (`/favicon.svg`) and RSS autodiscovery `<link>`

Social image URLs are emitted as absolute URLs (using `site_url`) so link
unfurlers on Facebook, X/Twitter, LinkedIn, and Slack resolve them correctly.

Post and collection-item `date:` frontmatter is parsed (ISO `YYYY-MM-DD`,
`YYYY/MM/DD`, `MM/DD/YYYY`, `Month DD, YYYY`, and `DD Month YYYY` are all
accepted), rendered for display as `Month DD, YYYY`, used for stable date
sorting, and emitted as RFC-822 `pubDate`/`lastBuildDate` in the RSS feed and
`YYYY-MM-DD` `lastmod` in the sitemap.

## Template Overrides

Built-in override points include:

- `templates/page-home.html`: home listing (`/`, `/page/N/`)
- `templates/page-blog.html`: blog listing (`/blog/`, `/blog/page/N/`)
- `templates/page-<blog_slug>.html`: listing override when blog slug is not `blog`
- `templates/page-<content_type>.html`: custom collection listing override
- `templates/post-<template>.html`: per-post or per-item template override

Listing templates receive placeholders including:

- `{{title}}`, `{{description}}`
- `{{cards}}`, `{{items}}`, `{{posts}}`, `{{posts_html}}`
- `{{pagination}}`
- `{{page_number}}`, `{{total_pages}}`
- `{{blog_slug}}`, `{{content_type}}`

## Build Output

Primary outputs include:

- `output/index.html`
- `output/page/N/index.html`
- `output/blog/index.html`
- `output/blog/page/N/index.html`
- `output/feed/index.xml`
- `output/sitemap.xml`
- `output/robots.txt`
- `output/llms.txt`
- `output/404.html`
- `output/favicon.svg`

`sitemap.xml` uses the sitemaps.org schema with absolute URLs, per-route
`changefreq`/`priority`, and `lastmod` from post dates. The RSS feed carries
`pubDate`/`lastBuildDate`. Generated HTML includes canonical, Open Graph,
Twitter Card, JSON-LD, and standard metadata derived from frontmatter and config
(see [SEO And Social Metadata](#seo-and-social-metadata)).

Public `llms.txt` output includes Posts and Pages sections followed by one
section per built custom collection. Each collection section links to its index
and every non-draft item using absolute URLs; collection sections are ordered by
content directory name, and items follow the configured `sort_by` order.

## Troubleshooting

- If Kujo is not on your `PATH`, set `KUJO_BIN` or `KUJO_RUNTIME_DIR` before running builds or gates.
- If a build succeeds but output validation fails, rerun `bash scripts/run_ci_checks.sh` to recheck CLI contracts, generated-output contracts, the VM build, and HTML validation in one path.
- If you only need content pages and item routes, use `--no-aux` to skip feed/sitemap/robots/llms generation.
- If you want item routes without listing pages, use `--no-index`.

## Engineering Workflow

- Main pipeline entrypoint: [build.kujo](build.kujo)
- Agent/contributor guide: [AGENTS.md](AGENTS.md)
- Main contract tests: `scripts/test-cli-contract.sh`, `scripts/test-generated-contract.sh`
- Primary validation path: `bash scripts/run_ci_checks.sh`
- Release gate: `bash scripts/run_release_gate.sh`
