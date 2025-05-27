#!/bin/bash

echo "Installing Tailscale..."

# Use correct repo for Ubuntu 22.04 (jammy)
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list

# Install
sudo apt-get update
sudo apt-get install -y tailscale

echo "Tailscale installed successfully!"
echo "To start using Tailscale, run: sudo tailscale up"