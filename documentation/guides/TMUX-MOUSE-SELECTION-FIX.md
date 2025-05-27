# Fix tmux Mouse Selection in iTerm2
**Problem**: Text selection immediately unhighlights in tmux, even with OSC52 enabled
**Solution**: Completely disable tmux mouse handling and unbind interfering commands

## The Root Cause

Even with `mouse off`, tmux may still have mouse bindings that interfere with terminal selection. Some tmux builds, plugins, or configurations silently re-enable mouse handling or have default mouse bindings that cancel selections.

## Complete Fix

### Step 1: Fully Disable Mouse in tmux

Add ALL of these lines to `~/.tmux.conf`:

```bash
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
```

### Step 2: Reload Configuration

```bash
# Inside tmux
tmux source-file ~/.tmux.conf

# Or from outside
tmux source ~/.tmux.conf
```

### Step 3: Restart tmux Completely

```bash
# Kill all tmux sessions
tmux kill-server

# Start fresh
tmux new -s main
```

### Step 4: Verify Mouse is Disabled

```bash
# Check mouse setting
tmux show -gv mouse

# Should output: off
```

## Testing Selection

1. Click and drag to select text
2. Selection should remain highlighted
3. Use Cmd+C or right-click → Copy
4. Paste elsewhere to verify

## iTerm2 Settings (Verify These)

1. **iTerm2 → Preferences → General → Selection**
   - ✅ "Copy to pasteboard on selection"
   - ✅ "Applications in terminal may access clipboard"

2. **iTerm2 → Preferences → Advanced**
   - Search for "OSC"
   - Set "When receiving OSC 52 escape sequence" to "Always"

## Troubleshooting

### Selection Still Clears?

1. **Check for plugins overriding settings:**
```bash
# List all mouse-related settings
tmux show-options -g | grep mouse

# Check for any mouse bindings
tmux list-keys | grep -i mouse
```

2. **Find conflicting configs:**
```bash
# Search for mouse commands in all tmux configs
grep -r "mouse" ~/.tmux* ~/.config/tmux* 2>/dev/null
```

3. **Check for auto-loading configs:**
```bash
# Some systems have global tmux configs
ls -la /etc/tmux.conf /usr/local/etc/tmux.conf 2>/dev/null
```

### Nuclear Option - Strip All Mouse Support

Create a file `~/.tmux-no-mouse.conf`:

```bash
# Complete mouse disable configuration
set -g mouse off

# Unbind everything mouse-related
unbind-key -a -T root MouseDown1Pane
unbind-key -a -T root MouseDrag1Pane
unbind-key -a -T root MouseUp1Pane
unbind-key -a -T root WheelUpPane
unbind-key -a -T root WheelDownPane
unbind-key -a -T copy-mode
unbind-key -a -T copy-mode-vi

# Re-bind only essential keys (no mouse)
bind-key -T prefix c new-window
bind-key -T prefix d detach-client
bind-key -T prefix [ copy-mode
```

Then start tmux with:
```bash
tmux -f ~/.tmux-no-mouse.conf new -s test
```

## Alternative Workflows

### Use Terminal Selection Instead of tmux
With mouse disabled, your terminal handles all selection:
- **iTerm2**: Native selection works perfectly
- **Copy**: Cmd+C after selecting
- **Paste**: Cmd+V anywhere

### Keyboard-Only Copy in tmux
```bash
# Enter copy mode
Ctrl+b [

# Navigate with arrows
# Start selection with Space
# End selection with Enter
# Paste with Ctrl+b ]
```

## Quick Diagnostic Script

Create `diagnose-tmux-mouse.sh`:

```bash
#!/bin/bash
echo "🔍 Diagnosing tmux mouse issues..."
echo ""

# Check tmux version
echo "tmux version: $(tmux -V)"
echo ""

# Check mouse setting
echo "Mouse setting: $(tmux show -gv mouse 2>/dev/null || echo 'not set')"
echo ""

# Check for mouse bindings
echo "Mouse bindings found:"
tmux list-keys | grep -i mouse | wc -l
echo ""

# Check for conflicting configs
echo "Config files:"
ls -la ~/.tmux.conf ~/.tmux/*.conf 2>/dev/null || echo "No config files found"
echo ""

# Test selection
echo "📋 To test selection:"
echo "1. Select this text with your mouse"
echo "2. It should stay highlighted"
echo "3. Copy with Cmd+C"
echo ""

# Offer fix
echo "🔧 To apply the fix, run:"
echo "tmux source-file ~/.tmux.conf && tmux kill-server"
```

## Best Practices

1. **Keep mouse disabled** for consistent behavior
2. **Use terminal's native selection** (more reliable)
3. **Learn keyboard shortcuts** as backup
4. **Document what works** for your specific setup
5. **Test after tmux updates** (settings can revert)

## The Ultimate Test

After applying all fixes:

```bash
# Generate text to select
seq 1 100

# Try selecting multiple lines
# Selection should persist
# Copy should work
```

If this still doesn't work, the issue may be:
- A tmux plugin re-enabling mouse
- A terminal emulator bug
- SSH client interfering

---
*With these settings, mouse selection should work like a normal terminal!*