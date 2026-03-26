#!/bin/bash
set -euo pipefail

# --- Color Definitions ---
BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

KEEP_GENS=${1:-5} # Defaults to 5 if no argument is provided

echo -e "${BLUE}--- Starting NixOS Storage Optimization ---${NC}"

# 1. Delete old generations
echo -e "${YELLOW}🗑️ Keeping the last ${KEEP_GENS} system generations...${NC}"
sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +${KEEP_GENS}

# 2. Collect garbage (Deletes unreferenced packages)
echo -e "${YELLOW}🧹 Collecting garbage...${NC}"
sudo nix-collect-garbage -d

# 3. Optimize the store (Hard-links duplicate files)
echo -e "${YELLOW}🔗 Optimizing the Nix store (This may take a moment)...${NC}"
sudo nix-store --optimise

# 4. Sync Bootloader (Clears out leftover EFI kernels)
echo -e "${YELLOW}🥾 Syncing bootloader...${NC}"
sudo /run/current-system/bin/switch-to-configuration boot > /dev/null 2>&1 || true

echo -e "${GREEN}✨ Cleanup Complete!${NC}"
