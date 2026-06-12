# SSG

Local static-site generation showcase for Kujo projects, built around a single entrypoint: [build.kujo](build.kujo).

`SSG` is designed for teams that want deterministic builds, straightforward template overrides, and a transparent content pipeline. Content, templates, assets, metadata, feeds, and validation stay visible in the repository instead of disappearing behind framework abstractions.

Prioritize copyable examples over tests: examples should model the most token-efficient idioms we want agents to imitate.

Exclude generated/bulk paths from the main sweep unless the task explicitly targets them; document the search exclusions you used.

It fits the Clarity / Context / Control story by keeping content models, routes, feeds, and validation predictable, surfacing generated artifacts and metadata as context, and making builds and release checks local and reviewable.

## Highlights

- Builds Markdown pages, blog posts, and custom content collections
- Renders SEO metadata from frontmatter, including canonical, Open Graph, and Twitter tags
- Generates paginated home/blog listings with configurable sort order
- Produces `sitemap.xml`, `robots.txt`, `feed/index.xml`, `llms.txt`, and `404.html`
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

- Kujo CLI available on your `PATH`, or a local Kujo binary path exposed through `KUJO_BIN`

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

If Kujo is not on your `PATH`, set one of these before running the gates:

- `KUJO_BIN=/path/to/kujo`
- `KUJO_RUNTIME_DIR=/path/to/kujo-runtime-repo`

## Project Layout

Core directories in a standard project:

- `content/`: Markdown source content and taxonomy lookup files
- `templates/`: page, listing, and item template overrides
- `assets/`: static assets copied or processed into output
- `output/`: generated site artifacts; do not edit by hand
- `scripts/`: validation and release automation

## Configuration

`build.kujo` loads config from the first file found in this order:

1. `SSG.yml`
2. `SSG.yaml`
3. `SSG.json`

CLI flags always override config values.

Example `SSG.yml`:

```yaml
site_url: https://example.com
site_title: My Site
site_tagline: Built with Kujo SSG

output: output
content: content
templates: templates
assets: assets

blog_slug: blog
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
- `--fonts <comma,list>`: local font generation configuration
- `--site-title <text>`
- `--site-tagline <text>`
- `--site-url <url>`
- `--robots <public|private>`
- `--llms <public|private>`
- `--watch`: reserved, currently not implemented
- `--minify`: emit minified CSS/JS assets
- `--download-remote-images`: mirror remote `featured_image` URLs into output
- `--blog-slug <slug>`: blog route base
- `--init <yml|yaml|json>`: scaffold starter config
- `--no-index`: skip index and blog listing pages
- `--no-aux`: skip feed, sitemap, robots, and llms outputs
- `--version`
- `--help`

Unknown flags, missing option values, malformed YAML/JSON config, invalid booleans, and invalid enum values fail fast with a nonzero exit.

## Content Model

- `content/pages/*.md`: standalone pages
- `content/posts/*.md`: blog posts
- `content/<type>/*.md`: custom content collection items

Routes are generated like this:

- Pages: `/<slug>/`
- Posts: `/<blog_slug>/<slug>/`
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

`draft: true` excludes content from generated public outputs.

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

- `SSG.yml`
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
- Processed assets are written to `output/images/` with deterministic names
- Raster images are converted to WebP when possible
- If conversion fails, Kujo SSG falls back to the original extension
- Remote images are only downloaded when `download_remote_images: true` or `--download-remote-images` is enabled

For deterministic CI and release builds, leave remote downloads disabled unless the build explicitly needs mirrored remote assets.

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

`sitemap.xml` uses the sitemaps.org schema with absolute URLs. Generated HTML includes canonical, Open Graph, Twitter, and standard metadata derived from frontmatter and config.

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
