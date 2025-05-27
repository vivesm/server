# Container Data Persistence Guide

This document explains how data persistence is configured for the Docker containers and how to properly handle updates without losing data.

## Overview

Proper data persistence in Docker requires mounting the right directories from the container to the host. This ensures that important data is preserved when containers are rebuilt or updated.

## Persistence Strategies

There are two main approaches to persisting data in Docker containers:

1. **Bind Mounts**: Mapping a host directory to a container directory
2. **Docker-managed Volumes**: Using Docker's volume management system

For most services, we use bind mounts with clearly defined directories. However, for services that require more reliable persistence, we use Docker-managed volumes.

## WordPress Persistence

### How WordPress Data is Organized

WordPress data can be divided into several categories:

1. **Core files**: The WordPress installation itself (/var/www/html)
2. **Custom content**: Themes, plugins, uploads (/var/www/html/wp-content)
3. **Configuration**: wp-config.php and .htaccess
4. **Database**: All posts, pages, settings (stored in MySQL)

### Our Persistence Strategy

We've configured WordPress to persist only what's necessary:

```yaml
volumes:
  # Only mount wp-content to preserve customizations
  - ./wordpress/wp-content:/var/www/html/wp-content
  # Mount config file to preserve settings
  - ./wordpress/wp-config.php:/var/www/html/wp-config.php:ro
  # Mount .htaccess if using it
  - ./wordpress/.htaccess:/var/www/html/.htaccess:ro
```

This approach:
- Preserves all themes, plugins, and uploads in wp-content
- Keeps your configuration settings in wp-config.php
- Maintains custom .htaccess rules
- Allows WordPress core files to be updated when the container is rebuilt

### Handling WordPress Updates

With this configuration:

1. **WordPress Core Updates**: When you pull a newer WordPress image and restart, the core files are automatically updated.

2. **Theme/Plugin Updates**: Since wp-content is persistent, you can update themes and plugins from the WordPress admin interface.

3. **Content**: All your posts, pages, users, and settings are stored in the MySQL database, which has its own persistent volume.

4. **After Major Version Updates**: You might need to run WordPress's database update by visiting `/wp-admin`.

## n8n Persistence

n8n data is properly configured to persist between container rebuilds:

```yaml
volumes:
  - ./n8n:/home/node/.n8n
user: "1000:1000"
```

This configuration:
- Persists all workflows, credentials, and configuration
- Uses the correct user ID to avoid permission issues

## MySQL Database

The MySQL database is configured to persist all data:

```yaml
volumes:
  - ./mysql:/var/lib/mysql
```

This ensures all database content (WordPress posts, pages, settings) remains intact when containers are rebuilt.

## Backup Recommendations

For added security, consider implementing a backup strategy:

1. **Regular database dumps**:
   ```bash
   docker exec mysql mysqldump -u root -p[root_password] --all-databases > backup.sql
   ```

2. **wp-content backup**:
   ```bash
   tar -czf wp-content-backup.tar.gz /home/shared/docker/wordpress/wp-content
   ```

3. **n8n workflows export**:
   Export workflows directly from the n8n interface or use n8n CLI commands.

## Troubleshooting

If you encounter issues with persistence:

1. **Check permissions**: Make sure the directories have correct ownership and permissions.
2. **Verify mount points**: Ensure the volumes are correctly mounted in the Docker Compose file.
3. **Check logs**: Look at container logs to identify potential issues.

## Portainer Persistence

Portainer data persistence is critical for maintaining container configurations, stacks, and user settings. We've implemented a specialized approach for Portainer:

### Docker-Managed Volume Approach

Portainer now uses a dedicated Docker-managed volume to ensure reliable persistence:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
  - portainer_data:/data
  - /etc/localtime:/etc/localtime:ro
  - ./portainer/stacks:/stacks
```

With volume declaration:
```yaml
volumes:
  portainer_data:
    name: portainer_data
```

### Independent Management

Portainer has its own Docker Compose file (`/home/shared/docker/portainer.yml`) to ensure its persistence is managed independently from other services. This provides several benefits:

1. **Increased reliability**: Portainer's persistence is not affected by issues with other services
2. **Independent lifecycle**: Portainer can be updated or restarted without affecting other services
3. **Simplified troubleshooting**: Issues with Portainer persistence can be isolated and addressed

### Network Connectivity

Portainer MUST be connected to both Docker networks to function properly:
- `stringbits_net`: Used by the Git service and for Portainer's own access
- `docker_stringbits_net`: Used by all application containers (n8n, WordPress, etc.)

If Portainer cannot be accessed via ptn.stringbits.com, check its network connections:

```bash
# Check if Portainer is on both networks
docker inspect portainer --format '{{json .NetworkSettings.Networks}}'

# Connect Portainer to missing networks if needed
docker network connect docker_stringbits_net portainer
# or
docker network connect stringbits_net portainer

# Run the network connectivity check script
./check-network-connectivity.sh
```

### Validation

A validation script is available to verify Portainer's persistence:

```bash
./validate-portainer-persistence.sh
```

This script:
1. Checks if Portainer is running
2. Captures the current Portainer configuration
3. Restarts Portainer
4. Verifies that configuration persists after restart
5. Tests API accessibility

## Special Considerations for Updates

### WordPress Update Procedure

For major WordPress updates, follow these steps:

1. Back up the database and wp-content folder
2. Pull the latest WordPress image: `docker pull wordpress:latest`
3. Restart the containers: `docker compose down && docker compose up -d`
4. Visit WordPress admin to complete any necessary database updates

### n8n Update Procedure

For major n8n updates:

1. Export important workflows from the UI
2. Pull the latest n8n image: `docker pull n8nio/n8n:latest`
3. Restart the containers: `docker compose down && docker compose up -d`

### Portainer Update Procedure

For Portainer updates, follow these steps:

1. Pull the latest Portainer image: `docker pull portainer/portainer-ce:latest`
2. Stop and remove only the Portainer container: `docker compose -f docker/portainer.yml down`
3. Start the new Portainer container: `docker compose -f docker/portainer.yml up -d`
4. Validate persistence: `./validate-portainer-persistence.sh`
5. Visit Portainer UI to verify all stacks and configurations are preserved