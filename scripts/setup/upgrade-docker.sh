#!/bin/bash

echo "Upgrading Docker to latest stable version..."

# Update package index
sudo apt-get update

# Upgrade Docker packages
sudo apt-get upgrade -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Show new version
echo ""
echo "Docker upgraded successfully!"
docker --version
docker compose version