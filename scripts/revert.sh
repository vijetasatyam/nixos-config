#!/bin/bash
# Revert script to jump back to a previous Git-tracked configuration

cd ~/nixos-config || exit

# 1. Show the last 10 commits so you can see where you want to go
echo "--- Recent Configuration History ---"
git log --oneline -n 10
echo "------------------------------------"

# 2. Ask for the Commit Hash
read -p "Enter the Commit Hash to revert to (or press Enter to cancel): " hash

if [[ -z "$hash" ]]; then
    echo "Revert cancelled."
    exit 0
fi

# 3. Confirm the action
read -p "This will reset your local files to $hash. Continue? (y/N) " confirm
if [[ $confirm == [yY] ]]; then

    # 4. Use Git to reset the files
    git reset --hard "$hash"

    # 5. Rebuild the system to match the files
    echo "Rebuilding system to match configuration at $hash..."
    sudo nixos-rebuild switch

    echo "Revert Complete! Your system now matches commit $hash."
else
    echo "Revert aborted."
fi
