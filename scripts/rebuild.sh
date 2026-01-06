#!/bin/bash
# Features: Default-to-Yes on all prompts, Clean Diffs, GPG Fix, Secret Scanner

# Ensure GPG can find the terminal for passphrase entry
export GPG_TTY=$(tty)

# --- Color Definitions ---
BLUE='\033[1;34m'; GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; NC='\033[0m'

START_TIME=$SECONDS
LOG_FILE="/tmp/nixos-build-error.log"

# --- 1. Preparation ---
echo -e "${BLUE}🚀 Starting Ultimate NixOS Rebuild...${NC}"
cd ~/nixos-config || exit

# Check for uncommitted changes
if [[ -n $(git status -s) ]]; then
    echo -e "${YELLOW}📝 Notice:${NC} Uncommitted changes found."
    git status -s
fi

# --- 2. Building ---
echo -e "\n${CYAN}📦 Step 1: Building new NixOS generation...${NC}"
sudo nixos-rebuild build 2>&1 | tee $LOG_FILE | grep -E "error:|failed"
BUILD_STATUS=${PIPESTATUS[0]}

if [ $BUILD_STATUS -ne 0 ]; then
    echo -e "\n${RED}━━━━━━━━━━━━━━ BUILD FAILED ━━━━━━━━━━━━━━${NC}"
    grep -i "error:" $LOG_FILE | tail -n 10
    exit 1
fi

# --- 3. High-Signal Analysis ---
echo -e "\n${BLUE}🔍 Step 2: Comprehensive Diff Analysis${NC}"

echo -e "\n${CYAN}[1/3] Version Changes (nvd):${NC}"
echo -e "${YELLOW}--------------------------------------------------${NC}"
# Use -- to prevent grep from misinterpreting the arrow
nvd diff /run/current-system ./result | grep -- "->" || nvd diff /run/current-system ./result | grep -E "Added packages:|Removed packages:"
echo -e "${YELLOW}--------------------------------------------------${NC}"

echo -e "\n${CYAN}[2/3] Env & Derivation Changes (nix-diff):${NC}"
# Show only lines that start with + or - while ignoring massive path strings
nix-diff --color always --environment /run/current-system ./result | grep -E "^(\s*)[\+\-]" | grep -v "DEFAULT=" || echo "  No significant environment changes."

echo -e "\n${CYAN}[3/3] Closure Size Comparison:${NC}"
old_size=$(du -shL /run/current-system 2>/dev/null | awk '{print $1}')
new_size=$(du -shL ./result 2>/dev/null | awk '{print $1}')
echo -e "Current System Size: ${YELLOW}$old_size${NC}"
echo -e "New System Size:     ${GREEN}$new_size${NC}"

# --- 4. Gate 1: Activation Prompt (Default: YES) ---
echo -e "\n"
read -p "❓ Apply this configuration? [Y/n] " confirm
if [[ $confirm =~ ^[Yy]$ || $confirm == [yY][eE][sS] || -z $confirm ]]; then

    # 5. Applying the Switch
    echo -e "${CYAN}⚙️ Step 3: Activating...${NC}"
    sudo nixos-rebuild switch --quiet

    # 6. Gate 2: Git Commit Prompt (Default: YES)
    if [ -d .git ]; then
        gen=$(nixos-rebuild list-generations | grep current | awk '{print $1}')
        git add .

        if git diff --cached --quiet; then
            echo -e "${YELLOW}⏭️ Nothing to commit, working tree clean.${NC}"
        else
            # Secret Scanner
            LEAKS=$(git diff --cached | grep -iE "PRIVATE KEY|PASSWORD|SECRET_KEY|API_KEY" | grep "^+")
            if [ -n "$LEAKS" ]; then
                echo -e "${RED}⚠️  POTENTIAL SECRET LEAK DETECTED:${NC}"
                echo "$LEAKS"
            fi

            echo -ne "\n${YELLOW}💾 Commit changes locally? [Y/n] ${NC}"
            read -r commit_confirm
            if [[ $commit_confirm =~ ^[Yy]$ || $commit_confirm == [yY][eE][sS] || -z $commit_confirm ]]; then
                if git commit -S -m "NixOS: Gen $gen"; then
                    echo -e "${GREEN}✔ Locally committed Gen $gen${NC}"

                    # 7. Gate 3: Smart Push Detection (Default: YES)
                    echo -ne "${BLUE}📡 Checking remotes... ${NC}"
                    git fetch --quiet origin main &
                    git fetch --quiet github main &
                    wait
                    echo -e "${GREEN}Done${NC}"

                    AHEAD_ORIGIN=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo 0)
                    AHEAD_GITHUB=$(git rev-list --count github/main..HEAD 2>/dev/null || echo 0)

                    if [ "$AHEAD_ORIGIN" -eq 0 ] && [ "$AHEAD_GITHUB" -eq 0 ]; then
                        echo -e "${GREEN}☁️ Remotes are already up to date.${NC}"
                    else
                        echo -e "\n${YELLOW}📡 Ahead by $AHEAD_ORIGIN (origin) and $AHEAD_GITHUB (github) commits.${NC}"
                        read -p "🌍 Push to Remotes? [Y/n] " push_confirm
                        if [[ $push_confirm =~ ^[Yy]$ || $push_confirm == [yY][eE][sS] || -z $push_confirm ]]; then
                            echo -e "${BLUE}📡 Syncing remotes...${NC}"
                            git push origin main && git push github main
                            echo -e "${GREEN}✅ Remotes updated.${NC}"
                        else
                            echo -e "${YELLOW}⏭️ Push skipped.${NC}"
                        fi
                    fi
                fi
            else
                echo -e "${YELLOW}⏭️ Commit skipped.${NC}"
            fi
        fi
    fi

    ELAPSED=$(( SECONDS - START_TIME ))
    echo -e "\n${GREEN}✨ DONE! System is at Generation $gen. (Time: ${ELAPSED}s)${NC}"
    rm ./result
else
    echo -e "${YELLOW}⏹️ Switch cancelled.${NC}"
    [ -L ./result ] && rm ./result
fi
