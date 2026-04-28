#!/bin/bash
set -uo pipefail

# Ensure GPG can find the terminal for passphrase entry
export GPG_TTY=$(tty)

# --- Color & Style Definitions ---
BLUE='\033[1;34m'; GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; NC='\033[0m'
BOLD='\033[1m'

START_TIME=$SECONDS
FLAKE_DIR="/home/alice/nixos-config/flake"

# Clean up the result symlink perfectly
trap 'rm -f ./result' EXIT

# --- Pre-flight Check ---
echo -e "${BLUE}${BOLD}🚀 Starting NixOS Flake Rebuild via nh${NC}\n"

# Authenticate sudo upfront
sudo -v
# Keep sudo alive for the duration of the script
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

cd "$FLAKE_DIR" || exit

if [[ -n $(git status -s) ]]; then
    echo -e "${YELLOW}📝 Uncommitted changes detected.${NC}"
fi

# --- 1. Building (Flake) ---
echo -e "${CYAN}⚙️ Building new generation for 'desktop'...${NC}"
# nh os build automatically uses nom for a beautiful progress UI
if ! nh os build "$FLAKE_DIR" --hostname desktop; then
    echo -e "${RED}❌ Build Failed! Check the output above.${NC}"
    exit 1
fi
echo -e "${GREEN}✔ Build Successful${NC}"

# --- 2. High-Signal Analysis ---
echo -e "\n${BLUE}🔍 Diff Analysis${NC}"

nvd_out=$(nvd diff /run/current-system ./result | grep -- "->")
if [ -n "$nvd_out" ]; then
    echo -e "${YELLOW}--- Package Updates ---${NC}"
    echo "$nvd_out"
fi

nix_diff_out=$(nix-diff --color always --environment /run/current-system ./result | grep -E "^(\s*)[\+\-]" | grep -v "DEFAULT=")
if [ -n "$nix_diff_out" ]; then
    echo -e "${YELLOW}--- Environment Changes ---${NC}"
    echo "$nix_diff_out"
fi

new_size=$(du -shL ./result 2>/dev/null | awk '{print $1}')
echo -e "New System Size: ${GREEN}$new_size${NC}\n"

# --- 3. Gate 1: Activation Prompt ---
read -p "❓ Apply this configuration? [Y/n] " confirm
if [[ $confirm =~ ^[Yy]$ || $confirm == [yY][eE][sS] || -z $confirm ]]; then

    # 4. Applying the Switch
    echo -e "${CYAN}🚀 Activating configuration...${NC}"
    nh os switch "$FLAKE_DIR" --hostname desktop
    echo -e "${GREEN}✔ System Activated${NC}"

    # 5. Gate 2: Git Commit
    if [ -d ../.git ]; then
        gen=$(ls -l /nix/var/nix/profiles/system | grep -Eo 'system-[0-9]+-link' | tail -1 | grep -Eo '[0-9]+')

        cd ..

        echo -e "${CYAN}🧹 Formatting with Alejandra...${NC}"
        nix run nixpkgs#alejandra -- --quiet .
        echo -e "${GREEN}✔ Code Formatted${NC}"

        git add .

        if git diff --cached --quiet; then
            echo -e "${YELLOW}⏭️ Working tree clean, nothing to commit.${NC}"
        else
            echo -ne "\n${YELLOW}💾 Commit changes locally? [y/N] ${NC}"
            read -r commit_confirm

            if [[ $commit_confirm =~ ^[Yy]$ || $commit_confirm == [yY][eE][sS] ]]; then
                default_msg="NixOS: Gen $gen"
                echo -ne "${CYAN}📝 Enter commit message (Default: '$default_msg'): ${NC}"
                read -r custom_msg
                commit_msg=${custom_msg:-$default_msg}

                if git commit --quiet -S -m "$commit_msg"; then
                    echo -e "${GREEN}✔ Committed: \"$commit_msg\"${NC}"

                    # 6. Gate 3: Push
                    echo -e "${CYAN}📡 Checking remotes...${NC}"
                    git fetch --quiet github main &
                    git fetch --quiet codeberg main &
                    wait

                    AHEAD_GITHUB=$(git rev-list --count github/main..HEAD 2>/dev/null || echo 0)
                    AHEAD_CODEBERG=$(git rev-list --count codeberg/main..HEAD 2>/dev/null || echo 0)

                    if [ "$AHEAD_GITHUB" -eq 0 ] && [ "$AHEAD_CODEBERG" -eq 0 ]; then
                        echo -e "${GREEN}☁️ Remotes are already up to date.${NC}"
                    else
                        echo -e "\n${YELLOW}📡 Ahead by $AHEAD_GITHUB (github) and $AHEAD_CODEBERG (codeberg).${NC}"
                        read -p "🌍 Push to Remotes? [y/N] " push_confirm

                        if [[ $push_confirm =~ ^[Yy]$ || $push_confirm == [yY][eE][sS] ]]; then
                            echo -e "${CYAN}🔄 Syncing to Github & Codeberg...${NC}"
                            git push --quiet github main && git push --quiet codeberg main
                            echo -e "${GREEN}✅ Remotes updated.${NC}"
                        else
                            echo -e "${YELLOW}⏭️ Push skipped.${NC}"
                        fi
                    fi
                else
                    echo -e "${RED}❌ Commit failed. Check GPG setup.${NC}"
                fi
            fi
        fi
    fi

    ELAPSED=$(( SECONDS - START_TIME ))
    echo -e "\n${GREEN}${BOLD}✨ DONE! Generation $gen active. (${ELAPSED}s)${NC}"
else
    echo -e "${YELLOW}⏹️ Switch cancelled.${NC}"
fi
