# Kujo SSG Docs Template

This starter turns Kujo SSG into a reusable documentation site package. It is local-first, deterministic, and designed to pair with `scripts/docgen_ssg_bridge.kujo`.

## Update Generated Reference

From this starter root:

```bash
kujo run scripts/update_docs.kujo -- \
	--target-repo /path/to/repo \
	--site-url https://docs.example.com \
	--source-link-template 'https://github.com/org/repo/blob/main/{path}#L{line}' \
	--strict
```

The update command writes generated reference Markdown under `content/reference/generated`, refreshes `assets/js/docs-search-index.json`, builds the SSG output, and validates it.

## Customize

- `kujo-ssg.yml`: site URL, title, output paths, sorting, and privacy controls.
- `content/`: authored tutorials, guides, concepts, examples, and operations material.
- `content/reference/generated/`: generated DocGen content. Review diffs, but do not hand-edit generated files.
- `templates/`: layout and docs page templates.
- `assets/css/style.css`: the docs theme tokens and component styles.
- `assets/js/docs.js`: local search and copy buttons.

## Content Metadata

Use frontmatter to keep pages structured:

```yaml
title: Install Kujo
description: Install the Kujo CLI and verify the runtime.
custom_url: install
template: docs
section: Start Here
order: 20
audience: beginner
difficulty: beginner
status: stable
version: current
prerequisites:
  - Terminal access
  - Supported operating system
previous: /overview/
next: /quickstart/
tags: [install, cli]
```

Generated reference pages use the same template contract so authored and generated docs feel like one product.
