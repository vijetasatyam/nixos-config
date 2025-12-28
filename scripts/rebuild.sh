#!/bin/bash
# Simple script to rebuild the system from the local config folder

# Navigate to the config directory
cd ~/nixos-config

# Run the rebuild
sudo nixos-rebuild switch

# Notify user of completion
echo "NixOS Rebuild Complete!"
