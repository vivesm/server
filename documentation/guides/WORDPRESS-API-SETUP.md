# WordPress API Setup Guide
**Created**: 2025-01-26

## Overview

This guide covers the WordPress REST API setup and important security considerations for the infrastructure documentation site.

## Security Configuration

### Content Security Policy (CSP) Removal

**Important**: The Content Security Policy (CSP) header has been intentionally removed from the WordPress site configuration in Caddy for compatibility reasons.

**Why CSP was removed for WordPress:**
- WordPress and its plugins inject inline scripts and styles dynamically
- Many WordPress themes and plugins require external resources
- The WordPress block editor (Gutenberg) uses extensive inline JavaScript
- Plugin functionality would break with strict CSP rules

**Location**: `/home/melvin/projects/server/docker-stack-infrastructure/caddy/config/Caddyfile`

```caddy
# WordPress-specific headers (more permissive)
(wordpress_headers) {
    header {
        # Enable HSTS
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        # Disable content-type sniffing
        X-Content-Type-Options "nosniff"
        # XSS protection
        X-XSS-Protection "1; mode=block"
        # Frame options
        X-Frame-Options "SAMEORIGIN"
        # Referrer policy
        Referrer-Policy "strict-origin-when-cross-origin"
        # Remove CSP for WordPress to allow all content
        # Content-Security-Policy header removed for WordPress compatibility
        # Remove server information
        -Server
    }
}
```

### Security Mitigation

To compensate for the lack of CSP:
1. **Keep WordPress and plugins updated** - Critical for security
2. **Use Application Passwords** - Never use main admin password for API
3. **Limit user permissions** - Create specific users for API access
4. **Regular security audits** - Monitor for suspicious activity
5. **Backup regularly** - Maintain recent backups

## REST API Configuration

### Enabling REST API

The WordPress REST API is enabled by default. Access it at:
```
https://wp.stringbits.com/wp-json/wp/v2/
```

### Authentication Methods

#### 1. Application Passwords (Recommended)

**Setup:**
1. Login to WordPress Admin
2. Navigate to **Users → Your Profile**
3. Scroll to **Application Passwords**
4. Enter application name: "Documentation Publisher"
5. Click **Add New Application Password**
6. **Copy immediately** - shown only once!

**Usage:**
```bash
# Basic auth with application password
curl -X GET https://wp.stringbits.com/wp-json/wp/v2/posts \
  -u "username:application-password"
```

#### 2. Cookie Authentication

For browser-based applications:
```javascript
// Uses WordPress nonce for CSRF protection
fetch('/wp-json/wp/v2/posts', {
    credentials: 'same-origin',
    headers: {
        'X-WP-Nonce': wpApiSettings.nonce
    }
});
```

## API Endpoints

### Common Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/wp-json/wp/v2/posts` | GET | List posts |
| `/wp-json/wp/v2/posts` | POST | Create post |
| `/wp-json/wp/v2/posts/{id}` | GET | Get single post |
| `/wp-json/wp/v2/posts/{id}` | PUT | Update post |
| `/wp-json/wp/v2/categories` | GET | List categories |
| `/wp-json/wp/v2/tags` | GET | List tags |
| `/wp-json/wp/v2/media` | POST | Upload media |

### Creating Posts via API

```bash
# Create a new post
curl -X POST https://wp.stringbits.com/wp-json/wp/v2/posts \
  -H "Content-Type: application/json" \
  -u "username:app-password" \
  -d '{
    "title": "API Test Post",
    "content": "<p>This is HTML content</p>",
    "status": "publish",
    "categories": [1],
    "tags": [2, 3]
  }'
```

### Searching Posts

```bash
# Search for posts containing "docker"
curl -X GET "https://wp.stringbits.com/wp-json/wp/v2/posts?search=docker" \
  -u "username:app-password"
```

## Content Formatting

### HTML Requirements

The WordPress REST API expects HTML content, not markdown. Our publisher scripts handle this conversion.

**Supported HTML elements:**
- Headers: `<h1>`, `<h2>`, `<h3>`, etc.
- Paragraphs: `<p>`
- Lists: `<ul>`, `<ol>`, `<li>`
- Code: `<pre>`, `<code>`
- Formatting: `<strong>`, `<em>`
- Links: `<a href="">`
- Images: `<img src="">`

### Code Block Formatting

For syntax highlighting with plugins:
```html
<pre class="wp-block-code">
<code class="language-bash">
#!/bin/bash
echo "Hello World"
</code>
</pre>
```

## API Rate Limits

WordPress doesn't enforce rate limits by default, but:
1. Be respectful - space requests by 1-2 seconds
2. Batch operations when possible
3. Cache responses client-side
4. Monitor server load

## Troubleshooting

### Common Issues

#### 401 Unauthorized
- Verify username and application password
- Check user has `publish_posts` capability
- Ensure Basic Auth header is sent

#### 403 Forbidden
- Check user permissions
- Verify REST API is enabled
- Check `.htaccess` isn't blocking API

#### Empty Response
- Check WordPress permalink settings
- Ensure mod_rewrite is enabled
- Verify Caddy proxy configuration

### Debug Mode

Enable WordPress debug mode temporarily:
```php
// In wp-config.php
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
```

Check logs at: `/home/shared/docker/wordpress/wp-content/debug.log`

## Security Best Practices

1. **Use HTTPS Only** - API credentials sent in plain text otherwise
2. **Limit API Access** - Create dedicated users with minimal permissions
3. **Rotate Passwords** - Change application passwords regularly
4. **Monitor Access** - Review access logs for suspicious activity
5. **Validate Input** - Sanitize all data before sending to API
6. **Error Handling** - Don't expose sensitive info in errors

## Performance Optimization

### Caching
- Use WordPress caching plugins
- Cache API responses client-side
- Consider CDN for media files

### Query Optimization
```bash
# Limit fields returned
curl "https://wp.stringbits.com/wp-json/wp/v2/posts?_fields=id,title,link"

# Pagination
curl "https://wp.stringbits.com/wp-json/wp/v2/posts?per_page=10&page=2"
```

## Additional Resources

- [WordPress REST API Handbook](https://developer.wordpress.org/rest-api/)
- [Authentication Guide](https://developer.wordpress.org/rest-api/using-the-rest-api/authentication/)
- [API Reference](https://developer.wordpress.org/rest-api/reference/)

---
*Note: CSP has been disabled for WordPress compatibility. Maintain strict security practices in other areas.*