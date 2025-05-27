#!/bin/bash
# Enhanced Docker Stack Health Monitoring Script
# This script monitors the health of Docker containers and services
# and sends notifications if issues are detected

# Exit on error
set -eo pipefail

# Configuration
NOTIFICATION_EMAIL="melvin@stringbits.com"    # Change to your email
SLACK_WEBHOOK_URL=""                          # Optional: Add your Slack webhook URL
DISCORD_WEBHOOK_URL=""                        # Optional: Add your Discord webhook URL
TEAMS_WEBHOOK_URL=""                          # Optional: Add your Microsoft Teams webhook URL
TELEGRAM_BOT_TOKEN=""                         # Optional: Add your Telegram bot token
TELEGRAM_CHAT_ID=""                           # Optional: Add your Telegram chat ID

# Services to monitor
SERVICES=("n8n.stringbits.com" "wp.stringbits.com" "rd.stringbits.com" "ptn.stringbits.com")
EXPECTED_CONTAINERS=("portainer" "caddy" "n8n" "watchtower" "wordpress" "mysql" "rustdesk-hbbs" "rustdesk-hbbr" "git-daemon")

# Network configuration
EXPECTED_NETWORKS=("stringbits_net" "docker_stringbits_net")

# Monitoring thresholds
DISK_WARNING_THRESHOLD=80
DISK_CRITICAL_THRESHOLD=90
MEMORY_WARNING_THRESHOLD=80
MEMORY_CRITICAL_THRESHOLD=90

# Log file
LOG_DIR="/home/shared/docker/logs"
LOG_FILE="${LOG_DIR}/monitor.log"
METRICS_FILE="${LOG_DIR}/metrics.json"
# Configure alert levels based on the severity of issues
ALERT_TRIGGERED=0
ERROR_DETECTED=0
WARNING_DETECTED=0

# Make sure log directory exists
mkdir -p "${LOG_DIR}"

# Create temporary files for the full report and specific sections
REPORT_FILE=$(mktemp)
READABLE_REPORT_FILE=$(mktemp)
CONTAINER_STATUS_FILE=$(mktemp)
ENDPOINT_STATUS_FILE=$(mktemp)
RESOURCE_STATUS_FILE=$(mktemp)
ERROR_LOGS_FILE=$(mktemp)
COMMAND_OUTPUT_FILE=$(mktemp)
RECOMMENDATIONS_FILE=$(mktemp)
STATUS_SUMMARY_FILE=$(mktemp)

# Colors for console output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to strip ANSI color codes
strip_ansi_colors() {
  sed 's/\x1b\[[0-9;]*m//g'
}

# Function to log messages
log() {
  local level=$1
  local message=$2
  local color=$NC
  
  case $level in
    "INFO") color=$GREEN ;;
    "WARN") color=$YELLOW ;;
    "ERROR") color=$RED ;;
    "DEBUG") color=$BLUE ;;
  esac
  
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo -e "${timestamp} - [${level}] ${message}" >> "${LOG_FILE}"
  echo -e "${color}${timestamp} - [${level}] ${message}${NC}" >> "${REPORT_FILE}"
  
  # Also add a clean version without color codes for email
  echo -e "${timestamp} - [${level}] ${message}" | strip_ansi_colors >> "${READABLE_REPORT_FILE}"
  
  # Also print to console if not running from cron
  if [ -t 1 ]; then
    echo -e "${color}${timestamp} - [${level}] ${message}${NC}"
  fi
  
  # Add to section files based on content type
  case $level in
    "ERROR")
      echo "${timestamp} - [${level}] ${message}" >> "${ERROR_LOGS_FILE}"
      ;;
  esac
}

# Function to add content to the container status table
add_container_status() {
  local container=$1
  local status=$2
  local status_class=$3
  
  echo "<tr>
    <td>${container}</td>
    <td><span class=\"badge badge-${status_class}\">${status}</span></td>
  </tr>" >> "${CONTAINER_STATUS_FILE}"
}

# Function to add content to the endpoint status table
add_endpoint_status() {
  local endpoint=$1
  local status=$2
  local http_code=$3
  local status_class=$4
  
  echo "<tr>
    <td>${endpoint}</td>
    <td><span class=\"badge badge-${status_class}\">${status}</span></td>
    <td>${http_code}</td>
  </tr>" >> "${ENDPOINT_STATUS_FILE}"
}

# Function to add command output
add_command_output() {
  local command=$1
  local output=$2
  
  echo -e "$ ${command}\n${output}\n" >> "${COMMAND_OUTPUT_FILE}"
}

# Function to add recommendation
add_recommendation() {
  local recommendation=$1
  
  echo "<li>${recommendation}</li>" >> "${RECOMMENDATIONS_FILE}"
}

# Function to record metrics
record_metric() {
  local metric_name=$1
  local metric_value=$2
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  
  # Create or update metrics file
  if [ ! -f "${METRICS_FILE}" ]; then
    echo "{\"metrics\":[]}" > "${METRICS_FILE}"
  fi
  
  # Add metric to file
  local temp_file=$(mktemp)
  jq ".metrics += [{\"name\":\"${metric_name}\",\"value\":\"${metric_value}\",\"timestamp\":\"${timestamp}\"}]" "${METRICS_FILE}" > "${temp_file}"
  mv "${temp_file}" "${METRICS_FILE}"
}

# Function to send email notification
send_email() {
  local subject="$1"
  
  if [ -n "${NOTIFICATION_EMAIL}" ]; then
    # Add timestamp and hostname to subject
    local email_subject="[Stringbits-VPS] ${subject} - $(hostname) - $(date '+%Y-%m-%d %H:%M')"
    
    # Create tables for container status
    local container_status_table="<table>
      <tr>
        <th>Container</th>
        <th>Status</th>
      </tr>
      $(cat "${CONTAINER_STATUS_FILE}")
    </table>"
    
    # Create tables for endpoint status
    local endpoint_status_table="<table>
      <tr>
        <th>Endpoint</th>
        <th>Status</th>
        <th>HTTP Code</th>
      </tr>
      $(cat "${ENDPOINT_STATUS_FILE}")
    </table>"
    
    # Format resource status
    local resource_status="$(cat "${RESOURCE_STATUS_FILE}")"
    
    # Format error logs
    local error_logs="$(cat "${ERROR_LOGS_FILE}")"
    if [ -z "${error_logs}" ]; then
      error_logs="No error logs found."
    fi
    
    # Format command outputs
    local command_outputs="$(cat "${COMMAND_OUTPUT_FILE}")"
    if [ -z "${command_outputs}" ]; then
      command_outputs="No command outputs recorded."
    fi
    
    # Format recommendations
    local recommendations="$(cat "${RECOMMENDATIONS_FILE}")"
    if [ -z "${recommendations}" ]; then
      recommendations="<li>No specific recommendations at this time.</li>"
    fi
    
    # Format status summary
    local status_summary="$(cat "${STATUS_SUMMARY_FILE}")"
    if [ -z "${status_summary}" ]; then
      if [ ${ERROR_DETECTED} -eq 1 ]; then
        status_summary="<p class='error'>Critical issues have been detected with your Docker stack. Please review the detailed report below.</p>"
      elif [ ${ALERT_TRIGGERED} -eq 1 ]; then
        status_summary="<p class='warning'>Issues have been detected with your Docker stack. Please review the detailed report below.</p>"
      elif [ ${WARNING_DETECTED} -eq 1 ]; then
        status_summary="<p class='warning'>Some minor warnings have been detected, but no critical issues found.</p>"
      else
        status_summary="<p class='success'>All systems are operating normally. No issues detected.</p>"
      fi
    fi
    
    # Determine status badge
    local status_badge
    if [ ${ERROR_DETECTED} -eq 1 ]; then
      status_badge="<span class='badge badge-error'>⚠️ CRITICAL ISSUES</span>"
      header_status_class="status-error"
    elif [ ${ALERT_TRIGGERED} -eq 1 ]; then
      status_badge="<span class='badge badge-warning'>⚠️ ALERT</span>"
      header_status_class="status-warning"
    elif [ ${WARNING_DETECTED} -eq 1 ]; then
      status_badge="<span class='badge badge-warning'>⚠️ WARNING</span>"
      header_status_class="status-warning"
    else
      status_badge="<span class='badge badge-success'>✅ ALL SYSTEMS NORMAL</span>"
      header_status_class="status-ok"
    fi
    
    # Calculate stats
    local containers_running=$(docker ps --format '{{.Names}}' | wc -l)
    local disk_usage=$(df -h / | tail -n 1 | awk '{print $5}' | cut -d'%' -f1)
    local memory_info=$(free -m)
    local total_memory=$(echo "${memory_info}" | grep Mem | awk '{print $2}')
    local used_memory=$(echo "${memory_info}" | grep Mem | awk '{print $3}')
    local memory_percent=$((used_memory * 100 / total_memory))
    local services_up=0
    for svc in "${SERVICES[@]}"; do
      local http_code=$(curl -s -o /dev/null -w "%{http_code}" -m 5 "https://${svc}" 2>/dev/null)
      if [ "${http_code}" -ge 200 ] && [ "${http_code}" -lt 400 ]; then
        services_up=$((services_up + 1))
      fi
    done
    
    # Read HTML template
    local template_file="/home/shared/improved-email-template.html"
    if [ ! -f "${template_file}" ]; then
      log "ERROR" "Email template file not found at ${template_file}!"
      return 1
    fi
    
    local email_template=$(cat "${template_file}")
    
    # Replace placeholders with actual content
    email_template="${email_template//STATUS_BADGE_PLACEHOLDER/$status_badge}"
    email_template="${email_template//STATUS_SUMMARY_PLACEHOLDER/$status_summary}"
    email_template="${email_template//CONTAINER_STATUS_TABLE_PLACEHOLDER/$container_status_table}"
    email_template="${email_template//ENDPOINT_STATUS_TABLE_PLACEHOLDER/$endpoint_status_table}"
    email_template="${email_template//RESOURCE_STATUS_PLACEHOLDER/$resource_status}"
    email_template="${email_template//ERROR_LOGS_PLACEHOLDER/$error_logs}"
    email_template="${email_template//COMMAND_OUTPUTS_PLACEHOLDER/$command_outputs}"
    email_template="${email_template//RECOMMENDATIONS_PLACEHOLDER/$recommendations}"
    
    # Replace stats in JavaScript variables
    email_template="${email_template//CONTAINERS_RUNNING_COUNT/$containers_running}"
    email_template="${email_template//DISK_USAGE_PERCENT/$disk_usage}"
    email_template="${email_template//MEMORY_USAGE_PERCENT/$memory_percent}"
    email_template="${email_template//SERVICES_UP_COUNT/$services_up}"
    
    # Update the header status class based on the overall status
    email_template="${email_template//status-warning/${header_status_class}}"
    
    # Create email content with headers for ssmtp
    local email_content="Subject: ${email_subject}
To: ${NOTIFICATION_EMAIL}
From: Stringbits-VPS Service Monitor <sb-admin@stringbits.com>
Content-Type: text/html; charset=UTF-8

${email_template}"
    
    # Send using ssmtp
    echo "${email_content}" | ssmtp "${NOTIFICATION_EMAIL}"
    log "INFO" "Email notification sent to ${NOTIFICATION_EMAIL}"
  fi
}

# Function to send Slack notification
send_slack() {
  local message="$1"
  
  if [ -n "${SLACK_WEBHOOK_URL}" ]; then
    # Format message for Slack
    local json_payload=$(jq -n \
      --arg text "${message}" \
      '{text: $text}')
    
    curl -s -X POST -H 'Content-type: application/json' \
      --data "${json_payload}" \
      "${SLACK_WEBHOOK_URL}"
    log "INFO" "Slack notification sent"
  fi
}

# Function to send Discord notification
send_discord() {
  local message="$1"
  
  if [ -n "${DISCORD_WEBHOOK_URL}" ]; then
    # Format message for Discord
    local json_payload=$(jq -n \
      --arg content "${message}" \
      '{content: $content}')
    
    curl -s -X POST -H "Content-Type: application/json" \
      --data "${json_payload}" \
      "${DISCORD_WEBHOOK_URL}"
    log "INFO" "Discord notification sent"
  fi
}

# Function to send Microsoft Teams notification
send_teams() {
  local message="$1"
  
  if [ -n "${TEAMS_WEBHOOK_URL}" ]; then
    # Format message for Microsoft Teams
    local json_payload=$(jq -n \
      --arg title "Docker Stack Monitor Alert" \
      --arg text "${message}" \
      '{
        "@type": "MessageCard",
        "@context": "http://schema.org/extensions",
        "themeColor": "0076D7",
        "summary": "Docker Stack Monitor Alert",
        "sections": [{
          "activityTitle": $title,
          "text": $text
        }]
      }')
    
    curl -s -X POST -H "Content-Type: application/json" \
      --data "${json_payload}" \
      "${TEAMS_WEBHOOK_URL}"
    log "INFO" "Microsoft Teams notification sent"
  fi
}

# Function to send Telegram notification
send_telegram() {
  local message="$1"
  
  if [ -n "${TELEGRAM_BOT_TOKEN}" ] && [ -n "${TELEGRAM_CHAT_ID}" ]; then
    curl -s -X POST \
      "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      -d chat_id="${TELEGRAM_CHAT_ID}" \
      -d text="${message}" \
      -d parse_mode="HTML"
    log "INFO" "Telegram notification sent"
  fi
}

# Function to check if container is running
check_container() {
  local container=$1
  local container_status=$(docker ps -f "name=^${container}$" --format "{{.Status}}" 2>/dev/null)
  
  if [ -z "${container_status}" ]; then
    log "ERROR" "Container ${container} is not running!"
    STOPPED_CONTAINERS+=("${container}")
    add_container_status "${container}" "STOPPED" "error"
    add_recommendation "Start the ${container} container: <code>docker start ${container}</code>"
    echo "<p class='error'>Container ${container} is not running!</p>" >> "${STATUS_SUMMARY_FILE}"
    ERROR_DETECTED=1
    return 1
  elif [[ "${container_status}" == *"Up"* ]]; then
    log "INFO" "✅ ${container}: ${container_status}"
    add_container_status "${container}" "RUNNING" "success"
    return 0
  else
    log "WARN" "⚠️ ${container}: ${container_status}"
    STOPPED_CONTAINERS+=("${container}")
    add_container_status "${container}" "WARNING" "warning"
    add_recommendation "Check the ${container} container status: <code>docker logs ${container}</code>"
    echo "<p class='warning'>Container ${container} status: ${container_status}</p>" >> "${STATUS_SUMMARY_FILE}"
    return 1
  fi
}

# Function to check container logs for errors
check_container_logs() {
  local container=$1
  local error_patterns=$2
  local log_since=${3:-"15m"}
  
  if docker ps -q -f "name=${container}" &>/dev/null; then
    # Get container logs from the last 15 minutes
    local container_logs=$(docker logs --since "${log_since}" "${container}" 2>&1)
    
    # Check for error patterns
    if echo "${container_logs}" | grep -iE "${error_patterns}" &>/dev/null; then
      log "WARN" "⚠️ Found error patterns in ${container} logs"
      local error_examples=$(echo "${container_logs}" | grep -iE "${error_patterns}" | head -n 5)
      log "DEBUG" "Error logs: ${error_examples}"
      
      # Format log examples for HTML
      echo "${error_examples}" | strip_ansi_colors >> "${ERROR_LOGS_FILE}"
      
      add_recommendation "Review ${container} logs for errors: <code>docker logs ${container}</code>"
      return 1
    else
      log "INFO" "✅ No error patterns found in ${container} logs"
      return 0
    fi
  else
    log "WARN" "⚠️ Cannot check logs for ${container} - container not running"
    return 1
  fi
}

# Function to check endpoint connectivity
check_endpoint() {
  local endpoint=$1
  local expected_code=${2:-200}
  local timeout=${3:-10}
  
  log "INFO" "Checking ${endpoint}..."
  local http_code=$(curl -s -o /dev/null -w "%{http_code}" -m "${timeout}" "https://${endpoint}" 2>/dev/null)
  local curl_status=$?
  
  if [ $curl_status -ne 0 ]; then
    log "ERROR" "Could not connect to ${endpoint} (curl error: ${curl_status})"
    record_metric "endpoint_${endpoint//./_}" "0"
    add_endpoint_status "${endpoint}" "UNREACHABLE" "0" "error"
    add_recommendation "Check if ${endpoint} is accessible and the Caddy configuration is correct"
    echo "<p class='error'>Endpoint ${endpoint} is unreachable!</p>" >> "${STATUS_SUMMARY_FILE}"
    return 1
  elif [ "${http_code}" -lt 200 ] || [ "${http_code}" -ge 400 ]; then
    log "ERROR" "${endpoint} returned HTTP code ${http_code}"
    record_metric "endpoint_${endpoint//./_}" "${http_code}"
    add_endpoint_status "${endpoint}" "ERROR" "${http_code}" "error"
    add_recommendation "Check the service running at ${endpoint}, HTTP code: ${http_code}"
    echo "<p class='error'>Endpoint ${endpoint} returned HTTP code ${http_code}</p>" >> "${STATUS_SUMMARY_FILE}"
    return 1
  else
    log "INFO" "✅ ${endpoint} HTTP Code: ${http_code}"
    record_metric "endpoint_${endpoint//./_}" "${http_code}"
    add_endpoint_status "${endpoint}" "OK" "${http_code}" "success"
    return 0
  fi
}

# Function to check security headers
check_security_headers() {
  local endpoint=$1
  local required_headers=("Strict-Transport-Security" "Content-Security-Policy" "X-Content-Type-Options" "X-Frame-Options" "X-XSS-Protection" "Referrer-Policy")
  local missing_headers=()
  
  log "INFO" "Checking security headers for ${endpoint}..."
  local headers=$(curl -sI "https://${endpoint}" 2>/dev/null)
  
  if [ -z "${headers}" ]; then
    log "ERROR" "Could not fetch headers from ${endpoint}"
    return 1
  fi
  
  # Check for each required header
  for header in "${required_headers[@]}"; do
    if ! echo "${headers}" | grep -q "${header}"; then
      missing_headers+=("${header}")
    fi
  done
  
  if [ ${#missing_headers[@]} -eq 0 ]; then
    log "INFO" "✅ All security headers are configured correctly"
    return 0
  else
    log "WARN" "⚠️ Missing security headers: ${missing_headers[*]}"
    log "DEBUG" "Current headers:\n${headers}"
    
    # Add properly formatted header info to log file
    echo -e "Current headers:\n${headers}" | strip_ansi_colors >> "${ERROR_LOGS_FILE}"
    
    add_recommendation "Add missing security headers to Caddy configuration: ${missing_headers[*]}"
    echo "<p class='warning'>Missing security headers: ${missing_headers[*]}</p>" >> "${STATUS_SUMMARY_FILE}"
    WARNING_DETECTED=1
    return 1
  fi
}

# Function to check disk space
check_disk_space() {
  local mount_point=$1
  local disk_usage=$(df -h "${mount_point}" | tail -n 1)
  local disk_percent=$(echo ${disk_usage} | awk '{print $5}' | cut -d'%' -f1)
  
  record_metric "disk_usage_percent" "${disk_percent}"
  
  # Add to resource status section
  echo "<h4>Disk Usage (${mount_point})</h4>" >> "${RESOURCE_STATUS_FILE}"
  
  if [ "${disk_percent}" -ge "${DISK_CRITICAL_THRESHOLD}" ]; then
    log "ERROR" "CRITICAL: Disk usage at ${mount_point} is ${disk_percent}%"
    echo "<p class='error'>CRITICAL: Disk usage is at ${disk_percent}% (threshold: ${DISK_CRITICAL_THRESHOLD}%)</p>" >> "${RESOURCE_STATUS_FILE}"
    echo "<p class='error'>CRITICAL: Disk usage at ${mount_point} is ${disk_percent}%</p>" >> "${STATUS_SUMMARY_FILE}"
    add_recommendation "Free up disk space immediately or increase disk capacity"
    add_recommendation "Run cleanup script: <code>./docker/cleanup.sh</code>"
    return 2
  elif [ "${disk_percent}" -ge "${DISK_WARNING_THRESHOLD}" ]; then
    log "WARN" "WARNING: Disk usage at ${mount_point} is ${disk_percent}%"
    echo "<p class='warning'>WARNING: Disk usage is at ${disk_percent}% (threshold: ${DISK_WARNING_THRESHOLD}%)</p>" >> "${RESOURCE_STATUS_FILE}"
    echo "<p class='warning'>WARNING: Disk usage at ${mount_point} is ${disk_percent}%</p>" >> "${STATUS_SUMMARY_FILE}"
    add_recommendation "Consider freeing up disk space: <code>docker system prune</code>"
    return 1
  else
    log "INFO" "✅ Disk usage at ${mount_point}: ${disk_percent}%"
    echo "<p class='success'>Disk usage is at ${disk_percent}% (healthy)</p>" >> "${RESOURCE_STATUS_FILE}"
    return 0
  fi
}

# Function to check memory usage
check_memory() {
  local memory_info=$(free -m)
  local total_memory=$(echo "${memory_info}" | grep Mem | awk '{print $2}')
  local used_memory=$(echo "${memory_info}" | grep Mem | awk '{print $3}')
  local memory_percent=$((used_memory * 100 / total_memory))
  
  record_metric "memory_usage_percent" "${memory_percent}"
  
  # Add to resource status section
  echo "<h4>Memory Usage</h4>" >> "${RESOURCE_STATUS_FILE}"
  
  if [ "${memory_percent}" -ge "${MEMORY_CRITICAL_THRESHOLD}" ]; then
    log "ERROR" "CRITICAL: Memory usage is ${memory_percent}%"
    echo "<p class='error'>CRITICAL: Memory usage is at ${memory_percent}% (threshold: ${MEMORY_CRITICAL_THRESHOLD}%)</p>" >> "${RESOURCE_STATUS_FILE}"
    echo "<p class='error'>CRITICAL: Memory usage is ${memory_percent}%</p>" >> "${STATUS_SUMMARY_FILE}"
    add_recommendation "Reduce memory usage or increase server memory"
    add_recommendation "Restart memory-intensive containers: <code>docker restart [container]</code>"
    return 2
  elif [ "${memory_percent}" -ge "${MEMORY_WARNING_THRESHOLD}" ]; then
    log "WARN" "WARNING: Memory usage is ${memory_percent}%"
    echo "<p class='warning'>WARNING: Memory usage is at ${memory_percent}% (threshold: ${MEMORY_WARNING_THRESHOLD}%)</p>" >> "${RESOURCE_STATUS_FILE}"
    echo "<p class='warning'>WARNING: Memory usage is ${memory_percent}%</p>" >> "${STATUS_SUMMARY_FILE}"
    add_recommendation "Monitor memory usage and consider optimizing container limits"
    return 1
  else
    log "INFO" "✅ Memory usage: ${memory_percent}%"
    echo "<p class='success'>Memory usage is at ${memory_percent}% (healthy)</p>" >> "${RESOURCE_STATUS_FILE}"
    return 0
  fi
}

# Function to check network connectivity
check_network_connectivity() {
  local container=$1
  local target=$2
  
  if ! docker ps -q -f "name=${container}" &>/dev/null; then
    log "WARN" "⚠️ Cannot check network for ${container} - container not running"
    return 1
  fi
  
  if docker exec "${container}" ping -c 1 -W 1 "${target}" &>/dev/null; then
    log "INFO" "✅ ${container} can connect to ${target}"
    return 0
  else
    log "WARN" "⚠️ ${container} cannot connect to ${target}"
    add_recommendation "Check network connectivity between ${container} and ${target}"
    echo "<p class='warning'>${container} cannot connect to ${target}</p>" >> "${STATUS_SUMMARY_FILE}"
    return 1
  fi
}

# Function to check Docker networks
check_docker_networks() {
  for network in "${EXPECTED_NETWORKS[@]}"; do
    if docker network inspect "${network}" &>/dev/null; then
      log "INFO" "✅ Network ${network} exists"
    else
      log "ERROR" "❌ Network ${network} does not exist"
      add_recommendation "Create missing Docker network: <code>docker network create ${network}</code>"
      echo "<p class='error'>Network ${network} does not exist!</p>" >> "${STATUS_SUMMARY_FILE}"
      ALERT_TRIGGERED=1
    fi
  done
  
  # Check if critical containers are on both networks
  critical_containers=("portainer" "caddy")
  for container in "${critical_containers[@]}"; do
    for network in "${EXPECTED_NETWORKS[@]}"; do
      if docker network inspect "${network}" --format '{{range .Containers}}{{.Name}}{{"\n"}}{{end}}' 2>/dev/null | grep -q "${container}"; then
        log "INFO" "✅ ${container} is connected to ${network}"
      else
        log "ERROR" "❌ ${container} is not connected to ${network}"
        add_recommendation "Connect ${container} to ${network}: <code>docker network connect ${network} ${container}</code>"
        echo "<p class='error'>${container} is not connected to ${network}</p>" >> "${STATUS_SUMMARY_FILE}"
        ALERT_TRIGGERED=1
      fi
    done
  done
}

# Function to run validation scripts
run_validation() {
  local script=$1
  local name=$2
  
  if [ -f "${script}" ] && [ -x "${script}" ]; then
    log "INFO" "Running ${name} validation..."
    if "${script}" &>/dev/null; then
      log "INFO" "✅ ${name} validation passed"
      return 0
    else
      log "WARN" "⚠️ ${name} validation failed"
      add_recommendation "Check the ${name} validation script: <code>${script}</code>"
      echo "<p class='warning'>${name} validation failed</p>" >> "${STATUS_SUMMARY_FILE}"
      return 1
    fi
  else
    log "WARN" "⚠️ ${name} validation script not found or not executable"
    return 1
  fi
}

# Function to check Git repository status
check_git_repo() {
  local repo_path=$1
  local name=$2
  
  if [ -d "${repo_path}/.git" ]; then
    cd "${repo_path}"
    
    # Check for uncommitted changes
    if git status --porcelain | grep -q .; then
      log "WARN" "⚠️ ${name} repository has uncommitted changes"
      add_recommendation "Commit and push changes in ${name} repository"
      echo "<p class='warning'>${name} repository has uncommitted changes</p>" >> "${STATUS_SUMMARY_FILE}"
      return 1
    else
      log "INFO" "✅ ${name} repository is clean"
      return 0
    fi
  else
    log "WARN" "⚠️ ${name} is not a Git repository"
    add_recommendation "Initialize ${name} as a Git repository"
    return 1
  fi
}

# Function to generate service report
generate_service_report() {
  local title=$1
  shift
  local services=("$@")
  
  log "INFO" "\n===== ${title} ====="
  for service in "${services[@]}"; do
    check_container "${service}"
  done
}

# Start the monitoring script
log "INFO" "========== Docker Stack Health Check Started: $(date) =========="

# Check if Docker is running
if ! docker info &>/dev/null; then
  log "ERROR" "Docker service is not running!"
  echo "<p class='error'>Docker service is not running!</p>" >> "${STATUS_SUMMARY_FILE}"
  add_recommendation "Start Docker service: <code>systemctl start docker</code>"
  ALERT_TRIGGERED=1
else
  log "INFO" "Docker service is running"
  
  # Generate metrics
  record_metric "docker_running" "1"
  record_metric "docker_containers" "$(docker ps -q | wc -l)"
  record_metric "docker_images" "$(docker images -q | wc -l)"
  record_metric "docker_volumes" "$(docker volume ls -q | wc -l)"
fi

# Check network configuration
check_docker_networks

# Check container status
log "INFO" "\n🩺 Container Status:"
CONTAINER_CHECK_FAILED=0
STOPPED_CONTAINERS=()

for container in "${EXPECTED_CONTAINERS[@]}"; do
  if ! check_container "${container}"; then
    CONTAINER_CHECK_FAILED=1
  fi
done

if [ ${CONTAINER_CHECK_FAILED} -eq 1 ]; then
  ALERT_TRIGGERED=1
fi

# Group services by function
generate_service_report "Core Infrastructure" "portainer" "caddy" "watchtower"
generate_service_report "Applications" "n8n" "wordpress" "mysql"
generate_service_report "RustDesk" "rustdesk-hbbs" "rustdesk-hbbr"
generate_service_report "Git Service" "git-daemon"

# List all running containers
docker_ps=$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")
log "INFO" "\nAll running containers:\n${docker_ps}"
add_command_output "docker ps" "${docker_ps}" 

# Check endpoint connectivity
log "INFO" "\n🌐 Endpoint Checks:"
ENDPOINT_CHECK_FAILED=0

for svc in "${SERVICES[@]}"; do
  if ! check_endpoint "${svc}"; then
    ENDPOINT_CHECK_FAILED=1
  fi
done

if [ ${ENDPOINT_CHECK_FAILED} -eq 1 ]; then
  ALERT_TRIGGERED=1
fi

# Check security headers
log "INFO" "\n🛡️ Security Headers Check:"
if ! check_security_headers "wp.stringbits.com"; then
  WARNING_DETECTED=1
fi

# Check RustDesk server status specifically
log "INFO" "\n🖥️ RustDesk Server Check:"
if docker ps -q -f "name=rustdesk-hbbs" &>/dev/null && docker ps -q -f "name=rustdesk-hbbr" &>/dev/null; then
  log "INFO" "✅ RustDesk services are running"
  
  # Check RustDesk logs for errors
  check_container_logs "rustdesk-hbbs" "error|critical|failed"
  check_container_logs "rustdesk-hbbr" "error|critical|failed"
  
  # Check public key
  if [ -f "/home/shared/docker/rustdesk/id_ed25519.pub" ]; then
    log "INFO" "✅ RustDesk public key is available"
  else
    log "WARN" "⚠️ RustDesk public key is not available"
    add_recommendation "Generate RustDesk public key"
    echo "<p class='warning'>RustDesk public key is not available</p>" >> "${STATUS_SUMMARY_FILE}"
    WARNING_DETECTED=1
  fi
else
  log "ERROR" "❌ RustDesk services are not running properly"
  add_recommendation "Check RustDesk services and restart if needed"
  echo "<p class='error'>RustDesk services are not running properly</p>" >> "${STATUS_SUMMARY_FILE}"
  ALERT_TRIGGERED=1
fi

# Check Portainer health specifically
log "INFO" "\n🐳 Portainer Health Check:"
if docker ps -q -f "name=portainer" &>/dev/null; then
  log "INFO" "✅ Portainer container is running"
  
  # Check Portainer API accessibility
  portainer_api_test=$(curl -sk -o /dev/null -w "%{http_code}" "https://localhost:9443/api/system/status" 2>/dev/null)
  
  if [ "${portainer_api_test}" -eq "200" ] || [ "${portainer_api_test}" -eq "401" ]; then
    log "INFO" "✅ Portainer API is responding (status: ${portainer_api_test})"
  else
    log "ERROR" "❌ Portainer API not responding properly (status: ${portainer_api_test})"
    add_recommendation "Check Portainer API and restart if needed"
    echo "<p class='error'>Portainer API not responding properly (status: ${portainer_api_test})</p>" >> "${STATUS_SUMMARY_FILE}"
    ALERT_TRIGGERED=1
  fi
  
  # Check if Portainer stacks match Git repository
  if [ -d "/home/shared/git-repos/portainer-stacks" ]; then
    check_git_repo "/home/shared/git-repos/portainer-stacks" "Portainer stacks"
  fi
else
  log "ERROR" "❌ Portainer container is not running"
  add_recommendation "Start Portainer container"
  echo "<p class='error'>Portainer container is not running</p>" >> "${STATUS_SUMMARY_FILE}"
  ALERT_TRIGGERED=1
fi

# Check caddy logs for errors
log "INFO" "\n📝 Caddy Log Check:"
if check_container_logs "caddy" "error|panic|fatal"; then
  log "INFO" "✅ No critical errors in Caddy logs"
else
  ALERT_TRIGGERED=1
fi

# Check system resources
log "INFO" "\n💾 System Resources:"

# Check disk space
if ! check_disk_space "/"; then
  ALERT_TRIGGERED=1
fi

# Show detailed disk usage
disk_usage=$(df -h /)
log "INFO" "Disk usage details:\n${disk_usage}"
add_command_output "df -h /" "${disk_usage}"

# Check memory usage
if ! check_memory; then
  ALERT_TRIGGERED=1
fi

# Run validation scripts
log "INFO" "\n🧪 Validation Checks:"
run_validation "/home/shared/docker/validate-configs.sh" "Configuration"
run_validation "/home/shared/docker/validate-portainer-persistence.sh" "Portainer persistence"

# Send notifications if issues were detected
# Determine if we should send notifications based on the severity of issues
if [ ${ERROR_DETECTED} -eq 1 ]; then
  # Critical errors detected - always send alert
  log "ERROR" "\n❌ CRITICAL ISSUES DETECTED! Sending notifications..."
  
  # Create alert message
  ALERT_MESSAGE="Docker Stack CRITICAL Issues Detected $(date)"
  
  if [ ${#STOPPED_CONTAINERS[@]} -gt 0 ]; then
    ALERT_MESSAGE="${ALERT_MESSAGE}\n\nStopped containers: ${STOPPED_CONTAINERS[*]}"
  fi
  
  # Send notifications through configured channels
  send_email "CRITICAL ALERT: Docker Stack Issues"
  send_slack "${ALERT_MESSAGE}"
  send_discord "${ALERT_MESSAGE}"
  send_teams "${ALERT_MESSAGE}"
  send_telegram "${ALERT_MESSAGE}"
  
elif [ ${ALERT_TRIGGERED} -eq 1 ] && [ ${WARNING_DETECTED} -eq 0 ]; then
  # Only true errors (not just warnings) - send alert
  log "WARN" "\n⚠️ ISSUES DETECTED! Sending notifications..."
  
  # Create alert message
  ALERT_MESSAGE="Docker Stack Issues Detected $(date)"
  
  if [ ${#STOPPED_CONTAINERS[@]} -gt 0 ]; then
    ALERT_MESSAGE="${ALERT_MESSAGE}\n\nStopped containers: ${STOPPED_CONTAINERS[*]}"
  fi
  
  # Send notifications through configured channels
  send_email "ALERT: Docker Stack Issues"
  send_slack "${ALERT_MESSAGE}"
  send_discord "${ALERT_MESSAGE}"
  send_teams "${ALERT_MESSAGE}"
  send_telegram "${ALERT_MESSAGE}"
  
elif [ ${WARNING_DETECTED} -eq 1 ] && [ ${ALERT_TRIGGERED} -eq 0 ]; then
  # Only warnings, no actual errors - log but don't send alert
  log "WARN" "\n⚠️ Minor warnings detected, but no critical issues."
  echo "<p class='warning'>Some non-critical warnings detected, but no major issues.</p>" >> "${STATUS_SUMMARY_FILE}"
  
  # Optionally send warnings-only email (commented out by default)
  # send_email "WARNING: Docker Stack Minor Issues"
  
else
  log "INFO" "\n✅ All systems operational! No issues detected."
  echo "<p class='success'>All systems operational! No issues detected.</p>" >> "${STATUS_SUMMARY_FILE}"
  
  # Optional: Send "all clear" notification
  # Uncomment the line below to enable "all clear" notifications
  # send_email "INFO: All Systems Operational"
fi

log "INFO" "========== End of Health Check =========="

# Print report to console
if [ -t 1 ]; then
  cat "${REPORT_FILE}"
fi

# Clean up
rm "${REPORT_FILE}" "${READABLE_REPORT_FILE}" "${CONTAINER_STATUS_FILE}" "${ENDPOINT_STATUS_FILE}" "${RESOURCE_STATUS_FILE}" \
   "${ERROR_LOGS_FILE}" "${COMMAND_OUTPUT_FILE}" "${RECOMMENDATIONS_FILE}" "${STATUS_SUMMARY_FILE}"

# Store exit code based on alert status
exit ${ALERT_TRIGGERED}