# Quick Branch Cleanup Guide

## Option 1: Using the Cleanup Script (Recommended)

If you have push access to the repository, simply run:

```bash
./cleanup-branches.sh
```

This interactive script will:
1. Show you all 38 branches that will be deleted
2. Ask for confirmation
3. Delete each branch and report progress
4. Show a summary of results

## Option 2: Using GitHub CLI

If you prefer using `gh` CLI:

```bash
# Authenticate first
gh auth login

# Delete all merged branches
gh api repos/ratbuddy/dcc-b/git/refs/heads/copilot/add-dccb-stub-start-zone -X DELETE
gh api repos/ratbuddy/dcc-b/git/refs/heads/copilot/add-start-redirect-point -X DELETE
# ... (repeat for each branch, or use the script)
```

Or bulk delete:
```bash
# Get all branch names and delete them
branches=(
    "copilot/add-dccb-stub-start-zone"
    "copilot/add-start-redirect-point"
    "copilot/bind-on-run-start-hook"
    "copilot/bind-verify-tome-engine-hooks"
    "copilot/confirm-addon-entrypoints"
    "copilot/create-actor-adapter-stub"
    "copilot/create-dcc-barony-directory-structure"
    "copilot/create-minimal-run-start-hook"
    "copilot/create-tome-addon-harness"
    "copilot/create-zone-adapter-stub"
    "copilot/document-zone-transition-api"
    "copilot/document-zone-transition-api-again"
    "copilot/fix-addon-folder-structure"
    "copilot/fix-addon-module-resolution"
    "copilot/fix-addon-require-paths"
    "copilot/fix-black-void-zone"
    "copilot/implement-central-event-bus"
    "copilot/implement-contestant-system-module"
    "copilot/implement-core-logging-rng"
    "copilot/implement-data-loading-validation"
    "copilot/implement-floor-director-module"
    "copilot/implement-global-dccb-state"
    "copilot/implement-meta-layer-module"
    "copilot/implement-region-director-module"
    "copilot/implement-tome-hooks-stub"
    "copilot/implement-zone-redirect"
    "copilot/implement-zone-tags-module"
    "copilot/log-zone-entry-timing"
    "copilot/make-init-lua-descriptor-only"
    "copilot/move-addon-harness-modules"
    "copilot/rename-docs-for-engine-pivot"
    "copilot/research-zone-transition-api"
    "copilot/restructure-addon-modules"
    "copilot/update-documentation-hooks-addons"
    "copilot/update-target-engine-references"
    "copilot/update-tome-integration-notes"
    "copilot/update-verticality-strategy-docs"
    "copilot/upgrade-redirect-decision"
)

for branch in "${branches[@]}"; do
    echo "Deleting $branch..."
    gh api "repos/ratbuddy/dcc-b/git/refs/heads/$branch" -X DELETE
done
```

## Option 3: Using GitHub Web Interface

1. Go to: https://github.com/ratbuddy/dcc-b/branches
2. For each branch listed in CLEANUP_SUMMARY.md:
   - Click the trash/delete icon next to the branch name
   - Confirm deletion

**Note**: This is tedious for 38 branches but works without command-line access.

## Option 4: Enable Auto-Delete (Prevent Future Buildup)

1. Go to: https://github.com/ratbuddy/dcc-b/settings
2. Navigate to "Pull Requests" section
3. Enable "Automatically delete head branches"

This will automatically delete branches after their PRs are merged, preventing future buildup.

## Verification

After cleanup, verify only essential branches remain:
```bash
git fetch --all
git branch -r
```

Expected result (after this PR is merged and its branch auto-deleted):
```
origin/main
```

**Note**: The `copilot/clean-up-old-branches` branch will also be deleted after this PR is merged, leaving only `main`.

## Need Help?

See `CLEANUP_SUMMARY.md` for full analysis and recommendations.
