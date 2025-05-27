#!/usr/bin/env python3
"""
Fix WordPress posts that are displaying HTML tags as plain text
"""

import json
import subprocess
import sys
import re

WP_URL = "https://wp.stringbits.com"
WP_API_URL = f"{WP_URL}/wp-json/wp/v2"
USERNAME = "itservice"
PASSWORD = "LV78 2PAJ XXOi YLzt AlMg SizX"

def get_all_posts():
    """Get all posts from WordPress"""
    cmd = [
        'curl', '-s',
        f'{WP_API_URL}/posts?per_page=100',
        '-u', f'{USERNAME}:{PASSWORD}'
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    return json.loads(result.stdout)

def check_post_has_html_tags(post):
    """Check if post content has visible HTML tags"""
    content = post['content']['rendered']
    # Check if content has HTML tags that should be rendered
    return '&lt;h' in content or '&lt;p&gt;' in content or '&amp;lt;' in content

def fix_post_content(post_id):
    """Fix post by re-saving it with proper HTML"""
    # Get the post
    cmd = [
        'curl', '-s',
        f'{WP_API_URL}/posts/{post_id}',
        '-u', f'{USERNAME}:{PASSWORD}'
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    post = json.loads(result.stdout)
    
    # Get the raw content
    content = post['content']['raw']
    
    # If content has escaped HTML, unescape it
    if '&lt;' in content or '&amp;' in content:
        content = content.replace('&lt;', '<')
        content = content.replace('&gt;', '>')
        content = content.replace('&amp;', '&')
        content = content.replace('&quot;', '"')
        
        # Update the post
        update_data = {
            'content': content
        }
        
        with open('/tmp/fix-post.json', 'w') as f:
            json.dump(update_data, f)
        
        cmd = [
            'curl', '-X', 'POST',
            f'{WP_API_URL}/posts/{post_id}',
            '-u', f'{USERNAME}:{PASSWORD}',
            '-H', 'Content-Type: application/json',
            '-d', '@/tmp/fix-post.json',
            '-s'
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        response = json.loads(result.stdout)
        
        if 'id' in response:
            return True
    return False

def main():
    print("🔍 Checking WordPress posts for HTML display issues...")
    
    posts = get_all_posts()
    problematic_posts = []
    
    for post in posts:
        if check_post_has_html_tags(post):
            problematic_posts.append({
                'id': post['id'],
                'title': post['title']['rendered'],
                'link': post['link']
            })
    
    if not problematic_posts:
        print("✅ No posts with HTML display issues found!")
        return
    
    print(f"\n⚠️  Found {len(problematic_posts)} posts with HTML display issues:")
    for post in problematic_posts:
        print(f"   - {post['title']} (ID: {post['id']})")
    
    response = input("\nFix these posts? (y/n): ")
    if response.lower() != 'y':
        print("Cancelled.")
        return
    
    print("\n🔧 Fixing posts...")
    fixed = 0
    for post in problematic_posts:
        print(f"   Fixing: {post['title']}...", end='')
        if fix_post_content(post['id']):
            print(" ✅")
            fixed += 1
        else:
            print(" ❌")
    
    print(f"\n✅ Fixed {fixed} out of {len(problematic_posts)} posts!")

if __name__ == '__main__':
    main()