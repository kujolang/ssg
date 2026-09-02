# Changelog

## Unreleased

### Added
- Added a responsive `sitemap.xsl` browser view so sitemap URLs render once in
  a readable table instead of relying on inconsistent browser XML viewers.
- Added a launch-readiness Spec and deterministic Eval suite for the local SSG release review.
- Added experimental, opt-in static WebMCP v1 generation with a versioned public
  content index, four universal read-only tools, automatic custom-layout
  injection, subpath support, and deterministic full/sharded output.

### Fixed
- Replaced oversized lossless featured-image WebP output with quality-82
  `cwebp` encoding, rejecting any conversion that is not smaller than its
  source.
- Guarded destructive output cleanup against the filesystem root, working directory, and overlapping source trees.
- Corrected calendar-date validation, repeated trailing slashes in `site_url`, empty blog slugs, and invalid shard indexes.
- Replaced delimiter-fragile post index fields with escaped payloads so tabs, newlines, and comma-bearing tags remain intact.
- Corrected numeric ordering for negative `order` values.
- Escaped plain frontmatter template values and normalized `lang` metadata before HTML rendering.

### Documentation
- Aligned the README version badge with the current documented SSG version.
- Defined the hard boundary between static public WebMCP tools and
  authenticated canonical Ability execution.

## 1.0.0 - 2026-08-08

### Added
- `--drafts` flag (and `drafts:` config key) to include `draft: true` content in a
  build for preview/staging workflows. Drafts remain excluded by default.

### Fixed
- Absolute `--output` (and other directory) paths are now built from the
  filesystem root instead of being silently rewritten relative to the working
  directory (`ensure_dir` preserved-root fix).
- `.DS_Store` / `Thumbs.db` OS junk files are no longer copied into the generated
  site by `copy_tree`.
- Google Font download warning no longer gives misleading capability advice; it
  now reflects that the default build runs in trusted mode with network access.

### Documentation
- Corrected the config-file precedence in `README.md` (`kujo-ssg.yml/.yaml/.json`,
  not `SSG.*`) and removed agent-guide text that had leaked into the README.
- Documented the Kujo runtime capability model and the `--untrusted` invocation.
