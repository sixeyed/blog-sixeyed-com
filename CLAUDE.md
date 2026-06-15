# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Jekyll-based blog using the Minimal Mistakes theme, hosted on GitHub Pages. The blog belongs to Elton Stoneman, a freelance IT consultant and trainer.

## Key Commands

### Local Development Setup
```bash
# Install Ruby dependencies (first time setup)
bundle install

# Start local Jekyll server
bundle exec jekyll serve

# Build the site
bundle exec jekyll build
```

The local site runs at http://localhost:4000

### Ruby Environment Setup (macOS)
If Ruby environment needs to be set up:
```bash
brew install chruby ruby-install xz
ruby-install ruby 3.1.3
echo "source $(brew --prefix)/opt/chruby/share/chruby/chruby.sh" >> ~/.zshrc
echo "source $(brew --prefix)/opt/chruby/share/chruby/auto.sh" >> ~/.zshrc
echo "chruby ruby-3.1.3" >> ~/.zshrc
gem install jekyll bundler
```

## Architecture and Structure

### Content Organization
- **_posts/**: Published blog posts in markdown format with YAML front matter
- **_drafts/**: Unpublished draft posts
- **_pages/**: Static pages (about, archives, etc.)
- **content/images/**: Blog post images organized by year/month
- **_includes/**: Reusable HTML components
- **_layouts/**: Page layout templates
- **_sass/**: Sass stylesheets

### Blog Post Format
Posts use Jekyll's naming convention: `YYYY-MM-DD-title.markdown`

Required front matter:
```yaml
---
title: 'Post Title'
date: 'YYYY-MM-DD HH:MM:SS'
tags:
- tag1
- tag2
description: Brief description
header:
  teaser: /content/images/path/to/image.png
---
```

### Theme Configuration
- Uses `mmistakes/minimal-mistakes` remote theme
- Minimal Mistakes skin: "mint"
- Configured for GitHub Pages deployment
- Includes social media links, author profile, and comment system via Utterances

### Key Features
- Pagination (5 posts per page)
- Search functionality
- SEO optimization
- RSS feed at `/rss`
- Tag and category archives
- Table of contents for posts
- Copy code button enabled
- Social sharing buttons

## Development Notes

### Image Handling
- Images stored in `/content/images/YYYY/MM/` structure
- Reference images in posts using absolute paths: `/content/images/2024/07/image.png`
- Include teaser images in front matter for social media previews

### Deployment
The blog uses a dual-environment deployment strategy with GitHub Actions:

**Production Environment:**
- Triggered by pushes to `master` branch
- Deploys to https://blog.sixeyed.com
- Uses `_config.yml` configuration

**Staging Environment:**
- Triggered by pushes to `develop` or `feature/*` branches
- Deploys to https://staging.blog.sixeyed.com
- Uses `_config.yml` + `_config_staging.yml` configuration
- Deploys to `gh-pages-staging` branch in same repository

**Testing Commands:**
```bash
# Test production build locally
bundle exec jekyll serve

# Test staging build locally
bundle exec jekyll serve --config _config.yml,_config_staging.yml
```

See `DEPLOYMENT.md` for detailed branching strategy and setup instructions.

## Link Management

The blog uses a redirect system for managing external links, especially for tracking and updating affiliate links.

### How It Works
1. Define redirects in `_data/redirects.yml`
2. Run `./generate-redirects.ps1` to create redirect pages
3. Use short URLs like `/l/ps-istio` in your posts
4. Commit both the YAML file and generated pages

### Adding New Redirects
Edit `_data/redirects.yml`:
```yaml
# Set the default URL for redirects without specific URLs
default_url: https://app.pluralsight.com/profile/author/elton-stoneman

- slug: my-link         # becomes /l/my-link
  url: https://...      # destination URL (optional - uses default_url if empty)
  description: ...      # optional, for reference
```

Then run: `./generate-redirects.ps1`

**Default URL Fallback**: If a redirect has no `url` specified (or empty `url:`), it will automatically redirect to the `default_url`. This is useful for dead links or courses that are no longer available.

### Benefits
- Update links in one place when URLs change
- Track link usage if needed
- Shorter, cleaner URLs in posts
- No dependency on external URL shorteners

## UI/UX Customizations

### Theme Override Approach
The blog uses the Minimal Mistakes theme. Customizations are made through:
- Custom CSS in `assets/css/main.scss` (imports theme, then adds overrides)
- Custom layouts in `_layouts/` (override theme defaults)
- Custom includes in `_includes/` (override theme components)

### Key UI Customizations

**Homepage Layout (60/40 split):**
- Post excerpts take 60% width, hero images 40%
- Custom CSS in `.list__item` using flexbox
- Hero images: 200px height with `object-fit: cover`
- Mobile responsive: stacks vertically on smaller screens

**Individual Post Hero Images:**
- Custom `_layouts/single.html` adds hero image after header
- Image appears inside article content, not at page top
- CSS class `.page__hero` with max-height constraints

**Content Images:**
- 90% max-width, left-aligned
- Preserves small images at natural size
- Border radius and subtle shadow for polish

**Mobile Sidebar (Critical fixes for <1024px):**
- Theme default hides social links on mobile - override with `display: block !important`
- Use CSS table display to maintain avatar + social links side-by-side
- Hide books section and detailed course listings
- Author bio updated to "15x Microsoft MVP"
- Key CSS pattern:
  ```scss
  .sidebar .author__avatar {
    display: table !important;
  }
  .sidebar .author__urls-wrapper {
    display: table-cell !important;
  }
  ```

**Typography Standards:**
- Base font: 18px (desktop), 16px (mobile)
- Homepage excerpts: Changed from 0.75em to 1rem to match posts
- Line height: 1.6-1.7 for readability
- Consistent across all pages

**Hidden Elements:**
- Top ad bar: `display: none` (code preserved)
- Books section on mobile: Hidden to save space
- Course details on mobile: Only show compact link

### CSS Organization
- Media query breakpoint: 1023px (not 768px) to catch tablet issues
- Use `!important` sparingly but necessary to override theme defaults
- Maintain theme variables where possible
- Comment liberally for future maintenance

## SEO and Discoverability

This section reflects search practice as of 2026. The short version: **write genuinely useful, experience-led content for humans and structure it so both Google and AI assistants can understand and cite it.** Keyword placement and density are not the game any more — topical relevance, search intent, demonstrated experience, and machine-readable structure are.

### The mental model (read this first)

Two audiences now find these posts:

1. **Search engines** — Google ranks on topical relevance, search intent, and E-E-A-T (Experience, Expertise, Authoritativeness, Trust). Since the Helpful Content updates (2022-24), keyword-stuffed or over-optimized content is actively *demoted*. BERT/MUM understand context, so you don't need to repeat exact keywords — you need to cover the topic well and match what the reader actually wants.
2. **AI assistants** — Google AI Overviews, ChatGPT, Perplexity, and Claude increasingly answer questions by summarizing and citing pages. This is Generative Engine Optimization (GEO / AEO). To get cited, content must be *quotable*: self-contained claims, clear definitions, comparison tables, stats with sources, and direct Q&A.

Optimize for both by being clear, concrete, accurate, and well-structured. There is no separate "SEO version" of a good technical post — the same qualities serve readers, Google, and LLMs.

### E-E-A-T: lead with experience (Elton's biggest asset)

Google added "Experience" to E-A-T in late 2022, and it's the single strongest lever this blog has. First-hand, been-there content outranks generic explainers.

- Keep the first-person experience markers — "I was brought in to...", "in a client project...", "here's what actually happens in production". These are an SEO asset, not just voice.
- Show real artifacts: actual commands, real output, screenshots, repos. Demonstrated experience > described experience.
- Date-stamp time-sensitive claims ("at the time of writing", versions, dates) so freshness is legible.
- The author profile and bio matter for authoritativeness — keep them current.

### Search intent and topic coverage (replaces "keyword placement")

- Decide what question/intent a post serves, and make sure it actually answers it — completely, in one place.
- Use natural language a reader would actually search or ask. Cover the subtopics and related questions a curious reader would have next; that breadth is what signals topical authority.
- Don't force keywords into headings or the first 100 words. Write the clearest heading for the reader; relevance follows naturally. Avoid the old "inject the keyword into every H2" tactic — it now reads as over-optimization.
- Brand/product names: use the canonical spelling in prose (e.g. `Rocket.Chat`, `Node.js`). Search engines tokenize on the dot, so the canonical form already matches the spaced query ("rocket chat"). Get the exact spaced phrase into the meta description once, where it's low-stakes.

### Titles and meta descriptions

- **Title**: aim for roughly 60 characters / ~600px so it doesn't truncate in results, but Google measures pixel width and rewrites titles often, so treat this as a guide, not a rule. Lead with the hook or the clearest framing of the benefit; front-load what matters since the tail may be cut. The on-page `title:` and the URL slug are independent — a catchy title can pair with a keyword-rich slug.
- **Description**: ~150-160 characters. It is **not a ranking factor** and Google rewrites most descriptions — write it for click-through (a clear, specific promise), not for rank. Still required in frontmatter for social/OG cards.
- **Slug**: the URL comes from the filename (permalink is `/:title/`). Use a concise, descriptive, hyphenated slug with the core search phrase. This is where keyword intent lives, not the headline.

### Structure for humans and machines

- **Headings**: proper H2/H3 hierarchy, never skip levels. Each section should be a self-contained, skimmable unit — that's also what AI assistants extract and cite.
- **Answer-first blocks**: for posts that target a question, put a direct, quotable answer near the top (a TL;DR / Quickstart works well), then expand. Self-contained paragraphs get cited; buried answers don't.
- **Tables, lists, and definitions**: comparison tables and clear inline definitions are highly citable by LLMs and useful for readers. Use them where they fit naturally.
- **FAQ sections**: a short FAQ targets long-tail and conversational queries and is ideal GEO fodder. Consider one for posts likely to be asked about in natural language.
- **Internal linking**: link to related posts naturally in context (and between posts in a series). This spreads relevance and keeps readers on site.
- **External links**: use the `/l/` redirect system for affiliate/tracked links (see Link Management). External links open in a new tab automatically.

### Structured data

- `{% seo %}` (jekyll-seo-tag) already emits the core Article JSON-LD, OpenGraph, and Twitter card metadata — make sure `title`, `description`, and `header.teaser` are set and it handles the rest.
- For posts with a genuine FAQ section, FAQPage schema can earn rich results / AI citations. Add it only when the Q&A is real (Google penalizes fake FAQ markup).

### Images, performance, and Core Web Vitals

- **Alt text**: required on every content image, via the Jekyll attribute syntax. Write it to describe the image for a screen-reader user; that genuinely-descriptive text is what helps accessibility *and* image search:
  ```markdown
  ![Description of image](/path/to/image.png)
  {: alt="Detailed, specific description of what the image shows"}
  ```
- **File names**: descriptive and hyphenated (e.g. `workflow-tempo-trace.png`).
- **Right-size images**: store images at sensible display dimensions (~1200-1600px wide is plenty for content/hero), not full camera/screenshot resolution. Oversized images hurt **LCP** (Largest Contentful Paint) and waste bandwidth. Resize before committing.
- **Core Web Vitals** are a ranking/page-experience factor: **LCP** (load speed), **CLS** (layout shift — give images dimensions so the page doesn't jump), and **INP** (interaction responsiveness; replaced FID in March 2024). The theme handles most of this, but image sizing is the one thing post authors control directly.
- **Hero/teaser**: set `header.teaser` in frontmatter; it drives the in-article hero and the social-share preview.

## Writing Style and Content Guidelines

### Writing Style
**Tone and Voice:**
- Conversational yet authoritative - write like an experienced mentor sharing practical knowledge
- Informal but professional - use contractions, direct address ("you can", "you'll")
- Educational focus with confidence - demonstrate expertise without being condescending
- Assume intermediate technical knowledge level

**Structure and Formatting:**
- Clear hierarchical organization with H2 (##) and H3 (###) headings
- Lead with practical examples, then explain underlying concepts
- Step-by-step progression from basic to advanced topics
- Include preview/summary sections early in posts
- Use Jekyll notice blocks: `{: .notice--info}` for important information

**Technical Approach:**
- Heavy use of Docker, Kubernetes, .NET, and cloud technology examples
- Abundant code blocks with proper syntax highlighting
- Always include complete working examples, not just snippets
- Focus on production-ready solutions with real-world constraints
- Address cross-platform scenarios (Windows, Linux, hybrid)

**Unique Elements:**
- Personal experience markers: "I was brought in to...", "In a client project..."
- Honest assessments that point out limitations and trade-offs
- Smooth promotional integration of Pluralsight courses and books
- "Here's what actually happens in production" perspective
- Multi-part series structure with clear part numbering

### Content Patterns
**Topics and Audience:**
- Primary focus: Docker, Kubernetes, containerization, .NET, cloud technologies
- Target audience: Intermediate to advanced practitioners and professional developers
- DevOps oriented: CI/CD, deployment patterns, infrastructure as code
- Enterprise scenarios with scaling and production considerations

**Post Structure:**
- Comprehensive coverage (2000-4000+ words typically)
- Prerequisites section listing required software/knowledge
- Step-by-step progression with verification steps
- Troubleshooting awareness and common issue solutions
- Forward-looking conclusions with "next steps"

**Formatting Standards:**
- Images stored in `/content/images/YYYY/MM/` structure
- Strategic image placement with teaser headers for social media
- Reference images using absolute paths: `/content/images/2024/07/image.png`
- Include teaser images in front matter
- Use code blocks with syntax highlighting for all technical examples

## Recent Content Optimizations (2025-07)

### Custom Styling for Text Wrapping
**Problem Solved**: Code blocks containing long text prompts were causing horizontal scrolling, making them hard to read on mobile.

**Solution Implemented**: Created a custom `.prompt-wrap` CSS class in `assets/css/main.scss`:
```css
.prompt-wrap {
  background-color: #f8f8f8;
  border: 1px solid #e1e4e8;
  border-radius: 6px;
  padding: 16px;
  margin: 1em 0;
  font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, Courier, monospace;
  font-size: 14px;
  line-height: 1.45;
  white-space: pre-wrap;
  word-wrap: break-word;
  overflow-wrap: break-word;
}
```

**Usage**: Wrap long text content (like AI prompts or conversational examples) in `<div class="prompt-wrap">content</div>` instead of markdown code blocks to ensure proper text wrapping.

### Content Enhancement Workflow
**SEO Optimization Process**:
1. **Alt Text**: Add genuinely descriptive alt text to all images — describe what the image shows for a screen-reader user. Be specific, not padded to a character count.
2. **Meta Descriptions**: Update to match content changes (conductor → director metaphor updates)
3. **Spelling Check**: Run comprehensive spell check, common issues found:
   - "knowledgable" → "knowledgeable"
   - "prduct" → "product" 
   - "Clkaude" → "Claude"
   - Possessive "it's" vs "its"
4. **Headings**: Write the clearest heading for the reader. Do NOT inject keywords into every H2 — that's an over-optimization signal now (see SEO and Discoverability). A descriptive heading that matches the section's intent is enough. Only reword a heading if the original is genuinely unclear, not to fit a keyword.
5. **Internal Linking**: Use Jekyll permalink format without dates: `/post-slug/` not `/2025/07/10/post-slug/`

### Content Publishing Workflow
**Draft to Publication Process**:
1. Content creation and revisions in `_drafts/filename.markdown`
2. SEO optimization (alt text, meta descriptions, spell check)
3. Final review and date update in frontmatter
4. Move to `_posts/YYYY-MM-DD-filename.markdown` for publication
5. Update CLAUDE.md with any new learnings or patterns

### AI-Related Content Best Practices
**For Claude Code/AI Development Posts**:
- Use emojis strategically at the beginning of sentences for visual interest
- Include practical examples from real projects
- Balance technical depth with accessibility
- Add FAQ sections for long-tail keyword targeting
- Link to official documentation (Anthropic, Claude Code docs)
- Include both free and paid tier information for tools
- Use "director" metaphor over "conductor" for AI development management

## External Links and User Experience (January 2025)

### Link Behavior Configuration
**Problem**: External links and redirects opened in the same tab, causing readers to navigate away from blog posts.

**Solution Implemented**: Added automatic new-tab opening for external links and redirects:

**CSS Visual Indicators** (`assets/css/main.scss`):
```css
/* External links and redirects visual indicator */
.page__content a[href^="http"]:not([href*="blog.sixeyed.com"]),
.page__content a[href^="https"]:not([href*="blog.sixeyed.com"]),
.page__content a[href^="/l/"] {
  &::after {
    content: " ↗";
    font-size: 0.8em;
    opacity: 0.6;
    margin-left: 0.2em;
  }
}
```

**JavaScript Implementation** (`assets/js/external-links.js`):
```javascript
document.addEventListener('DOMContentLoaded', function() {
  const externalLinks = document.querySelectorAll('.page__content a[href^="http"]:not([href*="blog.sixeyed.com"]), .page__content a[href^="https"]:not([href*="blog.sixeyed.com"]), .page__content a[href^="/l/"]');
  
  externalLinks.forEach(link => {
    link.setAttribute('target', '_blank');
    link.setAttribute('rel', 'noopener noreferrer');
  });
});
```

**Configuration** (`_config.yml`):
```yaml
footer_scripts:
  - /assets/js/external-links.js
```

### Link Categories
**Opens in New Tab**:
- External HTTP/HTTPS links (Claude Code, GitHub, etc.)
- `/l/` redirect links (Pluralsight, book links, etc.)
- Shows ↗ visual indicator

**Stays in Same Tab**:
- Internal blog post links
- Links within blog.sixeyed.com domain

### Benefits
- Improved user experience: readers don't lose their place
- Better engagement: blog posts stay open
- Clear visual feedback: users know when they're leaving the site
- Security: `noopener noreferrer` prevents potential security issues

## Hero Image Optimization (January 2025)

### Hero Image Display Fix
**Problem**: Hero images in individual posts were being cropped vertically with `object-fit: cover`, forcing images to fill container horizontally.

**Solution**: Updated CSS to preserve aspect ratio and only resize when necessary:

```scss
.page__hero-img {
  max-width: 100%;
  height: auto;
  max-height: 350px;
  object-fit: contain;  // Changed from 'cover'
  display: block;
  margin: 0 auto;
}

.page__hero {
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  text-align: center;  // Center smaller images
  // Removed: overflow: hidden (was causing cropping)
}
```

### Image Behavior
- **Small Images**: Display at natural size, centered
- **Large Images**: Scale down proportionally to fit container
- **Aspect Ratio**: Always preserved, never cropped
- **Responsive**: Adjusts gracefully on mobile devices

This ensures hero images look as intended without unwanted cropping.