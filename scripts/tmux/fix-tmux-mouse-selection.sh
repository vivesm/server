#!/bin/bash
# Fix tmux mouse selection issues - Complete disable of mouse handling

echo "🔧 Fixing tmux mouse selection issues..."
echo "This will completely disable tmux mouse handling"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Backup existing config
if [ -f ~/.tmux.conf ]; then
    cp ~/.tmux.conf ~/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)
    echo -e "${GREEN}✓ Backed up existing tmux.conf${NC}"
fi

# Check current mouse status
current_mouse=$(tmux show -gv mouse 2>/dev/null || echo "not running")
echo -e "${YELLOW}Current mouse setting: $current_mouse${NC}"

# Add comprehensive mouse disable configuration
cat >> ~/.tmux.conf << 'EOF'

# === COMPLETE MOUSE DISABLE FOR SELECTION FIX ===
# Added: $(date)
# This fixes selection immediately unhighlighting in iTerm2

# Disable tmux mouse handling completely
set -g mouse off

# Unbind ALL mouse actions to prevent interference
unbind -n MouseDown1Pane
unbind -n MouseDrag1Pane
unbind -n MouseUp1Pane
unbind -n DoubleClick1Pane
unbind -n TripleClick1Pane
unbind -n MouseDown2Pane
unbind -n MouseDown3Pane
unbind -n WheelUpPane
unbind -n WheelDownPane

# Unbind copy-mode mouse actions
unbind -T copy-mode MouseDown1Pane
unbind -T copy-mode MouseDrag1Pane
unbind -T copy-mode MouseDragEnd1Pane
unbind -T copy-mode WheelUpPane
unbind -T copy-mode WheelDownPane
unbind -T copy-mode DoubleClick1Pane
unbind -T copy-mode TripleClick1Pane

# Unbind vi-mode mouse actions
unbind -T copy-mode-vi MouseDown1Pane
unbind -T copy-mode-vi MouseDrag1Pane
unbind -T copy-mode-vi MouseDragEnd1Pane
unbind -T copy-mode-vi WheelUpPane
unbind -T copy-mode-vi WheelDownPane
unbind -T copy-mode-vi DoubleClick1Pane
unbind -T copy-mode-vi TripleClick1Pane

# Keyboard-only copy mode (as fallback)
bind [ copy-mode
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send -X copy-selection-and-cancel
bind -T copy-mode-vi Escape send -X cancel
bind ] paste-buffer

# === END MOUSE DISABLE ===
EOF

echo -e "${GREEN}✓ Added mouse disable configuration${NC}"

# Reload configuration if tmux is running
if pgrep tmux > /dev/null; then
    echo -e "${YELLOW}Reloading tmux configuration...${NC}"
    tmux source-file ~/.tmux.conf 2>/dev/null || true
    
    # Check if mouse is now disabled
    new_mouse=$(tmux show -gv mouse 2>/dev/null || echo "not running")
    if [ "$new_mouse" = "off" ]; then
        echo -e "${GREEN}✓ Mouse successfully disabled${NC}"
    else
        echo -e "${RED}⚠ Mouse still enabled - restart tmux${NC}"
    fi
fi

# Check for conflicting mouse settings
echo ""
echo -e "${YELLOW}Checking for conflicting mouse settings...${NC}"
mouse_bindings=$(tmux list-keys 2>/dev/null | grep -i mouse | wc -l || echo "0")
if [ "$mouse_bindings" -gt 0 ]; then
    echo -e "${YELLOW}Found $mouse_bindings mouse bindings still active${NC}"
    echo -e "${YELLOW}You may need to restart tmux completely${NC}"
else
    echo -e "${GREEN}✓ No mouse bindings found${NC}"
fi

# Provide restart instructions
echo ""
echo -e "${GREEN}✅ Configuration complete!${NC}"
echo ""
echo "To fully apply changes:"
echo "1. Exit all tmux sessions: ${YELLOW}tmux kill-server${NC}"
echo "2. Start fresh: ${YELLOW}tmux new -s main${NC}"
echo ""
echo "📋 How to use selection now:"
echo "  • Click and drag to select text (handled by iTerm2)"
echo "  • Selection should stay highlighted"
echo "  • Copy with Cmd+C"
echo "  • For keyboard copy: Ctrl+b [ to enter copy mode"
echo ""
echo "🧪 Test selection with: ${YELLOW}seq 1 100${NC}"

# Offer immediate restart
if pgrep tmux > /dev/null; then
    echo ""
    read -p "Restart tmux now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Restarting tmux...${NC}"
        tmux kill-server 2>/dev/null || true
        sleep 1
        echo -e "${GREEN}✓ tmux stopped. Start a new session with: tmux new -s main${NC}"
    fi
fi