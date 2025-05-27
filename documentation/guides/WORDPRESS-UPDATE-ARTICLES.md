# Updating WordPress Articles via REST API
**Created**: 2025-05-27

## Overview

This guide covers how to update existing WordPress articles using the REST API, including lessons learned from our implementation.

## Key Lessons Learned

### 1. Content Formatting Issues

**Problem**: Basic bash/sed conversions result in posts with only titles or partial content.

**Solution**: Use proper JSON encoding and comprehensive HTML conversion:
- Python handles JSON encoding correctly
- Escape HTML entities in code blocks (`&`, `<`, `>`)
- Preserve formatting with proper paragraph tags
- Use WordPress block editor classes for better styling

### Important Discovery: HTML Tag Display Issue

**Problem**: Some posts show raw HTML tags instead of rendered content (e.g., `<h2>Overview</h2>` appears as text).

**Root Cause**: This happens when content is double-escaped or when WordPress treats HTML as plain text. Common with bash script posting due to improper JSON encoding.

**Solution**: 
1. Always use the Python publisher (`wp-publisher.py`) for new posts
2. For existing posts with HTML display issues, re-publish them using the Python script
3. The bash script's `sed` and `echo` commands don't properly handle JSON encoding, leading to escaped HTML

### 2. Content Security Policy (CSP)

**Problem**: Strict CSP headers block WordPress content and scripts.

**Solution**: Remove CSP headers for WordPress in Caddy configuration:
```nginx
# WordPress-specific headers (CSP removed)
(wordpress_headers) {
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-XSS-Protection "1; mode=block"
        X-Frame-Options "SAMEORIGIN"
        Referrer-Policy "strict-origin-when-cross-origin"
        # CSP removed for WordPress compatibility
        -Server
    }
}
```

## Updating Articles

### Find Article ID

First, search for the article you want to update:

```bash
# Search by title
curl -s "https://wp.stringbits.com/wp-json/wp/v2/posts?search=tmux" \
  -u "itservice:YOUR_APP_PASSWORD" | grep -E '"id":|"title":'

# Get specific post by ID
curl -s "https://wp.stringbits.com/wp-json/wp/v2/posts/7" \
  -u "itservice:YOUR_APP_PASSWORD"
```

### Update Methods

#### Method 1: Full Content Update (Recommended)

```python
#!/usr/bin/env python3
import json
import subprocess

def update_post(post_id, new_content, title=None):
    """Update a WordPress post with new content"""
    
    # Prepare update data
    update_data = {
        'content': new_content
    }
    
    if title:
        update_data['title'] = title
    
    # Save to temp file
    with open('/tmp/update-post.json', 'w') as f:
        json.dump(update_data, f)
    
    # Update via API
    cmd = [
        'curl', '-X', 'POST',
        f'https://wp.stringbits.com/wp-json/wp/v2/posts/{post_id}',
        '-u', 'itservice:YOUR_APP_PASSWORD',
        '-H', 'Content-Type: application/json',
        '-d', '@/tmp/update-post.json',
        '-s'
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    response = json.loads(result.stdout)
    
    if 'id' in response:
        print(f"✅ Updated post {post_id}")
        print(f"   URL: {response['link']}")
    else:
        print(f"❌ Failed to update: {response}")

# Example usage
html_content = """
<h2>Updated Content</h2>
<p>This article has been updated with new information.</p>
<pre class="wp-block-code"><code>echo "Hello, World!"</code></pre>
"""

update_post(7, html_content, "New Title (Optional)")
```

#### Method 2: Partial Update

Update only specific fields:

```bash
# Update just the title
curl -X POST https://wp.stringbits.com/wp-json/wp/v2/posts/7 \
  -u "itservice:YOUR_APP_PASSWORD" \
  -H "Content-Type: application/json" \
  -d '{"title": "Updated Title"}'

# Update excerpt
curl -X POST https://wp.stringbits.com/wp-json/wp/v2/posts/7 \
  -u "itservice:YOUR_APP_PASSWORD" \
  -H "Content-Type: application/json" \
  -d '{"excerpt": "New summary of the article"}'

# Change status (draft, publish, pending, private)
curl -X POST https://wp.stringbits.com/wp-json/wp/v2/posts/7 \
  -u "itservice:YOUR_APP_PASSWORD" \
  -H "Content-Type: application/json" \
  -d '{"status": "draft"}'
```

## Complete Update Script

Here's a complete script that can update posts from markdown files:

```python
#!/usr/bin/env python3
"""
wp-updater.py - Update existing WordPress posts from markdown files
"""

import json
import subprocess
import re
import sys
import os

def markdown_to_html(content):
    """Convert markdown to HTML (same as wp-publisher.py)"""
    # Headers
    content = re.sub(r'^### (.+)$', r'<h3>\1</h3>', content, flags=re.MULTILINE)
    content = re.sub(r'^## (.+)$', r'<h2>\1</h2>', content, flags=re.MULTILINE)
    content = re.sub(r'^# (.+)$', r'<h1>\1</h1>', content, flags=re.MULTILINE)
    
    # Code blocks with escaping
    def escape_code(match):
        lang = match.group(1) or ''
        code = match.group(2)
        code = code.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
        if lang:
            return f'<pre class="wp-block-code"><code class="language-{lang}">{code}</code></pre>'
        return f'<pre class="wp-block-code"><code>{code}</code></pre>'
    
    content = re.sub(r'```(\w*)\n(.*?)\n```', escape_code, content, flags=re.DOTALL)
    
    # Inline code, bold, italic, links
    content = re.sub(r'`([^`]+)`', r'<code>\1</code>', content)
    content = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', content)
    content = re.sub(r'(?<!\*)\*([^*]+)\*(?!\*)', r'<em>\1</em>', content)
    content = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', content)
    
    # Lists and paragraphs (simplified)
    lines = content.split('\n\n')
    formatted = []
    for line in lines:
        line = line.strip()
        if line and not line.startswith('<'):
            formatted.append(f'<p>{line}</p>')
        else:
            formatted.append(line)
    
    return '\n'.join(formatted)

def find_post_by_title(title, username, password):
    """Find post ID by title"""
    cmd = [
        'curl', '-s',
        f'https://wp.stringbits.com/wp-json/wp/v2/posts?search={title}&per_page=5',
        '-u', f'{username}:{password}'
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    posts = json.loads(result.stdout)
    
    for post in posts:
        if post['title']['rendered'].lower() == title.lower():
            return post['id']
    
    # Return first match if no exact match
    return posts[0]['id'] if posts else None

def update_post(post_id, content, title=None, username='itservice', password='YOUR_APP_PASSWORD'):
    """Update WordPress post"""
    update_data = {'content': content}
    if title:
        update_data['title'] = title
    
    with open('/tmp/wp-update.json', 'w') as f:
        json.dump(update_data, f)
    
    cmd = [
        'curl', '-X', 'POST',
        f'https://wp.stringbits.com/wp-json/wp/v2/posts/{post_id}',
        '-u', f'{username}:{password}',
        '-H', 'Content-Type: application/json',
        '-d', '@/tmp/wp-update.json',
        '-s'
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    response = json.loads(result.stdout)
    
    if 'id' in response:
        print(f"✅ Updated: {response['title']['rendered']}")
        print(f"   URL: {response['link']}")
        return True
    else:
        print(f"❌ Error: {response}")
        return False

# Example usage
if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: wp-updater.py <post-id-or-title> <markdown-file>")
        sys.exit(1)
    
    post_ref = sys.argv[1]
    md_file = sys.argv[2]
    
    # Read markdown file
    with open(md_file, 'r') as f:
        content = f.read()
    
    # Convert to HTML
    html_content = markdown_to_html(content)
    
    # Update post
    if post_ref.isdigit():
        update_post(int(post_ref), html_content)
    else:
        post_id = find_post_by_title(post_ref, 'itservice', 'YOUR_APP_PASSWORD')
        if post_id:
            update_post(post_id, html_content)
        else:
            print(f"❌ Post not found: {post_ref}")
```

## Common Update Scenarios

### 1. Fix Formatting Issues

If a post only shows title/partial content:
```python
# Get current post
curl -s https://wp.stringbits.com/wp-json/wp/v2/posts/7 \
  -u "itservice:YOUR_APP_PASSWORD" > post.json

# Extract and fix content
# Then update with properly formatted HTML
```

### 2. Bulk Updates

Update multiple posts:
```bash
for post_id in 7 8 9; do
    echo "Updating post $post_id..."
    curl -X POST https://wp.stringbits.com/wp-json/wp/v2/posts/$post_id \
      -u "itservice:YOUR_APP_PASSWORD" \
      -H "Content-Type: application/json" \
      -d '{"categories": [3]}' \
      -s > /dev/null
done
```

### 3. Add Media to Posts

```bash
# First upload image
curl -X POST https://wp.stringbits.com/wp-json/wp/v2/media \
  -u "itservice:YOUR_APP_PASSWORD" \
  -H "Content-Disposition: attachment; filename=image.jpg" \
  --data-binary @image.jpg

# Then update post with image HTML
```

## Troubleshooting

### Content Not Displaying

1. **Check JSON encoding**: Use Python or `jq` for proper encoding
2. **Verify HTML**: WordPress may strip invalid HTML
3. **Check response**: Always parse API response for errors

### 403/401 Errors

1. **Verify credentials**: Test with `GET` request first
2. **Check permissions**: User needs edit_posts capability
3. **Application password**: Ensure it hasn't been revoked

### Content Blocked

1. **Remove CSP headers**: Done in Caddy for WordPress
2. **Check theme**: Some themes have additional restrictions
3. **Plugin conflicts**: Disable security plugins temporarily

## Best Practices

1. **Always backup**: Save original content before updating
2. **Test first**: Update a test post before production
3. **Use revisions**: WordPress tracks changes automatically
4. **Validate HTML**: Ensure proper formatting
5. **Handle errors**: Check API responses

## Example: Update This Guide

```bash
# This very guide can be updated with:
./wp-updater.py "Updating WordPress Articles" ./WORDPRESS-UPDATE-ARTICLES.md
```

## API Reference

Key endpoints for updates:
- `GET /wp/v2/posts/{id}` - Retrieve post
- `POST /wp/v2/posts/{id}` - Update post  
- `DELETE /wp/v2/posts/{id}` - Delete post
- `GET /wp/v2/posts/{id}/revisions` - View history

Updateable fields:
- `title` - Post title
- `content` - Post content (HTML)
- `excerpt` - Post summary
- `status` - publish, draft, pending, private
- `categories` - Array of category IDs
- `tags` - Array of tag IDs
- `featured_media` - Featured image ID
- `meta` - Custom fields