#!/bin/bash
# Script to install LXD on Ubuntu

set -e

echo "Updating system..."
sudo apt update && sudo apt upgrade -y

echo "Installing LXD via snap..."
sudo apt install snapd -y
sudo snap install lxd

echo "Adding current user to lxd group..."
sudo usermod -aG lxd $USER
newgrp lxd

echo "Initializing LXD..."
sudo lxd init --auto

echo "LXD installed and initialized successfully!"
echo "Please log out and back in if needed to apply group changes."
