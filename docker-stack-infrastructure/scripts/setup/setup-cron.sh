#!/bin/bash
# Setup cron jobs for Docker Stack Infrastructure monitoring and maintenance

# Exit on error
set -e

echo "Setting up cron jobs for monitoring and maintenance..."

# Create a temporary file for crontab
TEMP_CRONTAB=$(mktemp)

# Get current crontab content
crontab -l > "$TEMP_CRONTAB" 2>/dev/null || echo "# Docker Stack Infrastructure cron jobs" > "$TEMP_CRONTAB"

# Add monitoring job (every 15 minutes)
if ! grep -q "enhanced-monitor.sh" "$TEMP_CRONTAB"; then
  echo "*/15 * * * * /home/shared/docker/enhanced-monitor.sh > /dev/null 2>&1" >> "$TEMP_CRONTAB"
  echo "Added monitoring job (runs every 15 minutes)"
else
  echo "Monitoring job already exists"
fi

# Add daily validation job (3 AM)
if ! grep -q "validate-all.sh" "$TEMP_CRONTAB"; then
  echo "0 3 * * * /home/shared/docker/validate-all.sh > /home/shared/docker/logs/validation.log 2>&1" >> "$TEMP_CRONTAB"
  echo "Added validation job (runs daily at 3 AM)"
else
  echo "Validation job already exists"
fi

# Add weekly comprehensive test job (Sunday, 4 AM)
if ! grep -q "run-tests.sh" "$TEMP_CRONTAB"; then
  echo "0 4 * * 0 /home/shared/docker/run-tests.sh > /home/shared/docker/logs/tests.log 2>&1" >> "$TEMP_CRONTAB"
  echo "Added weekly test job (runs Sunday at 4 AM)"
else
  echo "Weekly test job already exists"
fi

# Add cleanup job (Saturday, 2 AM)
if ! grep -q "cleanup.sh" "$TEMP_CRONTAB"; then
  echo "0 2 * * 6 /home/shared/docker/cleanup.sh > /dev/null 2>&1" >> "$TEMP_CRONTAB"
  echo "Added cleanup job (runs Saturday at 2 AM)"
else
  echo "Cleanup job already exists"
fi

# Set the crontab
crontab "$TEMP_CRONTAB"

# Remove the temporary file
rm "$TEMP_CRONTAB"

echo "Cron jobs setup completed!"
echo "To view current cron jobs: crontab -l"