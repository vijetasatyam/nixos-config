#!/bin/bash
set -euo pipefail

# --- Color Definitions ---
BLUE='\033[1;34m'; GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

cd ~/nixos-config || exit

echo -e "${BLUE}--- Recent Configuration History ---${NC}"
git log --oneline -n 10
echo -e "${BLUE}------------------------------------${NC}"

read -p "🎯 Enter the Commit Hash to revert to (or press Enter to cancel): " hash

if [[ -z "$hash" ]]; then
    echo -e "${YELLOW}⏹️ Revert cancelled.${NC}"
    exit 0
fi

# Check for uncommitted changes before doing a hard reset
if [[ -n $(git status -s) ]]; then
    echo -e "${RED}⚠️ WARNING: You have uncommitted changes!${NC}"
    echo "A hard reset will PERMANENTLY delete them."
    read -p "Are you absolutely sure you want to proceed? (y/N) " dirty_confirm
    if [[ ! $dirty_confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}⏹️ Revert aborted to save uncommitted work.${NC}"
        exit 1
    fi
fi

read -p "⚠️ This will reset your local files to $hash. Continue? (y/N) " confirm
if [[ $confirm =~ ^[Yy]$ ]]; then

    echo -e "${CYAN}⏪ Resetting files to $hash...${NC}"
    git reset --hard "$hash"

    # CRITICAL: Added the flake flag here!
    echo -e "${CYAN}⚙️ Rebuilding system to match configuration at $hash...${NC}"
    sudo nixos-rebuild switch --flake ./flake#nixos

    echo -e "${GREEN}✨ Revert Complete! Your system now matches commit $hash.${NC}"
else
    echo -e "${YELLOW}⏹️ Revert aborted.${NC}"
fi
