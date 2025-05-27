#!/bin/bash

# GitHub Backup Script
# This script commits and pushes changes from the local Git repository to GitHub

# Log file for the backup
LOG_FILE="/home/shared/docker/github-backup.log"

# Function to log messages
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

log "Starting GitHub backup process"

# Change to the repository directory
cd /home/shared/git-repos/portainer-stacks || {
  log "ERROR: Could not change to repository directory"
  exit 1
}

# Add all changes
git add . >> $LOG_FILE 2>&1

# Check if there are changes to commit
if git diff --cached --quiet; then
  log "No changes to commit"
else
  # Commit changes
  git commit -m "Automated backup $(date '+%Y-%m-%d %H:%M:%S')" >> $LOG_FILE 2>&1
  
  # Test if configuration is valid before pushing
  log "Validating docker-compose files"
  
  # Test core-infrastructure.yml
  if docker compose -f core-infrastructure.yml config > /dev/null 2>> $LOG_FILE; then
    log "core-infrastructure.yml is valid"
  else
    log "ERROR: core-infrastructure.yml has validation errors"
    git reset --soft HEAD~1
    log "Commit was reset due to validation errors"
    exit 1
  fi
  
  # Test applications.yml
  if docker compose -f applications.yml config > /dev/null 2>> $LOG_FILE; then
    log "applications.yml is valid"
  else
    log "ERROR: applications.yml has validation errors"
    git reset --soft HEAD~1
    log "Commit was reset due to validation errors"
    exit 1
  fi
  
  # Test rustdesk.yml
  if docker compose -f rustdesk.yml config > /dev/null 2>> $LOG_FILE; then
    log "rustdesk.yml is valid"
  else
    log "ERROR: rustdesk.yml has validation errors"
    git reset --soft HEAD~1
    log "Commit was reset due to validation errors"
    exit 1
  fi
  
  # If we're here, all tests passed - Push to GitHub
  if [ -n "$(git remote | grep origin)" ]; then
    log "Pushing changes to GitHub"
    git push origin main >> $LOG_FILE 2>&1
    if [ $? -eq 0 ]; then
      log "Backup completed successfully"
    else
      log "ERROR: Failed to push to GitHub"
      exit 1
    fi
  else
    log "No remote 'origin' configured. Skipping push."
  fi
fi

log "Backup process completed"
exit 0