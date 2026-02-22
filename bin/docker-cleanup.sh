#!/bin/bash
# Category: cleanup
# Description: Clean Docker build cache, container logs, and unused resources

# Docker cleanup script for reclaiming disk space
# Truncates container logs, prunes build cache, dangling images, and unused volumes
# Safe to run frequently - only removes expendable data
# Designed for crontab usage with detailed logging
#
# Usage: docker-cleanup.sh [-v|--verbose] [-q|--quiet] [-n|--dry-run]
#   -v, --verbose  Show all operations (default: quiet, only show summary if changes made)
#   -q, --quiet    Suppress all output except errors
#   -n, --dry-run  Show what would be cleaned without actually cleaning

# Docker data root (override with DOCKER_DATA_ROOT env var)
DOCKER_DATA_ROOT="${DOCKER_DATA_ROOT:-/var/lib/docker}"

# Modes: 0=quiet (default), 1=verbose, 2=silent
VERBOSITY=0
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSITY=1
            shift
            ;;
        -q|--quiet)
            VERBOSITY=2
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            VERBOSITY=1
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-v|--verbose] [-q|--quiet] [-n|--dry-run]"
            echo "Options:"
            echo "  -v, --verbose    Show all operations"
            echo "  -q, --quiet      Suppress all output except errors"
            echo "  -n, --dry-run    Show what would be cleaned without cleaning"
            echo "  -h, --help       Show this help message"
            echo ""
            echo "Environment:"
            echo "  DOCKER_DATA_ROOT  Docker data directory (default: /var/lib/docker)"
            exit 0
            ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# Tracking
TOTAL_BYTES_FREED=0

# Logging functions
log() {
    if [ "$VERBOSITY" -eq 1 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    fi
}

log_summary() {
    if [ "$VERBOSITY" -ne 2 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    fi
}

error() {
    echo "ERROR: $1" >&2
}

# Format bytes to human readable
format_bytes() {
    local bytes=$1
    if [ "$bytes" -ge 1073741824 ]; then
        echo "$(echo "scale=2; $bytes / 1073741824" | bc) GB"
    elif [ "$bytes" -ge 1048576 ]; then
        echo "$(echo "scale=2; $bytes / 1048576" | bc) MB"
    elif [ "$bytes" -ge 1024 ]; then
        echo "$(echo "scale=2; $bytes / 1024" | bc) KB"
    else
        echo "$bytes bytes"
    fi
}

# Check prerequisites
if ! command -v docker &>/dev/null; then
    error "docker not found"
    exit 1
fi

if ! docker info &>/dev/null; then
    error "Cannot connect to Docker daemon (try running with sudo or as docker group member)"
    exit 1
fi

log "=============================================="
log "Docker Cleanup Started"
log "=============================================="
log "Docker data root: $DOCKER_DATA_ROOT"
log "Hostname: $(hostname)"
log ""

# 1. Truncate container logs
log "--- Container Logs ---"
LOGS_DIR="$DOCKER_DATA_ROOT/containers"
if [ -d "$LOGS_DIR" ]; then
    log_size=0
    log_count=0
    while IFS= read -r logfile; do
        size=$(stat -c%s "$logfile" 2>/dev/null || echo 0)
        if [ "$size" -gt 0 ]; then
            log_size=$((log_size + size))
            log_count=$((log_count + 1))
            log "  $(basename "$(dirname "$logfile")" | cut -c1-12): $(format_bytes $size)"
        fi
    done < <(sudo find "$LOGS_DIR" -name "*-json.log" -size +0c 2>/dev/null)

    if [ "$log_count" -gt 0 ]; then
        if [ "$DRY_RUN" = true ]; then
            log "[DRY-RUN] Would truncate $log_count log files, freeing $(format_bytes $log_size)"
        else
            sudo find "$LOGS_DIR" -name "*-json.log" -size +0c -exec truncate -s 0 {} \; 2>/dev/null
            log "Truncated $log_count log files, freed $(format_bytes $log_size)"
        fi
        TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + log_size))
    else
        log "No container logs to truncate"
    fi
else
    log "Container logs directory not found at $LOGS_DIR"
fi

# 2. Docker build cache
log ""
log "--- Build Cache ---"
cache_size=$(docker system df --format '{{.Size}}' 2>/dev/null | tail -1)
if [ "$DRY_RUN" = true ]; then
    log "[DRY-RUN] Would prune build cache (current size: $cache_size)"
else
    output=$(docker builder prune -a -f 2>/dev/null)
    reclaimed=$(echo "$output" | grep -oP 'Total reclaimed space: \K.*' || echo "0B")
    log "Build cache pruned (reclaimed: $reclaimed)"
fi

# 3. Dangling images (untagged, unused)
log ""
log "--- Dangling Images ---"
dangling_count=$(docker images -f "dangling=true" -q 2>/dev/null | wc -l | tr -d ' ')
if [ "$dangling_count" -gt 0 ]; then
    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would remove $dangling_count dangling images"
    else
        output=$(docker image prune -f 2>/dev/null)
        reclaimed=$(echo "$output" | grep -oP 'Total reclaimed space: \K.*' || echo "0B")
        log "Removed $dangling_count dangling images (reclaimed: $reclaimed)"
    fi
else
    log "No dangling images found"
fi

# 4. Stopped containers
log ""
log "--- Stopped Containers ---"
stopped_count=$(docker ps -a -f "status=exited" -q 2>/dev/null | wc -l | tr -d ' ')
if [ "$stopped_count" -gt 0 ]; then
    stopped_names=$(docker ps -a -f "status=exited" --format "{{.Names}}" 2>/dev/null | paste -sd ", ")
    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would remove $stopped_count stopped containers: $stopped_names"
    else
        output=$(docker container prune -f 2>/dev/null)
        reclaimed=$(echo "$output" | grep -oP 'Total reclaimed space: \K.*' || echo "0B")
        log "Removed $stopped_count stopped containers (reclaimed: $reclaimed): $stopped_names"
    fi
else
    log "No stopped containers found"
fi

# 5. Unused volumes
log ""
log "--- Unused Volumes ---"
unused_vols=$(docker volume ls -f "dangling=true" -q 2>/dev/null | wc -l | tr -d ' ')
if [ "$unused_vols" -gt 0 ]; then
    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would remove $unused_vols unused volumes"
    else
        output=$(docker volume prune -f 2>/dev/null)
        reclaimed=$(echo "$output" | grep -oP 'Total reclaimed space: \K.*' || echo "0B")
        log "Removed $unused_vols unused volumes (reclaimed: $reclaimed)"
    fi
else
    log "No unused volumes found"
fi

# 6. Journal logs (if available)
log ""
log "--- Journal Logs ---"
if command -v journalctl &>/dev/null; then
    journal_size=$(journalctl --disk-usage 2>/dev/null | grep -oP '[\d.]+[KMGT]' || echo "unknown")
    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would vacuum journal logs older than 3 days (current size: $journal_size)"
    else
        sudo journalctl --vacuum-time=3d &>/dev/null
        journal_size_after=$(journalctl --disk-usage 2>/dev/null | grep -oP '[\d.]+[KMGT]' || echo "unknown")
        log "Journal logs vacuumed to 3 days (${journal_size} -> ${journal_size_after})"
    fi
else
    log "journalctl not available, skipping"
fi

# Summary
log ""
log "=============================================="
log "Docker Cleanup Summary"
log "=============================================="
if [ "$DRY_RUN" = true ]; then
    log_summary "[DRY-RUN] Docker cleanup: would free at least $(format_bytes $TOTAL_BYTES_FREED) from logs alone (build cache and images not counted)"
else
    log_summary "Docker cleanup completed: freed at least $(format_bytes $TOTAL_BYTES_FREED) from logs (build cache and images reclaimed separately)"
fi
log "=============================================="
