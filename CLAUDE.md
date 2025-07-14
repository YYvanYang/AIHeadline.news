# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Critical Rules

### Content Directory Management
**NEVER manually create or edit files in the `content/` directory** - it is entirely auto-generated:
- `content/_index.md` - Homepage with month cards
- `content/YYYY-MM/_index.md` - Month index pages
- `content/YYYY-MM/YYYY-MM-DD.md` - Daily summaries

All content files are in `.gitignore` and must NOT be committed.

## Essential Commands

```bash
# Local development setup
bash .github/scripts/test-sync.sh  # Sync content from ai-news-vault for testing
hugo server                        # Start dev server (http://localhost:1313)
hugo --gc --minify                # Build for production

# Testing before commit
npm run dev                       # Test Worker locally
# Run these commands to ensure code quality
```

### Local Development Notes
- Use `.github/scripts/test-sync.sh` to pull latest content from ai-news-vault repository
- This script is required for local testing but should NOT be run in production
- The script will clone/update the source repository and regenerate all content

## Project Overview

**AI News Hugo Site** - Automated daily AI news aggregation site
- **Content Source**: Private `YYvanYang/ai-news-vault` repository
- **Sync Schedule**: Daily at UTC 0:00 via GitHub Actions
- **Deployment**: Cloudflare Workers (生产) + GitHub Pages (备份)
- **RSS Feed**: Available at `/index.xml` with full content

## Architecture

### Worker Implementation Notes
- GA4 authentication uses JWT self-signing with WebCrypto API
- Access tokens are cached using Cloudflare Cache API (55 min TTL)
- No external npm packages required for GA4 integration
- CORS is restricted to production domain and localhost
- GA4_PROPERTY_ID is defined in wrangler.jsonc (vars section)
- GA4_SERVICE_KEY must be set separately as a secret

### Key Files
- `hugo.yaml` - Site configuration
- `wrangler.jsonc` - Cloudflare Workers configuration
- `_worker.ts` - Worker script with GA4 stats API (using WebCrypto JWT)
- `.github/workflows/deploy.yml` - GitHub Actions workflow
- `.github/scripts/sync-news.sh` - Content sync script
- `.github/scripts/test-sync.sh` - Local development script for content sync
- `.github/templates/` - Templates for dynamic content generation
- `layouts/partials/custom/footer.html` - Custom footer with stats display

### Content Flow
1. GitHub Actions triggers daily
2. Syncs markdown files from private vault
3. Generates homepage and month indexes dynamically
4. Deploys to both Cloudflare Workers and GitHub Pages

### Required Secrets
- `PERSONAL_ACCESS_TOKEN` - GitHub token for private repo access
- `CF_API_TOKEN` - Cloudflare API token for Worker deployment
- `CF_ACCOUNT_ID` - Cloudflare account ID

### Cloudflare Worker Configuration
- `GA4_SERVICE_KEY` - Must be configured as encrypted variable via Dashboard/CLI (not in wrangler.jsonc)
- `GA4_PROPERTY_ID` - Configured in wrangler.jsonc vars section (no Dashboard setup needed)

## Best Practices

### Template Management
- Use template files in `.github/templates/` for complex content
- Use simple placeholders like `{{VARIABLE}}`
- Keep logic in shell scripts, not YAML

### CSS and Styling
- Place custom CSS in `assets/css/custom.css` (NOT in `static/css/`)
- Follow Hextra theme conventions for footer customization:
  - Use `layouts/partials/custom/footer.html` for custom footer content
  - Disable default footer in `hugo.yaml` with `displayCopyright: false` and `displayPoweredBy: false`
- Keep CSS minimal and focused on specific customizations
- Always test responsive design on multiple screen sizes

### GitHub Actions Security (2025)
1. **Use v4+ versions**: All actions must use v4 or higher (required after Jan 30, 2025)
2. **Specific runners**: Use `ubuntu-24.04` not `ubuntu-latest`
3. **Script security**: Always use `set -euo pipefail`
4. **Dependabot**: Configure for automatic Action updates
5. **Cloudflare deployment**: Use independent build approach to avoid artifact issues

### Development Workflow
1. Run `bash .github/scripts/test-sync.sh` to sync latest content
2. Test locally with `hugo server`
3. Never edit files in `content/` directory
4. Commit only source files, not generated content
5. Let GitHub Actions handle deployment

### Common Issues & Solutions
- **Missing sidebar navigation**: The sidebar only shows on screens ≥768px due to custom CSS
- **Content not updating**: Run `.github/scripts/test-sync.sh` to pull latest from ai-news-vault
- **Hugo module errors**: Ensure Go is in PATH: `export PATH="$HOME/go/bin:$PATH"`
- **CSS styles not applying**: 
  - CSS files must be in `assets/css/` directory, NOT `static/css/`
  - Hugo processes files in `assets/` for optimization, while `static/` files are just copied
  - Check browser developer tools for CSS conflicts or overrides
- **Page content offset issues**: 
  - Avoid modifying article margins or layout-related CSS
  - Hextra theme handles responsive layout automatically
  - Test CSS changes on different screen sizes
- **Cloudflare Worker errors**:
  - "Could not resolve": Check network connectivity and API endpoints
  - "CLOUDFLARE_API_TOKEN not found": Set both in `with` and `env` for wrangler-action
  - "public directory does not exist": Use independent build in deploy-cf-worker job
- **Wrangler configuration**: Use `wrangler.jsonc` format (Cloudflare recommended)

### Hugo Template Title Duplication Issue Resolution

**Problem Description**: Monthly pages (e.g., `/2025-07/`) showed duplicate titles, displaying both "2025-07" and "2025年07月"

**Root Cause**: 
- Different page types use different Hugo templates:
  - `_index.md` (month indexes) → `layouts/docs/list.html`
  - Single page files → `layouts/docs/single.html`
- Initially only modified `single.html`, but monthly index pages actually use `list.html`

**Solution**:
1. **Create shared partial template**: `layouts/_partials/title-controller.html`
   ```go
   {{ partial "title-controller.html" (dict "context" . "pageType" $pageType) }}
   ```
2. **Intelligent page type detection**:
   - `"daily"`: Daily briefing pages (`\d{4}-\d{2}/\d{4}-\d{2}-\d{2}\.md$`)
   - `"monthIndex"`: Monthly index pages (`\d{4}-\d{2}/_index\.md$`)
   - `"normal"`: Regular pages
3. **Unified template logic**: Ensure `single.html` and `list.html` use consistent conditional logic

**Key Lessons Learned**:
- ✅ **Identify page type first**: Confirm which Hugo template the current page uses (list vs single)
- ✅ **Consult official documentation**: Use Context7 to query Hugo best practices, learn about partial templates
- ✅ **Prioritize code reuse**: Create shared partials to avoid duplicate logic and improve maintainability
- ✅ **Follow proper test workflow**: Must re-run `test-sync.sh` after template modifications to regenerate content
- ✅ **Standardize logic patterns**: Conditional checks for same functionality should maintain consistent order and style
- ❌ **Never manually edit content directory**: Auto-generated files in `content/` should never be manually modified

**Debugging Techniques**:
- Use `curl` commands to test page HTML structure: `curl -s http://localhost:1313/2025-07/ | grep "<h1"`
- Add debug comments to confirm template usage: `<!-- DEBUG: list.html template -->`
- Monitor Hugo server logs for template recompilation messages