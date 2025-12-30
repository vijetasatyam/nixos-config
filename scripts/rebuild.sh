#!/bin/bash
# ❄️ NixOS Ultimate Rebuild Script (v3.0)
# Triple-Diff + Error Reporting + Timer

# --- Color Definitions ---
BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

START_TIME=$SECONDS
LOG_FILE="/tmp/nixos-build-error.log"

# --- 1. Preparation ---
echo -e "${BLUE}🚀 Starting Ultimate NixOS Rebuild...${NC}"
cd ~/nixos-config || exit

# --- 2. Building with Error Capture ---
echo -e "\n${CYAN}📦 Step 1: Building new NixOS generation...${NC}"

# We use 'tee' to show you the output in real-time while saving it to a log
if ! sudo nixos-rebuild build 2>&1 | tee $LOG_FILE; then
    echo -e "\n${RED}━━━━━━━━━━━━━━ BUILD FAILED ━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Relevant Error Snippet:${NC}"
    # Extracts the last 20 lines, looking for 'error:' or 'failed'
    grep -A 5 -B 5 "error:" $LOG_FILE || tail -n 20 $LOG_FILE
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
fi

# --- 3. The Triple Diff Analysis ---
echo -e "\n${BLUE}🔍 Step 2: Comprehensive Diff Analysis${NC}"

# A. NVD (High Level Version Changes)
echo -e "\n${CYAN}[1/3] Version Changes (nvd):${NC}"
echo -e "${YELLOW}--------------------------------------------------${NC}"
nvd diff /run/current-system ./result
echo -e "${YELLOW}--------------------------------------------------${NC}"

# B. NIX-DIFF (Focused Environment Deep-Dive)
echo -e "\n${CYAN}[2/3] Env & Derivation Changes (nix-diff):${NC}"
# --environment: shows only changed env vars
# --color: keeps the terminal pretty
nix-diff --color --environment /run/current-system ./result

# C. NVDTOOLS (Path & Closure Summary)
echo -e "\n${CYAN}[3/3] Closure Summary (nvdtools):${NC}"
nvd-diff /run/current-system ./result

# --- 4. Activation Prompt ---
echo -e "\n"
read -p "❓ Apply this configuration? (y/N) " confirm
if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then

    # 5. Applying the Switch
    echo -e "${CYAN}⚙️ Step 3: Activating configuration...${NC}"
    sudo nixos-rebuild switch

    # 6. Git Automation
    gen=$(nixos-rebuild list-generations | grep current | awk '{print $1}')

    echo -e "\n${GREEN}✅ Rebuild successful!${NC} Committing changes..."
    git add .
    if git commit -S -m "NixOS Rebuild: Generation $gen"; then
        echo -e "${GREEN}💾 Commit successful.${NC}"

        # 7. Push Confirmation
        echo -e "\n"
        read -p "🌍 Push changes to Codeberg and GitHub? (y/N) " push_confirm
        if [[ $push_confirm == [yY] || $push_confirm == [yY][eE][sS] ]]; then
            echo -e "${BLUE}📡 Syncing remotes...${NC}"
            git push origin main && git push github main
            echo -e "${GREEN}✅ Remotes updated.${NC}"
        else
            echo -e "${YELLOW}⏭️ Push skipped.${NC}"
        fi
    else
        echo -e "${RED}⚠️ Commit failed (Check GPG).${NC}"
    fi

    ELAPSED=$(( SECONDS - START_TIME ))
    echo -e "\n${GREEN}✨ DONE! Generation $gen active. (Time: $((ELAPSED/60))m $((ELAPSED%60))s)${NC}"
else
    echo -e "${YELLOW}⏹️ Switch cancelled.${NC}"
    rm ./result
fi
