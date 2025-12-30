#!/bin/bash
# Rebuild script with nvd diffing and automatic Git committing

# 1. Navigate to the config directory
cd ~/nixos-config || exit

# 2. Check for uncommitted changes in Git (Optional but recommended)
if [[ -n $(git status -s) ]]; then
    echo "Notice: You have uncommitted changes in your config folder."
fi

# 3. Build the new configuration
echo "Building new NixOS generation..."
if ! sudo nixos-rebuild build; then
    echo "Build failed! Fix the errors above before continuing."
    exit 1
fi

# 4. Run nvd to show a human-readable package version diff
echo -e "\n--- Package Version Changes (nvd) ---"
nvd diff /run/current-system ./result

# 5. Prompt to apply the changes
echo -e "\n"
read -p "Apply this configuration? (y/N) " confirm
if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then

    # 6. Apply the switch
    sudo nixos-rebuild switch

    # 7. Git Automation
    # Capture the generation number for the commit message
    gen=$(nixos-rebuild list-generations | grep current | awk '{print $1}')

    echo "Rebuild successful. Committing changes to Git..."
    git add .
    git commit -m "NixOS Rebuild: Generation $gen"

    # 8. Push to remotes (optional - uses your sync logic)
    # git push origin main && git push github main

    echo "Done! System is at Generation $gen and changes are committed."
else
    echo "Switch cancelled. No Git commit made."
    rm ./result  # Clean up the result link
fi
