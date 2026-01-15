#!/bin/bash
# Category: cleanup
# Description: Clean package manager caches (npm, pip, Homebrew, etc.)

# Cross-platform cache cleanup script for macOS and Linux
# Cleans package manager caches older than specified thresholds
# Safe to run frequently - only deletes stale cache entries
# Designed for crontab usage with detailed logging
#
# Usage: clean-caches.sh [-v|--verbose] [-q|--quiet] [-n|--dry-run]
#   -v, --verbose  Show all operations (default: quiet, only show summary if changes made)
#   -q, --quiet    Suppress all output except errors
#   -n, --dry-run  Show what would be deleted without actually deleting

# Age thresholds in days
CACHE_MAX_AGE_DAYS=30
HOMEBREW_MAX_AGE_DAYS=14

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
            VERBOSITY=1  # Force verbose in dry-run to show what would happen
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [-v|--verbose] [-q|--quiet] [-n|--dry-run]"
            exit 1
            ;;
    esac
done

# Tracking variables
TOTAL_FILES_DELETED=0
TOTAL_BYTES_FREED=0
TOTAL_DIRS_DELETED=0

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

# Get directory size in bytes (cross-platform)
get_dir_size() {
    local dir="$1"
    if [ -d "$dir" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            du -sk "$dir" 2>/dev/null | awk '{print $1 * 1024}'
        else
            du -sb "$dir" 2>/dev/null | awk '{print $1}'
        fi
    else
        echo "0"
    fi
}

# Clean cache directory with detailed reporting
# Usage: clean_cache "Name" "path" age_days [extra_find_args...]
clean_cache() {
    local name="$1"
    local path="$2"
    local age_days="$3"
    shift 3
    local extra_args=("$@")

    if [ ! -d "$path" ]; then
        return 0
    fi

    local size_before=$(get_dir_size "$path")
    local files_before=$(find "$path" -type f 2>/dev/null | wc -l | tr -d ' ')

    # Build find command with optional extra arguments
    local find_cmd=(find "$path" -type f -mtime "+${age_days}")
    if [ ${#extra_args[@]} -gt 0 ]; then
        find_cmd+=("${extra_args[@]}")
    fi

    # Count files to be deleted and their size
    local stale_files=$("${find_cmd[@]}" 2>/dev/null | wc -l | tr -d ' ')
    local stale_size=0
    if [ "$stale_files" -gt 0 ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            stale_size=$("${find_cmd[@]}" -exec stat -f%z {} + 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        else
            stale_size=$("${find_cmd[@]}" -exec stat -c%s {} + 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        fi
    fi

    if [ "$stale_files" -gt 0 ]; then
        log "${name}: Found ${stale_files} stale files ($(format_bytes $stale_size)) older than ${age_days} days"
        if [ "$DRY_RUN" = true ]; then
            log "${name}: [DRY-RUN] Would delete ${stale_files} files, freeing $(format_bytes $stale_size)"
        else
            "${find_cmd[@]}" -delete 2>/dev/null
            log "${name}: Deleted ${stale_files} files, freed $(format_bytes $stale_size)"
        fi
        TOTAL_FILES_DELETED=$((TOTAL_FILES_DELETED + stale_files))
        TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + stale_size))
    else
        log "${name}: No stale files found (cache: $(format_bytes $size_before), ${files_before} files)"
    fi
}

# Clean cache using sudo (for system caches)
clean_cache_sudo() {
    local name="$1"
    local path="$2"
    local age_days="$3"
    shift 3
    local extra_args=("$@")

    if [ ! -d "$path" ]; then
        return 0
    fi

    local find_cmd=(sudo find "$path" -type f -mtime "+${age_days}")
    if [ ${#extra_args[@]} -gt 0 ]; then
        find_cmd+=("${extra_args[@]}")
    fi

    local stale_files=$("${find_cmd[@]}" 2>/dev/null | wc -l | tr -d ' ')
    local stale_size=0
    if [ "$stale_files" -gt 0 ]; then
        stale_size=$("${find_cmd[@]}" -exec stat -c%s {} + 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    fi

    if [ "$stale_files" -gt 0 ]; then
        log "${name}: Found ${stale_files} stale files ($(format_bytes $stale_size)) older than ${age_days} days"
        if [ "$DRY_RUN" = true ]; then
            log "${name}: [DRY-RUN] Would delete ${stale_files} files, freeing $(format_bytes $stale_size)"
        else
            "${find_cmd[@]}" -delete 2>/dev/null
            log "${name}: Deleted ${stale_files} files, freed $(format_bytes $stale_size)"
        fi
        TOTAL_FILES_DELETED=$((TOTAL_FILES_DELETED + stale_files))
        TOTAL_BYTES_FREED=$((TOTAL_BYTES_FREED + stale_size))
    else
        log "${name}: No stale files found"
    fi
}

log "=============================================="
log "Cache Cleanup Started"
log "=============================================="
log "Configuration: General cache age: ${CACHE_MAX_AGE_DAYS} days, Homebrew: ${HOMEBREW_MAX_AGE_DAYS} days"
log "Hostname: $(hostname)"
log "User: $(whoami)"
log ""

# Yarn cache
clean_cache "Yarn (~/.yarn/cache)" "$HOME/.yarn/cache" "$CACHE_MAX_AGE_DAYS"
clean_cache "Yarn (~/.cache/yarn)" "$HOME/.cache/yarn" "$CACHE_MAX_AGE_DAYS"

# npm cache
clean_cache "npm" "$HOME/.npm/_cacache" "$CACHE_MAX_AGE_DAYS"

# pnpm cache
clean_cache "pnpm (~/.local/share/pnpm/store)" "$HOME/.local/share/pnpm/store" "$CACHE_MAX_AGE_DAYS"
clean_cache "pnpm (~/.pnpm-store)" "$HOME/.pnpm-store" "$CACHE_MAX_AGE_DAYS"

# pip cache
clean_cache "pip (~/.cache/pip)" "$HOME/.cache/pip" "$CACHE_MAX_AGE_DAYS"
clean_cache "pip (Library/Caches)" "$HOME/Library/Caches/pip" "$CACHE_MAX_AGE_DAYS"

# Go module cache
clean_cache "Go modules" "$HOME/go/pkg/mod/cache" "$CACHE_MAX_AGE_DAYS"

# Gradle cache
clean_cache "Gradle caches" "$HOME/.gradle/caches" "$CACHE_MAX_AGE_DAYS"
clean_cache "Gradle wrapper" "$HOME/.gradle/wrapper/dists" "$CACHE_MAX_AGE_DAYS"

# Maven cache - clean old entries and metadata
clean_cache "Maven (.lastUpdated)" "$HOME/.m2/repository" "$CACHE_MAX_AGE_DAYS" -name "*.lastUpdated"
clean_cache "Maven (_remote.repositories)" "$HOME/.m2/repository" "$CACHE_MAX_AGE_DAYS" -name "_remote.repositories"
clean_cache "Maven (resolver-status)" "$HOME/.m2/repository" "$CACHE_MAX_AGE_DAYS" -name "resolver-status.properties"

# Composer cache
clean_cache "Composer (~/.composer/cache)" "$HOME/.composer/cache" "$CACHE_MAX_AGE_DAYS"
clean_cache "Composer (~/.cache/composer)" "$HOME/.cache/composer" "$CACHE_MAX_AGE_DAYS"

# Cargo cache (Rust)
clean_cache "Cargo registry" "$HOME/.cargo/registry/cache" "$CACHE_MAX_AGE_DAYS"

# Ruby gems cache
clean_cache "Ruby gems" "$HOME/.gem/ruby" "$CACHE_MAX_AGE_DAYS" -name "*.gem"

# CocoaPods cache (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    clean_cache "CocoaPods" "$HOME/Library/Caches/CocoaPods" "$CACHE_MAX_AGE_DAYS"
fi

# Homebrew cache (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    clean_cache "Homebrew" "$HOME/Library/Caches/Homebrew" "$HOMEBREW_MAX_AGE_DAYS"
fi

# APT cache (Linux)
if [[ "$OSTYPE" == "linux-gnu"* ]] && [ -d "/var/cache/apt/archives" ]; then
    clean_cache_sudo "APT" "/var/cache/apt/archives" "$CACHE_MAX_AGE_DAYS" -name "*.deb"
fi

# Clean empty directories left behind
log ""
log "Cleaning empty cache directories..."
DIRS_BEFORE=$TOTAL_DIRS_DELETED
for cache_dir in \
    "$HOME/.yarn/cache" \
    "$HOME/.cache/yarn" \
    "$HOME/.npm/_cacache" \
    "$HOME/.local/share/pnpm/store" \
    "$HOME/.cache/pip" \
    "$HOME/Library/Caches/pip" \
    "$HOME/go/pkg/mod/cache" \
    "$HOME/.gradle/caches" \
    "$HOME/.m2/repository" \
    "$HOME/.composer/cache" \
    "$HOME/.cache/composer" \
    "$HOME/.cargo/registry/cache" \
    "$HOME/.gem/ruby" \
    "$HOME/Library/Caches/CocoaPods" \
    "$HOME/Library/Caches/Homebrew"
do
    if [ -d "$cache_dir" ]; then
        empty_dirs=$(find "$cache_dir" -type d -empty 2>/dev/null | wc -l | tr -d ' ')
        if [ "$empty_dirs" -gt 0 ]; then
            if [ "$DRY_RUN" = false ]; then
                find "$cache_dir" -type d -empty -delete 2>/dev/null
            fi
            TOTAL_DIRS_DELETED=$((TOTAL_DIRS_DELETED + empty_dirs))
        fi
    fi
done

if [ "$TOTAL_DIRS_DELETED" -gt "$DIRS_BEFORE" ]; then
    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would remove $((TOTAL_DIRS_DELETED - DIRS_BEFORE)) empty directories"
    else
        log "Removed $((TOTAL_DIRS_DELETED - DIRS_BEFORE)) empty directories"
    fi
else
    log "No empty directories found"
fi

# Summary - only show if something was cleaned (or verbose mode)
if [ "$TOTAL_FILES_DELETED" -gt 0 ] || [ "$TOTAL_DIRS_DELETED" -gt 0 ] || [ "$VERBOSITY" -eq 1 ]; then
    log ""
    log "=============================================="
    log "Cache Cleanup Summary"
    log "=============================================="

    if [ "$DRY_RUN" = true ]; then
        log_summary "[DRY-RUN] Would delete ${TOTAL_FILES_DELETED} files, freeing $(format_bytes $TOTAL_BYTES_FREED)"
        log_summary "[DRY-RUN] Would remove ${TOTAL_DIRS_DELETED} empty directories"
    else
        if [ "$TOTAL_FILES_DELETED" -gt 0 ] || [ "$TOTAL_DIRS_DELETED" -gt 0 ]; then
            log_summary "Cache cleanup: deleted ${TOTAL_FILES_DELETED} files, freed $(format_bytes $TOTAL_BYTES_FREED), removed ${TOTAL_DIRS_DELETED} empty dirs"
        else
            log "No stale cache entries found"
        fi
    fi

    log "=============================================="
fi
