# Git Workflow Commands for Submodules

This document explains how to use the Makefile commands for managing git operations across all submodules in the ecommerce-polyrepo.

## Quick Reference

### Check Status
```bash
# Check which submodules have uncommitted changes
make git-check-changes

# Show detailed status for all submodules
make git-status
```

### Branch Management
```bash
# Create a new feature branch in all submodules
make git-branch-all BRANCH_NAME="feature/my-new-feature"

# Checkout main branch in all submodules
make git-checkout-main-all

# Pull latest changes for all submodules
make git-pull-all
```

### Commit & Push
```bash
# Commit changes in all submodules that have modifications
make git-commit-all COMMIT_MSG="Add new feature"

# Push all submodules to their remote branches
make git-push-all
```

### Create Pull Requests
```bash
# Create PRs for all submodules on non-main branches
make git-create-pr-all PR_TITLE="Add new feature" PR_BODY="Description of changes"
```

### Complete Workflow (One Command)
```bash
# Commit, push, and create PRs in one go
make git-workflow COMMIT_MSG="Add feature" PR_TITLE="Add new feature" PR_BODY="Detailed description"
```

### Sync Parent Repo
```bash
# Update parent repo to track latest submodule commits
make git-sync-submodules
```

## Typical Workflows

### Scenario 1: Starting New Feature Work
```bash
# 1. Create feature branches in all submodules
make git-branch-all BRANCH_NAME="feature/add-payment-gateway"

# 2. Make your changes in the submodules
# ... edit files in be-api-gin, fe-nextjs, etc ...

# 3. Check which submodules have changes
make git-check-changes

# 4. Run the complete workflow
make git-workflow \
  COMMIT_MSG="Add payment gateway integration" \
  PR_TITLE="Add payment gateway integration" \
  PR_BODY="Adds Stripe payment integration across frontend and backend services"

# 5. Update parent repo with new submodule references
make git-sync-submodules
```

### Scenario 2: Commit and Push Only (No PRs Yet)
```bash
# 1. Commit changes in all modified submodules
make git-commit-all COMMIT_MSG="WIP: Working on payment feature"

# 2. Push to remote
make git-push-all
```

### Scenario 3: Create PRs for Existing Branches
```bash
# If you already have feature branches pushed, just create PRs
make git-create-pr-all \
  PR_TITLE="Add payment gateway integration" \
  PR_BODY="This PR adds Stripe payment integration"
```

### Scenario 4: Update All Submodules to Latest
```bash
# Pull latest changes from remote for all submodules
make git-pull-all

# Sync parent repo to track latest commits
make git-sync-submodules
```

## Understanding Submodule Status

When you run `git submodule status`, you may see:
- ` ` (space) - Submodule is checked out at the commit recorded in parent repo
- `+` - Submodule is checked out at a different commit than recorded in parent
- `-` - Submodule is not initialized
- `U` - Submodule has merge conflicts

The `git-sync-submodules` command helps update the parent repo when submodules are at different commits (the `+` case).

## Current Submodules

The following submodules are managed by these commands:
- `be-api-gin` - API Gateway (Go/Gin)
- `fe-nextjs` - Frontend (Next.js)
- `infra-terraform-eks` - Infrastructure (Terraform)
- `local-k8s` - Local Kubernetes configs (Skaffold)
- `proto-schemas` - Protocol Buffer schemas
- `svc-inventory-rails` - Inventory Service (Rails)
- `svc-listing-spring` - Listing Service (Spring Boot)
- `svc-user-django` - User Service (Django)

## Notes

- The `git-create-pr-all` command only creates PRs for submodules on non-main branches
- The `git-workflow` command will fail early if required parameters are missing
- All commands use color coding: 🟢 Green = success, 🟡 Yellow = info, 🔴 Red = error
- The `|| true` in scripts ensures failures in one submodule don't stop processing others
