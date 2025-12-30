#!/bin/bash
# ❄️ NixOS Ultimate Rebuild Script (v3.2.1)
# Fixes: Removed du permission errors & improved GPG TTY handling

# Ensure GPG can find the terminal for passphrase entry
export GPG_TTY=$(tty)

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

# Check for uncommitted changes
if [[ -n $(git status -s) ]]; then
    echo -e "${YELLOW}📝 Notice:${NC} You have uncommitted changes in your config folder."
    git status -s
fi

# --- 2. Building with Error Capture ---
echo -e "\n${CYAN}📦 Step 1: Building new NixOS generation...${NC}"

sudo nixos-rebuild build 2>&1 | tee $LOG_FILE
BUILD_STATUS=${PIPESTATUS[0]}

if [ $BUILD_STATUS -ne 0 ]; then
    echo -e "\n${RED}━━━━━━━━━━━━━━ BUILD FAILED ━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Relevant Error Snippet:${NC}"
    grep -i "error:" $LOG_FILE | tail -n 10
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

# B. NIX-DIFF
echo -e "\n${CYAN}[2/3] Env & Derivation Changes (nix-diff):${NC}"
nix-diff --color always --environment /run/current-system ./result

# C. CLOSURE SIZE (Permission Errors Fixed)
echo -e "\n${CYAN}[3/3] Closure Size Comparison:${NC}"
# 2>/dev/null silences errors for restricted files like /etc/cups/ssl
old_size=$(du -shL /run/current-system 2>/dev/null | awk '{print $1}')
new_size=$(du -shL ./result 2>/dev/null | awk '{print $1}')
echo -e "Current System Size: ${YELLOW}$old_size${NC}"
echo -e "New System Size:     ${GREEN}$new_size${NC}"

# --- 4. Activation Prompt ---
echo -e "\n"
read -p "❓ Apply this configuration? (y/N) " confirm
if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then

    # 5. Applying the Switch
    echo -e "${CYAN}⚙️ Step 3: Activating configuration...${NC}"
    sudo nixos-rebuild switch

    # 6. Git Automation
    gen=$(nixos-rebuild list-generations | grep current | awk '{print $1}')

    echo -e "\n${GREEN}✅ Rebuild successful!${NC} Committing changes to Git..."
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
            echo -e "${YELLOW}⏭️ Push skipped.${NC} Changes saved locally."
        fi
    else
        echo -e "${RED}⚠️ Commit failed (Check GPG/Passphrase).${NC}"
        echo -e "${YELLOW}Tip: Try running 'gpg-connect-agent reloadagent /bye' if the prompt didn't appear.${NC}"
    fi

    ELAPSED=$(( SECONDS - START_TIME ))
    echo -e "\n${GREEN}✨ DONE! System is at Generation $gen. (Build Time: $((ELAPSED/60))m $((ELAPSED%60))s)${NC}"
else
    echo -e "${YELLOW}⏹️ Switch cancelled.${NC} No Git commit made."
    rm ./result
fi
