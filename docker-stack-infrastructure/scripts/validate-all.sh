#!/bin/bash
# Unified Docker Stack Validation Script
# This script runs all validation checks in a single pass

set -eo pipefail

# Log file
LOG_DIR="/home/shared/docker/logs"
LOG_FILE="${LOG_DIR}/validation.log"
REPORT_FILE=$(mktemp)

# Make sure log directory exists
mkdir -p "${LOG_DIR}"

# Colors for console output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Passed and failed tests counters
PASSED_COUNT=0
FAILED_COUNT=0

# Arrays to track test results
declare -a passed
declare -a failed

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
  echo -e "${color}${timestamp} - [${level}] ${message}${NC}" | tee -a "${REPORT_FILE}"
}

# Function to check if container is running
check_container() {
  local container=$1
  local container_status=$(docker ps -f "name=^${container}$" --format "{{.Status}}" 2>/dev/null)
  
  log "INFO" "Checking container: ${container}"
  
  if [ -z "${container_status}" ]; then
    log "ERROR" "❌ Container ${container} is not running!"
    failed+=("container:${container}")
    ((FAILED_COUNT++))
    return 1
  elif [[ "${container_status}" == *"Up"* ]]; then
    log "INFO" "✅ ${container}: ${container_status}"
    passed+=("container:${container}")
    ((PASSED_COUNT++))
    return 0
  else
    log "WARN" "⚠️ ${container}: ${container_status}"
    failed+=("container:${container}")
    ((FAILED_COUNT++))
    return 1
  fi
}

# Function to validate Docker Compose files
validate_compose_files() {
  local directory=$1
  
  log "INFO" "Validating Docker Compose files in ${directory}"
  
  if [ ! -d "${directory}" ]; then
    log "ERROR" "❌ Directory ${directory} does not exist"
    failed+=("compose_directory:${directory}")
    ((FAILED_COUNT++))
    return 1
  fi
  
  # Change to the directory
  pushd "${directory}" > /dev/null
  
  # Test all YAML files in the directory
  for file in *.yml; do
    if [ ! -f "$file" ]; then
      log "WARN" "No YAML files found in ${directory}"
      continue
    fi
    
    log "INFO" "Testing ${file}..."
    if docker compose -f "$file" config > /dev/null 2>&1; then
      log "INFO" "✅ ${file} passed validation"
      passed+=("compose_file:${file}")
      ((PASSED_COUNT++))
    else
      log "ERROR" "❌ ${file} failed validation"
      failed+=("compose_file:${file}")
      ((FAILED_COUNT++))
    fi
  done
  
  # Return to original directory
  popd > /dev/null
}

# Function to validate Caddy configuration
validate_caddy_config() {
  log "INFO" "Validating Caddy configuration"
  
  # Check if Caddy container is running
  if ! docker ps -q -f "name=caddy" &>/dev/null; then
    log "ERROR" "❌ Caddy container is not running"
    failed+=("caddy:container_not_running")
    ((FAILED_COUNT++))
    return 1
  fi
  
  # Validate Caddy configuration syntax
  if docker exec caddy caddy validate --config /etc/caddy/Caddyfile > /dev/null 2>&1; then
    log "INFO" "✅ Caddyfile passed syntax validation"
    passed+=("caddy:syntax_valid")
    ((PASSED_COUNT++))
  else
    log "ERROR" "❌ Caddyfile failed syntax validation"
    failed+=("caddy:syntax_invalid")
    ((FAILED_COUNT++))
    return 1
  fi
  
  # Check for startup errors in Caddy logs
  if docker logs caddy 2>&1 | grep -v "level=info" | grep -v "level=warn" | grep -i "error" | wc -l | grep -q "^0$"; then
    log "INFO" "✅ No startup errors detected in Caddy logs"
    passed+=("caddy:no_startup_errors")
    ((PASSED_COUNT++))
  else
    log "ERROR" "❌ Startup errors detected in Caddy logs"
    log "ERROR" "Error details: $(docker logs caddy 2>&1 | grep -i "error" | head -n 3)"
    failed+=("caddy:startup_errors")
    ((FAILED_COUNT++))
    return 1
  fi
  
  # Verify Caddy is correctly proxying to n8n
  local http_code=$(curl -s -o /dev/null -w "%{http_code}" -m 5 https://n8n.stringbits.com 2>/dev/null)
  if [ "${http_code}" = "502" ]; then
    log "ERROR" "❌ Caddy is responding with 502 for n8n.stringbits.com"
    failed+=("caddy:proxy_error_n8n")
    ((FAILED_COUNT++))
    return 1
  else
    log "INFO" "✅ Caddy is correctly proxying n8n (HTTP ${http_code})"
    passed+=("caddy:proxy_valid_n8n")
    ((PASSED_COUNT++))
  fi
  
  return 0
}

# Function to validate network configuration
validate_networks() {
  local networks=("stringbits_net" "docker_stringbits_net")
  
  log "INFO" "Validating Docker networks"
  
  for network in "${networks[@]}"; do
    if docker network inspect "${network}" > /dev/null 2>&1; then
      log "INFO" "✅ Network ${network} exists"
      passed+=("network:${network}")
      ((PASSED_COUNT++))
    else
      log "ERROR" "❌ Network ${network} does not exist"
      failed+=("network:${network}")
      ((FAILED_COUNT++))
    fi
  done
  
  # Check if critical containers are on both networks
  critical_containers=("portainer" "caddy")
  for container in "${critical_containers[@]}"; do
    # Skip if container is not running
    if ! docker ps -q -f "name=${container}" &>/dev/null; then
      log "WARN" "⚠️ Cannot check networks for ${container} - container not running"
      continue
    fi
    
    for network in "${networks[@]}"; do
      if docker network inspect "${network}" --format '{{range .Containers}}{{.Name}}{{"\n"}}{{end}}' 2>/dev/null | grep -q "${container}"; then
        log "INFO" "✅ ${container} is connected to ${network}"
        passed+=("network_connection:${container}_on_${network}")
        ((PASSED_COUNT++))
      else
        log "ERROR" "❌ ${container} is not connected to ${network}"
        failed+=("network_connection:${container}_not_on_${network}")
        ((FAILED_COUNT++))
      fi
    done
  done
}

# Function to validate Portainer persistence
validate_portainer_persistence() {
  log "INFO" "Validating Portainer persistence"
  
  # Check if Portainer is running
  if ! docker ps -q -f "name=portainer" &>/dev/null; then
    log "ERROR" "❌ Portainer is not running"
    failed+=("portainer:not_running")
    ((FAILED_COUNT++))
    return 1
  fi
  
  log "INFO" "Getting Portainer information before restart"
  CONTAINER_ID=$(docker ps -q -f "name=portainer")
  
  # Save information about Portainer configuration
  docker inspect portainer > /tmp/portainer-before.json
  
  log "INFO" "Restarting Portainer to test persistence"
  docker restart portainer > /dev/null
  sleep 5
  
  # Check if Portainer is still running after restart
  if ! docker ps -q -f "name=portainer" &>/dev/null; then
    log "ERROR" "❌ Portainer failed to restart"
    failed+=("portainer:restart_failed")
    ((FAILED_COUNT++))
    return 1
  fi
  
  log "INFO" "Validating Portainer configuration persistence"
  docker inspect portainer > /tmp/portainer-after.json
  
  # Compare the important parts of the configuration
  BEFORE_MOUNTS=$(grep -A 10 "Mounts" /tmp/portainer-before.json)
  AFTER_MOUNTS=$(grep -A 10 "Mounts" /tmp/portainer-after.json)
  
  if [ "$BEFORE_MOUNTS" = "$AFTER_MOUNTS" ]; then
    log "INFO" "✅ Portainer volume mounts preserved correctly"
    passed+=("portainer:mounts_preserved")
    ((PASSED_COUNT++))
  else
    log "ERROR" "❌ Portainer volume mounts changed after restart"
    failed+=("portainer:mounts_changed")
    ((FAILED_COUNT++))
  fi
  
  # Test API accessibility
  if curl -s -I -k https://localhost:9443 | grep -q "200 OK"; then
    log "INFO" "✅ Portainer API is accessible"
    passed+=("portainer:api_accessible")
    ((PASSED_COUNT++))
  else
    log "ERROR" "❌ Portainer API is not responding correctly"
    failed+=("portainer:api_inaccessible")
    ((FAILED_COUNT++))
  fi
  
  # Clean up
  rm -f /tmp/portainer-before.json /tmp/portainer-after.json
}

# Function to validate RustDesk configuration
validate_rustdesk() {
  log "INFO" "Validating RustDesk configuration"
  
  # Check if RustDesk containers are running
  if docker ps -q -f "name=rustdesk-hbbs" &>/dev/null && docker ps -q -f "name=rustdesk-hbbr" &>/dev/null; then
    log "INFO" "✅ RustDesk containers are running"
    passed+=("rustdesk:containers_running")
    ((PASSED_COUNT++))
  else
    log "ERROR" "❌ RustDesk containers are not running"
    failed+=("rustdesk:containers_not_running")
    ((FAILED_COUNT++))
    return 1
  fi
  
  # Check if RustDesk data directory exists
  if [ -d "/home/shared/docker/rustdesk" ]; then
    log "INFO" "✅ RustDesk data directory exists"
    passed+=("rustdesk:data_directory_exists")
    ((PASSED_COUNT++))
  else
    log "ERROR" "❌ RustDesk data directory does not exist"
    failed+=("rustdesk:data_directory_missing")
    ((FAILED_COUNT++))
  fi
  
  # Check for RustDesk public key
  if [ -f "/home/shared/docker/rustdesk/id_ed25519.pub" ]; then
    log "INFO" "✅ RustDesk public key exists"
    passed+=("rustdesk:public_key_exists")
    ((PASSED_COUNT++))
    
    # Show public key
    log "DEBUG" "RustDesk public key: $(cat /home/shared/docker/rustdesk/id_ed25519.pub)"
  else
    log "ERROR" "❌ RustDesk public key does not exist"
    failed+=("rustdesk:public_key_missing")
    ((FAILED_COUNT++))
  fi
}

# Function to validate Git repository status
validate_git_repos() {
  local repos=(
    "/home/shared/git-repos/portainer-stacks:Portainer stacks"
  )
  
  log "INFO" "Validating Git repositories"
  
  for repo_info in "${repos[@]}"; do
    IFS=':' read -r repo_path repo_name <<< "${repo_info}"
    
    if [ -d "${repo_path}/.git" ]; then
      log "INFO" "✅ ${repo_name} repository exists"
      passed+=("git_repo:${repo_name}_exists")
      ((PASSED_COUNT++))
      
      # Check for uncommitted changes
      if (cd "${repo_path}" && git status --porcelain | grep -q .); then
        log "WARN" "⚠️ ${repo_name} repository has uncommitted changes"
        failed+=("git_repo:${repo_name}_uncommitted_changes")
        ((FAILED_COUNT++))
      else
        log "INFO" "✅ ${repo_name} repository is clean"
        passed+=("git_repo:${repo_name}_clean")
        ((PASSED_COUNT++))
      fi
    else
      log "ERROR" "❌ ${repo_name} repository does not exist"
      failed+=("git_repo:${repo_name}_missing")
      ((FAILED_COUNT++))
    fi
  done
}

# Function to validate endpoint accessibility
validate_endpoints() {
  local endpoints=("n8n.stringbits.com" "wp.stringbits.com" "rd.stringbits.com" "ptn.stringbits.com")
  
  log "INFO" "Validating endpoint accessibility"
  
  for endpoint in "${endpoints[@]}"; do
    # Try to resolve the hostname
    if host "${endpoint}" > /dev/null 2>&1; then
      log "INFO" "✅ ${endpoint} DNS resolves correctly"
      passed+=("endpoint:${endpoint}_dns")
      ((PASSED_COUNT++))
    else
      log "WARN" "⚠️ ${endpoint} DNS does not resolve"
      failed+=("endpoint:${endpoint}_dns")
      ((FAILED_COUNT++))
    fi
    
    # Try to access the endpoint
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" -m 5 "https://${endpoint}" 2>/dev/null)
    local curl_status=$?
    
    if [ $curl_status -ne 0 ]; then
      log "ERROR" "❌ Could not connect to ${endpoint} (curl error: ${curl_status})"
      failed+=("endpoint:${endpoint}_connection")
      ((FAILED_COUNT++))
    elif [ "${http_code}" -lt 200 ] || [ "${http_code}" -ge 400 ]; then
      log "ERROR" "❌ ${endpoint} returned HTTP code ${http_code}"
      failed+=("endpoint:${endpoint}_http_${http_code}")
      ((FAILED_COUNT++))
    else
      log "INFO" "✅ ${endpoint} is accessible (HTTP code: ${http_code})"
      passed+=("endpoint:${endpoint}_accessible")
      ((PASSED_COUNT++))
    fi
  done
}

# Function to validate system resources
validate_system_resources() {
  log "INFO" "Validating system resources"
  
  # Check disk space
  local disk_usage=$(df -h / | tail -n 1)
  local disk_percent=$(echo ${disk_usage} | awk '{print $5}' | cut -d'%' -f1)
  
  if [ "${disk_percent}" -ge 90 ]; then
    log "ERROR" "❌ Disk usage is critical: ${disk_percent}%"
    failed+=("resources:disk_critical")
    ((FAILED_COUNT++))
  elif [ "${disk_percent}" -ge 80 ]; then
    log "WARN" "⚠️ Disk usage is high: ${disk_percent}%"
    failed+=("resources:disk_warning")
    ((FAILED_COUNT++))
  else
    log "INFO" "✅ Disk usage is acceptable: ${disk_percent}%"
    passed+=("resources:disk_ok")
    ((PASSED_COUNT++))
  fi
  
  # Check memory usage
  local memory_info=$(free -m)
  local total_memory=$(echo "${memory_info}" | grep Mem | awk '{print $2}')
  local used_memory=$(echo "${memory_info}" | grep Mem | awk '{print $3}')
  local memory_percent=$((used_memory * 100 / total_memory))
  
  if [ "${memory_percent}" -ge 90 ]; then
    log "ERROR" "❌ Memory usage is critical: ${memory_percent}%"
    failed+=("resources:memory_critical")
    ((FAILED_COUNT++))
  elif [ "${memory_percent}" -ge 80 ]; then
    log "WARN" "⚠️ Memory usage is high: ${memory_percent}%"
    failed+=("resources:memory_warning")
    ((FAILED_COUNT++))
  else
    log "INFO" "✅ Memory usage is acceptable: ${memory_percent}%"
    passed+=("resources:memory_ok")
    ((PASSED_COUNT++))
  fi
}

# Run all validation tests
log "INFO" "========== Starting Unified Validation: $(date) =========="

# Validate Docker Compose files
validate_compose_files "/home/shared/git-repos/portainer-stacks"

# Validate container status
log "INFO" "\n===== Container Status ====="
containers=("portainer" "caddy" "n8n" "watchtower" "wordpress" "mysql" "rustdesk-hbbs" "rustdesk-hbbr" "git-daemon")
for container in "${containers[@]}"; do
  check_container "${container}"
done

# Validate Caddy configuration
log "INFO" "\n===== Caddy Configuration ====="
validate_caddy_config

# Validate network configuration
log "INFO" "\n===== Network Configuration ====="
validate_networks

# Validate Portainer persistence
log "INFO" "\n===== Portainer Persistence ====="
validate_portainer_persistence

# Validate RustDesk configuration
log "INFO" "\n===== RustDesk Configuration ====="
validate_rustdesk

# Validate Git repositories
log "INFO" "\n===== Git Repositories ====="
validate_git_repos

# Validate endpoint accessibility
log "INFO" "\n===== Endpoint Accessibility ====="
validate_endpoints

# Validate system resources
log "INFO" "\n===== System Resources ====="
validate_system_resources

# Summary
log "INFO" "\n===== Validation Summary ====="
log "INFO" "Total tests: $((PASSED_COUNT + FAILED_COUNT))"
log "INFO" "Passed tests: ${PASSED_COUNT}"
log "INFO" "Failed tests: ${FAILED_COUNT}"

if [ ${FAILED_COUNT} -gt 0 ]; then
  log "ERROR" "\nFailed tests:"
  for item in "${failed[@]}"; do
    log "ERROR" "  - ${item}"
  done
  log "ERROR" "\nValidation failed with ${FAILED_COUNT} failed tests."
  
  # Generate HTML report
  HTML_REPORT="/home/shared/docker/logs/validation-report.html"
  
  # Create HTML report with modern styling
  cat > "${HTML_REPORT}" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Docker Stack Validation Report</title>
  <style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; color: #333; line-height: 1.6; background-color: #f5f7f9; }
    .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    .header { background-color: #2c3e50; color: #fff; padding: 20px; margin: -20px -20px 20px; border-radius: 8px 8px 0 0; }
    .summary { display: flex; gap: 20px; margin-bottom: 20px; }
    .summary-item { flex: 1; padding: 15px; border-radius: 8px; text-align: center; }
    .total { background-color: #f8f9fa; border: 1px solid #dee2e6; }
    .passed { background-color: #d4edda; border: 1px solid #c3e6cb; color: #155724; }
    .failed { background-color: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; }
    .section { margin: 20px 0; padding: 15px; border-left: 4px solid #3498db; background-color: #f8f9fa; }
    .success { color: #2ecc71; }
    .warning { color: #f39c12; }
    .error { color: #e74c3c; }
    table { width: 100%; border-collapse: collapse; margin: 15px 0; }
    th, td { padding: 12px 15px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background-color: #f2f2f2; }
    tr:hover { background-color: #f5f5f5; }
    .timestamp { color: #666; font-size: 0.9em; }
    .footer { margin-top: 40px; color: #666; font-size: 0.9em; text-align: center; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Docker Stack Validation Report</h1>
      <p>Generated on $(date)</p>
    </div>
    
    <div class="summary">
      <div class="summary-item total">
        <h2>Total Tests</h2>
        <div style="font-size: 2.5em; font-weight: bold;">$((PASSED_COUNT + FAILED_COUNT))</div>
      </div>
      <div class="summary-item passed">
        <h2>Passed</h2>
        <div style="font-size: 2.5em; font-weight: bold;">${PASSED_COUNT}</div>
      </div>
      <div class="summary-item failed">
        <h2>Failed</h2>
        <div style="font-size: 2.5em; font-weight: bold;">${FAILED_COUNT}</div>
      </div>
    </div>
    
    <div class="section">
      <h2>Validation Results</h2>
      <table>
        <tr>
          <th>Status</th>
          <th>Test Name</th>
        </tr>
EOF

  # Add passed tests
  for item in "${passed[@]}"; do
    echo "<tr><td><span class=\"success\">✅ PASSED</span></td><td>${item}</td></tr>" >> "${HTML_REPORT}"
  done
  
  # Add failed tests
  for item in "${failed[@]}"; do
    echo "<tr><td><span class=\"error\">❌ FAILED</span></td><td>${item}</td></tr>" >> "${HTML_REPORT}"
  done
  
  # Close HTML report
  cat >> "${HTML_REPORT}" << EOF
      </table>
    </div>
    
    <div class="section">
      <h2>Validation Log</h2>
      <pre style="white-space: pre-wrap; overflow-x: auto; background-color: #f8f9fa; padding: 15px; border-radius: 5px;">
$(cat "${REPORT_FILE}" | sed 's/\[INFO\]/<span class="success">[INFO]<\/span>/g' \
  | sed 's/\[WARN\]/<span class="warning">[WARN]<\/span>/g' \
  | sed 's/\[ERROR\]/<span class="error">[ERROR]<\/span>/g' \
  | sed 's/\[DEBUG\]/<span class="debug">[DEBUG]<\/span>/g' \
  | sed 's/✅/<span class="success">✅<\/span>/g' \
  | sed 's/⚠️/<span class="warning">⚠️<\/span>/g' \
  | sed 's/❌/<span class="error">❌<\/span>/g')
      </pre>
    </div>
    
    <div class="footer">
      <p>Stringbits Docker Stack Validation System</p>
      <p>Server: $(hostname) | Date: $(date)</p>
    </div>
  </div>
</body>
</html>
EOF

  log "INFO" "Generated HTML report: ${HTML_REPORT}"
  exit 1
else
  log "INFO" "✅ All validation tests passed successfully!"
  exit 0
fi