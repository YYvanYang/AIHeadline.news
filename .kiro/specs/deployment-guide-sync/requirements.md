# Requirements Document

## Introduction

The deployment guide (`docs/deployment-guide.md`) contains outdated information that doesn't match the current project configuration. This creates confusion for developers and deployment issues. We need to synchronize the deployment guide with the actual project files to ensure accuracy and maintainability.

## Requirements

### Requirement 1

**User Story:** As a developer setting up the project, I want the deployment guide to accurately reflect the current configuration files, so that I can successfully deploy without encountering mismatched information.

#### Acceptance Criteria

1. WHEN a developer reads the deployment guide THEN the file references SHALL match actual project file names and formats
2. WHEN the guide shows configuration examples THEN they SHALL exactly match the current `hugo.toml`, `wrangler.jsonc`, and `package.json` contents
3. WHEN the guide references GitHub Actions workflow THEN it SHALL match the actual `.github/workflows/deploy.yml` structure
4. WHEN the guide mentions Hugo version THEN it SHALL match the version specified in the GitHub Actions workflow

### Requirement 2

**User Story:** As a developer following the deployment guide, I want consistent file naming and format references throughout the document, so that I don't get confused by mixed terminology.

#### Acceptance Criteria

1. WHEN the guide references Hugo configuration THEN it SHALL consistently use `hugo.toml` not `hugo.yaml`
2. WHEN the guide shows directory structure THEN it SHALL use correct file extensions and names
3. WHEN the guide references scripts THEN it SHALL use the actual script names from the project
4. WHEN the guide mentions CSS file locations THEN it SHALL correctly reference `assets/css/` directory structure

### Requirement 3

**User Story:** As a developer troubleshooting deployment issues, I want the guide's troubleshooting section to address current project-specific scenarios, so that I can resolve issues efficiently.

#### Acceptance Criteria

1. WHEN the guide provides troubleshooting steps THEN they SHALL reference actual script names and file paths
2. WHEN the guide mentions error scenarios THEN they SHALL be relevant to the current deployment architecture
3. WHEN the guide provides debugging commands THEN they SHALL use the correct script names from `.github/scripts/`
4. WHEN the guide references environment variables THEN they SHALL match the current `wrangler.jsonc` and `.dev.vars.example` format

### Requirement 4

**User Story:** As a project maintainer, I want the deployment guide to accurately document the current GitHub Actions workflow, so that team members understand the actual deployment process.

#### Acceptance Criteria

1. WHEN the guide describes the workflow structure THEN it SHALL match the actual job names and steps in `deploy.yml`
2. WHEN the guide shows workflow configuration THEN it SHALL include the correct Hugo version (0.148.1)
3. WHEN the guide references GitHub Actions versions THEN they SHALL match the actual versions used (checkout@v4, etc.)
4. WHEN the guide describes the sync process THEN it SHALL reference the correct script name `sync-news.sh`

### Requirement 5

**User Story:** As a developer setting up local development, I want the guide's local development section to provide accurate commands and file references, so that I can run the project locally without issues.

#### Acceptance Criteria

1. WHEN the guide provides local development commands THEN they SHALL match the npm scripts in `package.json`
2. WHEN the guide references environment files THEN it SHALL correctly point to `.dev.vars.example`
3. WHEN the guide shows local testing commands THEN they SHALL use correct script paths
4. WHEN the guide mentions Hugo server commands THEN they SHALL be compatible with the current Hugo configuration

### Requirement 6

**User Story:** As a developer reviewing project architecture, I want the deployment guide to accurately reflect the current dual-deployment setup, so that I understand how both GitHub Pages and Cloudflare Workers deployments work.

#### Acceptance Criteria

1. WHEN the guide describes the architecture THEN it SHALL accurately reflect the independent build processes for each deployment target
2. WHEN the guide shows the workflow diagram THEN it SHALL match the actual job dependencies in the GitHub Actions workflow
3. WHEN the guide explains the deployment process THEN it SHALL correctly describe how both deployments use the same source but build independently
4. WHEN the guide references deployment artifacts THEN it SHALL accurately describe the `public/` directory usage for both targets