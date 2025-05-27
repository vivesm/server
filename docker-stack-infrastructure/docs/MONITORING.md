# Docker Stack Monitoring and Testing System

This document provides comprehensive information about the monitoring, validation, and testing systems for the StringBits Docker infrastructure.

## Overview

The monitoring system automatically checks the health of your Docker containers and services every 15 minutes and sends notifications when issues are detected. It includes comprehensive validation and testing capabilities to ensure your infrastructure remains reliable and robust.

Key features:

- **Multi-channel notifications**: Email, Slack, Discord, Teams, and Telegram
- **Comprehensive container monitoring**: Status, health checks, and logs analysis
- **Network validation**: Configuration and connectivity checks
- **Service endpoint testing**: Availability and response validation
- **Resource monitoring**: Disk space, memory usage, and trend analysis
- **Security validation**: Security headers, configurations, and best practices
- **HTML report generation**: Detailed validation and test reports
- **Metrics collection**: Performance data for trend analysis
- **Smart alerting**: Only sends alerts for critical issues, reducing notification fatigue

## Components

### 1. Enhanced Monitoring Script

**Location**: `/home/shared/docker/enhanced-monitor.sh`

This script performs the following checks:
- Container status for all expected services
- Network configuration and connectivity
- Endpoint availability for all services (n8n, WordPress, RustDesk, Portainer)
- Security headers implemented in Caddy
- Disk space and memory usage
- Portainer and RustDesk specific health checks
- Container logs for critical errors

The monitoring system uses different alert levels:
- **ERROR_DETECTED**: Critical issues that require immediate attention
- **ALERT_TRIGGERED**: Issues that should be addressed but aren't critical
- **WARNING_DETECTED**: Non-critical warnings that don't require immediate action

Notifications are sent based on the severity level, with emails only sent for actual errors that require attention, not for minor warnings.

### 2. Email Alert System

**Location**: 
- Email Template: `/home/shared/improved-email-template.html`
- Test Scripts: `/home/shared/docker/test-email-template.sh`, `/home/shared/docker/test-email-template-updated.sh`

The system uses a modern, responsive HTML email template with:
- Visual status summaries with color-coded indicators
- Organization by sections (Summary, Container Status, Endpoints, Resources)
- Proper formatting for code blocks and command outputs
- Resource usage metrics with visual indicators
- Clear recommendations for resolving detected issues
- Mobile-friendly responsive design

Email notifications are only sent when:
- Critical errors are detected that require immediate attention
- Real service disruptions are occurring
- Not for minor warnings like missing security headers

To test the email system:
```bash
/home/shared/docker/test-email-template-updated.sh
```

### 3. Unified Validation Script

**Location**: `/home/shared/docker/validate-all.sh`

This comprehensive validation script:
- Validates all Docker Compose files
- Checks container status and health
- Validates Caddy configuration
- Verifies network configuration
- Tests Portainer persistence
- Validates RustDesk configuration
- Checks Git repository status
- Tests endpoint accessibility
- Verifies system resources
- Generates HTML test reports

### 4. Network Connectivity Check

**Location**: `/home/shared/docker/check-network-connectivity.sh`

This script specifically checks network connectivity:
- Lists all Docker networks
- Shows containers on each network
- Tests connectivity between critical containers
- Checks web service accessibility

### 5. Notification System

The system supports multiple notification channels:
- Email notifications (via SSMTP)
- Slack notifications
- Discord notifications
- Microsoft Teams notifications
- Telegram notifications

**Email Configuration**: `/etc/ssmtp/ssmtp.conf`

### 6. Metrics Collection

The monitoring system now collects and stores key metrics:
- Container status and count
- Endpoint availability
- Disk and memory usage
- Network connectivity
- Service response times

**Metrics Storage**: `/home/shared/docker/logs/metrics.json`

### 7. Automated Execution

The monitoring script runs automatically every 15 minutes via a cron job.

**Crontab Entry**:
```
*/15 * * * * /home/shared/docker/enhanced-monitor.sh > /dev/null 2>&1
```

**Setup Script**: `/home/shared/docker/setup-cron.sh`

## Testing Functionality

The infrastructure includes comprehensive testing capabilities to ensure all components are working correctly. Tests are automatically run weekly (every Sunday at 4 AM) and can be manually triggered at any time.

### 1. Continuous Validation

The validation system runs checks on:
- **Configuration validity**: Ensures all Docker Compose and Caddy configurations are valid
- **Container health**: Verifies all containers are running and in a healthy state
- **Network connectivity**: Tests that containers can communicate with each other
- **Endpoint accessibility**: Ensures all services are externally accessible
- **Persistence**: Tests that data persists across container restarts
- **Security**: Validates security headers and configurations
- **Resource usage**: Monitors disk and memory usage

### 2. End-to-End Service Tests

The testing system performs the following end-to-end tests:
- **Portainer API**: Tests that the Portainer API is accessible and responding correctly
- **WordPress accessibility**: Ensures the WordPress site loads correctly
- **RustDesk connectivity**: Verifies that RustDesk services are properly configured
- **n8n workflow execution**: Tests basic n8n functionality
- **Caddy security headers**: Verifies security headers are correctly implemented
- **Network connectivity**: Tests inter-container connectivity
- **Docker configuration**: Validates all Docker Compose files

### 3. Running Tests

To run the full validation suite:

```bash
sudo /home/shared/docker/validate-all.sh
```

To run specific tests:

```bash
# Test network connectivity
sudo /home/shared/docker/check-network-connectivity.sh

# Test Portainer persistence
sudo /home/shared/docker/validate-portainer-persistence.sh

# Test configurations
sudo /home/shared/docker/validate-configs.sh
```

### 4. Test Reports

The validation script generates a comprehensive HTML report at:
```
/home/shared/docker/logs/validation-report.html
```

This report includes:
- Summary of passed and failed tests
- Detailed test results
- Full validation log
- Timestamp and server information

## Maintenance and Troubleshooting

The monitoring system is designed to be self-maintaining, with automatic log rotation and cleanup. The `cleanup.sh` script runs regularly to remove old logs and temporary files.

### Logs

You can check the following logs for troubleshooting:
- Email delivery logs: `/var/log/mail.log`
- Monitor script logs: `/home/shared/docker/logs/monitor.log`
- Validation logs: `/home/shared/docker/logs/validation.log`
- Metrics data: `/home/shared/docker/logs/metrics.json`

### Modifying Email Recipients

To change the email recipient, edit the `NOTIFICATION_EMAIL` variable in the `/home/shared/docker/enhanced-monitor.sh` script:

```bash
NOTIFICATION_EMAIL="new-recipient@example.com"
```

### Adding Other Notification Channels

To enable additional notification channels, update the following variables in the enhanced-monitor.sh script:

```bash
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."
TEAMS_WEBHOOK_URL="https://outlook.office.com/webhook/..."
TELEGRAM_BOT_TOKEN="your-telegram-bot-token"
TELEGRAM_CHAT_ID="your-telegram-chat-id"
```

### Testing the System

To manually run the monitoring system:

```bash
sudo /home/shared/docker/enhanced-monitor.sh
```

To test email delivery specifically:

```bash
sudo /home/shared/docker/test-email-template-updated.sh
```

### Customizing Email Alerts

The email template is located at:
```
/home/shared/improved-email-template.html
```

This HTML template can be modified to change the formatting, styling, and organization of email alerts.

### Customizing Monitoring Thresholds

You can adjust the monitoring thresholds by editing the following variables in the enhanced-monitor.sh script:

```bash
DISK_WARNING_THRESHOLD=80     # Warning at 80% disk usage
DISK_CRITICAL_THRESHOLD=90    # Critical at 90% disk usage
MEMORY_WARNING_THRESHOLD=80   # Warning at 80% memory usage
MEMORY_CRITICAL_THRESHOLD=90  # Critical at 90% memory usage
```

### Alert Levels

To adjust which conditions trigger email alerts, modify the logic in the `send_email` section of the enhanced-monitor.sh script:

```bash
# Current settings only send emails for:
# 1. Critical errors (ERROR_DETECTED=1)
# 2. Regular errors without warnings (ALERT_TRIGGERED=1 && WARNING_DETECTED=0)
# 3. Warnings are logged but don't trigger emails by default
```

## Security Considerations

- All credentials are stored securely with restricted permissions
- Email communication is encrypted using TLS
- The monitoring system runs with appropriate permissions
- Validation reports include only non-sensitive information

## Adding New Services

When adding new services to the infrastructure:

1. Add the service to the `EXPECTED_CONTAINERS` array in enhanced-monitor.sh
2. Add the service endpoint to the `SERVICES` array if applicable
3. Update the validation script to include the new service
4. Run a full validation to ensure the new service is properly monitored
5. Update docker-compose files as needed
6. If the service requires special health checks, add them to enhanced-monitor.sh

## Troubleshooting Common Issues

1. **Email notifications not working**:
   - Check SSMTP configuration in /etc/ssmtp/ssmtp.conf
   - Verify sender address is sb-admin@stringbits.com
   - Run test-email-template-updated.sh to test email delivery
   - Check mail logs: `tail -f /var/log/mail.log`

2. **Container status alerts**:
   - Check the container logs: `docker logs [container_name]`
   - Verify Docker service is running: `systemctl status docker`
   - Check for network issues: `./check-network-connectivity.sh`

3. **Disk space alerts**:
   - Run cleanup.sh to remove old logs and temporary files
   - Check Docker volume usage: `docker system df -v`
   - Remove unused Docker images: `docker image prune -a`

4. **Network connectivity issues**:
   - Verify Docker networks: `docker network ls`
   - Check network settings: `docker network inspect stringbits_net`
   - Test inter-container connectivity: `./check-network-connectivity.sh`

5. **Service endpoint failures**:
   - Check Caddy configuration: `docker exec caddy caddy validate --config /etc/caddy/Caddyfile`
   - Verify DNS resolution: `host [endpoint]`
   - Test HTTPS configuration: `curl -vI https://[endpoint]`

6. **Receiving too many alert emails**:
   - The system is configured to only send alerts for critical issues
   - If you're receiving too many alerts, check the `/home/shared/docker/enhanced-monitor.sh` script
   - Modify the conditions in the `if [ ${ERROR_DETECTED} -eq 1 ]` section to adjust when emails are sent
   - You can also adjust warning thresholds (e.g., increase DISK_WARNING_THRESHOLD from 80 to 85)