#!/bin/bash
set -uo pipefail

# Ensure GPG can find the terminal for passphrase entry
export GPG_TTY=$(tty)

# --- Color Definitions ---
BLUE='\033[1;34m'; GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; NC='\033[0m'

START_TIME=$SECONDS
LOG_FILE="/tmp/nixos-build-error.log"

# Clean up the result symlink perfectly, even if the script crashes or is Ctrl+C'd
trap 'rm -f ./result' EXIT

# --- 1. Preparation ---
echo -e "${BLUE}🚀 Starting NixOS Flake Rebuild...${NC}"
cd ~/nixos-config || exit

if [[ -n $(git status -s) ]]; then
    echo -e "${YELLOW}📝 Notice:${NC} Uncommitted changes found."
    git status -s
fi

# --- 2. Building (Flake) ---
echo -e "\n${CYAN}📦 Step 1: Building new NixOS generation...${NC}"
if ! sudo nixos-rebuild build --flake ./flake#nixos 2>&1 | tee $LOG_FILE | grep -E "error:|failed"; then
    echo -e "\n${RED}━━━━━━━━━━━━━━ BUILD FAILED ━━━━━━━━━━━━━━${NC}"
    grep -i "error:" $LOG_FILE | tail -n 10
    exit 1
fi

# --- 3. High-Signal Analysis ---
echo -e "\n${BLUE}🔍 Step 2: Comprehensive Diff Analysis${NC}"

echo -e "\n${CYAN}[1/3] Version Changes (nvd):${NC}"
echo -e "${YELLOW}--------------------------------------------------${NC}"
nvd diff /run/current-system ./result | grep -- "->" || nvd diff /run/current-system ./result | grep -E "Added packages:|Removed packages:" || echo "No package version changes."
echo -e "${YELLOW}--------------------------------------------------${NC}"

echo -e "\n${CYAN}[2/3] Env & Derivation Changes (nix-diff):${NC}"
nix-diff --color always --environment /run/current-system ./result | grep -E "^(\s*)[\+\-]" | grep -v "DEFAULT=" || echo "  No significant environment changes."

echo -e "\n${CYAN}[3/3] Closure Size Comparison:${NC}"
old_size=$(du -shL /run/current-system 2>/dev/null | awk '{print $1}')
new_size=$(du -shL ./result 2>/dev/null | awk '{print $1}')
echo -e "Current System Size: ${YELLOW}$old_size${NC}"
echo -e "New System Size:     ${GREEN}$new_size${NC}"

# --- 4. Gate 1: Activation Prompt ---
echo -e "\n"
read -p "❓ Apply this configuration? [Y/n] " confirm
if [[ $confirm =~ ^[Yy]$ || $confirm == [yY][eE][sS] || -z $confirm ]]; then

    # 5. Applying the Switch
    echo -e "${CYAN}⚙️ Step 3: Activating...${NC}"
    sudo nixos-rebuild switch --flake ./flake#nixos --quiet

    # 6. Gate 2: Git Commit
    if [ -d .git ]; then
        # Fast generation extraction
        gen=$(ls -l /nix/var/nix/profiles/system | grep -Eo 'system-[0-9]+-link' | tail -1 | grep -Eo '[0-9]+')

        # --- NEW: Auto-Formatting Phase ---
        echo -e "\n${CYAN}🧹 Formatting .nix files with Alejandra...${NC}"
        # This uses 'nix run' to fetch and execute alejandra without permanently installing it
        nix run nixpkgs#alejandra -- --quiet .

        # Stage the newly formatted files (along with any other changes)
        git add .

        if git diff --cached --quiet; then
            echo -e "${YELLOW}⏭️ Nothing to commit, working tree clean.${NC}"
        else
            # Secret Scanner
            LEAKS=$(git diff --cached | grep -iE "PRIVATE KEY|PASSWORD|SECRET_KEY|API_KEY" | grep "^+")
            if [ -n "$LEAKS" ]; then
                echo -e "${RED}⚠️  POTENTIAL SECRET LEAK DETECTED:${NC}"
                echo "$LEAKS"
                read -p "🚨 Do you want to ABORT the commit to fix this? [Y/n] " leak_confirm
                if [[ $leak_confirm =~ ^[Yy]$ || -z $leak_confirm ]]; then
                    git reset HEAD # Unstage everything
                    echo -e "${YELLOW}⏹️ Commit aborted. Files unstaged.${NC}"
                    exit 1
                fi
            fi

            echo -ne "\n${YELLOW}💾 Commit changes locally? [y/N] ${NC}"
            read -r commit_confirm

            if [[ $commit_confirm =~ ^[Yy]$ || $commit_confirm == [yY][eE][sS] ]]; then

                default_msg="NixOS: Gen $gen"
                echo -ne "${CYAN}📝 Enter commit message (Default: '$default_msg'): ${NC}"
                read -r custom_msg
                commit_msg=${custom_msg:-$default_msg}

                if git commit -S -m "$commit_msg"; then
                    echo -e "${GREEN}✔ Committed with message: \"$commit_msg\"${NC}"

                    # 7. Gate 3: Push
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
                        read -p "🌍 Push to Remotes? [y/N] " push_confirm

                        if [[ $push_confirm =~ ^[Yy]$ || $push_confirm == [yY][eE][sS] ]]; then
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
else
    echo -e "${YELLOW}⏹️ Switch cancelled.${NC}"
fi
