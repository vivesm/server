# Portainer Stack Management

This document describes how to manage Portainer stacks and keep them in sync with local stack definitions.

## Understanding the Stack Structure

Our infrastructure uses three main stack definitions:

1. **core-infrastructure.yml**: Core services like Portainer, Caddy, and Watchtower
2. **applications.yml**: Application services like n8n, WordPress, and MySQL
3. **rustdesk.yml**: RustDesk self-hosted remote desktop server

These stacks are stored in a Git repository at `/home/shared/git-repos/portainer-stacks` for version control and deployed through Portainer.

## Portainer Stack Deployment

Portainer stacks can be deployed in two ways:

### Method 1: Through the Portainer UI

1. In Portainer, go to Stacks
2. Click "Add stack" 
3. Choose "Repository" as the build method
4. Enter the Git repository URL
5. Set the reference to "refs/heads/master"
6. Set the Compose path to the specific YAML file (e.g., "core-infrastructure.yml")
7. Click "Deploy the stack"

### Method 2: Using the Update Script

We've created an API-based script to update stacks directly:

```bash
/home/shared/docker/update-portainer-stacks.sh
```

This script:
1. Authenticates with the Portainer API
2. Creates or updates stacks to match local stack definitions
3. Provides detailed feedback on the update process

## Synchronizing Local Configuration

Before updating Portainer stacks, ensure your local stack definitions are synchronized:

```bash
/home/shared/docker/sync-portainer-config.sh
```

This script:
1. Updates the Git repository files based on current Docker Compose configuration
2. Ensures network configurations are correct
3. Harmonizes volume definitions

## Git Integration

For version control and team collaboration, use the Git integration script:

```bash
/home/shared/docker/git-sync.sh
```

This interactive script provides options to:
- Initialize the Git repository
- Commit changes
- Push changes to a remote repository
- Pull changes from a remote repository
- Update Portainer stacks directly

## Network Requirements

All services must be connected to both Docker networks:

- **stringbits_net**: Primary network for core services
- **docker_stringbits_net**: Network for application services

This dual-network configuration ensures all services can communicate with each other.

## Troubleshooting

### Connectivity Issues

If services can't communicate with each other:

1. Check if all containers are on both networks:
   ```bash
   /home/shared/docker/check-network-connectivity.sh
   ```

2. Manually connect a container to a missing network:
   ```bash
   docker network connect docker_stringbits_net container_name
   ```

### Stack Deployment Failures

If a stack fails to deploy:

1. Validate the stack configuration:
   ```bash
   docker-compose -f /home/shared/git-repos/portainer-stacks/stack-name.yml config
   ```

2. Check Portainer logs for errors:
   ```bash
   docker logs portainer
   ```

3. Ensure networks exist:
   ```bash
   docker network ls | grep stringbits
   ```

## Best Practices

1. **Always commit and push changes**: Keep the Git repository up to date
2. **Test configurations**: Validate configurations before deployment
3. **Use meaningful commit messages**: Document what changed and why
4. **Keep credentials secure**: Use environment variables for sensitive data
5. **Regular backups**: Backup stack definitions and volumes regularly

## Update Workflow

When making infrastructure changes:

1. Update local Docker Compose files if needed
2. Run `/home/shared/docker/sync-portainer-config.sh` to update Git repository files
3. Test configuration validity
4. Commit changes using `/home/shared/docker/git-sync.sh`
5. Update Portainer stacks using `/home/shared/docker/update-portainer-stacks.sh`
6. Deploy stacks through Portainer UI
7. Verify services are working correctly