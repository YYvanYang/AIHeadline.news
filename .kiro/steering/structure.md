# Project Structure

## Root Directory Organization

```
├── _worker.ts              # Cloudflare Worker entry point with GA4 stats API
├── wrangler.jsonc          # Cloudflare Workers configuration
├── hugo.toml               # Hugo site configuration
├── go.mod                  # Hugo theme dependencies
├── package.json            # npm dependencies and scripts
├── tsconfig.json           # TypeScript configuration
├── .editorconfig           # Code formatting rules
├── .prettierrc             # Prettier configuration
└── README.md               # Project documentation
```

## Hugo Site Structure

```
├── archetypes/             # Content templates
│   └── default.md
├── assets/                 # Source assets (CSS, JS)
│   └── css/
├── content/                # Markdown content (auto-generated, DO NOT EDIT)
├── layouts/                # Hugo template overrides
│   ├── _partials/
│   │   ├── custom/
│   │   │   └── footer.html # Custom footer with stats
│   │   └── title-controller.html
│   ├── docs/               # Documentation templates
│   └── *.rss.xml          # RSS feed templates
├── static/                 # Static assets (images, favicons)
│   ├── images/
│   ├── favicon.ico
│   ├── favicon.svg
│   └── apple-touch-icon.png
└── public/                 # Generated site (build output)
```

## Key Directories

### `/content/` - Auto-Generated Content
- **NEVER manually edit files here**
- Content synced from private `ai-news-vault` repository
- Organized by year/month structure
- Contains only `.md` files (HTML/PDF ignored)

### `/layouts/` - Theme Customizations
- `_partials/custom/footer.html`: Custom footer with GA4 stats display
- `docs/`: Documentation page templates
- RSS templates for feed generation

### `/assets/` - Source Assets
- `css/`: Custom CSS files (processed by Hugo)
- Must use `assets/css/` not `static/css/` for Hugo processing

### `/static/` - Static Files
- Images, favicons, and other static assets
- Served directly without processing
- Logo files for light/dark themes

## Build Artifacts

```
├── public/                 # Hugo build output (served by Cloudflare Workers)
├── node_modules/           # npm dependencies
└── .dev.vars              # Local environment variables (not committed)
```

## Configuration Hierarchy

1. **Hugo Configuration**: `hugo.toml`
   - Site metadata, theme settings
   - Menu configuration, search settings
   - GA4 tracking ID, caching rules

2. **Worker Configuration**: `wrangler.jsonc`
   - Assets binding to `public/` directory
   - Environment variables
   - Observability settings

3. **Development Configuration**:
   - `.dev.vars`: Local secrets
   - `tsconfig.json`: TypeScript settings
   - `.editorconfig` + `.prettierrc`: Code style

## Deployment Structure

### GitHub Actions (`.github/workflows/`)
- Single workflow for dual deployment
- Independent builds for GitHub Pages and Cloudflare Workers
- Content synchronization from private vault

### Secrets Management
- GitHub Secrets: `CF_API_TOKEN`, `CF_ACCOUNT_ID`, `PERSONAL_ACCESS_TOKEN`
- Cloudflare Secrets: `GA4_SERVICE_KEY` (encrypted)
- Public Variables: `GA4_PROPERTY_ID` in wrangler.jsonc

## File Naming Conventions

- Configuration files: lowercase with extensions (`.toml`, `.jsonc`, `.json`)
- TypeScript files: underscore prefix for workers (`_worker.ts`)
- Hugo templates: lowercase with hyphens
- Content files: auto-generated, follow vault repository structure
- Asset files: descriptive names with appropriate extensions

## Important Notes

- Never commit `.dev.vars` or any files containing secrets
- Content directory is managed by automation - manual changes will be overwritten
- Use `layouts/_partials/custom/` for theme customizations
- Static assets go in `static/`, processed assets go in `assets/`
- Worker serves Hugo-generated `public/` directory via Assets binding