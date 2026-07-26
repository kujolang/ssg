---
title: Update Generated Reference
description: Refresh DocGen content and rebuild the docs site deterministically.
custom_url: update-generated-reference
template: docs
section: Guides
order: 10
audience: maintainer
difficulty: intermediate
status: stable
version: current
prerequisites:
  - Target repository checkout
  - Kujo CLI on PATH
previous: /tutorials/five-minute-quickstart/
next: /concepts/docs-pipeline/
tags: [docgen, bridge, automation]
---

# Update Generated Reference

Run the update command from the docs site root.

## Command

```bash
kujo run scripts/update_docs.kujo -- \
	--target-repo /path/to/repo \
	--site-url https://docs.example.com \
	--source-link-template 'https://github.com/org/repo/blob/main/{path}#L{line}' \
	--strict
```

## What Changes

The command runs DocGen with an incremental cache, converts the payload into reviewable Markdown, refreshes the local search index, builds the site, and validates generated output.

## Review

Review generated Markdown diffs before publishing. Hand-authored narrative pages should stay outside `content/reference/generated/`.
