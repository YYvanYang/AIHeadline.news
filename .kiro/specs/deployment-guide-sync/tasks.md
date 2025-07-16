# Implementation Plan

- [x] 1. Fix critical file reference mismatches














  - Replace all instances of `hugo.yaml` with `hugo.toml` throughout the deployment guide
  - Update script name references from generic names to actual `sync-news.sh`
  - Correct GitHub Actions workflow file references to match actual path
  - _Requirements: 1.1, 2.1, 2.3_



- [x] 2. Synchronize configuration examples with actual project files







  - Update `wrangler.jsonc` example to match actual file content exactly
  - Sync `package.json` script references with actual npm scripts
  - Update `.dev.vars.example` format documentation to match actual file
  - Replace Hugo configuration example

s with content from actual `hugo.toml`
  - _Requirements: 1.2, 2.2, 5.1, 5.2_

- [x] 3. Update GitHub Actions workflow documentation







  - Correct Hugo version references to 0.14
8.1 throughout the document
  - Update all GitHub Actions version references to match actual workflow (checkout@v4, etc.)
  - Document the actual three-job structure (build, deploy-gh-pages, deploy-cf-worker)
  - Update workflow name and trigger docume
ntation to match actual `deploy.yml`
  - _Requirements: 1.3, 4.1, 4.2, 4.3, 6.2_

- [x] 4. Fix local development command references






  - Update npm script references to match actual `package.json` scripts
  - Correct Hugo server command documentation for current configuration
  - Update Wrangler development command syntax to match current version
  - Fix environment variable setup instructions to reference correct files
  - _Requirements: 5.1, 5.3, 5.4, 3.4_

- [x] 5. Correct directory structure and file path documentation
















  - Update directory structure examples to show correct file names and extensions
  - Fix CSS file location references to correctly point to `assets/css/` directory
  - Correct all file paths and directory references throughout the guide
  - Update code structure section to match actual project layout
  - _Requirements: 2.2, 2.4, 1.1_

- [x] 6. Align troubleshooting section with current project setup








  - Update troubleshooting steps to reference actual script names and file paths
  - Revise error scenarios to be relevant to current deployment architecture
  - Update debugging commands to use correct script names from `.github/scripts/`
  - Fix environment variable troubleshooting to match current format
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 7. Update architecture documentation for dual deployment





  - Revise architecture description to accurately reflect independent build processes
  - Update workflow diagram references to match actual job dependencies
  - Correct deployment process explanation for both GitHub Pages and Cloudflare Workers
  - Update deployment artifact documentation for `public/` directory usage
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 8. Validate and test all documented procedures









  - Verify all file references exist in the actual project
  - Validate all configuration examples for syntax correctness
  - Confirm all cross-references and internal links work correctly
  - _Requirements: 1.1, 1.2, 5.3, 5.4_