# Post-Merge Cleanup Checklist

Use this checklist after merging the cleanup PR to complete the repository cleanup.

## Step 1: Branch Cleanup ⭐ MAIN TASK

### Option A: Using the Script (Recommended)
```bash
cd /path/to/dcc-b
./cleanup-branches.sh
```

**What it does:**
- ✅ Lists all 38 branches to be deleted
- ✅ Asks for confirmation (y/yes)
- ✅ Deletes branches one by one
- ✅ Shows progress and results
- ✅ Provides summary at the end

**Expected time:** 2-3 minutes

### Option B: Manual Deletion
See `QUICK_CLEANUP.md` for:
- GitHub CLI commands
- Web interface instructions
- Individual git commands

## Step 2: Verify Cleanup

```bash
git fetch --all --prune
git branch -r
```

**Expected output:**
```
origin/main
```

All copilot/* branches should be gone!

## Step 3: Optional - Delete Unmerged Branch

If you want to also delete the unmerged branch from closed PR #26:

```bash
git push origin --delete copilot/fix-addon-harness-require-errors
```

## Step 4: Enable Auto-Delete (Recommended)

Prevent future branch buildup:

1. Go to: https://github.com/ratbuddy/dcc-b/settings
2. Click "Pull Requests" in sidebar
3. Enable: ☑️ "Automatically delete head branches"
4. Save changes

**What this does:**
- Automatically deletes branches after PR merge
- No more manual cleanup needed
- Keeps repo clean going forward

## Step 5: Clean Up Local Branches (Optional)

If you have a local clone with old branches:

```bash
# Fetch latest and prune deleted remote branches
git fetch --all --prune

# List local branches
git branch

# Delete local branches that no longer exist on remote
git branch -D copilot/branch-name  # Repeat for each branch
```

Or use this one-liner to clean up all local branches that were deleted from remote:
```bash
git fetch --prune && git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -D
```

## Step 6: Verify Repository State

Run these commands to confirm everything is clean:

```bash
# Should show only main (and maybe your current working branch)
git branch -r

# Should be empty or have minimal output
git branch -a | grep copilot/

# Verify no cruft files
ls -la | grep -E '\.tmp|\.bak|~$'
```

## Completion Checklist

- [ ] Merged the cleanup PR
- [ ] Ran `cleanup-branches.sh` or manually deleted 38 branches
- [ ] Verified only `main` branch remains (using `git branch -r`)
- [ ] Optionally deleted unmerged branch from PR #26
- [ ] Enabled "Automatically delete head branches" in GitHub settings
- [ ] Cleaned up local branches (if applicable)
- [ ] Verified repository is clean

## Need Help?

- **Script errors?** Check CLEANUP_SUMMARY.md for troubleshooting
- **Alternative methods?** See QUICK_CLEANUP.md
- **Questions about branches?** All details in CLEANUP_SUMMARY.md

## Success! 🎉

Your repository is now clean and ready for the next phase of development!

**Benefits achieved:**
- ✅ 38 old branches removed
- ✅ Cleaner GitHub UI
- ✅ Faster clone/fetch operations
- ✅ `.gitignore` preventing future cruft
- ✅ Auto-delete enabled (if completed Step 4)

You're now at a good resting point with minimal cruft! 🚀
