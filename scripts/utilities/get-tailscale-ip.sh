#!/bin/bash

# Get Tailscale IP address
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null)

if [ -z "$TAILSCALE_IP" ]; then
    echo "Error: Tailscale is not running or not connected"
    echo "Please run: sudo tailscale up"
    exit 1
fi

echo "$TAILSCALE_IP"