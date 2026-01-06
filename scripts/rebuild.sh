#!/bin/bash
export GPG_TTY=$(tty)

# --- Colors & Icons ---
BLUE='\033[1;34m'; GREEN='\033[1;32m'; RED='\033[1;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
CHECK="✔"; ERROR="✖"; INFO="ℹ"

START_TIME=$SECONDS
LOG_FILE="/tmp/nixos-build.log"

echo -e "${BLUE}🚀 NixOS Evolution Started...${NC}"
cd ~/nixos-config || exit

# --- 1. Silent Build ---
# We hide everything unless there is an error
echo -ne "${BLUE}🔨 Building Generation... ${NC}"
sudo nixos-rebuild build > $LOG_FILE 2>&1
BUILD_STATUS=$?

if [ $BUILD_STATUS -ne 0 ]; then
    echo -e "${RED}${ERROR} FAILED${NC}"
    echo -e "${YELLOW}Last 10 lines of error log:${NC}"
    tail -n 10 $LOG_FILE | grep -iE "error:|failed"
    exit 1
fi
echo -e "${GREEN}${CHECK} DONE${NC}"

# --- 2. High-Signal Diff Analysis ---
echo -e "\n${BLUE}🔍 Change Summary:${NC}"

# Package versions (nvd)
# We use -- to tell grep "->"" is a string, not a flag
echo -ne "${YELLOW}📦 Packages: ${NC}"
nvd diff /run/current-system ./result | grep -- "->" | sed 's/^/  /' || echo " No version changes."

# Env changes (nix-diff)
echo -ne "${YELLOW}⚙️ Environment: ${NC}"
# Filter out the boring derivation paths and just show actual env var changes
nix-diff --environment /run/current-system ./result | grep -E "^\+|^-" | grep -v "derivation" | sed 's/^/  /' || echo " No env changes."

# Size Comparison (Silencing permission errors)
# 2>/dev/null hides the "Permission denied" junk
old_size=$(du -shL /run/current-system 2>/dev/null | awk '{print $1}')
new_size=$(du -shL ./result 2>/dev/null | awk '{print $1}')

if [ "$old_size" == "$new_size" ]; then
    echo -e "${YELLOW}💾 Size Check: ${NC}${old_size} (No change)"
else
    echo -e "${YELLOW}💾 Size Check: ${NC}${old_size} ➔ ${GREEN}${new_size}${NC}"
fi

# --- 3. Activation ---
echo -ne "\n${BLUE}❓ Apply Evolution? [Y/n] ${NC}"
read -r confirm
if [[ $confirm == [yY] || -z $confirm ]]; then

    # Switch silently but show critical errors
    echo -ne "${BLUE}⚙️ Activating... ${NC}"
    sudo nixos-rebuild switch --quiet > /dev/null 2>&1
    echo -e "${GREEN}${CHECK}${NC}"

    # --- 4. Git Intelligence ---
    gen=$(nixos-rebuild list-generations | grep current | awk '{print $1}')
    git add .

    if ! git diff --cached --quiet; then
        git commit -S -m "Gen $gen" --quiet
        echo -e "${GREEN}${CHECK} Committed Gen $gen${NC}"

        # Smart Push (One-line summary)
        echo -ne "${BLUE}📡 Syncing Remotes... ${NC}"
        (git push origin main && git push github main) > /dev/null 2>&1
        echo -e "${GREEN}${CHECK} GitHub/Codeberg Updated${NC}"
    fi

    ELAPSED=$(( SECONDS - START_TIME ))
    echo -e "\n${GREEN}✨ Evolution Complete. (Time: ${ELAPSED}s)${NC}"
else
    echo -e "${YELLOW}⏹️ Cancelled.${NC}"
    rm ./result
fi
