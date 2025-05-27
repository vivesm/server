# Validation and Monitoring Guide
**Last Updated**: 2025-01-26

## Overview

This guide covers the validation and monitoring tools used to ensure the health and security of the Docker infrastructure. These tools provide automated checking, alerting, and reporting capabilities.

## Validation System

### validate-all.sh

**Location**: `/home/melvin/projects/server/docker-stack-infrastructure/scripts/validate-all.sh`

**Purpose**: Comprehensive validation of the entire Docker stack

**Features**:
- Container health status checks
- Docker Compose file syntax validation
- Caddy configuration verification
- Network connectivity testing
- Portainer persistence validation
- RustDesk configuration checks
- Git repository status
- Endpoint accessibility testing
- System resource monitoring
- HTML report generation

### Usage

```bash
# Run full validation
cd /home/melvin/projects/server/docker-stack-infrastructure
./scripts/validate-all.sh

# View results
cat /home/shared/docker/logs/validation.log

# Open HTML report
open /home/shared/docker/logs/validation-report.html
```

### What It Validates

1. **Container Status**
   - Checks if all expected containers are running
   - Verifies container health status
   - Reports on stopped or unhealthy containers

2. **Docker Compose Files**
   - Validates YAML syntax
   - Checks configuration validity
   - Tests compose file compatibility

3. **Caddy Configuration**
   - Validates Caddyfile syntax
   - Checks for startup errors
   - Verifies proxy functionality

4. **Network Configuration**
   - Confirms Docker networks exist
   - Verifies container network connections
   - Checks inter-service connectivity

5. **Portainer Persistence**
   - Tests data persistence across restarts
   - Validates volume mounts
   - Checks API accessibility

6. **Endpoint Accessibility**
   - Tests HTTPS endpoints
   - Verifies DNS resolution
   - Checks HTTP response codes

7. **System Resources**
   - Monitors disk usage
   - Checks memory utilization
   - Warns on resource constraints

### Output Format

The script generates:
- Console output with color-coded results
- Log file at `/home/shared/docker/logs/validation.log`
- HTML report at `/home/shared/docker/logs/validation-report.html`

### Exit Codes
- `0`: All validations passed
- `1`: One or more validations failed

## Enhanced Monitoring System

### enhanced-monitor.sh

**Location**: `/home/melvin/projects/server/docker-stack-infrastructure/monitoring/scripts/enhanced-monitor.sh`

**Purpose**: Continuous health monitoring with alerting capabilities

**Features**:
- Real-time container monitoring
- Service endpoint checking
- Resource utilization tracking
- Security header validation
- Multi-channel alerting (Email, Slack, Discord, Teams, Telegram)
- Metric collection and storage
- HTML email reports with charts

### Configuration

Edit the script to configure notification channels:

```bash
# Email configuration
NOTIFICATION_EMAIL="your-email@example.com"

# Optional webhook URLs
SLACK_WEBHOOK_URL=""
DISCORD_WEBHOOK_URL=""
TEAMS_WEBHOOK_URL=""
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""
```

### Thresholds

Default warning/critical thresholds:

```bash
DISK_WARNING_THRESHOLD=80
DISK_CRITICAL_THRESHOLD=90
MEMORY_WARNING_THRESHOLD=80
MEMORY_CRITICAL_THRESHOLD=90
```

### Usage

```bash
# Run manual monitoring check
./docker-stack-infrastructure/monitoring/scripts/enhanced-monitor.sh

# View monitoring logs
tail -f /home/shared/docker/logs/monitor.log

# Check metrics
cat /home/shared/docker/logs/metrics.json
```

### Automated Monitoring

Set up via cron for regular checks:

```bash
# Run setup-cron.sh to configure
sudo ./docker-stack-infrastructure/scripts/setup/setup-cron.sh

# Or manually add to crontab
crontab -e

# Add this line for 15-minute checks
*/15 * * * * /home/melvin/projects/server/docker-stack-infrastructure/monitoring/scripts/enhanced-monitor.sh
```

### What It Monitors

1. **Container Health**
   - Running status
   - Container logs for errors
   - Resource usage per container

2. **Service Endpoints**
   - HTTPS accessibility
   - Response times
   - HTTP status codes

3. **Security Headers**
   - HSTS (Strict-Transport-Security)
   - CSP (Content-Security-Policy)
   - X-Content-Type-Options
   - X-Frame-Options
   - X-XSS-Protection
   - Referrer-Policy

4. **System Resources**
   - Disk space usage
   - Memory utilization
   - CPU load

5. **Network Connectivity**
   - Docker network status
   - Inter-container communication
   - External connectivity

6. **Application-Specific Checks**
   - RustDesk server status
   - Portainer API health
   - Caddy error logs
   - Git repository status

### Alert Levels

1. **INFO**: Normal operations, no issues
2. **WARNING**: Non-critical issues (e.g., high resource usage)
3. **ERROR**: Critical issues requiring attention
4. **CRITICAL**: System failures needing immediate action

### Email Reports

Enhanced HTML email reports include:
- Visual status indicators
- Container status tables
- Endpoint accessibility results
- Resource usage charts
- Error logs
- Recommended actions
- Quick stats dashboard

## Best Practices

### Regular Validation

1. **Daily Checks**
   ```bash
   # Quick validation
   docker ps --format "table {{.Names}}\t{{.Status}}"
   ```

2. **Weekly Full Validation**
   ```bash
   ./scripts/validate-all.sh
   ```

3. **After Changes**
   - Always run validation after configuration changes
   - Check specific services after updates

### Monitoring Strategy

1. **Automated Monitoring**
   - 15-minute health checks via cron
   - Critical alerts sent immediately
   - Daily summary reports

2. **Manual Checks**
   - Review HTML reports weekly
   - Check metrics trends
   - Analyze error patterns

3. **Response Plan**
   - Document common issues and fixes
   - Create runbooks for alerts
   - Test recovery procedures

## Troubleshooting

### Common Validation Failures

1. **Container Not Running**
   ```bash
   # Check why container stopped
   docker logs <container-name>
   
   # Restart container
   docker start <container-name>
   ```

2. **Network Issues**
   ```bash
   # Verify network exists
   docker network ls
   
   # Reconnect container
   docker network connect <network> <container>
   ```

3. **Endpoint Unreachable**
   ```bash
   # Check Caddy logs
   docker logs caddy
   
   # Verify DNS
   nslookup <endpoint>
   ```

### Monitoring Alert Issues

1. **Too Many Alerts**
   - Adjust thresholds in script
   - Filter warning-only conditions
   - Implement alert suppression

2. **Missing Alerts**
   - Verify cron job running
   - Check notification configuration
   - Review log files for errors

3. **Email Delivery Issues**
   - Verify SMTP configuration
   - Check ssmtp settings
   - Test email manually

## Integration with Other Tools

### Validation Pipeline

```bash
# Full infrastructure check sequence
cd /home/melvin/projects/server

# 1. Check network connectivity
./docker-stack-infrastructure/scripts/check-network-connectivity.sh

# 2. Run full validation
./docker-stack-infrastructure/scripts/validate-all.sh

# 3. Run monitoring check
./docker-stack-infrastructure/monitoring/scripts/enhanced-monitor.sh

# 4. Review results
cat /home/shared/docker/logs/validation-report.html
```

### CI/CD Integration

These tools can be integrated into CI/CD pipelines:

```yaml
# Example GitLab CI
validate-infrastructure:
  script:
    - ./scripts/validate-all.sh
  only:
    - main
```

## Metrics and Reporting

### Available Metrics

- Container count
- Service availability percentage
- Resource usage trends
- Error frequency
- Response times

### Accessing Metrics

```bash
# View raw metrics
cat /home/shared/docker/logs/metrics.json | jq

# Generate report
./scripts/generate-metrics-report.sh
```

## Related Documentation

- [Docker Infrastructure Overview](../architecture/PROJECT-OVERVIEW.md)
- [Troubleshooting Guide](../../docker-stack-infrastructure/docs/TROUBLESHOOTING.md)
- [Security Review](../security/SECURITY-REVIEW.md)
- [Tools and Scripts Index](../TOOLS-AND-SCRIPTS.md)