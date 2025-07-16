# Technology Stack

## Core Technologies

- **Static Site Generator**: Hugo (Go-based)
- **Theme**: Hextra (Hugo module)
- **Runtime**: Cloudflare Workers with Assets binding
- **Language**: TypeScript for Worker logic
- **Package Manager**: npm
- **Deployment**: Wrangler CLI

## Key Dependencies

- `@cloudflare/workers-types`: TypeScript definitions for Workers
- `wrangler`: Cloudflare Workers CLI and deployment tool
- Hugo Hextra theme via Go modules

## Build System

### Local Development
```bash
# Sync latest content from private vault
bash .github/scripts/test-sync.sh

# Start Hugo development server
hugo server

# Build static site
hugo --gc --minify

# Start Cloudflare Workers development (after npm ci)
npm run dev
# or
wrangler dev --assets ./public
```

### Production Build
- Hugo builds static site to `public/` directory
- Wrangler deploys Worker with Assets binding to `public/`
- GitHub Actions handles automated deployment

## Configuration Files

- `hugo.toml`: Hugo site configuration with Hextra theme settings
- `wrangler.jsonc`: Cloudflare Workers configuration with Assets binding
- `tsconfig.json`: TypeScript configuration for Worker
- `package.json`: npm scripts and dependencies
- `go.mod`: Hugo theme module dependencies

## Code Style

- **Indentation**: Tabs (configured in .editorconfig)
- **Line endings**: LF
- **Prettier**: 140 character width, single quotes, semicolons, tabs
- **TypeScript**: Strict mode enabled with comprehensive type checking

## Environment Variables

### Development (.dev.vars)
- `GA4_SERVICE_KEY`: Google Analytics service account JSON
- `GA4_PROPERTY_ID`: GA4 property ID (also in wrangler.jsonc)

### Production (Cloudflare Secrets)
- `GA4_SERVICE_KEY`: Encrypted secret via Wrangler CLI or Dashboard
- `GA4_PROPERTY_ID`: Public variable in wrangler.jsonc

## Architecture Notes

- Uses Web Standards APIs (WebCrypto) instead of Node.js compatibility
- JWT self-signing for GA4 authentication without external dependencies
- Assets binding serves Hugo-generated static files
- CORS configured for localhost development and production domain