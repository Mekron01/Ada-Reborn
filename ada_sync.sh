#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# ada_sync.sh - Auto sync Ada-Reborn repo: pull, commit, and push changes.
# Usage: ./ada_sync.sh "Your optional commit message"
###############################################################################

REPO_DIR="$HOME/Ada-Reborn"
cd "$REPO_DIR" || { echo "Ada-Reborn directory not found!"; exit 1; }

echo "==[ Syncing Ada-Reborn ]=="
echo "Pulling latest from remote..."

# Pull with merge (change to --rebase if preferred)
git pull origin main --no-edit || { echo "Pull failed, resolve manually."; exit 1; }

echo "Staging all changes..."
git add .

# Use custom commit message if provided, or default
COMMIT_MSG=${1:-"Auto-sync: $(date)"}
echo "Committing changes: $COMMIT_MSG"
git commit -m "$COMMIT_MSG" 2>/dev/null || echo "Nothing to commit."

echo "Pushing to GitHub..."
git push origin main || { echo "Push failed."; exit 1; }

echo "==[ Sync Complete ]=="
