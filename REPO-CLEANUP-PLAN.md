# Repository Cleanup Plan

## Current Issues
1. Too many files in root directory
2. Duplicate service files (mcp services)
3. Mixed concerns (scripts, docs, configs)
4. WordPress-related files (service removed)
5. Temporary/test files

## Proposed Structure
```
server/
├── README.md                    # Main project overview
├── CLAUDE.md                    # AI assistant instructions
├── .gitignore                   
├── scripts/                     # All executable scripts
│   ├── backup/
│   │   ├── backup-all.sh
│   │   └── backup-secrets.sh
│   ├── setup/
│   │   ├── install-docker.sh
│   │   ├── install-tailscale.sh
│   │   └── setup-passwordless-sudo.sh
│   ├── security/
│   │   └── lockdown.sh
│   ├── tmux/
│   │   ├── tmux-setup.sh
│   │   ├── fix-tmux-scrolling.sh
│   │   └── fix-tmux-mouse-selection.sh
│   └── utilities/
│       ├── get-tailscale-ip.sh
│       ├── start-portainer.sh
│       └── stop-portainer.sh
├── archives/                    # Old/deprecated files
│   ├── mcp-services/           # Old service definitions
│   └── wordpress/              # Removed WordPress scripts
├── documentation/              # Already organized
├── docker-stack-infrastructure/ # Already organized
└── n8n-backups/               # Critical backups

## Files to Remove/Archive
- All *.service files (move to archives/mcp-services/)
- WordPress-related scripts (move to archives/wordpress/)
- Test files (test-post.md, tmux-guide-formatted.html)
- Temporary docs (emergency-access.md, safe-lockdown-steps.md)
- Old docker-compose.yml in root
- Password files (n8n_password.txt)

## Files to Keep in Root
- README.md (create comprehensive one)
- CLAUDE.md
- .gitignore
- Main directories only