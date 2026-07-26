---
title: Release Documentation
description: Validate and publish a documentation update.
custom_url: release-docs
template: docs
section: Operations
order: 10
audience: maintainer
difficulty: intermediate
status: stable
version: current
previous: /concepts/docs-pipeline/
next: /examples/minimal-docs-site/
tags: [release, validation]
---

# Release Documentation

Run the same checks locally that CI will run.

## Validate

```bash
bash scripts/run_ci_checks.sh
```

## Review

Review generated content, search index changes, and rendered output before publishing.

## Rollback

Because output is static and source-controlled inputs are deterministic, rollback should use the previous known-good commit or deployment artifact.
