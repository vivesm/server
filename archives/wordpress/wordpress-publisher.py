#!/usr/bin/env python3
"""
WordPress Documentation Publisher
Publishes markdown documentation to WordPress
"""

import requests
import json
import base64
import re
import sys
import time
from pathlib import Path

# WordPress configuration
WP_URL = "https://wp.stringbits.com"
WP_API_URL = f"{WP_URL}/wp-json/wp/v2"

class WordPressPublisher:
    def __init__(self, username, password):
        self.username = username
        self.password = password
        self.auth_header = self._create_auth_header()
        self.category_id = None
        
    def _create_auth_header(self):
        """Create basic auth header"""
        credentials = f"{self.username}:{self.password}"
        encoded = base64.b64encode(credentials.encode()).decode()
        return {"Authorization": f"Basic {encoded}"}
    
    def markdown_to_html(self, content):
        """Convert markdown to HTML with improved formatting"""
        import html
        
        # Escape HTML entities in code blocks first
        def escape_code_content(match):
            lang = match.group(1) or ''
            code = html.escape(match.group(2))
            if lang:
                return f'<pre class="wp-block-code"><code class="language-{lang}">{code}</code></pre>'
            else:
                return f'<pre class="wp-block-code"><code>{code}</code></pre>'
        
        # Code blocks with syntax highlighting (handle before other conversions)
        content = re.sub(r'```(\w*)\n(.*?)\n```', escape_code_content, content, flags=re.DOTALL)
        
        # Inline code (escape HTML)
        content = re.sub(r'`([^`]+)`', lambda m: f'<code>{html.escape(m.group(1))}</code>', content)
        
        # Headers (handle headers with # at line start)
        content = re.sub(r'^#### (.+)$', r'<h4>\1</h4>', content, flags=re.MULTILINE)
        content = re.sub(r'^### (.+)$', r'<h3>\1</h3>', content, flags=re.MULTILINE)
        content = re.sub(r'^## (.+)$', r'<h2>\1</h2>', content, flags=re.MULTILINE)
        content = re.sub(r'^# (.+)$', r'<h1>\1</h1>', content, flags=re.MULTILINE)
        
        # Links [text](url)
        content = re.sub(r'\[([^\]]+)\]\(([^\)]+)\)', r'<a href="\2">\1</a>', content)
        
        # Images ![alt](url)
        content = re.sub(r'!\[([^\]]*)\]\(([^\)]+)\)', r'<img src="\2" alt="\1" />', content)
        
        # Bold (handle before italic to avoid conflicts)
        content = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', content)
        content = re.sub(r'__([^_]+)__', r'<strong>\1</strong>', content)
        
        # Italic
        content = re.sub(r'\*([^*]+)\*', r'<em>\1</em>', content)
        content = re.sub(r'_([^_]+)_', r'<em>\1</em>', content)
        
        # Blockquotes
        content = re.sub(r'^> (.+)$', r'<blockquote>\1</blockquote>', content, flags=re.MULTILINE)
        
        # Horizontal rules
        content = re.sub(r'^---+$', r'<hr />', content, flags=re.MULTILINE)
        
        # Process lists with proper nesting
        lines = content.split('\n')
        new_lines = []
        list_stack = []  # Track list types (ul/ol) and indentation levels
        
        for line in lines:
            # Check for unordered list
            ul_match = re.match(r'^(\s*)[-*+] (.+)$', line)
            # Check for ordered list
            ol_match = re.match(r'^(\s*)\d+\. (.+)$', line)
            
            if ul_match or ol_match:
                if ul_match:
                    indent = len(ul_match.group(1))
                    item_content = ul_match.group(2)
                    list_type = 'ul'
                else:
                    indent = len(ol_match.group(1))
                    item_content = ol_match.group(2)
                    list_type = 'ol'
                
                # Calculate list level (assuming 2 or 4 spaces per level)
                level = indent // 2
                
                # Close lists if we're at a lower level
                while len(list_stack) > level:
                    closed = list_stack.pop()
                    new_lines.append(f'</{closed}>')
                
                # Open new list if needed
                if len(list_stack) == level:
                    if not list_stack or list_stack[-1] != list_type:
                        # Close different type list at same level
                        if list_stack:
                            closed = list_stack.pop()
                            new_lines.append(f'</{closed}>')
                        new_lines.append(f'<{list_type}>')
                        list_stack.append(list_type)
                    new_lines.append(f'<li>{item_content}</li>')
                else:
                    # We need to open lists to reach this level
                    while len(list_stack) < level:
                        new_lines.append(f'<{list_type}>')
                        list_stack.append(list_type)
                    new_lines.append(f'<{list_type}>')
                    list_stack.append(list_type)
                    new_lines.append(f'<li>{item_content}</li>')
            else:
                # Close all open lists if we hit non-list content
                while list_stack:
                    closed = list_stack.pop()
                    new_lines.append(f'</{closed}>')
                new_lines.append(line)
        
        # Close any remaining open lists
        while list_stack:
            closed = list_stack.pop()
            new_lines.append(f'</{closed}>')
        
        content = '\n'.join(new_lines)
        
        # Tables (basic support)
        def convert_table(match):
            table_text = match.group(0)
            rows = table_text.strip().split('\n')
            if len(rows) < 2:
                return table_text
            
            html_table = '<table class="wp-block-table">\n'
            
            # Header row
            headers = [cell.strip() for cell in rows[0].split('|') if cell.strip()]
            html_table += '<thead>\n<tr>\n'
            for header in headers:
                html_table += f'<th>{header}</th>\n'
            html_table += '</tr>\n</thead>\n'
            
            # Body rows (skip separator row)
            if len(rows) > 2:
                html_table += '<tbody>\n'
                for row in rows[2:]:
                    cells = [cell.strip() for cell in row.split('|') if cell.strip()]
                    if cells:
                        html_table += '<tr>\n'
                        for cell in cells:
                            html_table += f'<td>{cell}</td>\n'
                        html_table += '</tr>\n'
                html_table += '</tbody>\n'
            
            html_table += '</table>'
            return html_table
        
        # Match tables (lines with | separators)
        content = re.sub(r'^\|[^\n]+\|$\n^\|[-:\s|]+\|$(\n^\|[^\n]+\|$)*', 
                        convert_table, content, flags=re.MULTILINE)
        
        # Wrap paragraphs (but not elements that are already wrapped)
        paragraphs = content.split('\n\n')
        wrapped_paragraphs = []
        
        for para in paragraphs:
            para = para.strip()
            if para:
                # Check if paragraph starts with HTML tag
                if not re.match(r'^<(?:h[1-6]|p|ul|ol|li|blockquote|pre|table|hr)', para):
                    # Also check it doesn't end with a closing tag that indicates it's already wrapped
                    if not re.search(r'</(?:h[1-6]|p|ul|ol|blockquote|pre|table)>$', para):
                        para = f'<p>{para}</p>'
                wrapped_paragraphs.append(para)
        
        content = '\n\n'.join(wrapped_paragraphs)
        
        # Clean up any double line breaks within HTML tags
        content = re.sub(r'(<[^>]+>)\n\n([^<]+</[^>]+>)', r'\1\2', content)
        
        return content
    
    def check_wordpress_ready(self):
        """Check if WordPress is installed and ready"""
        try:
            response = requests.get(WP_URL, timeout=5)
            if 'wp-admin/install.php' in response.text:
                print("❌ WordPress needs initial setup!")
                print(f"Please visit {WP_URL} to complete installation")
                print("\nAfter setup:")
                print("1. Login to WordPress admin")
                print("2. Go to Users -> Your Profile")
                print("3. Create an Application Password")
                print("4. Run this script with: python3 wordpress-publisher.py <username> <app-password>")
                return False
            return True
        except requests.exceptions.RequestException:
            print("❌ Cannot connect to WordPress. Is it running?")
            return False
    
    def create_category(self):
        """Create or get documentation category"""
        # Try to create new category
        data = {
            "name": "Infrastructure Documentation",
            "slug": "infrastructure-docs",
            "description": "Technical documentation for Docker infrastructure"
        }
        
        response = requests.post(
            f"{WP_API_URL}/categories",
            headers={**self.auth_header, "Content-Type": "application/json"},
            data=json.dumps(data)
        )
        
        if response.status_code == 201:
            self.category_id = response.json()['id']
            print(f"✅ Created category with ID: {self.category_id}")
        else:
            # Try to get existing category
            response = requests.get(f"{WP_API_URL}/categories?slug=infrastructure-docs")
            if response.json():
                self.category_id = response.json()[0]['id']
                print(f"✅ Using existing category ID: {self.category_id}")
            else:
                self.category_id = 1  # Default uncategorized
                print("⚠️  Using default category")
    
    def create_post(self, title, content, tags=[]):
        """Create a WordPress post"""
        html_content = self.markdown_to_html(content)
        
        data = {
            "title": title,
            "content": html_content,
            "status": "publish",
            "categories": [self.category_id] if self.category_id else [],
            "tags": tags,
            "format": "standard"
        }
        
        response = requests.post(
            f"{WP_API_URL}/posts",
            headers={**self.auth_header, "Content-Type": "application/json"},
            data=json.dumps(data)
        )
        
        if response.status_code == 201:
            post_data = response.json()
            print(f"✅ Created: {title}")
            print(f"   URL: {post_data['link']}")
            return True
        else:
            print(f"❌ Failed to create: {title}")
            print(f"   Error: {response.text}")
            return False
    
    def publish_documentation(self):
        """Publish all documentation files"""
        docs = [
            {
                "file": "SECURITY-REVIEW.md",
                "title": "Security Review Report - Docker Infrastructure",
                "tags": ["security", "docker", "audit"]
            },
            {
                "file": "service-access.md",
                "title": "Service Access Guide - Unified Architecture",
                "tags": ["services", "architecture", "documentation"]
            },
            {
                "file": "TODO.md",
                "title": "Security Lockdown TODO List",
                "tags": ["security", "todo", "tasks"]
            },
            {
                "file": "TMUX-SETUP.md",
                "title": "Persistent Terminal Setup with TMUX",
                "tags": ["tmux", "terminal", "mobile", "ssh"]
            },
            {
                "file": "CLAUDE.md",
                "title": "Docker Infrastructure Project Overview",
                "tags": ["overview", "claude", "documentation"]
            }
        ]
        
        published = 0
        for doc in docs:
            if Path(doc["file"]).exists():
                print(f"\n📄 Publishing {doc['file']}...")
                content = Path(doc["file"]).read_text()
                if self.create_post(doc["title"], content, doc["tags"]):
                    published += 1
                time.sleep(1)  # Be nice to the API
            else:
                print(f"⚠️  File not found: {doc['file']}")
        
        print(f"\n✅ Published {published} documents successfully!")
        print(f"🌐 Visit your WordPress site at: {WP_URL}")

def main():
    print("📚 WordPress Documentation Publisher")
    print("===================================")
    
    if len(sys.argv) < 3:
        print("Usage: python3 wordpress-publisher.py <username> <app-password>")
        print("\nTo create an Application Password:")
        print("1. Login to WordPress admin")
        print("2. Go to Users -> Your Profile")
        print("3. Scroll to 'Application Passwords'")
        print("4. Create a new password")
        sys.exit(1)
    
    username = sys.argv[1]
    password = sys.argv[2]
    
    publisher = WordPressPublisher(username, password)
    
    # Check WordPress is ready
    print("\n🔍 Checking WordPress status...")
    if not publisher.check_wordpress_ready():
        sys.exit(1)
    
    print("✅ WordPress is ready")
    
    # Create category
    print("\n📁 Setting up category...")
    publisher.create_category()
    
    # Publish documentation
    print("\n📤 Publishing documentation...")
    publisher.publish_documentation()

if __name__ == "__main__":
    main()