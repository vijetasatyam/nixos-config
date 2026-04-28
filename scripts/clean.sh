#!/bin/bash
set -euo pipefail

# --- Color Definitions ---
BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

KEEP_GENS=${1:-5} # Defaults to 5 if no argument is provided

echo -e "${BLUE}--- Starting NixOS Storage Optimization ---${NC}"

# 1 & 2. Delete old generations and collect garbage via nh
echo -e "${YELLOW}🗑️ Cleaning store and keeping the last ${KEEP_GENS} generations...${NC}"
nh clean all --keep $KEEP_GENS

# 3. Optimize the store (Hard-links duplicate files)
echo -e "${YELLOW}🔗 Optimizing the Nix store (This may take a moment)...${NC}"
nix store optimise

echo -e "${GREEN}✨ Cleanup Complete!${NC}"
