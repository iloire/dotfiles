#!/bin/bash
# Category: system
# Description: Sync local directories with GitHub repositories

# Set PATH for cron environment
PATH=/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:$PATH

# Parse command line arguments
VERBOSE=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--verbose) VERBOSE=true ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -v, --verbose    Enable verbose output"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# Configuration
CONFIG_FILE="$HOME/github_sync.conf"  # Config file in home directory
LOG_FILE="$HOME/sync_log.txt"
FAILURES_FILE="$HOME/sync_failures.txt"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file $CONFIG_FILE not found. Please create it." >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Config file $CONFIG_FILE not found" >> "$LOG_FILE"
    exit 1
fi

# Add timestamp to log messages
log_message() {
    local MESSAGE="$1"
    local LOG_ENTRY="[$(date '+%Y-%m-%d %H:%M:%S')] $MESSAGE"
    # Always write to log file
    echo "$LOG_ENTRY" >> "$LOG_FILE"
    # Only display to console if verbose mode is enabled
    if [ "$VERBOSE" = true ]; then
        echo "$LOG_ENTRY"
    fi
}

# Error logging - always outputs to stderr
error_message() {
    local MESSAGE="$1"
    local LOG_ENTRY="[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $MESSAGE"
    echo "$LOG_ENTRY" >> "$LOG_FILE"
    echo "ERROR: $MESSAGE" >&2
}

# Check for internet connectivity (exit silently to avoid cron mail spam)
if ! ping -c 1 -W 3 github.com >/dev/null 2>&1; then
    log_message "No internet connectivity (ping failed) — skipping sync"
    exit 0
fi

# Verify SSH access to GitHub
if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    log_message "GitHub SSH auth failed — skipping sync"
    exit 0
fi

# Function to load config from a file in the directory (optional override)
load_local_config() {
    local DIR="$1"
    local CONFIG_FILE="$DIR/.sync_config"
    local REPO_URL=""
    local BRANCH=""

    if [ ! -d "$DIR" ]; then
        return 1
    fi

    if [ -f "$CONFIG_FILE" ]; then
        while IFS='=' read -r key value; do
            [[ -z "$key" || "$key" =~ ^# ]] && continue
            
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            
            case "$key" in
                REPO_URL) REPO_URL="$value" ;;
                BRANCH) BRANCH="$value" ;;
            esac
        done < "$CONFIG_FILE"
        
        if [ -n "$REPO_URL" ] && [ -n "$BRANCH" ]; then
            log_message "Successfully loaded local config for $DIR" >&2
            echo "$REPO_URL||$BRANCH"
            return 0
        else
            error_message "Invalid or incomplete local config in $CONFIG_FILE" >&2
            return 1
        fi
    fi
    return 1
}

# Function to sync a single directory
sync_directory() {
    local DIR="$1"
    local REPO_URL="$2"
    local BRANCH="$3"

    log_message "=== Starting sync for directory: $DIR ==="
    log_message "Repository URL: $REPO_URL"
    log_message "Branch: $BRANCH"

    # Navigate to the directory
    cd "$DIR" || { 
        error_message "Failed to change to directory $DIR"
        return 1 
    }

    # Ensure it's a Git repository
    if [ ! -d .git ]; then
        log_message "Directory is not a Git repository. Initializing..."
        if [ "$VERBOSE" = true ]; then
            git init 2>&1 | tee -a "$LOG_FILE"
        else
            git init >> "$LOG_FILE" 2>&1
        fi
        if [ $? -eq 0 ]; then
            log_message "Git repository initialized successfully"
        else
            error_message "Failed to initialize Git repository"
            return 1
        fi

        log_message "Adding remote origin: $REPO_URL"
        if [ "$VERBOSE" = true ]; then
            git remote add origin "$REPO_URL" 2>&1 | tee -a "$LOG_FILE"
        else
            git remote add origin "$REPO_URL" >> "$LOG_FILE" 2>&1
        fi
        log_message "Setting up branch: $BRANCH"
        if [ "$VERBOSE" = true ]; then
            git branch -M "$BRANCH" 2>&1 | tee -a "$LOG_FILE"
        else
            git branch -M "$BRANCH" >> "$LOG_FILE" 2>&1
        fi
        
        log_message "Performing initial commit..."
        if [ "$VERBOSE" = true ]; then
            git add . 2>&1 | tee -a "$LOG_FILE"
            git commit -m "Initial commit" 2>&1 | tee -a "$LOG_FILE" || {
                error_message "Initial commit failed in $DIR"
                return 1
            }
        else
            git add . >> "$LOG_FILE" 2>&1
            git commit -m "Initial commit" >> "$LOG_FILE" 2>&1 || {
                error_message "Initial commit failed in $DIR"
                return 1
            }
        fi
        
        log_message "Pushing to remote repository..."
        if [ "$VERBOSE" = true ]; then
            git push -u origin "$BRANCH" 2>&1 | tee -a "$LOG_FILE" || {
                error_message "Initial push failed in $DIR"
                return 1
            }
        else
            git push -u origin "$BRANCH" >> "$LOG_FILE" 2>&1 || {
                error_message "Initial push failed in $DIR"
                return 1
            }
        fi
        log_message "Repository setup completed successfully"
    fi

    # Skip if the repo is on a different branch (likely intentional work)
    local CURRENT_BRANCH
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
        log_message "Skipping $DIR: on branch '$CURRENT_BRANCH', expected '$BRANCH'"
        return 0
    fi

    # Pull latest changes from GitHub (retry up to 3 times for transient failures)
    local PULL_SUCCESS=false
    local PULL_OUTPUT
    for attempt in 1 2 3; do
        log_message "Pulling latest changes from $REPO_URL (attempt $attempt/3)..."
        PULL_OUTPUT=$(git pull origin "$BRANCH" 2>&1)
        local PULL_EXIT=$?

        echo "$PULL_OUTPUT" >> "$LOG_FILE"
        if [ "$VERBOSE" = true ]; then
            echo "$PULL_OUTPUT"
        fi

        if [ $PULL_EXIT -eq 0 ]; then
            log_message "Successfully pulled latest changes"
            PULL_SUCCESS=true
            break
        fi

        # Don't retry non-transient errors
        if echo "$PULL_OUTPUT" | grep -qE "Not possible to fast-forward|CONFLICT|diverging|stash failed|not a git repository|does not have a commit checked out"; then
            error_message "Pull failed in $DIR (non-transient): $(echo "$PULL_OUTPUT" | grep -E 'fatal:|error:|CONFLICT|Not possible' | head -3)"
            return 1
        fi

        if [ $attempt -lt 3 ]; then
            log_message "Pull failed (transient?), retrying in 5 seconds..."
            sleep 5
        fi
    done
    if [ "$PULL_SUCCESS" = false ]; then
        error_message "Failed to pull $BRANCH from $REPO_URL (in $DIR) after 3 attempts. Last output: $(echo "$PULL_OUTPUT" | grep -E 'fatal:|error:' | head -3)"
        return 1
    fi

    # Check for changes
    log_message "Checking for local changes..."
    if [ "$VERBOSE" = true ]; then
        git status --porcelain 2>&1 | tee -a "$LOG_FILE"
    else
        git status --porcelain >> "$LOG_FILE" 2>&1
    fi
    git status --porcelain | grep -q .
    if [ $? -eq 0 ]; then
        log_message "Changes detected, preparing to sync..."
        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

        if [ "$VERBOSE" = true ]; then
            git add . 2>&1 | tee -a "$LOG_FILE"
            log_message "Committing changes..."
            git commit -m "Auto-sync: Changes detected on $TIMESTAMP" 2>&1 | tee -a "$LOG_FILE" || {
                error_message "Commit failed in $DIR"
                return 1
            }

            log_message "Pushing changes to remote repository..."
            git push origin "$BRANCH" 2>&1 | tee -a "$LOG_FILE" || {
                error_message "Push failed to $REPO_URL"
                return 1
            }
        else
            git add . >> "$LOG_FILE" 2>&1
            log_message "Committing changes..."
            git commit -m "Auto-sync: Changes detected on $TIMESTAMP" >> "$LOG_FILE" 2>&1 || {
                error_message "Commit failed in $DIR"
                return 1
            }

            log_message "Pushing changes to remote repository..."
            git push origin "$BRANCH" >> "$LOG_FILE" 2>&1 || {
                error_message "Push failed to $REPO_URL"
                return 1
            }
        fi
        log_message "Successfully pushed changes to remote repository"
    else
        log_message "No local changes detected"
    fi
    
    log_message "=== Completed sync for directory: $DIR ==="
}

# Main loop: Read config file and sync directories
# Clear failures file at the start of each run
> "$FAILURES_FILE"

log_message "Starting GitHub sync script"
log_message "Using config file: $CONFIG_FILE"

while IFS='=' read -r DIR CONFIG; do
    # Skip empty lines or comments
    [[ -z "$DIR" || "$DIR" =~ ^# ]] && continue
    
    # Trim whitespace
    DIR=$(echo "$DIR" | xargs)
    CONFIG=$(echo "$CONFIG" | xargs)
    
    # Check for local override first
    LOCAL_CONFIG=$(load_local_config "$DIR" 2>/dev/null)
    local_config_status=$?
    
    if [ $local_config_status -eq 0 ]; then
        # Parse values using awk and trim any whitespace/newlines
        temp_repo=$(echo "$LOCAL_CONFIG" | awk -F'\\|\\|' '{print $1}' | tr -d '\n')
        temp_branch=$(echo "$LOCAL_CONFIG" | awk -F'\\|\\|' '{print $2}' | tr -d '\n')
        
        # Explicit assignment
        REPO_URL="${temp_repo}"
        BRANCH="${temp_branch}"
    else
        # Parse values using awk and trim any whitespace/newlines
        temp_repo=$(echo "$CONFIG" | awk -F'\\|\\|' '{print $1}' | tr -d '\n')
        temp_branch=$(echo "$CONFIG" | awk -F'\\|\\|' '{print $2}' | tr -d '\n')
        
        # Explicit assignment
        REPO_URL="${temp_repo}"
        BRANCH="${temp_branch}"
    fi

    if [ -n "$DIR" ] && [ -n "$REPO_URL" ] && [ -n "$BRANCH" ]; then
        if ! sync_directory "$DIR" "$REPO_URL" "$BRANCH"; then
            echo "$DIR" >> "$FAILURES_FILE"
        fi
    else
        error_message "Invalid config entry for $DIR"
    fi
done < "$CONFIG_FILE"

log_message "Script completed"

# Report to watchdog
if [ -s "$FAILURES_FILE" ]; then
    FAIL_COUNT=$(wc -l < "$FAILURES_FILE" | tr -d ' ')
    WATCHDOG_METADATA="{\"machine\":\"$(hostname)\",\"fail_count\":$FAIL_COUNT}" \
    WATCHDOG_NOTIFY=true \
        $HOME/dotfiles/bin/send-watchdog "backups" "github.sync.failed" "error" "$FAIL_COUNT repos failed to sync"
else
    WATCHDOG_METADATA="{\"machine\":\"$(hostname)\"}" \
    $HOME/dotfiles/bin/send-watchdog "backups" "github.sync.complete" "info"
fi