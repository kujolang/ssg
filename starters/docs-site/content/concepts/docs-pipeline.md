---
title: Documentation Pipeline
description: How authored docs, generated reference, search, and static output fit together.
custom_url: docs-pipeline
template: docs
section: Concepts
order: 10
audience: maintainer
difficulty: intermediate
status: stable
version: current
previous: /guides/update-generated-reference/
next: /operations/release-docs/
tags: [architecture, pipeline]
---

# Documentation Pipeline

The docs site is built from two sources: human-authored Markdown and generated DocGen reference Markdown.

## Source Inputs

- Authored pages live under `content/`.
- Generated reference lives under `content/reference/generated/`.
- Templates live under `templates/`.
- Local assets live under `assets/`.

## Determinism

Stable source content should produce stable routes, search records, generated Markdown, and validation results. Generated files are tracked by manifest so removed symbols can remove stale pages without touching hand-authored content.

## Local-first Operation

The default path uses local files and a local cache. Network access is only needed when you intentionally use remote assets or external link validation.
