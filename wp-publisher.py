#!/usr/bin/env python3
"""
WordPress Publisher - Posts markdown files to WordPress with proper formatting
"""

import json
import subprocess
import re
import sys
import os
from pathlib import Path

# WordPress configuration
WP_URL = "https://wp.stringbits.com"
WP_API_URL = f"{WP_URL}/wp-json/wp/v2"
DEFAULT_USER = "itservice"
DEFAULT_PASS = "LV78 2PAJ XXOi YLzt AlMg SizX"

def markdown_to_html(content, skip_first_h1=False):
    """Convert markdown to HTML with proper formatting"""
    
    # IMPORTANT: Process code blocks FIRST to prevent header conversion inside them
    # Convert code blocks with proper escaping
    def escape_code(match):
        lang = match.group(1) or ''
        code = match.group(2)
        # Escape HTML entities in code
        code = code.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
        if lang:
            return f'<pre class="wp-block-code"><code class="language-{lang}">{code}</code></pre>'
        return f'<pre class="wp-block-code"><code>{code}</code></pre>'
    
    content = re.sub(r'```(\w*)\n(.*?)\n```', escape_code, content, flags=re.DOTALL)
    
    # NOW convert headers (after code blocks are protected)
    content = re.sub(r'^### (.+)$', r'<h3>\1</h3>', content, flags=re.MULTILINE)
    content = re.sub(r'^## (.+)$', r'<h2>\1</h2>', content, flags=re.MULTILINE)
    
    if skip_first_h1:
        # Skip the first H1 heading
        content = re.sub(r'^# .+\n', '', content, count=1)
    
    content = re.sub(r'^# (.+)$', r'<h1>\1</h1>', content, flags=re.MULTILINE)
    
    # Convert inline code
    content = re.sub(r'`([^`]+)`', r'<code>\1</code>', content)
    
    # Convert bold and italic
    content = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', content)
    content = re.sub(r'(?<!\*)\*([^*]+)\*(?!\*)', r'<em>\1</em>', content)
    
    # Convert links
    content = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', content)
    
    # Convert lists
    lines = content.split('\n')
    in_list = False
    list_type = None
    new_lines = []
    
    for i, line in enumerate(lines):
        # Unordered list
        if line.strip().startswith('- '):
            if not in_list or list_type != 'ul':
                if in_list and list_type == 'ol':
                    new_lines.append('</ol>')
                new_lines.append('<ul>')
                in_list = True
                list_type = 'ul'
            new_lines.append(f'<li>{line.strip()[2:]}</li>')
        # Ordered list
        elif re.match(r'^\d+\.\s+', line.strip()):
            if not in_list or list_type != 'ol':
                if in_list and list_type == 'ul':
                    new_lines.append('</ul>')
                new_lines.append('<ol>')
                in_list = True
                list_type = 'ol'
            content_start = line.find('.') + 2
            new_lines.append(f'<li>{line.strip()[content_start:]}</li>')
        else:
            if in_list and line.strip() == '':
                if list_type == 'ol':
                    new_lines.append('</ol>')
                else:
                    new_lines.append('</ul>')
                in_list = False
                list_type = None
            new_lines.append(line)
    
    if in_list:
        if list_type == 'ol':
            new_lines.append('</ol>')
        else:
            new_lines.append('</ul>')
    
    content = '\n'.join(new_lines)
    
    # Convert blockquotes
    content = re.sub(r'^> (.+)$', r'<blockquote>\1</blockquote>', content, flags=re.MULTILINE)
    
    # Convert tables
    def convert_table(match):
        table_text = match.group(0)
        lines = table_text.strip().split('\n')
        
        if len(lines) < 3:  # Need at least header, separator, and one row
            return table_text
            
        html = '<table class="wp-block-table"><thead><tr>'
        
        # Header
        headers = [cell.strip() for cell in lines[0].split('|')[1:-1]]
        for header in headers:
            html += f'<th>{header}</th>'
        html += '</tr></thead><tbody>'
        
        # Rows
        for line in lines[2:]:
            if line.strip():
                html += '<tr>'
                cells = [cell.strip() for cell in line.split('|')[1:-1]]
                for cell in cells:
                    html += f'<td>{cell}</td>'
                html += '</tr>'
        
        html += '</tbody></table>'
        return html
    
    # Simple table detection (lines with pipes)
    content = re.sub(r'(\|.+\|[\n\r]+\|[-:\s|]+\|[\n\r]+(?:\|.+\|[\n\r]*)+)', convert_table, content)
    
    # Convert paragraphs (but not inside HTML tags)
    paragraphs = content.split('\n\n')
    formatted_paragraphs = []
    
    for p in paragraphs:
        p = p.strip()
        if p and not p.startswith('<') and not p.startswith('|'):
            formatted_paragraphs.append(f'<p>{p}</p>')
        else:
            formatted_paragraphs.append(p)
    
    return '\n'.join(formatted_paragraphs)

def create_post(title, content, username=DEFAULT_USER, password=DEFAULT_PASS, category_id=1):
    """Create a WordPress post via REST API"""
    
    # Check if content starts with same title as post title
    first_line = content.split('\n')[0].strip()
    skip_first_h1 = first_line.startswith('#') and first_line.lstrip('#').strip() == title
    
    # Convert markdown to HTML
    html_content = markdown_to_html(content, skip_first_h1=skip_first_h1)
    
    # Create post data
    post_data = {
        'title': title,
        'content': html_content,
        'status': 'publish',
        'categories': [category_id],
        'format': 'standard'  # Ensure WordPress treats as standard post
    }
    
    # Write to temp file
    with open('/tmp/wp-post.json', 'w') as f:
        json.dump(post_data, f)
    
    # Post using curl
    cmd = [
        'curl', '-X', 'POST',
        f'{WP_API_URL}/posts',
        '-u', f'{username}:{password}',
        '-H', 'Content-Type: application/json',
        '-d', '@/tmp/wp-post.json',
        '-s'
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    try:
        response = json.loads(result.stdout)
        
        if 'id' in response:
            print(f'✅ Created: {title}')
            print(f'   URL: {response["link"]}')
            return True
        else:
            print(f'❌ Failed to create: {title}')
            print(f'   Error: {response}')
            return False
            
    except json.JSONDecodeError:
        print(f'❌ Invalid response: {result.stdout}')
        return False

def main():
    """Main function to post markdown files"""
    
    if len(sys.argv) < 2:
        print("Usage: wp-publisher.py <markdown-file> [title]")
        print("Example: wp-publisher.py TMUX-SETUP.md 'TMUX Guide'")
        sys.exit(1)
    
    md_file = sys.argv[1]
    
    if not os.path.exists(md_file):
        print(f"❌ File not found: {md_file}")
        sys.exit(1)
    
    # Get title from argument or file name
    if len(sys.argv) > 2:
        title = sys.argv[2]
    else:
        # Use first heading or filename
        with open(md_file, 'r') as f:
            first_line = f.readline().strip()
            if first_line.startswith('#'):
                title = first_line.lstrip('#').strip()
            else:
                title = Path(md_file).stem.replace('-', ' ').title()
    
    # Read content
    with open(md_file, 'r') as f:
        content = f.read()
    
    print(f"📝 Publishing: {title}")
    print(f"📄 From file: {md_file}")
    
    # Create post
    create_post(title, content)

if __name__ == '__main__':
    main()