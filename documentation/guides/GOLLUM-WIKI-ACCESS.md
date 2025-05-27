# Accessing Documentation via Gollum Wiki

## Overview

Gollum is a simple, Git-powered wiki that provides a web interface for viewing and editing your documentation.

## Access Methods

### 1. Direct Access (Tailscale Only)
- **URL**: http://100.112.235.46:4567
- **Access**: Only from Tailscale network
- **Mode**: Read-only (default) or editable

### 2. HTTPS Access via Caddy
- **URL**: https://docs.stringbits.com
- **Access**: Public but shows documentation
- **SSL**: Automatic via Caddy

## Features

### Current Configuration
- **Read-only mode**: Prevents accidental edits
- **Live preview**: See changes as you type (if editing enabled)
- **Sidebar navigation**: Easy document browsing
- **Table of Contents**: Auto-generated for long documents
- **Search**: Full-text search across all documentation
- **Emoji support**: Use :+1: and other emojis
- **Math support**: LaTeX math formulas with MathJax

### Document Structure
```
/wiki (documentation/)
├── README.md                    # Home page
├── TOOLS-AND-SCRIPTS.md        # Scripts index
├── QUICK-REFERENCE.md          # Quick reference
├── setup/                      # Setup guides
├── security/                   # Security docs
├── guides/                     # How-to guides
└── architecture/              # Architecture docs
```

## Switching Between Modes

### Read-Only Mode (Default)
```bash
cd docker-stack-infrastructure
docker compose -f docker-compose/gollum.yml up -d
```

### Editable Mode
```bash
cd docker-stack-infrastructure
docker compose -f docker-compose/gollum-editable.yml up -d
```

## Navigation Tips

1. **Home Page**: Click the wiki title or "Home" link
2. **Page History**: Click "History" on any page
3. **Search**: Use the search box in the header
4. **Create New Page**: In edit mode, create links to non-existent pages
5. **Upload Files**: In edit mode, use the upload feature

## Custom Styling

Gollum supports custom CSS. To add your own styles:

1. Create `/config/custom.css` in the container
2. Add your CSS rules
3. Restart Gollum

Example custom CSS:
```css
/* Better code blocks */
pre {
    background-color: #f4f4f4;
    border-radius: 5px;
    padding: 15px;
    overflow-x: auto;
}

/* Larger fonts for readability */
body {
    font-size: 16px;
    line-height: 1.6;
}

/* Better table styling */
table {
    border-collapse: collapse;
    width: 100%;
    margin: 15px 0;
}

th, td {
    border: 1px solid #ddd;
    padding: 12px;
    text-align: left;
}

th {
    background-color: #f2f2f2;
}
```

## Security

- **Network**: Only accessible from Tailscale network
- **Authentication**: Can be enabled in environment variables
- **Permissions**: Runs as non-root user
- **Updates**: Auto-updated via Watchtower

## Troubleshooting

### Can't Access Wiki
```bash
# Check if running
docker ps | grep gollum

# Check logs
docker logs gollum

# Restart
docker restart gollum
```

### Search Not Working
- Gollum indexes on startup
- For large wikis, wait a moment after starting

### Changes Not Saving
- Check if in read-only mode
- Verify volume mount permissions
- Check disk space

## Integration with Git

Since Gollum is Git-backed:
```bash
# View recent changes
cd /home/melvin/projects/server/documentation
git log --oneline -10

# See what changed
git diff

# Commit changes made via Gollum
git add .
git commit -m "Documentation updates via Gollum"
```

## Best Practices

1. **Use Markdown**: All docs should be .md files
2. **Meaningful Names**: Use descriptive file names
3. **Organize Well**: Use folders for categories
4. **Link Between Docs**: Create cross-references
5. **Regular Backups**: Commit changes to Git

## Quick Links

After starting Gollum, access:
- **Home**: http://100.112.235.46:4567
- **All Pages**: http://100.112.235.46:4567/pages
- **Search**: http://100.112.235.46:4567/search

---
*Gollum makes documentation accessible and maintainable!*