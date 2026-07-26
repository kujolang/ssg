---
title: Five-minute Quickstart
description: Build confidence with a short complete path.
custom_url: five-minute-quickstart
template: docs
section: Tutorials
order: 10
audience: beginner
difficulty: beginner
estimated_time: 5 minutes
status: stable
version: current
prerequisites:
  - Local checkout
  - Kujo CLI on PATH
previous: /overview/
next: /guides/update-generated-reference/
tags: [quickstart]
---

# Five-minute Quickstart

This tutorial should produce a visible, verifiable result quickly.

## Run A Build

```bash
kujo run ./build.kujo -- --site-url https://docs.example.com
```

## Verify The Output

```bash
bash scripts/validate-generated-output.sh output
```

## Expected Result

The `output/` directory contains static HTML, metadata, sitemap, robots, feed, and `llms.txt` artifacts.
