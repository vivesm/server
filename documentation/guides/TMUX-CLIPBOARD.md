# tmux Clipboard and Selection Guide

## Problem: Can't Select Text in tmux

When using tmux over SSH, text selection fails because tmux intercepts mouse events.

## Solutions

### Option 1: Disable Mouse Mode (Simple)

```bash
# Add to ~/.tmux.conf
set -g mouse off

# Apply changes
tmux source-file ~/.tmux.conf
```

**Pros**: Terminal handles selection normally  
**Cons**: Lose tmux mouse features (scrolling, pane selection)

### Option 2: Hold Shift (Quick Workaround)

Keep mouse mode enabled and hold `Shift` while selecting:
- **macOS Terminal/iTerm2**: Hold `Shift` + drag to select
- **Linux**: Hold `Shift` + drag to select
- **Windows Terminal**: Hold `Shift` + drag to select

### Option 3: OSC52 Clipboard Sync (Best)

Keep tmux features AND sync clipboard over SSH:

```bash
# Add to ~/.tmux.conf
set -g mouse on
set -g set-clipboard on
set -g allow-passthrough on

# Bind copy to use OSC52
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy || xclip -sel clip || wl-copy"
bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "pbcopy || xclip -sel clip || wl-copy"
bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy || xclip -sel clip || wl-copy"
```

For pure OSC52 (no external tools):
```bash
# OSC52 copy function
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "base64 -w0 | sed 's/^/\x1b]52;c;/' | sed 's/$/\x07/'"
```

## Terminal Configuration

### iTerm2
1. Preferences → General → Selection
2. Enable "Applications in terminal may access clipboard"
3. Enable "Allow clipboard access to terminal apps"

### Terminal.app (macOS)
OSC52 enabled by default

### Windows Terminal
1. Settings → Interaction
2. Enable "Copy on select"

### Alacritty
Add to `~/.config/alacritty/alacritty.yml`:
```yaml
selection:
  save_to_clipboard: true
```

## Complete tmux Config

```bash
cat > ~/.tmux.conf << 'EOF'
# Enable mouse
set -g mouse on

# Increase scrollback
set -g history-limit 50000

# OSC52 clipboard support
set -g set-clipboard on
set -g allow-passthrough on

# Copy mode bindings
setw -g mode-keys vi
bind -T copy-mode-vi v send-keys -X begin-selection
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy 2>/dev/null || xclip -sel clip 2>/dev/null || wl-copy 2>/dev/null || base64 -w0 | sed 's/^/\x1b]52;c;/' | sed 's/$/\x07/'"
bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "pbcopy 2>/dev/null || xclip -sel clip 2>/dev/null || wl-copy 2>/dev/null || base64 -w0 | sed 's/^/\x1b]52;c;/' | sed 's/$/\x07/'"
bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy 2>/dev/null || xclip -sel clip 2>/dev/null || wl-copy 2>/dev/null || base64 -w0 | sed 's/^/\x1b]52;c;/' | sed 's/$/\x07/'"

# Double-click to select word
bind -T copy-mode-vi DoubleClick1Pane select-pane \; send-keys -X select-word
bind -n DoubleClick1Pane select-pane \; copy-mode -M \; send-keys -X select-word

# Triple-click to select line
bind -T copy-mode-vi TripleClick1Pane select-pane \; send-keys -X select-line
bind -n TripleClick1Pane select-pane \; copy-mode -M \; send-keys -X select-line
EOF
```

## Testing Your Setup

1. **Test OSC52**:
   ```bash
   echo "test" | base64 | sed 's/^/\x1b]52;c;/' | sed 's/$/\x07/'
   ```
   Should copy "test" to your local clipboard

2. **Test tmux copy**:
   - Run `seq 1 100`
   - Enter copy mode: `Ctrl+b [`
   - Select text with mouse or `v` + arrow keys
   - Copy with `y` or `Enter`
   - Paste locally to verify

## Troubleshooting

### Selection disappears immediately
- Hold `Shift` while selecting
- Or disable mouse: `set -g mouse off`

### Clipboard not syncing
- Check terminal supports OSC52
- Verify `allow-passthrough` is on
- Try the pure OSC52 method

### Copy mode exits on release
```bash
# Stay in copy mode after mouse selection
set -g @copy_mode_exit "off"
```

### Can't paste
- tmux paste: `Ctrl+b ]`
- System paste: `Cmd+V` (macOS) or `Ctrl+Shift+V` (Linux)

## Pro Tips

1. **Quick copy line**: Triple-click to select entire line
2. **Rectangle selection**: `Ctrl+v` in copy mode
3. **Search and copy**: `/` in copy mode to search
4. **Save buffer**: `Ctrl+b :` then `save-buffer ~/clipboard.txt`

## References

- [OSC52 Specification](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands)
- [tmux clipboard integration](https://github.com/tmux/tmux/wiki/Clipboard)