# WordPress Documentation Publishing Guide
**Created**: 2025-01-26

## Overview

This guide explains how to publish infrastructure documentation to WordPress for team access and knowledge sharing.

**Important Security Note**: Content Security Policy (CSP) headers have been removed from the WordPress site configuration in Caddy for compatibility with WordPress themes and plugins. See the [WordPress API Setup Guide](./WORDPRESS-API-SETUP.md) for details.

## Quick Start - New Python Publisher

The bash script has limitations with content formatting. Use the new Python publisher for best results:

```bash
# Publish a single markdown file
./wp-publisher.py /path/to/guide.md "Post Title"

# Example
./wp-publisher.py documentation/guides/TMUX-SETUP.md

# The script will:
# - Convert markdown to proper HTML
# - Handle code blocks with syntax highlighting
# - Support tables, lists, and all formatting
# - Post the complete content to WordPress
```

## Prerequisites

1. **WordPress Running**
   ```bash
   docker ps | grep wordpress
   # Should show wordpress and mysql containers
   ```

2. **WordPress Installed**
   - Visit http://100.112.235.46:8080
   - Complete initial setup if needed

3. **Application Password**
   - Required for REST API access
   - More secure than using main password

## Setting Up WordPress

### Step 1: Initial Installation

If WordPress shows installation page:
```
1. Visit http://100.112.235.46:8080
2. Choose language
3. Set site title: "Infrastructure Documentation"
4. Create admin user
5. Save password securely
6. Complete installation
```

### Step 2: Create Application Password

1. Login to WordPress admin
2. Navigate to **Users → Your Profile**
3. Scroll to **Application Passwords** section
4. Enter name: "Documentation Publisher"
5. Click **Add New Application Password**
6. **Copy the password immediately** (shown only once!)

Example:
```
Username: admin
App Password: xxxx xxxx xxxx xxxx xxxx xxxx
```

### Step 3: Install Recommended Plugins

For better documentation display:
```
1. Go to Plugins → Add New
2. Search and install:
   - "SyntaxHighlighter Evolved" (code highlighting)
   - "Table of Contents Plus" (auto TOC)
   - "WP Markdown" (better markdown support)
3. Activate all plugins
```

## Publishing Documentation

### Method 1: Python Script (Recommended)

```bash
cd /home/melvin/projects/server

# Run the publisher
python3 wordpress-publisher.py <username> <app-password>

# Example:
python3 wordpress-publisher.py admin "xxxx xxxx xxxx xxxx xxxx xxxx"
```

Features:
- Better markdown conversion
- Automatic categorization
- Tag support
- Error handling

### Method 2: Bash Script

```bash
cd /home/melvin/projects/server

# Run the bash version
./post-to-wordpress.sh <username> <app-password>
```

### What Gets Published

| Document | Title | Category | Tags |
|----------|-------|----------|------|
| SECURITY-REVIEW.md | Security Review Report | Infrastructure Documentation | security, docker, audit |
| service-access.md | Service Access Guide | Infrastructure Documentation | services, architecture |
| TODO.md | Security Lockdown TODO | Infrastructure Documentation | security, todo, tasks |
| TMUX-SETUP.md | Persistent Terminal Setup | Infrastructure Documentation | tmux, terminal, mobile |
| CLAUDE.md | Project Overview | Infrastructure Documentation | overview, documentation |

## Manual Publishing

### Via WordPress Editor

1. Login to WordPress admin
2. Go to **Posts → Add New**
3. Copy markdown content
4. Use "Text" tab (not Visual)
5. Paste and format
6. Set category: "Infrastructure Documentation"
7. Add relevant tags
8. Publish

### Via REST API

```bash
# Create a post manually
curl -X POST https://100.112.235.46:8080/wp-json/wp/v2/posts \
  -H "Content-Type: application/json" \
  -u "username:app-password" \
  -d '{
    "title": "Document Title",
    "content": "HTML content here",
    "status": "publish",
    "categories": [1]
  }'
```

## Customizing Publication

### Update Publisher Scripts

Edit `wordpress-publisher.py` to:
- Add new documents
- Change categories
- Modify conversion rules
- Add custom fields

Example:
```python
docs = [
    {
        "file": "documentation/new-guide.md",
        "title": "New Guide Title",
        "tags": ["guide", "custom"]
    }
]
```

### WordPress Theme Customization

For better documentation display:
1. Go to **Appearance → Customize**
2. Adjust typography for readability
3. Increase content width
4. Add custom CSS for code blocks

Recommended CSS:
```css
/* Better code display */
pre {
    background: #f4f4f4;
    padding: 15px;
    overflow-x: auto;
    border-radius: 5px;
}

/* Documentation styling */
.infrastructure-documentation {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    line-height: 1.6;
}
```

## Organizing Documentation

### Categories Structure
```
Infrastructure Documentation
├── Security
├── Setup Guides  
├── Architecture
├── How-To Guides
└── Maintenance
```

### Tagging Strategy
- Use technology tags: docker, tailscale, nginx
- Add type tags: guide, reference, tutorial
- Include status: draft, review, published

## Maintenance

### Regular Updates
```bash
# Schedule weekly documentation updates
crontab -e

# Add:
0 9 * * 1 cd /home/melvin/projects/server && python3 wordpress-publisher.py admin "password"
```

### Backup WordPress
```bash
# Backup database
docker exec mysql mysqldump -u root -prootpassword wordpress > wordpress-backup.sql

# Backup files
tar -czf wordpress-files.tar.gz /home/shared/docker/wordpress/
```

## Troubleshooting

### Common Issues

1. **401 Unauthorized**
   - Check username and password
   - Ensure Application Password is used
   - Verify user has publish permissions

2. **Connection Refused**
   - Check WordPress is running
   - Verify correct URL/port
   - Check firewall rules

3. **Conversion Issues**
   - Review markdown syntax
   - Check for special characters
   - Test with simple content first

### Debug Mode

```python
# Enable debug in publisher
response = requests.post(url, ...)
print(f"Status: {response.status_code}")
print(f"Response: {response.text}")
```

## Best Practices

1. **Version Control**
   - Keep documentation in git
   - Tag published versions
   - Track changes

2. **Review Process**
   - Review before publishing
   - Use draft status first
   - Get team feedback

3. **Consistency**
   - Use templates
   - Maintain style guide
   - Regular updates

## Next Steps

1. Set up regular publishing schedule
2. Create documentation templates
3. Train team on WordPress usage
4. Implement review workflow
5. Set up analytics to track usage

---
*Documentation is only valuable if it's accessible and up-to-date*