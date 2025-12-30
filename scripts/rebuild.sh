#!/bin/bash
# ❄️ NixOS Ultimate Rebuild Script (v3.2)
# Features: Error Reporting, Triple-Diff, Timer, and Dual-Remote Sync

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

# We use 'tee' to show real-time output while saving to a log for error parsing
if ! sudo nixos-rebuild build 2>&1 | tee $LOG_FILE; then
    echo -e "\n${RED}━━━━━━━━━━━━━━ BUILD FAILED ━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Relevant Error Snippet:${NC}"
    # Looks for 'error:' or 'failed' and shows context
    grep -iA 5 -iB 5 "error:" $LOG_FILE || tail -n 20 $LOG_FILE
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}💡 Tip: Run 'less /tmp/nixos-build-error.log' to see full log.${NC}"
    exit 1
fi

# --- 3. The Triple Diff Analysis ---
echo -e "\n${BLUE}🔍 Step 2: Comprehensive Diff Analysis${NC}"

# A. NVD (High Level Version Changes)
echo -e "\n${CYAN}[1/3] Version Changes (nvd):${NC}"
echo -e "${YELLOW}--------------------------------------------------${NC}"
nvd diff /run/current-system ./result
echo -e "${YELLOW}--------------------------------------------------${NC}"

# B. NIX-DIFF (Corrected color flag)
echo -e "\n${CYAN}[2/3] Env & Derivation Changes (nix-diff):${NC}"
nix-diff --color always --environment /run/current-system ./result

# C. CLOSURE SIZE (Fixed command name)
echo -e "\n${CYAN}[3/3] Closure Size Comparison:${NC}"
# In newer Nix, the command is 'nix-store --query --references' or similar
# Let's use a simpler, more universal way:
old_size=$(du -shL /run/current-system | awk '{print $1}')
new_size=$(du -shL ./result | awk '{print $1}')
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
    # Capture the generation number for the commit message
    gen=$(nixos-rebuild list-generations | grep current | awk '{print $1}')

    echo -e "\n${GREEN}✅ Rebuild successful!${NC} Committing changes to Git..."
    git add .

    # Commit with GPG Signing
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
    fi

    # Calculate Time Elapsed
    ELAPSED=$(( SECONDS - START_TIME ))
    echo -e "\n${GREEN}✨ DONE! System is at Generation $gen. (Build Time: $((ELAPSED/60))m $((ELAPSED%60))s)${NC}"
else
    echo -e "${YELLOW}⏹️ Switch cancelled.${NC} No Git commit made."
    rm ./result  # Clean up the build symlink
fi
