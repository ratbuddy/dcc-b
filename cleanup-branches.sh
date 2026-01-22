#!/bin/bash
# Branch cleanup script for ratbuddy/dcc-b repository
# This script deletes all merged feature branches except main
#
# IMPORTANT: Review the branch list before running this script!
# This action cannot be undone easily.

set -e

echo "=========================================="
echo "Repository Branch Cleanup Script"
echo "=========================================="
echo ""
echo "This script will delete 38 merged branches from the remote repository."
echo ""

# List of merged branches to delete
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

# Optional: Also delete the unmerged branch from closed PR #26
# Uncomment the following line if you want to delete it:
# branches+=("copilot/fix-addon-harness-require-errors")

echo "Branches to be deleted:"
printf '%s\n' "${branches[@]}"
echo ""
echo "Total: ${#branches[@]} branches"
echo ""

read -p "Do you want to proceed with deletion? (yes/y/no/n): " confirm

# Convert to lowercase for case-insensitive comparison
confirm_lower=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')

if [ "$confirm_lower" != "yes" ] && [ "$confirm_lower" != "y" ]; then
    echo "Aborted. No branches were deleted."
    exit 0
fi

echo ""
echo "Deleting branches..."
echo ""

success_count=0
error_count=0

for branch in "${branches[@]}"; do
    echo -n "Deleting $branch... "
    error_output=$(git push origin --delete "$branch" 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "✓ deleted"
        ((success_count++))
    else
        echo "✗ failed"
        # Show error details for troubleshooting
        echo "  Error: $error_output" | head -n 1
        ((error_count++))
    fi
done

echo ""
echo "=========================================="
echo "Cleanup Summary"
echo "=========================================="
echo "Successfully deleted: $success_count branches"
echo "Failed/Already deleted: $error_count branches"
echo ""
echo "Cleanup complete!"
