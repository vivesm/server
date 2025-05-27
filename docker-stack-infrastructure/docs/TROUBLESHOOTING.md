# StringBits Docker Infrastructure Troubleshooting Guide

This document provides comprehensive troubleshooting steps for common issues that may arise with the StringBits Docker infrastructure.

## Table of Contents

1. [Container Issues](#container-issues)
2. [Network Issues](#network-issues)
3. [Endpoint Access Issues](#endpoint-access-issues)
4. [Notification Issues](#notification-issues)
5. [Resource Issues](#resource-issues)
6. [Backup and Persistence Issues](#backup-and-persistence-issues)
7. [Service-Specific Issues](#service-specific-issues)

## Container Issues

### Container Fails to Start

**Symptoms:**
- Container is not running when checking `docker ps`
- Error messages in container logs

**Troubleshooting Steps:**
1. Check container logs:
   ```bash
   docker logs <container_name>
   ```

2. Verify Docker service is running:
   ```bash
   systemctl status docker
   ```

3. Check if the container's image exists:
   ```bash
   docker images | grep <image_name>
   ```

4. Validate Docker Compose configuration:
   ```bash
   docker-compose -f docker-compose.core.yml config
   ```

5. Try starting the container manually:
   ```bash
   docker start <container_name>
   ```

### Container Restarts Repeatedly

**Symptoms:**
- Container status shows "Restarting"
- Restart count increases continuously

**Troubleshooting Steps:**
1. Check container logs for error messages:
   ```bash
   docker logs --tail 100 <container_name>
   ```

2. Check container resource usage:
   ```bash
   docker stats <container_name>
   ```

3. Verify volume mounts are correct:
   ```bash
   docker inspect <container_name> | grep -A 10 "Mounts"
   ```

4. Check for dependency issues:
   ```bash
   docker-compose -f docker-compose.core.yml ps
   ```

## Network Issues

### Container Network Connectivity

**Symptoms:**
- Containers cannot communicate with each other
- Network-related errors in logs

**Troubleshooting Steps:**
1. List all Docker networks:
   ```bash
   docker network ls
   ```

2. Check network configuration:
   ```bash
   docker network inspect stringbits_net
   ```

3. Run the network connectivity check script:
   ```bash
   ./check-network-connectivity.sh
   ```

4. Verify containers are on the correct network:
   ```bash
   docker inspect <container_name> | grep -A 5 "Networks"
   ```

### DNS Resolution Issues

**Symptoms:**
- Container cannot resolve hostnames
- "Unknown host" errors in logs

**Troubleshooting Steps:**
1. Check DNS settings inside container:
   ```bash
   docker exec <container_name> cat /etc/resolv.conf
   ```

2. Test DNS resolution from inside container:
   ```bash
   docker exec <container_name> ping -c 1 google.com
   ```

3. Verify Docker daemon DNS configuration:
   ```bash
   cat /etc/docker/daemon.json | grep dns
   ```

4. Restart Docker daemon if necessary:
   ```bash
   systemctl restart docker
   ```

## Endpoint Access Issues

### HTTPS Certificate Issues

**Symptoms:**
- Browser shows certificate errors
- SSL handshake failures

**Troubleshooting Steps:**
1. Check Caddy logs:
   ```bash
   docker logs caddy | grep -i "certificate"
   ```

2. Verify Caddyfile configuration:
   ```bash
   docker exec caddy caddy validate --config /etc/caddy/Caddyfile
   ```

3. Check certificate expiration:
   ```bash
   echo | openssl s_client -connect wp.stringbits.com:443 -servername wp.stringbits.com 2>/dev/null | openssl x509 -noout -dates
   ```

4. Restart Caddy container:
   ```bash
   docker restart caddy
   ```

### Service Endpoint Unreachable

**Symptoms:**
- Cannot access a service via its domain
- 502 Bad Gateway or connection timeout errors

**Troubleshooting Steps:**
1. Check if the service container is running:
   ```bash
   docker ps | grep <service_name>
   ```

2. Verify Caddy configuration for the service:
   ```bash
   docker exec caddy cat /etc/caddy/Caddyfile | grep -A 5 "<service_domain>"
   ```

3. Test direct container access (if applicable):
   ```bash
   curl -v http://localhost:<container_port>
   ```

4. Check Caddy logs for routing issues:
   ```bash
   docker logs caddy | grep -i "<service_domain>"
   ```

## Notification Issues

### Email Notifications Not Sending

**Symptoms:**
- No email alerts received
- Email sending errors in logs

**Troubleshooting Steps:**
1. Verify SSMTP configuration:
   ```bash
   cat /etc/ssmtp/ssmtp.conf
   ```

2. Test email sending manually:
   ```bash
   ./test-ssmtp.sh
   ```

3. Check mail logs:
   ```bash
   tail -n 50 /var/log/mail.log
   ```

4. Verify correct email address is being used:
   ```bash
   grep -n "From:" /home/shared/docker/enhanced-monitor.sh
   ```
   Ensure it's using `sb-admin@stringbits.com`

### Slack/Discord/Teams Notifications Not Working

**Symptoms:**
- No alerts received in chat platform
- Webhook errors in logs

**Troubleshooting Steps:**
1. Verify webhook URL is configured:
   ```bash
   grep -n "WEBHOOK_URL" /home/shared/docker/enhanced-monitor.sh
   ```

2. Test webhook manually:
   ```bash
   curl -X POST -H "Content-type: application/json" --data '{"text":"Test message"}' <webhook_url>
   ```

3. Check for rate limiting or IP blocking on the service side

## Resource Issues

### Disk Space Alerts

**Symptoms:**
- Disk space warning or critical alerts
- Low disk space affecting services

**Troubleshooting Steps:**
1. Check disk usage:
   ```bash
   df -h
   ```

2. Identify large directories:
   ```bash
   du -h --max-depth=1 /home/shared | sort -hr
   ```

3. Clean up Docker resources:
   ```bash
   docker system prune -a
   ```

4. Run cleanup script:
   ```bash
   ./cleanup.sh
   ```

### Memory Usage Issues

**Symptoms:**
- High memory usage alerts
- Container out-of-memory errors

**Troubleshooting Steps:**
1. Check memory usage:
   ```bash
   free -h
   ```

2. Monitor container resource usage:
   ```bash
   docker stats
   ```

3. Check for memory leaks in specific containers:
   ```bash
   docker logs <container_name> | grep -i "memory"
   ```

4. Adjust container memory limits if needed:
   ```bash
   docker update --memory <limit> <container_name>
   ```

## Backup and Persistence Issues

### Data Persistence After Container Restart

**Symptoms:**
- Data is lost after container restarts
- Configuration changes don't persist

**Troubleshooting Steps:**
1. Verify volume configurations:
   ```bash
   docker-compose -f docker-compose.core.yml config | grep -A 10 volumes
   ```

2. Check volume mounts for the container:
   ```bash
   docker inspect <container_name> | grep -A 10 "Mounts"
   ```

3. Test volume persistence:
   ```bash
   ./validate-portainer-persistence.sh
   ```

4. Verify volume data exists on host:
   ```bash
   ls -la /var/lib/docker/volumes/
   ```

### Git Backup Issues

**Symptoms:**
- Git backups failing
- Errors in git operations

**Troubleshooting Steps:**
1. Check git status:
   ```bash
   cd /home/shared/git-repos/portainer-stacks && git status
   ```

2. Verify git configuration:
   ```bash
   cd /home/shared/git-repos/portainer-stacks && git config -l
   ```

3. Test git operations manually:
   ```bash
   cd /home/shared/git-repos/portainer-stacks && git add . && git commit -m "Test commit"
   ```

4. Check git-sync script logs:
   ```bash
   grep -n "git" /home/shared/docker/logs/cron.log
   ```

## Service-Specific Issues

### Portainer Issues

**Symptoms:**
- Cannot access Portainer UI
- Portainer API errors

**Troubleshooting Steps:**
1. Check Portainer container status:
   ```bash
   docker ps | grep portainer
   ```

2. Verify Portainer volume:
   ```bash
   docker volume inspect portainer_data
   ```

3. Test Portainer API:
   ```bash
   curl -sk https://localhost:9443/api/status
   ```

4. Restart Portainer:
   ```bash
   docker restart portainer
   ```

### n8n Issues

**Symptoms:**
- Workflows failing
- Authentication issues
- Links pointing to incorrect URLs (like 0.0.0.0:5678 instead of n8n.stringbits.com)

**Troubleshooting Steps:**
1. Check n8n container logs:
   ```bash
   docker logs n8n
   ```

2. Verify n8n environment variables:
   ```bash
   docker inspect n8n | grep -A 20 "Env"
   ```

3. Test n8n API access:
   ```bash
   curl -u admin:changeme -I https://n8n.stringbits.com/rest/workflows
   ```

4. Check n8n data volume:
   ```bash
   docker volume inspect n8n_data
   ```

5. Fix incorrect URL issues:
   - Create a dedicated n8n.yml configuration file with comprehensive URL settings:
     ```yaml
     environment:
       - N8N_HOST=n8n.stringbits.com
       - N8N_PROTOCOL=https
       - N8N_PORT=443
       - N8N_WEBHOOKS_HOST=n8n.stringbits.com
       - N8N_WEBHOOKS_PROTOCOL=https
       - N8N_WEBHOOKS_PORT=443
       - WEBHOOK_URL=https://n8n.stringbits.com/
       - N8N_EDITOR_BASE_URL=https://n8n.stringbits.com/
       - N8N_PUBLIC_API_URL=https://n8n.stringbits.com/
     ```
   - Restart using the dedicated config file:
     ```bash
     cd /home/shared/docker
     docker compose -f n8n.yml down
     docker compose -f n8n.yml up -d
     ```

### WordPress Issues

**Symptoms:**
- WordPress site down
- Database connection errors

**Troubleshooting Steps:**
1. Check WordPress container logs:
   ```bash
   docker logs wordpress
   ```

2. Verify MySQL is running:
   ```bash
   docker ps | grep mysql
   ```

3. Test database connection:
   ```bash
   docker exec mysql mysqladmin -u wpuser -pwppassword ping
   ```

4. Check WordPress files:
   ```bash
   docker exec wordpress ls -la /var/www/html/
   ```

### RustDesk Issues

**Symptoms:**
- Cannot connect to RustDesk
- Server connection errors

**Troubleshooting Steps:**
1. Check RustDesk containers:
   ```bash
   docker ps | grep rustdesk
   ```

2. Verify RustDesk logs:
   ```bash
   docker logs rustdesk-hbbs
   docker logs rustdesk-hbbr
   ```

3. Check RustDesk configuration:
   ```bash
   ls -la /home/shared/docker/rustdesk/
   ```

4. Test RustDesk endpoint:
   ```bash
   curl -v https://rd.stringbits.com
   ```

---

## Additional Troubleshooting Resources

- **Docker Documentation**: [https://docs.docker.com/](https://docs.docker.com/)
- **Caddy Documentation**: [https://caddyserver.com/docs/](https://caddyserver.com/docs/)
- **Portainer Documentation**: [https://docs.portainer.io/](https://docs.portainer.io/)
- **n8n Documentation**: [https://docs.n8n.io/](https://docs.n8n.io/)
- **WordPress Documentation**: [https://wordpress.org/documentation/](https://wordpress.org/documentation/)
- **RustDesk Documentation**: [https://rustdesk.com/docs/](https://rustdesk.com/docs/)

For additional assistance or to report persistent issues, contact the infrastructure maintainer at melvin@stringbits.com.