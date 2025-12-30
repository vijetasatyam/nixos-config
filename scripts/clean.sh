#!/bin/bash
# Smart Cleanup: Keeps the last 5 generations and clears the rest

echo "--- Starting NixOS Storage Optimization ---"

# 1. Delete generations older than 7 days (or keep a specific number)
# This ensures you always have a 'way back' if something breaks
echo "Deleting old system generations..."
sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +5

# 2. Collect garbage (Deletes unreferenced packages)
echo "Collecting garbage..."
sudo nix-collect-garbage -d

# 3. Optimize the store (Hard-links duplicate files)
# This can save several gigabytes of space by deduplicating files
echo "Optimizing the Nix store..."
sudo nix-store --optimise -v

echo "--- Cleanup Complete! ---"
