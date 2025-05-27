# Fix tmux Scrolling for Long Outputs
**Issue**: Can't scroll back through command output in tmux
**Solution**: Enable proper scrollback and copy mode

## ⚠️ Mouse Selection Issue

**Problem**: Text selection gets unselected immediately because tmux intercepts mouse events.

### Quick Fix (Basic)
```bash
# Add to ~/.tmux.conf
set -g mouse off

# Apply changes
tmux source-file ~/.tmux.conf
```

### Complete Fix (For Persistent Issues)
If selection still unhighlights immediately (common with iTerm2), you need to fully disable ALL mouse bindings:

```bash
# Run the comprehensive fix script
./fix-tmux-mouse-selection.sh
```

Or manually add to `~/.tmux.conf`:
```bash
# Disable mouse completely
set -g mouse off

# Unbind ALL mouse events
unbind -n MouseDown1Pane
unbind -n MouseDrag1Pane
unbind -n MouseUp1Pane
unbind -T copy-mode-vi MouseDragEnd1Pane
# ... (see TMUX-MOUSE-SELECTION-FIX.md for complete list)
```

Then restart tmux: `tmux kill-server && tmux new`

**Better Solution**: Keep mouse scrolling but fix selection with OSC52 (see Advanced section below).

## Quick Fix

Add these lines to your `~/.tmux.conf`:

```bash
# Enable mouse scrolling
set -g mouse on

# Increase scrollback buffer (default is 2000)
set -g history-limit 50000

# Better scrolling behavior
bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'select-pane -t=; copy-mode -e; send-keys -M'"
bind -n WheelDownPane select-pane -t= \; send-keys -M

# Use vim keys in copy mode
setw -g mode-keys vi

# Enter copy mode with Ctrl+a [
bind [ copy-mode

# Exit copy mode with q
bind -T copy-mode-vi q send-keys -X cancel
```

Then reload tmux config:
```bash
# If inside tmux:
tmux source-file ~/.tmux.conf

# Or press: Ctrl+a, then r (if using our config)
```

## How to Scroll

### Method 1: Mouse Scrolling (Easiest)
- Just use your mouse wheel or touchpad
- Scroll up to see history
- Scroll down to return to prompt

### Method 2: Keyboard Copy Mode
1. Press `Ctrl+a [` to enter copy mode
2. Use arrow keys or Page Up/Down to scroll
3. Press `q` to exit copy mode

### Method 3: Vim-style Navigation (in copy mode)
- `k` - scroll up
- `j` - scroll down  
- `Ctrl+u` - scroll up half page
- `Ctrl+d` - scroll down half page
- `g` - go to top
- `G` - go to bottom

## iPhone-Specific Tips

For Blink Shell:
```bash
# Add to ~/.tmux.conf for better touch support
set -g @scroll-speed-num-lines-per-scroll 3
set -g @scroll-down-exit-copy-mode "on"
```

For Termius:
- Use two-finger swipe to scroll
- Or tap and hold, then drag

## Advanced Configuration

### OSC52 Clipboard Integration (Best Solution)

Enable clipboard sync over SSH so tmux selections automatically copy to your local machine:

```bash
# Add to ~/.tmux.conf for OSC52 support
set -g set-clipboard on

# Allow terminal to access clipboard
set -g allow-passthrough on

# For tmux 3.3+, use external clipboard program
set -g copy-command 'yank'

# Or use OSC52 directly (works with most modern terminals)
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "sed 's/\x1b\[[0-9;]*m//g' | base64 -w0 | sed 's/^/\x1b]52;c;/' | sed 's/$/\x07/'"
```

Create the `yank` script for better OSC52 support:
```bash
sudo tee /usr/local/bin/yank > /dev/null << 'EOF'
#!/bin/bash
# OSC52 clipboard helper
buf=$(cat)
esc="\033]52;c;$(printf %s "$buf" | base64 -w0)\007"
printf %s "$esc"
EOF

sudo chmod +x /usr/local/bin/yank
```

### Full scrolling-optimized config:
```bash
cat >> ~/.tmux.conf << 'EOF'

# === Scrollback Configuration ===
# Huge history
set -g history-limit 100000

# Clear history binding
bind -n C-l send-keys C-l \; clear-history

# Save pane history to file
bind-key P command-prompt -p 'save history to filename:' -I '~/tmux.history' 'capture-pane -S -100000 ; save-buffer %1 ; delete-buffer'

# Search in copy mode
bind-key / copy-mode \; send-keys ?

# Copy to system clipboard (Linux)
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'

# Stay in copy mode after yanking
bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'

# === OSC52 Support ===
set -g set-clipboard on
set -g allow-passthrough on
EOF
```

## Troubleshooting

### Can't scroll at all?
```bash
# Check if mouse is enabled
tmux show -g mouse

# Should output: mouse on
# If not, run:
tmux set -g mouse on
```

### Scrolling exits immediately?
```bash
# Disable scroll-down-exit
set -g @scroll-down-exit-copy-mode "off"
```

### Lost in scroll mode?
- Press `q` to exit
- Or `Ctrl+c`
- Or scroll to bottom

## Pro Tips

1. **Search in history**:
   - Enter copy mode: `Ctrl+a [`
   - Press `/` to search up
   - Press `?` to search down
   - Press `n` for next match

2. **Select and copy text**:
   - Enter copy mode
   - Press `v` to start selection
   - Move to select text
   - Press `y` to copy

3. **Clear screen but keep history**:
   - `Ctrl+l` clears screen
   - `Ctrl+a Ctrl+l` clears history too

## Test Your Setup

```bash
# Generate long output
seq 1 1000

# Now try scrolling up with mouse
# Or press Ctrl+a [ and use arrows
```

Your scrollback should work perfectly now! 📜✨