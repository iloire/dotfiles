#!/bin/bash
# Category: cleanup
# Description: Remove old downloads by file type and age

# Downloads cleanup script for macOS and Linux
# Cleans download directories based on age thresholds
# Designed for crontab usage with detailed logging
#
# Usage: clean-downloads.sh [-v|--verbose] [-q|--quiet] [-n|--dry-run]
#   -v, --verbose  Show all operations (default: quiet, only show summary if changes made)
#   -q, --quiet    Suppress all output except errors
#   -n, --dry-run  Show what would be deleted without actually deleting

# Age thresholds in days
DOWNLOADS_MAX_AGE=10
INSTALLERS_MAX_AGE=4
IMAGES_MAX_AGE=10
TORRENTS_MAX_AGE=10
ARCHIVES_MAX_AGE=10
ARCHIVES_ZIP_MAX_AGE=2

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

# Clean files in directory with detailed reporting
# Usage: clean_files "Name" "path" age_days maxdepth [extra_find_args...]
clean_files() {
    local name="$1"
    local path="$2"
    local age_days="$3"
    local maxdepth="$4"
    shift 4
    local extra_args=("$@")

    if [ ! -d "$path" ]; then
        return 0
    fi

    # Build find command
    local find_cmd=(find "$path" -maxdepth "$maxdepth" -type f -mtime "+${age_days}")
    if [ ${#extra_args[@]} -gt 0 ]; then
        find_cmd+=("${extra_args[@]}")
    fi

    # Count files to be deleted and their size
    local stale_files=$("${find_cmd[@]}" 2>/dev/null | wc -l | tr -d ' ')
    local stale_size=0
    if [ "$stale_files" -gt 0 ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            stale_size=$("${find_cmd[@]}" -exec stat -f%z {} + 2>/dev/null | awk '{sum+=$1} END {printf "%.0f\n", sum+0}')
        else
            stale_size=$(LC_NUMERIC=C "${find_cmd[@]}" -exec stat -c%s {} + 2>/dev/null | awk '{sum+=$1} END {printf "%.0f\n", sum+0}')
        fi
    fi

    if [ "$stale_files" -gt 0 ]; then
        log "${name}: Found ${stale_files} files ($(format_bytes $stale_size)) older than ${age_days} days"
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

# Clean directories with detailed reporting
# Usage: clean_dirs "Name" "path" age_days maxdepth
clean_dirs() {
    local name="$1"
    local path="$2"
    local age_days="$3"
    local maxdepth="$4"

    if [ ! -d "$path" ]; then
        return 0
    fi

    # Find directories older than age_days (excluding the root path itself)
    local stale_dirs_list=$(find "$path" -mindepth 1 -maxdepth "$maxdepth" -type d -mtime "+${age_days}" 2>/dev/null)
    local stale_dirs=0
    if [ -n "$stale_dirs_list" ]; then
        stale_dirs=$(echo "$stale_dirs_list" | wc -l | tr -d ' ')
    fi

    if [ "$stale_dirs" -gt 0 ]; then
        log "${name}: Found ${stale_dirs} directories older than ${age_days} days:"
        echo "$stale_dirs_list" | while read -r dir; do
            log "  - $(basename "$dir")"
        done
        if [ "$DRY_RUN" = true ]; then
            log "${name}: [DRY-RUN] Would delete ${stale_dirs} directories"
        else
            find "$path" -mindepth 1 -maxdepth "$maxdepth" -type d -mtime "+${age_days}" -exec rm -rf {} + 2>/dev/null
            log "${name}: Deleted ${stale_dirs} directories"
        fi
        TOTAL_DIRS_DELETED=$((TOTAL_DIRS_DELETED + stale_dirs))
    else
        log "${name}: No stale directories found"
    fi
}

log "=============================================="
log "Downloads Cleanup Started"
log "=============================================="
log "Hostname: $(hostname)"
log "User: $(whoami)"
log ""

# Main Downloads folder
clean_files "Downloads" "$HOME/Downloads" "$DOWNLOADS_MAX_AGE" 1

# Installers
clean_files "Installers" "$HOME/Downloads/installers" "$INSTALLERS_MAX_AGE" 1

# Images
clean_files "Images" "$HOME/Downloads/images" "$IMAGES_MAX_AGE" 1

# Torrents
clean_files "Torrents" "$HOME/Downloads/torrents" "$TORRENTS_MAX_AGE" 1

# Archives - files
clean_files "Archives (all)" "$HOME/Downloads/archives" "$ARCHIVES_MAX_AGE" 2
clean_files "Archives (zip)" "$HOME/Downloads/archives" "$ARCHIVES_ZIP_MAX_AGE" 2 -name "*.zip"

# Archives - directories
clean_dirs "Archives (dirs)" "$HOME/Downloads/archives" "$ARCHIVES_MAX_AGE" 2

# Any other old directories in Downloads root
clean_dirs "Downloads (dirs)" "$HOME/Downloads" "$DOWNLOADS_MAX_AGE" 1

# Summary - only show if something was cleaned (or verbose mode)
if [ "$TOTAL_FILES_DELETED" -gt 0 ] || [ "$TOTAL_DIRS_DELETED" -gt 0 ] || [ "$VERBOSITY" -eq 1 ]; then
    log ""
    log "=============================================="
    log "Downloads Cleanup Summary"
    log "=============================================="

    if [ "$DRY_RUN" = true ]; then
        log_summary "[DRY-RUN] Would delete ${TOTAL_FILES_DELETED} files, freeing $(format_bytes $TOTAL_BYTES_FREED)"
        log_summary "[DRY-RUN] Would remove ${TOTAL_DIRS_DELETED} directories"
    else
        if [ "$TOTAL_FILES_DELETED" -gt 0 ] || [ "$TOTAL_DIRS_DELETED" -gt 0 ]; then
            log_summary "Downloads cleanup: deleted ${TOTAL_FILES_DELETED} files, freed $(format_bytes $TOTAL_BYTES_FREED), removed ${TOTAL_DIRS_DELETED} dirs"
        else
            log "No stale files found"
        fi
    fi

    log "=============================================="
fi
