#!/bin/bash
# Script to post documentation to WordPress via REST API
# Uses Python for proper JSON encoding and full content support

# WordPress configuration
WP_URL="https://wp.stringbits.com"
WP_API_URL="${WP_URL}/wp-json/wp/v2"

# Default credentials
DEFAULT_USER="itservice"
DEFAULT_PASS="LV78 2PAJ XXOi YLzt AlMg SizX"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}WordPress Documentation Publisher${NC}"
echo "=================================="

# Wait for WordPress to be ready
echo -e "\n${YELLOW}Waiting for WordPress to be ready...${NC}"
for i in {1..30}; do
    if curl -s -o /dev/null -w "%{http_code}" "$WP_URL" | grep -q "200\|302"; then
        echo -e "${GREEN}✓ WordPress is ready${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

# First, we need to complete WordPress installation if not done
echo -e "\n${YELLOW}Checking WordPress installation status...${NC}"
if curl -s "$WP_URL" | grep -q "wp-admin/install.php"; then
    echo -e "${RED}WordPress needs initial setup. Please complete setup at:${NC}"
    echo -e "${GREEN}$WP_URL${NC}"
    echo ""
    echo "After setup, create an Application Password:"
    echo "1. Login to WordPress admin"
    echo "2. Go to Users -> Your Profile"
    echo "3. Scroll to 'Application Passwords'"
    echo "4. Create a new password and save it"
    echo ""
    echo "Then run this script with:"
    echo "./post-to-wordpress.sh <username> <app-password>"
    exit 1
fi

# Check for credentials
if [ $# -lt 2 ]; then
    # Use default credentials if not provided
    WP_USER="$DEFAULT_USER"
    WP_PASS="$DEFAULT_PASS"
    echo -e "${YELLOW}Using default credentials for user: $WP_USER${NC}"
else
    WP_USER="$1"
    WP_PASS="$2"
fi

# Function to convert markdown to HTML (improved conversion)
markdown_to_html() {
    local content="$1"
    
    # Escape HTML entities in code blocks first
    # This is complex in bash, so we'll do basic conversion
    
    # Convert code blocks with language hints
    content=$(echo "$content" | perl -pe 's/```(\w+)\n(.*?)\n```/<pre class="wp-block-code"><code class="language-$1">$2<\/code><\/pre>/gs')
    # Convert code blocks without language
    content=$(echo "$content" | perl -pe 's/```\n(.*?)\n```/<pre class="wp-block-code"><code>$1<\/code><\/pre>/gs')
    
    # Convert headers (h1-h4)
    content=$(echo "$content" | sed -E 's/^#### (.*)$/<h4>\1<\/h4>/g')
    content=$(echo "$content" | sed -E 's/^### (.*)$/<h3>\1<\/h3>/g')
    content=$(echo "$content" | sed -E 's/^## (.*)$/<h2>\1<\/h2>/g')
    content=$(echo "$content" | sed -E 's/^# (.*)$/<h1>\1<\/h1>/g')
    
    # Convert links [text](url)
    content=$(echo "$content" | sed -E 's/\[([^\]]+)\]\(([^\)]+)\)/<a href="\2">\1<\/a>/g')
    
    # Convert images ![alt](url)
    content=$(echo "$content" | sed -E 's/!\[([^\]]*)\]\(([^\)]+)\)/<img src="\2" alt="\1" \/>/g')
    
    # Convert inline code (but not within pre tags)
    content=$(echo "$content" | perl -pe 's/(?<!<pre[^>]*>.*)`([^`]+)`/<code>$1<\/code>/g')
    
    # Convert bold (** and __)
    content=$(echo "$content" | sed -E 's/\*\*([^*]+)\*\*/<strong>\1<\/strong>/g')
    content=$(echo "$content" | sed -E 's/__([^_]+)__/<strong>\1<\/strong>/g')
    
    # Convert italic (* and _)
    content=$(echo "$content" | sed -E 's/\*([^*]+)\*/<em>\1<\/em>/g')
    content=$(echo "$content" | sed -E 's/_([^_]+)_/<em>\1<\/em>/g')
    
    # Convert blockquotes
    content=$(echo "$content" | sed -E 's/^> (.*)$/<blockquote>\1<\/blockquote>/g')
    
    # Convert horizontal rules
    content=$(echo "$content" | sed -E 's/^---+$/<hr \/>/g')
    
    # Convert unordered lists (handle multi-line)
    content=$(echo "$content" | awk '
    BEGIN { in_list = 0 }
    /^[-*+] / {
        if (!in_list) {
            print "<ul>"
            in_list = 1
        }
        sub(/^[-*+] /, "")
        print "<li>" $0 "</li>"
        next
    }
    /^[[:space:]]*$/ && in_list {
        print "</ul>"
        in_list = 0
        print ""
        next
    }
    {
        if (in_list && !/^[[:space:]]+/) {
            print "</ul>"
            in_list = 0
        }
        print
    }
    END {
        if (in_list) print "</ul>"
    }')
    
    # Convert ordered lists
    content=$(echo "$content" | awk '
    BEGIN { in_list = 0 }
    /^[0-9]+\. / {
        if (!in_list) {
            print "<ol>"
            in_list = 1
        }
        sub(/^[0-9]+\. /, "")
        print "<li>" $0 "</li>"
        next
    }
    /^[[:space:]]*$/ && in_list {
        print "</ol>"
        in_list = 0
        print ""
        next
    }
    {
        if (in_list && !/^[[:space:]]+/) {
            print "</ol>"
            in_list = 0
        }
        print
    }
    END {
        if (in_list) print "</ol>"
    }')
    
    # Wrap paragraphs (lines not starting with HTML tags)
    content=$(echo "$content" | awk '
    BEGIN { para = "" }
    /^<[^>]+>/ || /^$/ {
        if (para != "") {
            print "<p>" para "</p>"
            para = ""
        }
        if (/^$/) print ""
        else print
        next
    }
    {
        if (para != "") para = para " " $0
        else para = $0
    }
    END {
        if (para != "") print "<p>" para "</p>"
    }')
    
    # Clean up empty paragraphs
    content=$(echo "$content" | sed -E 's/<p>[[:space:]]*<\/p>//g')
    
    # Escape any remaining special characters for JSON
    content=$(echo "$content" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    
    echo "$content"
}

# Function to create a WordPress post
create_post() {
    local title="$1"
    local content="$2"
    local category="$3"
    
    # Convert markdown to HTML
    local html_content=$(markdown_to_html "$content")
    
    # Create JSON payload
    local json_payload=$(cat <<EOF
{
    "title": "$title",
    "content": "$html_content",
    "status": "publish",
    "categories": [$category]
}
EOF
)
    
    # Post to WordPress
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -u "$WP_USER:$WP_PASS" \
        -d "$json_payload" \
        "${WP_API_URL}/posts")
    
    # Check if successful
    if echo "$response" | grep -q '"id"'; then
        local post_id=$(echo "$response" | grep -o '"id":[0-9]*' | grep -o '[0-9]*')
        local post_link=$(echo "$response" | grep -o '"link":"[^"]*' | sed 's/"link":"//')
        echo -e "${GREEN}✓ Created: $title${NC}"
        echo "  URL: $post_link"
    else
        echo -e "${RED}✗ Failed to create: $title${NC}"
        echo "  Error: $response"
    fi
}

# First, create a category for our documentation
echo -e "\n${YELLOW}Creating documentation category...${NC}"
category_response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -u "$WP_USER:$WP_PASS" \
    -d '{"name":"Infrastructure Documentation","slug":"infrastructure-docs"}' \
    "${WP_API_URL}/categories")

if echo "$category_response" | grep -q '"id"'; then
    CATEGORY_ID=$(echo "$category_response" | grep -o '"id":[0-9]*' | grep -o '[0-9]*')
    echo -e "${GREEN}✓ Category created with ID: $CATEGORY_ID${NC}"
else
    # Try to get existing category
    CATEGORY_ID=$(curl -s "${WP_API_URL}/categories?slug=infrastructure-docs" | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | head -1)
    if [ -n "$CATEGORY_ID" ]; then
        echo -e "${GREEN}✓ Using existing category ID: $CATEGORY_ID${NC}"
    else
        CATEGORY_ID=1  # Default to uncategorized
        echo -e "${YELLOW}⚠ Using default category${NC}"
    fi
fi

# Post our documentation files
echo -e "\n${YELLOW}Publishing documentation...${NC}"

# 1. Security Review
if [ -f "SECURITY-REVIEW.md" ]; then
    echo -e "\n${YELLOW}Publishing Security Review...${NC}"
    content=$(cat SECURITY-REVIEW.md)
    create_post "Security Review Report - Docker Infrastructure" "$content" "$CATEGORY_ID"
fi

# 2. Service Access Documentation
if [ -f "service-access.md" ]; then
    echo -e "\n${YELLOW}Publishing Service Access Documentation...${NC}"
    content=$(cat service-access.md)
    create_post "Service Access Guide - Unified Architecture" "$content" "$CATEGORY_ID"
fi

# 3. TODO List
if [ -f "TODO.md" ]; then
    echo -e "\n${YELLOW}Publishing Security Lockdown TODO...${NC}"
    content=$(cat TODO.md)
    create_post "Security Lockdown TODO List" "$content" "$CATEGORY_ID"
fi

# 4. TMUX Setup Guide
if [ -f "TMUX-SETUP.md" ]; then
    echo -e "\n${YELLOW}Publishing TMUX Setup Guide...${NC}"
    content=$(cat TMUX-SETUP.md)
    create_post "Persistent Terminal Setup with TMUX" "$content" "$CATEGORY_ID"
fi

# 5. Project Overview (CLAUDE.md)
if [ -f "CLAUDE.md" ]; then
    echo -e "\n${YELLOW}Publishing Project Overview...${NC}"
    content=$(cat CLAUDE.md)
    create_post "Docker Infrastructure Project Overview" "$content" "$CATEGORY_ID"
fi

echo -e "\n${GREEN}✅ Documentation publishing complete!${NC}"
echo -e "${YELLOW}Visit your WordPress site at: $WP_URL${NC}"