#!/bin/bash
# Quick fix for tmux scrolling issues

echo "🔧 Fixing tmux scrolling configuration..."

# Backup current config
if [ -f ~/.tmux.conf ]; then
    cp ~/.tmux.conf ~/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)
    echo "✓ Backed up existing config"
fi

# Add scrolling fixes
cat >> ~/.tmux.conf << 'EOF'

# === Scrollback Fix Configuration ===
# Added: $(date)

# Enable mouse scrolling
set -g mouse on

# Increase scrollback buffer significantly
set -g history-limit 50000

# Better scrolling behavior
bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'select-pane -t=; copy-mode -e; send-keys -M'"
bind -n WheelDownPane select-pane -t= \; send-keys -M

# Clear screen and history
bind -n C-l send-keys C-l \; clear-history

# Copy mode improvements
setw -g mode-keys vi
bind [ copy-mode
bind -T copy-mode-vi q send-keys -X cancel
bind -T copy-mode-vi Escape send-keys -X cancel

# Search in copy mode
bind-key / copy-mode \; send-keys ?

# Mobile-friendly settings
set -g @scroll-speed-num-lines-per-scroll 3
set -g @scroll-down-exit-copy-mode "on"

# Visual feedback
set -g mode-style "bg=colour238,fg=colour255"
EOF

# Reload tmux configuration if tmux is running
if pgrep tmux > /dev/null; then
    tmux source-file ~/.tmux.conf 2>/dev/null && echo "✓ Configuration reloaded in running sessions"
fi

echo ""
echo "✅ Scrolling fix applied!"
echo ""
echo "📜 How to use scrolling:"
echo "  • Mouse: Just scroll with wheel/trackpad"
echo "  • Keyboard: Press Ctrl+a [ then use arrows/PgUp/PgDn"
echo "  • Exit scroll mode: Press 'q'"
echo "  • Clear screen: Ctrl+l"
echo ""
echo "🔍 Test it:"
echo "  1. Run: seq 1 1000"
echo "  2. Try scrolling up with your mouse"
echo "  3. Or press Ctrl+a [ and use arrows"
echo ""

# If in tmux, reload now
if [ -n "$TMUX" ]; then
    echo "🔄 Reloading configuration now..."
    tmux source-file ~/.tmux.conf
    echo "✓ Configuration active in this session!"
fi