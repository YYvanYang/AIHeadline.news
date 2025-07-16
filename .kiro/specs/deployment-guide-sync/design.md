# Design Document

## Overview

This design outlines the systematic approach to synchronize the deployment guide with the current project configuration. The solution involves identifying specific discrepancies, creating a comprehensive update strategy, and implementing changes that ensure long-term accuracy.

## Architecture

### Current State Analysis

The deployment guide contains several categories of outdated information:

1. **File Reference Mismatches**: References to `hugo.yaml` instead of `hugo.toml`
2. **Script Name Inconsistencies**: References to non-existent script names
3. **Configuration Discrepancies**: Examples that don't match actual file contents
4. **Workflow Documentation Gaps**: Missing details about the actual GitHub Actions implementation

### Update Strategy

The synchronization will follow a structured approach:

1. **Direct File Content Synchronization**: Update configuration examples to match actual files
2. **Reference Correction**: Fix all file name and path references
3. **Workflow Documentation Update**: Align GitHub Actions documentation with actual implementation
4. **Consistency Verification**: Ensure terminology and naming conventions are uniform

## Components and Interfaces

### Component 1: Configuration Examples Sync

**Purpose**: Ensure all configuration examples in the guide match actual project files

**Implementation**:
- Replace `hugo.yaml` references with `hugo.toml`
- Update `wrangler.jsonc` examples to match actual content
- Sync `package.json` script references
- Update `.dev.vars.example` format documentation

### Component 2: File Path and Script Reference Correction

**Purpose**: Fix all file paths, script names, and directory references

**Implementation**:
- Correct script references from generic names to actual `sync-news.sh`
- Update directory structure documentation
- Fix CSS file location references (`assets/css/` vs `static/css/`)
- Correct GitHub Actions workflow file references

### Component 3: GitHub Actions Workflow Documentation

**Purpose**: Align workflow documentation with actual implementation

**Implementation**:
- Update Hugo version references to 0.148.1
- Correct GitHub Actions version references (checkout@v4, etc.)
- Document the actual job structure and dependencies
- Update workflow name and trigger documentation

### Component 4: Local Development Command Sync

**Purpose**: Ensure local development instructions match actual project setup

**Implementation**:
- Update npm script references to match `package.json`
- Correct Hugo server command documentation
- Update Wrangler development command syntax
- Sync environment variable setup instructions

## Data Models

### Discrepancy Categories

```typescript
interface DocumentationDiscrepancy {
  category: 'file-reference' | 'configuration' | 'workflow' | 'command';
  location: string; // Section in deployment guide
  current: string; // What the guide currently says
  correct: string; // What it should say
  impact: 'high' | 'medium' | 'low';
}
```

### Update Operations

```typescript
interface UpdateOperation {
  type: 'replace' | 'add' | 'remove';
  section: string;
  oldContent?: string;
  newContent: string;
  validation: string; // How to verify the change is correct
}
```

## Error Handling

### Validation Strategy

1. **Cross-Reference Validation**: Every file reference in the guide must correspond to an actual project file
2. **Configuration Accuracy**: All configuration examples must be syntactically valid and match actual files
3. **Command Verification**: All commands mentioned in the guide must be executable in the project context
4. **Link Integrity**: All internal references and links must be valid

### Error Prevention

1. **Template-Based Updates**: Use actual file contents as templates for documentation examples
2. **Automated Validation**: Implement checks to ensure documentation stays in sync
3. **Version Pinning**: Document specific versions to prevent drift
4. **Regular Review Process**: Establish process for keeping documentation current

## Testing Strategy

### Validation Tests

1. **File Reference Tests**:
   - Verify all mentioned files exist in the project
   - Confirm all paths are correct and accessible
   - Validate all script names match actual files

2. **Configuration Accuracy Tests**:
   - Parse and validate all configuration examples
   - Compare examples with actual file contents
   - Verify syntax correctness for all code blocks

3. **Command Execution Tests**:
   - Test all local development commands
   - Verify all npm scripts exist and work
   - Validate all deployment commands

4. **Workflow Documentation Tests**:
   - Compare documented workflow with actual `.github/workflows/deploy.yml`
   - Verify all job names and steps are accurate
   - Confirm all environment variables and secrets are documented correctly

### Integration Testing

1. **End-to-End Documentation Flow**:
   - Follow the complete deployment guide from start to finish
   - Verify each step works as documented
   - Test both local development and deployment processes

2. **Cross-Platform Validation**:
   - Ensure commands work on different operating systems
   - Verify file paths use correct separators
   - Test environment variable setup across platforms

## Implementation Approach

### Phase 1: Immediate Corrections
- Fix critical file name mismatches (`hugo.yaml` → `hugo.toml`)
- Update script name references
- Correct major configuration discrepancies

### Phase 2: Content Synchronization
- Sync all configuration examples with actual files
- Update GitHub Actions workflow documentation
- Align local development instructions

### Phase 3: Validation and Testing
- Implement validation checks
- Test all documented procedures
- Verify cross-references and links

### Phase 4: Consistency Review
- Ensure uniform terminology throughout
- Standardize formatting and structure
- Add missing details and clarifications

## Specific Updates Required

### Critical File Reference Fixes

1. **Hugo Configuration**: Change all `hugo.yaml` references to `hugo.toml`
2. **Script Names**: Update `test-sync.sh` references to `sync-news.sh`
3. **Workflow File**: Ensure correct reference to `.github/workflows/deploy.yml`

### Configuration Content Updates

1. **Hugo Version**: Update to 0.148.1 throughout the document
2. **GitHub Actions Versions**: Ensure all action versions match actual workflow
3. **Package Scripts**: Sync npm script documentation with actual `package.json`

### Workflow Documentation Enhancements

1. **Job Structure**: Document the actual three-job structure (build, deploy-gh-pages, deploy-cf-worker)
2. **Dependencies**: Clarify job dependencies and execution order
3. **Environment Variables**: Update all environment variable references

This design ensures comprehensive synchronization while maintaining the guide's usefulness and accuracy for developers working with the project.