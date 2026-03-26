#!/bin/bash
set -uo pipefail

# Ensure GPG can find the terminal for passphrase entry
export GPG_TTY=$(tty)

# --- Color & Style Definitions ---
BLUE='\033[1;34m'; GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; NC='\033[0m'
BOLD='\033[1m'

START_TIME=$SECONDS
LOG_FILE="/tmp/nixos-build-error.log"

# Clean up the result symlink perfectly
trap 'rm -f ./result' EXIT

# --- Animation Function ---
spin() {
    local pid=$1
    local msg=$2
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${CYAN}${frames[i]} ${msg}...${NC}"
        i=$(( (i + 1) % 10 ))
        sleep 0.1
    done
    printf "\r\033[K" # Clear the line when done
}

# --- Pre-flight Check ---
echo -e "${BLUE}${BOLD}🚀 Starting NixOS Flake Rebuild${NC}\n"

# Authenticate sudo upfront so background animations don't hang asking for a password
sudo -v
# Keep sudo alive for the duration of the script
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

cd ~/nixos-config/flake || exit

if [[ -n $(git status -s) ]]; then
    echo -e "${YELLOW}📝 Uncommitted changes detected.${NC}"
fi

# --- 1. Building (Flake) ---
# Run the build in the background, pipe output to log, and start spinner
sudo nixos-rebuild build --flake /home/alice/nixos-config/flake#nixos &> $LOG_FILE &
build_pid=$!
spin $build_pid "Building new generation"
wait $build_pid

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build Failed!${NC}"
    echo -e "${YELLOW}Last 15 lines of error:${NC}"
    tail -n 15 $LOG_FILE
    exit 1
fi
echo -e "${GREEN}✔ Build Successful${NC}"

# --- 2. High-Signal Analysis ---
# Re-compressed the output to only show what actually changed
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
    sudo nixos-rebuild switch --flake /home/alice/nixos-config/flake#nixos &>> $LOG_FILE &
    switch_pid=$!
    spin $switch_pid "Activating configuration"
    wait $switch_pid
    echo -e "${GREEN}✔ System Activated${NC}"

    # 5. Gate 2: Git Commit
    if [ -d ../.git ]; then
        gen=$(ls -l /nix/var/nix/profiles/system | grep -Eo 'system-[0-9]+-link' | tail -1 | grep -Eo '[0-9]+')

        cd ..
        nix run nixpkgs#alejandra -- --quiet . &>> $LOG_FILE &
        fmt_pid=$!
        spin $fmt_pid "Formatting with Alejandra"
        wait $fmt_pid
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

                # Suppress output unless it fails
                if git commit --quiet -S -m "$commit_msg"; then
                    echo -e "${GREEN}✔ Committed: \"$commit_msg\"${NC}"

                    # 6. Gate 3: Push
                    git fetch --quiet github main &
                    git fetch --quiet codeberg main &
                    fetch_pid=$!
                    spin $fetch_pid "Checking remotes"
                    wait $fetch_pid

                    AHEAD_GITHUB=$(git rev-list --count github/main..HEAD 2>/dev/null || echo 0)
                    AHEAD_CODEBERG=$(git rev-list --count codeberg/main..HEAD 2>/dev/null || echo 0)

                    if [ "$AHEAD_GITHUB" -eq 0 ] && [ "$AHEAD_CODEBERG" -eq 0 ]; then
                        echo -e "${GREEN}☁️ Remotes are already up to date.${NC}"
                    else
                        echo -e "\n${YELLOW}📡 Ahead by $AHEAD_GITHUB (github) and $AHEAD_CODEBERG (codeberg).${NC}"
                        read -p "🌍 Push to Remotes? [y/N] " push_confirm

                        if [[ $push_confirm =~ ^[Yy]$ || $push_confirm == [yY][eE][sS] ]]; then
                            git push --quiet github main && git push --quiet codeberg main &
                            push_pid=$!
                            spin $push_pid "Syncing to Github & Codeberg"
                            wait $push_pid
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





# #!/bin/bash
# set -uo pipefail

# # Ensure GPG can find the terminal for passphrase entry
# export GPG_TTY=$(tty)

# # --- Color Definitions ---
# BLUE='\033[1;34m'; GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; NC='\033[0m'

# START_TIME=$SECONDS
# LOG_FILE="/tmp/nixos-build-error.log"

# # Clean up the result symlink perfectly
# trap 'rm -f ./result' EXIT

# # --- 1. Preparation ---
# echo -e "${BLUE}🚀 Starting NixOS Flake Rebuild...${NC}"
# cd ~/nixos-config/flake || exit

# if [[ -n $(git status -s) ]]; then
#     echo -e "${YELLOW}📝 Notice:${NC} Uncommitted changes found."
#     git status -v # Verbose git status
# fi

# # --- 2. Building (Flake) ---
# echo -e "\n${CYAN}📦 Step 1: Building new NixOS generation (Verbose)...${NC}"

# # REMOVED: grep filter that was hiding output
# # ADDED: --show-trace for maximum error detail
# # ADDED: --print-build-logs to see everything Nix is doing
# if ! sudo nixos-rebuild build --flake /home/alice/nixos-config/flake#nixos --show-trace --print-build-logs 2>&1 | tee $LOG_FILE; then
#     echo -e "\n${RED}━━━━━━━━━━━━━━ BUILD FAILED ━━━━━━━━━━━━━━${NC}"
#     echo -e "${YELLOW}Full log available at: $LOG_FILE${NC}"
#     exit 1
# fi

# # --- 3. High-Signal Analysis ---
# echo -e "\n${BLUE}🔍 Step 2: Comprehensive Diff Analysis${NC}"

# echo -e "\n${CYAN}[1/3] Version Changes (nvd):${NC}"
# echo -e "${YELLOW}--------------------------------------------------${NC}"
# # Removed grep to show the full nvd output
# nvd diff /run/current-system ./result || echo "No package version changes."
# echo -e "${YELLOW}--------------------------------------------------${NC}"

# echo -e "\n${CYAN}[2/3] Env & Derivation Changes (nix-diff):${NC}"
# # Removed grep to show the full nix-diff output
# nix-diff --color always --environment /run/current-system ./result || echo "  No environment changes."

# echo -e "\n${CYAN}[3/3] Closure Size Comparison:${NC}"
# old_size=$(du -shL /run/current-system 2>/dev/null | awk '{print $1}')
# new_size=$(du -shL ./result 2>/dev/null | awk '{print $1}')
# echo -e "Current System Size: ${YELLOW}$old_size${NC}"
# echo -e "New System Size:     ${GREEN}$new_size${NC}"

# # --- 4. Gate 1: Activation Prompt ---
# echo -e "\n"
# read -p "❓ Apply this configuration? [Y/n] " confirm
# if [[ $confirm =~ ^[Yy]$ || $confirm == [yY][eE][sS] || -z $confirm ]]; then

#     # 5. Applying the Switch
#     echo -e "${CYAN}⚙️ Step 3: Activating...${NC}"
#     # Removed --quiet so you see the activation logs
#     sudo nixos-rebuild switch --flake /home/alice/nixos-config/flake#nixos

#     # 6. Gate 2: Git Commit
#     if [ -d ../.git ]; then
#         gen=$(ls -l /nix/var/nix/profiles/system | grep -Eo 'system-[0-9]+-link' | tail -1 | grep -Eo '[0-9]+')

#         echo -e "\n${CYAN}🧹 Formatting .nix files with Alejandra...${NC}"
#         cd ..
#         # Removed --quiet
#         nix run nixpkgs#alejandra -- .
#         git add .

#         if git diff --cached --quiet; then
#             echo -e "${YELLOW}⏭️ Nothing to commit, working tree clean.${NC}"
#         else
#             # Show exactly what is being committed
#             echo -e "${CYAN}📄 Staged changes for commit:${NC}"
#             git diff --cached --stat

#             echo -ne "\n${YELLOW}💾 Commit changes locally? [y/N] ${NC}"
#             read -r commit_confirm

#             if [[ $commit_confirm =~ ^[Yy]$ || $commit_confirm == [yY][eE][sS] ]]; then
#                 default_msg="NixOS: Gen $gen"
#                 echo -ne "${CYAN}📝 Enter commit message (Default: '$default_msg'): ${NC}"
#                 read -r custom_msg
#                 commit_msg=${custom_msg:-$default_msg}

#                 # Git commit with verbose output
#                 if git commit -v -S -m "$commit_msg"; then
#                     echo -e "${GREEN}✔ Committed successfully.${NC}"

#                     # 7. Gate 3: Push
#                     echo -ne "${BLUE}📡 Syncing remotes... ${NC}"
#                     # Fetching without --quiet to see network progress
#                     git fetch github main
#                     git fetch codeberg main

#                     AHEAD_GITHUB=$(git rev-list --count github/main..HEAD 2>/dev/null || echo 0)
#                     AHEAD_CODEBERG=$(git rev-list --count codeberg/main..HEAD 2>/dev/null || echo 0)

#                     if [ "$AHEAD_GITHUB" -eq 0 ] && [ "$AHEAD_CODEBERG" -eq 0 ]; then
#                         echo -e "${GREEN}☁️ Remotes are already up to date.${NC}"
#                     else
#                         echo -e "\n${YELLOW}📡 Ahead by $AHEAD_GITHUB (github) and $AHEAD_CODEBERG (codeberg) commits.${NC}"
#                         read -p "🌍 Push to Remotes? [y/N] " push_confirm

#                         if [[ $push_confirm =~ ^[Yy]$ || $push_confirm == [yY][eE][sS] ]]; then
#                             # Pushing with full output
#                             git push github main && git push codeberg main
#                             echo -e "${GREEN}✅ Remotes updated.${NC}"
#                         else
#                             echo -e "${YELLOW}⏭️ Push skipped.${NC}"
#                         fi
#                     fi
#                 fi
#             fi
#         fi
#     fi

#     ELAPSED=$(( SECONDS - START_TIME ))
#     echo -e "\n${GREEN}✨ DONE! System is at Generation $gen. (Time: ${ELAPSED}s)${NC}"
# else
#     echo -e "${YELLOW}⏹️ Switch cancelled.${NC}"
# fi
