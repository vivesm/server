# Persistent Remote Coding Environment via tmux
**For iPhone SSH Access to Ubuntu VPS**

## 🎯 Objective
Maintain persistent coding sessions on Ubuntu VPS via iPhone terminal apps, ensuring no work is lost during disconnections, app sleep, or network changes.

## 📱 Recommended iPhone Terminal Apps
1. **Blink Shell** (Premium, best for coding)
2. **Termius** (Free with premium options)
3. **a-Shell** (Free, basic but functional)

## 🚀 Quick Start

### One-Time Setup (5 minutes)
```bash
# Install tmux and create automated setup
curl -sSL https://raw.githubusercontent.com/yourusername/dotfiles/main/tmux-setup.sh | bash
```

Or manually:

## 📋 Phase 1: Environment Preparation

### 1.1 Update System & Install tmux
```bash
# Update package lists
sudo apt update

# Install tmux
sudo apt install tmux -y

# Verify installation
tmux -V
```

### 1.2 Create SSH Key for iPhone (if not done)
```bash
# On VPS, add your iPhone's SSH key to authorized_keys
echo "YOUR_IPHONE_SSH_PUBLIC_KEY" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### 1.3 Configure SSH for Better Mobile Experience
```bash
# Edit SSH client config on VPS
cat >> ~/.ssh/config << 'EOF'
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes
EOF
```

## 🖥️ Phase 2: Create Persistent Session

### 2.1 Basic Session Creation
```bash
# Start new session named 'vibe'
tmux new -s vibe

# Start with specific window name
tmux new -s vibe -n coding
```

### 2.2 Enhanced tmux Configuration
Create `~/.tmux.conf`:
```bash
cat > ~/.tmux.conf << 'EOF'
# Better mobile experience
set -g mouse on
set -g history-limit 10000

# Status bar customization
set -g status-bg black
set -g status-fg white
set -g status-left '#[fg=green]#S '
set -g status-right '#[fg=yellow]%H:%M %d-%b-%y'

# Easy splitting
bind | split-window -h
bind - split-window -v

# Reload config
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Better copy mode for iPhone
setw -g mode-keys vi
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send -X copy-selection-and-cancel

# Prevent accidental detach
bind-key d confirm-before -p "detach? (y/n)" detach

# Activity monitoring
setw -g monitor-activity on
set -g visual-activity on

# iPhone-friendly window switching
bind-key -n C-n next-window
bind-key -n C-p previous-window
EOF
```

## 📱 Phase 3: Disconnection Handling

### 3.1 Essential Commands
```bash
# Detach session (keeps it running)
Ctrl + b, then d

# List active sessions
tmux ls

# Reattach to session
tmux attach -t vibe

# Attach and detach others
tmux attach -d -t vibe
```

### 3.2 Connection Recovery Script
```bash
# Create recovery script
cat > ~/tmux-recover.sh << 'EOF'
#!/bin/bash
# Auto-recover tmux session

SESSION="vibe"

# Check if session exists
tmux has-session -t $SESSION 2>/dev/null

if [ $? != 0 ]; then
    # Create new session
    tmux new-session -d -s $SESSION -n main
    tmux send-keys -t $SESSION "cd ~/projects" C-m
    tmux send-keys -t $SESSION "clear" C-m
    echo "Created new session: $SESSION"
else
    echo "Session $SESSION exists"
fi

# Attach to session
tmux attach -t $SESSION
EOF

chmod +x ~/tmux-recover.sh
```

## 🤖 Phase 4: Automation

### 4.1 Shell Aliases
```bash
# Add to ~/.bashrc
cat >> ~/.bashrc << 'EOF'

# tmux aliases for mobile
alias vibe='tmux attach -t vibe || tmux new -s vibe'
alias tl='tmux ls'
alias tn='tmux new -s'
alias ta='tmux attach -t'
alias tk='tmux kill-session -t'

# Auto-attach on SSH login (optional)
if [[ -n "$SSH_CLIENT" ]] && [[ -z "$TMUX" ]]; then
    tmux attach -t vibe 2>/dev/null || tmux new -s vibe
fi
EOF

# Reload bashrc
source ~/.bashrc
```

### 4.2 Create Session Templates
```bash
# Development environment setup
cat > ~/tmux-dev.sh << 'EOF'
#!/bin/bash
SESSION="dev"

tmux new-session -d -s $SESSION -n editor
tmux send-keys -t $SESSION:editor "cd ~/projects" C-m
tmux send-keys -t $SESSION:editor "vim" C-m

tmux new-window -t $SESSION -n terminal
tmux send-keys -t $SESSION:terminal "cd ~/projects" C-m

tmux new-window -t $SESSION -n logs
tmux send-keys -t $SESSION:logs "tail -f /var/log/syslog" C-m

tmux select-window -t $SESSION:editor
tmux attach -t $SESSION
EOF

chmod +x ~/tmux-dev.sh
```

## 🔧 Phase 5: Advanced Session Management

### 5.1 Multiple Sessions Setup
```bash
# Create work environments
cat > ~/tmux-workspaces.sh << 'EOF'
#!/bin/bash

case "$1" in
    "web")
        tmux new -s web -n frontend -d
        tmux new-window -t web -n backend
        tmux new-window -t web -n database
        tmux attach -t web
        ;;
    "ops")
        tmux new -s ops -n monitor -d
        tmux new-window -t ops -n logs
        tmux new-window -t ops -n ssh
        tmux attach -t ops
        ;;
    "list")
        tmux ls
        ;;
    *)
        echo "Usage: $0 {web|ops|list}"
        ;;
esac
EOF

chmod +x ~/tmux-workspaces.sh
```

### 5.2 Session Persistence & Backup
```bash
# Install tmux-resurrect for session saving
git clone https://github.com/tmux-plugins/tmux-resurrect ~/.tmux/plugins/tmux-resurrect

# Add to ~/.tmux.conf
echo "run-shell ~/.tmux/plugins/tmux-resurrect/resurrect.tmux" >> ~/.tmux.conf

# Save session: Ctrl+b, Ctrl+s
# Restore session: Ctrl+b, Ctrl+r
```

### 5.3 Collaborative Sessions
```bash
# Share read-only session
tmux new -s shared
# Other user: tmux attach -t shared -r

# Named pipes for collaboration
tmux -S /tmp/shared-session new -s collab
chmod 777 /tmp/shared-session
# Other user: tmux -S /tmp/shared-session attach
```

## 📱 iPhone-Specific Tips

### Touch-Friendly Key Bindings
```bash
# Add to ~/.tmux.conf
# Use Option+Arrow for pane navigation (easier on iPhone)
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D
```

### Blink Shell Configuration
```bash
# In Blink Shell, create a host:
# Host: vps
# Hostname: your.server.ip
# User: yourusername
# Key: your-key

# Then connect with:
# mosh vps -- tmux attach -t vibe
```

### Quick Access Widget
```bash
# Create a quick command
echo 'alias q="tmux attach -t vibe || tmux new -s vibe"' >> ~/.bashrc

# Now just type 'q' to connect
```

## 🛡️ Security Considerations

### Secure Your Sessions
```bash
# Lock session when away
# Ctrl+b, x (requires password to unlock)

# Set lock command in ~/.tmux.conf
set -g lock-command vlock
set -g lock-after-time 300  # 5 minutes
```

## 🚨 Troubleshooting

### Common Issues:
1. **"sessions should be nested with care"**
   ```bash
   # Exit current tmux before starting new
   exit  # or Ctrl+d
   ```

2. **Can't create session**
   ```bash
   # Check for existing sessions
   tmux ls
   # Kill all sessions
   tmux kill-server
   ```

3. **Lost in tmux**
   ```bash
   # Show current session info
   Ctrl+b, i
   ```

## 📊 Status Line Customization
```bash
# Professional status line for coding
cat >> ~/.tmux.conf << 'EOF'
# Status line
set -g status-interval 1
set -g status-left-length 30
set -g status-left '#[fg=green](#S) #(whoami)@#h '
set -g status-right '#[fg=yellow]#(cut -d " " -f 1-3 /proc/loadavg)#[default] #[fg=white]%H:%M:%S#[default]'
EOF
```

## 🎯 Quick Reference Card

| Action | Command |
|--------|---------|
| New session | `tmux new -s name` |
| List sessions | `tmux ls` |
| Attach | `tmux attach -t name` |
| Detach | `Ctrl+b, d` |
| New window | `Ctrl+b, c` |
| Next window | `Ctrl+b, n` |
| Split horizontal | `Ctrl+b, %` |
| Split vertical | `Ctrl+b, "` |
| Switch pane | `Ctrl+b, arrow` |
| Kill pane | `Ctrl+b, x` |
| Zoom pane | `Ctrl+b, z` |

## 🎉 You're Ready!

With this setup, you can:
- Code from your iPhone anywhere
- Never lose work due to disconnections
- Manage multiple projects simultaneously
- Collaborate with team members

Just type `vibe` to start coding!