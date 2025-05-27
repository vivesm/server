#!/bin/bash

# Hardcode the username for safety
USERNAME="melvin"

# Verify we're setting up for the right user
CURRENT_USER=$(whoami)

echo "Setting up passwordless sudo for user: $USERNAME"
echo "Current user: $CURRENT_USER"

# Safety check
if [ "$CURRENT_USER" != "$USERNAME" ]; then
    echo "WARNING: You're logged in as '$CURRENT_USER' but setting up sudo for '$USERNAME'"
    echo "Press Ctrl+C to cancel or Enter to continue..."
    read
fi

# Create temporary file first
TEMP_FILE=$(mktemp)
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "$TEMP_FILE"

# Verify syntax before applying
if sudo visudo -c -f "$TEMP_FILE"; then
    # Copy to sudoers.d with proper permissions
    sudo cp "$TEMP_FILE" "/etc/sudoers.d/$USERNAME"
    sudo chmod 0440 "/etc/sudoers.d/$USERNAME"
    
    # Final verification
    if sudo visudo -c; then
        echo "✅ Passwordless sudo configured successfully for $USERNAME"
        echo "You can now use sudo without entering a password."
    else
        echo "❌ ERROR: Sudoers configuration is invalid!"
        echo "Removing the file to prevent lockout..."
        sudo rm -f "/etc/sudoers.d/$USERNAME"
        exit 1
    fi
else
    echo "❌ ERROR: Invalid sudoers syntax!"
    exit 1
fi

# Cleanup
rm -f "$TEMP_FILE"

echo ""
echo "⚠️  IMPORTANT: Keep this SSH session open and test sudo in a NEW terminal!"
echo "Test command: sudo ls /"