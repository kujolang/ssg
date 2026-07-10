#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO_BIN="${KUJO_BIN:-kujo}"
BUILD_SCRIPT="$REPO_ROOT/build.kujo"

source "$REPO_ROOT/scripts/test_helpers.sh"

assert_substring_order() {
	local target_path="$1"
	local first_text="$2"
	local second_text="$3"
	local first_pos
	local second_pos
	first_pos="$(grep -boF "$first_text" "$target_path" | head -n 1 | cut -d: -f1 || true)"
	second_pos="$(grep -boF "$second_text" "$target_path" | head -n 1 | cut -d: -f1 || true)"
	if [[ -z "$first_pos" || -z "$second_pos" || "$first_pos" -ge "$second_pos" ]]; then
		echo "FAIL expected text order in $target_path: '$first_text' before '$second_text'"
		exit 1
	fi
}

main() {
	local temp_dir
	temp_dir="$(mktemp -d)"
	trap "rm -rf '$temp_dir'" EXIT

	setup_temp_site "$REPO_ROOT" "$temp_dir"
	pushd "$temp_dir" >/dev/null
	rm -rf content
	cp -R "$REPO_ROOT/content" content

	cat > content/pages/metadata-proof.md <<'EOF'
---
title: Metadata Proof
custom_url: metadata-proof
description: Metadata proof description.
seo_title: Metadata Proof Title
seo_description: Metadata proof social description.
canonical: https://docs.example.test/metadata-proof/
featured_image: /assets/images/post-welcome-kujo-ssg.jpg
---

# Metadata Proof

This page exists only to prove metadata rendering and slug handling.
EOF

	cat > content/pages/draft-page.md <<'EOF'
---
title: Draft Page
draft: true
---

# Draft Page

This draft page must not be published.
EOF

	cat > content/posts/draft-post.md <<'EOF'
---
title: Draft Post
date: 2026-05-28
draft: true
---

# Draft Post

This draft post must not be published.
EOF

	run_expect_success "$KUJO_BIN" run "$BUILD_SCRIPT" -- --site-url https://example.com
	assert_output_contains "Build complete"
	assert_path_exists output/index.html
	assert_path_exists output/blog/index.html
	assert_path_exists output/about/index.html
	assert_path_exists output/about.html
	assert_path_exists output/contact/index.html
	assert_path_exists output/getting-started/index.html
	assert_path_exists output/blog/welcome-to-kujo-ssg/index.html
	assert_path_exists output/metadata-proof/index.html
	assert_path_exists output/storefronts/north-austin/index.html
	assert_path_exists output/storefronts/index.html
	assert_path_exists output/tshirts/index.html
	assert_path_exists output/404.html
	assert_path_exists output/page/2/index.html
	assert_path_exists output/blog/page/2/index.html
	assert_path_exists output/feed/index.xml
	assert_path_exists output/sitemap.xml
	assert_path_exists output/robots.txt
	assert_path_exists output/llms.txt
	assert_path_missing output/page/3
	assert_path_missing output/blog/page/3
	assert_file_contains output/about.html '<meta http-equiv="refresh" content="0; url=/about/">'
	assert_file_contains output/404.html 'id="main-content"'
	assert_file_contains output/robots.txt 'Allow: /'
	assert_file_contains output/llms.txt 'https://example.com/sitemap.xml'
	assert_file_contains output/sitemap.xml '<loc>https://example.com/about/</loc>'
	assert_file_contains output/sitemap.xml '<loc>https://example.com/blog/welcome-to-kujo-ssg/</loc>'
	assert_file_contains output/feed/index.xml '<rss version="2.0">'
	assert_file_contains output/about/index.html '<title>About the Kujo SSG Starter | Kujo SSG Starter Site</title>'
	assert_file_contains output/about/index.html '<link rel="canonical" href="https://example.com/about/">'
	assert_file_contains output/blog/welcome-to-kujo-ssg/index.html '<meta property="og:title" content="Welcome to Kujo SSG">'
	assert_file_contains output/blog/welcome-to-kujo-ssg/index.html '<meta name="twitter:card" content="summary_large_image">'
	assert_file_contains output/blog/welcome-to-kujo-ssg/index.html '<meta property="og:type" content="article">'
	assert_file_contains output/blog/welcome-to-kujo-ssg/index.html '<meta property="article:published_time" content="2026-05-07">'
	assert_file_contains output/blog/welcome-to-kujo-ssg/index.html '<span class="date">May 7, 2026</span>'
	assert_file_contains output/blog/welcome-to-kujo-ssg/index.html '<script type="application/ld+json">'
	assert_file_contains output/feed/index.xml '<pubDate>'
	assert_file_contains output/feed/index.xml '<lastBuildDate>'
	assert_file_contains output/storefronts/north-austin/index.html 'taxonomy-label">District'
	assert_path_exists output/favicon.svg
	assert_file_contains output/metadata-proof/index.html '<title>Metadata Proof Title | Kujo SSG Starter Site</title>'
	assert_file_contains output/metadata-proof/index.html '<meta name="description" content="Metadata proof social description.">'
	assert_file_contains output/metadata-proof/index.html '<link rel="canonical" href="https://docs.example.test/metadata-proof/">'
	assert_file_contains output/metadata-proof/index.html '<meta property="og:url" content="https://docs.example.test/metadata-proof/">'
	assert_file_contains output/metadata-proof/index.html '<meta name="twitter:image" content="https://example.com/images/post-welcome-kujo-ssg-'
	assert_file_contains output/metadata-proof/index.html '<meta property="og:image" content="https://example.com/images/post-welcome-kujo-ssg-'
	assert_file_contains output/metadata-proof/index.html '<meta property="og:site_name" content="Kujo SSG Starter Site">'
	assert_path_missing output/draft-page
	assert_path_missing output/draft-post
	assert_file_contains output/llms.txt 'https://example.com/metadata-proof/'
	assert_file_contains output/llms.txt 'https://example.com/blog/welcome-to-kujo-ssg/'
	if grep -Fq 'draft-post' output/sitemap.xml || grep -Fq 'draft-post' output/llms.txt || grep -Fq 'Draft Post' output/blog/index.html; then
		echo 'Draft content leaked into indexed outputs'
		exit 1
	fi

	run_expect_success "$KUJO_BIN" run "$BUILD_SCRIPT" -- --site-url https://example.com --no-aux
	assert_output_contains "Build complete"
	assert_path_exists output/about/index.html
	assert_path_missing output/robots.txt
	assert_path_missing output/llms.txt
	assert_path_missing output/sitemap.xml
	assert_path_missing output/feed/index.xml

	run_expect_success "$KUJO_BIN" run "$BUILD_SCRIPT" -- --site-url https://example.com --no-index
	assert_output_contains "Build complete"
	assert_path_exists output/about/index.html
	assert_path_missing output/index.html
	assert_path_missing output/blog/index.html
	assert_path_missing output/page/2/index.html
	assert_path_missing output/blog/page/2/index.html

	run_expect_success "$KUJO_BIN" run "$BUILD_SCRIPT" -- --site-url https://example.com --posts-at-root
	assert_output_contains "Build complete"
	assert_path_exists output/welcome-to-kujo-ssg/index.html
	assert_path_exists output/blog/index.html
	assert_path_missing output/blog/welcome-to-kujo-ssg/index.html
	assert_file_contains output/llms.txt 'https://example.com/welcome-to-kujo-ssg/'

	cp -R content content-sort-date
	rm -rf content-sort-date/posts
	mkdir -p content-sort-date/posts
	cat > content-sort-date/posts/a-tie-first.md <<'EOF'
---
title: Tie First
date: 2026-05-10
author: 1
categories: [1]
tags: [1]
excerpt: Tie excerpt first
---

# Tie First
EOF
	cat > content-sort-date/posts/b-tie-second.md <<'EOF'
---
title: Tie Second
date: 2026-05-10
author: 1
categories: [1]
tags: [1]
excerpt: Tie excerpt second
---

# Tie Second
EOF
	cat > content-sort-date/posts/z-newest-anchor.md <<'EOF'
---
title: Newest Anchor
date: 2026-05-11
author: 1
categories: [1]
tags: [1]
excerpt: Newest excerpt
---

# Newest Anchor
EOF
	run_expect_success "$KUJO_BIN" run "$BUILD_SCRIPT" -- --content content-sort-date --output output-sort-date --posts-per-page 20 --site-url https://example.com --sort-by date
	assert_output_contains "Build complete"
	assert_substring_order output-sort-date/blog/index.html 'Newest Anchor' 'Tie First'
	assert_substring_order output-sort-date/blog/index.html 'Tie First' 'Tie Second'

	cp -R content content-sort-title
	rm -rf content-sort-title/posts
	mkdir -p content-sort-title/posts
	cat > content-sort-title/posts/a-title-tie-first.md <<'EOF'
---
title: Same Title
date: 2026-05-10
author: 1
categories: [1]
tags: [1]
excerpt: Title tie first excerpt
---

# Same Title First
EOF
	cat > content-sort-title/posts/b-title-tie-second.md <<'EOF'
---
title: Same Title
date: 2026-05-10
author: 1
categories: [1]
tags: [1]
excerpt: Title tie second excerpt
---

# Same Title Second
EOF
	cat > content-sort-title/posts/z-title-anchor.md <<'EOF'
---
title: Aardvark Title
date: 2026-05-10
author: 1
categories: [1]
tags: [1]
excerpt: Title anchor excerpt
---

# Aardvark Title
EOF
	run_expect_success "$KUJO_BIN" run "$BUILD_SCRIPT" -- --content content-sort-title --output output-sort-title --posts-per-page 20 --site-url https://example.com --sort-by title
	assert_output_contains "Build complete"
	assert_substring_order output-sort-title/blog/index.html 'Aardvark Title' 'Title tie first excerpt'
	assert_substring_order output-sort-title/blog/index.html 'Title tie first excerpt' 'Title tie second excerpt'

	cp -R content content-sort-author
	rm -rf content-sort-author/posts
	mkdir -p content-sort-author/posts
	cat > content-sort-author/posts/a-author-tie-first.md <<'EOF'
---
title: Author Tie First
date: 2026-05-10
author: 2
categories: [1]
tags: [1]
excerpt: Author tie first excerpt
---

# Author Tie First
EOF
	cat > content-sort-author/posts/b-author-tie-second.md <<'EOF'
---
title: Author Tie Second
date: 2026-05-10
author: 2
categories: [1]
tags: [1]
excerpt: Author tie second excerpt
---

# Author Tie Second
EOF
	cat > content-sort-author/posts/z-author-anchor.md <<'EOF'
---
title: Author Anchor
date: 2026-05-10
author: 1
categories: [1]
tags: [1]
excerpt: Author anchor excerpt
---

# Author Anchor
EOF
	run_expect_success "$KUJO_BIN" run "$BUILD_SCRIPT" -- --content content-sort-author --output output-sort-author --posts-per-page 20 --site-url https://example.com --sort-by author
	assert_output_contains "Build complete"
	assert_substring_order output-sort-author/blog/index.html 'Author Anchor' 'Author Tie First'
	assert_substring_order output-sort-author/blog/index.html 'Author Tie First' 'Author Tie Second'

	cp -R content content-sort-order
	rm -rf content-sort-order/posts
	mkdir -p content-sort-order/posts
	cat > content-sort-order/posts/a-order-tie-first.md <<'EOF'
---
title: Order Tie First
date: 2026-05-10
author: 1
categories: [1]
tags: [1]
order: 10
excerpt: Order tie first excerpt
---

# Order Tie First
EOF
	cat > content-sort-order/posts/b-order-tie-second.md <<'EOF'
---
title: Order Tie Second
date: 2026-05-10
author: 1
categories: [1]
tags: [1]
order: 10
excerpt: Order tie second excerpt
---

# Order Tie Second
EOF
	cat > content-sort-order/posts/z-order-anchor.md <<'EOF'
---
title: Order Anchor
date: 2026-05-10
author: 1
categories: [1]
tags: [1]
order: 1
excerpt: Order anchor excerpt
---

# Order Anchor
EOF
	cat > content-sort-order/posts/zz-order-missing.md <<'EOF'
---
title: Order Missing
date: 2026-05-10
author: 1
categories: [1]
tags: [1]
excerpt: Order missing excerpt
---

# Order Missing
EOF
	run_expect_success "$KUJO_BIN" run "$BUILD_SCRIPT" -- --content content-sort-order --output output-sort-order --posts-per-page 20 --site-url https://example.com --sort-by order
	assert_output_contains "Build complete"
	assert_substring_order output-sort-order/blog/index.html 'Order Anchor' 'Order Tie First'
	assert_substring_order output-sort-order/blog/index.html 'Order Tie First' 'Order Tie Second'
	assert_substring_order output-sort-order/blog/index.html 'Order Tie Second' 'Order Missing'

	popd >/dev/null
	echo "Generated output contract tests passed"
}

main "$@"
