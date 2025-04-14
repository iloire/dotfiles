#!/bin/bash

# Backup script for home directory plus system directories with selective exclusions

echo "===== SYSTEM AND HOME DIRECTORY BACKUP SCRIPT ====="
echo "Starting backup process at $(date)"

SOURCE="$HOME"
echo "Source directory: $SOURCE"

# Initialize variables
REMOTE_BACKUP=false
REMOTE_USER=""
REMOTE_HOST=""
REMOTE_PATH=""

# Store the current user information
CURRENT_USER=$(whoami)
CURRENT_USER_ID=$(id -u)
CURRENT_GROUP_ID=$(id -g)

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --backup-dir)
            if [ -n "$2" ]; then
                BACKUP_DIR="$2"
                echo "Using BACKUP_DIR from command line argument: $BACKUP_DIR"
                shift 2
            else
                echo "ERROR: --backup-dir requires a directory path"
                exit 1
            fi
            ;;
        --remote-backup)
            REMOTE_BACKUP=true
            shift
            # Next three arguments should be user, host, path
            if [ $# -lt 3 ]; then
                echo "ERROR: --remote-backup requires three additional parameters: <remote_user> <remote_host> <remote_path>"
                exit 1
            fi
            REMOTE_USER="$1"
            REMOTE_HOST="$2"
            REMOTE_PATH="$3"
            shift 3
            ;;
        *)
            # For backward compatibility, check if we have 3 positional args (user, host, path)
            if [ $# -ge 3 ] && [ "$REMOTE_BACKUP" = "false" ]; then
                REMOTE_BACKUP=true
                REMOTE_USER="$1"
                REMOTE_HOST="$2"
                REMOTE_PATH="$3"
                shift 3
            else
                echo "ERROR: Unknown parameter: $1"
                echo "Usage: $0 [--backup-dir <backup_directory>] [--remote-backup <remote_user> <remote_host> <remote_path>]"
                exit 1
            fi
            ;;
    esac
done

# Check if BACKUP_DIR is set from environment or command line
if [ -z "$BACKUP_DIR" ]; then
    if [ -n "$BACKUP_DIR_ENV" ]; then
        BACKUP_DIR="$BACKUP_DIR_ENV"
        echo "Using BACKUP_DIR from environment variable: $BACKUP_DIR"
    else
        echo "ERROR: BACKUP_DIR not specified"
        echo "Please set the BACKUP_DIR environment variable or provide it as an argument:"
        echo "Usage: $0 --backup-dir <backup_directory> [--remote-backup <remote_user> <remote_host> <remote_path>]"
        exit 1
    fi
fi

# Check if backup directory exists or can be created
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Backup directory does not exist, attempting to create: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "ERROR: Failed to create backup directory at $BACKUP_DIR"
        echo "Please ensure the path exists and is writable"
        exit 1
    fi
fi

# Check if backup directory is writable
if [ ! -w "$BACKUP_DIR" ]; then
    echo "ERROR: Backup directory exists but is not writable: $BACKUP_DIR"
    echo "Please ensure proper permissions are set"
    exit 1
fi

echo "Backup directory verified: $BACKUP_DIR"

# Temporary backup file name with date (e.g., home_backup_2025-03-16.tar.gz)
DATE=$(date +%Y-%m-%d)
DATE_STR=$(date +"%Y-%m-%d %H:%M:%S")

BACKUP_FILE="$BACKUP_DIR/home_backup_$DATE.tar.gz"
LOG_FILE="$BACKUP_DIR/home_backup_$DATE.log"
DIRS_LOG_FILE="$BACKUP_DIR/home_backup_directories_$DATE.log"
echo "Backup will be saved as: $BACKUP_FILE"
echo "Log will be saved as: $LOG_FILE"
echo "Directory list will be saved as: $DIRS_LOG_FILE"

# Start logging
exec > >(tee -a "$LOG_FILE") 2>&1
echo "===== BACKUP LOG: $(date) ====="
echo "Source directory: $SOURCE"
echo "Backup directory: $BACKUP_DIR"
if [ "$REMOTE_BACKUP" = "true" ]; then
    echo "Remote backup enabled: $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH"
fi

# Start timer
START_TIME=$(date +%s)

echo "Creating tar.gz archive with the following exclusions:"
echo "  - .cache"
echo "  - .local/share/Trash"
echo "  - .thumbnails"
echo "  - *.bak files"
echo "  - *.tmp files"
echo "  - .npm"
echo "  - .steam and .local/share/Steam"
echo "  - .wine"
echo "  - Various system files and directories"
echo "  - Downloads directory"
echo "  - Development-related directories (.git, node_modules, venv, .venv)"
echo "  - Patterns from .gitignore files"
echo "  - Patterns from .tarignore files (if present)"
echo "  - All 'Cache' folders inside .config directory"
echo "  - /etc and /root directories"

# Function to create a list of directories with sizes
generate_directory_list() {
    echo "===== BACKED UP DIRECTORIES WITH SIZES =====" > "$DIRS_LOG_FILE"
    echo "Generated on: $(date)" >> "$DIRS_LOG_FILE"
    echo "Source directory: $SOURCE" >> "$DIRS_LOG_FILE"
    echo "" >> "$DIRS_LOG_FILE"
    
    echo "Generating list of home directory sizes..."
    echo "HOME DIRECTORY SIZES:" >> "$DIRS_LOG_FILE"
    echo "-------------------" >> "$DIRS_LOG_FILE"
    find "$SOURCE" -type d -not -path "*/\.*" -maxdepth 2 | while read -r dir; do
        if [ -d "$dir" ]; then
            # Check against exclusion patterns
            for pattern in "*.bak" "*.tmp" ".git" "$HOME/.cache" "$HOME/Downloads" "$HOME/dotfiles" "$HOME/backup" "venv" ".venv" "$HOME/snap"; do
                if [[ "$dir" == $pattern ]]; then
                    continue 2
                fi
            done
            size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            echo "$size  $dir" >> "$DIRS_LOG_FILE"
        fi
    done
    
    echo "" >> "$DIRS_LOG_FILE"
    echo "SYSTEM DIRECTORY SIZES:" >> "$DIRS_LOG_FILE"
    echo "-------------------" >> "$DIRS_LOG_FILE"
    find "/etc" -type d -maxdepth 2 | while read -r dir; do
        if [ -d "$dir" ]; then
            # Check against exclusion patterns
            for pattern in "/etc/alternatives" "/etc/cache" "/etc/lvm/cache" "/etc/ssl/certs"; do
                if [[ "$dir" == $pattern ]]; then
                    continue 2
                fi
            done
            size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            echo "$size  $dir" >> "$DIRS_LOG_FILE"
        fi
    done
    
    echo "" >> "$DIRS_LOG_FILE"
    echo "TOP 20 LARGEST DIRECTORIES:" >> "$DIRS_LOG_FILE"
    echo "-------------------" >> "$DIRS_LOG_FILE"
    {
        find "$SOURCE" -type d -not -path "*/\.*" 2>/dev/null
        find "/etc" -type d 2>/dev/null
    } | while read -r dir; do
        du -sk "$dir" 2>/dev/null
    done | sort -rn | head -20 | while read -r size dir; do
        human_size=$(numfmt --to=iec-i --suffix=B --format="%.2f" "$size"K)
        echo "$human_size  $dir" >> "$DIRS_LOG_FILE"
    done
    
    echo "" >> "$DIRS_LOG_FILE"
    echo "===== END OF DIRECTORY LIST =====" >> "$DIRS_LOG_FILE"
    
    # Also include the summary in the main log
    echo "$DATE_STR - Directory list with sizes generated: $DIRS_LOG_FILE"
}

echo "$DATE_STR - Starting tar archive creation..."

# Create the tar.gz archive with exclusions
sudo tar -czvf "$BACKUP_FILE" \
    --exclude="*.bak" \
    --exclude="*.tmp" \
    --exclude=".git" \
    --exclude="$HOME/.nv" \
    --exclude="$HOME/.arduino*" \
    --exclude="$HOME/.cache" \
    --exclude="$HOME/.cache/compizconfig-1" \
    --exclude="$HOME/.compiz" \
    --exclude="$HOME/.config/BraveSoftware" \
    --exclude="$HOME/.config/dconf" \
    --exclude="$HOME/.config/google-chrome" \
    --exclude="$HOME/.config/unity*" \
    --exclude="$HOME/.config/*/Cache" \
    --exclude="$HOME/.config/*/CachedData" \
    --exclude="$HOME/.config/*/CacheStorage" \
    --exclude="$HOME/.config/*/cache" \
    --exclude="$HOME/.config/balena-etcher*" \
    --exclude="$HOME/.oh-my-zsh" \
    --exclude="$HOME/code/*/build" \
    --exclude="$HOME/code/*/dist" \
    --exclude="$HOME/code/*/out" \
    --exclude="$HOME/code/*/release" \
    --exclude="$HOME/code/*/cache" \
    --exclude="$HOME/*/node_modules" \
    --exclude="$HOME/.dbus" \
    --exclude="$HOME/.docker" \
    --exclude="$HOME/dotfiles" \
    --exclude="$HOME/notes" \
    --exclude="$HOME/.googleearth" \
    --exclude="$HOME/.ICEauthority" \
    --exclude="$HOME/.local/lib" \
    --exclude="$HOME/.local/share/nvim" \
    --exclude="$HOME/.local/share/nvim*" \
    --exclude="$HOME/.local/share/Steam" \
    --exclude="$HOME/.local/share/torbrowser" \
    --exclude="$HOME/.local/share/Trash" \
    --exclude="$HOME/.local/share/unity" \
    --exclude="$HOME/.npm" \
    --exclude="$HOME/.nvm" \
    --exclude="$HOME/.steam" \
    --exclude="$HOME/.tastytrade" \
    --exclude="$HOME/.thumbnails" \
    --exclude="$HOME/.vagrant.d" \
    --exclude="$HOME/.var" \
    --exclude="$HOME/.wine" \
    --exclude="$HOME/.vscode" \
    --exclude="$HOME/.Xauthority" \
    --exclude="$HOME/VirtualBox*" \
    --exclude="$HOME/vms" \
    --exclude="$HOME/*/Cache" \
    --exclude="$HOME/backup" \
    --exclude="$HOME/Downloads" \
    --exclude="$HOME/Unity" \
    --exclude="$HOME/miniconda*" \
    --exclude="/root/miniconda*" \
    --exclude="$HOME/snap" \
    --exclude="$HOME/tor-browser" \
    --exclude="venv" \
    --exclude=".venv" \
    --exclude="/etc/alternatives" \
    --exclude="/etc/cache" \
    --exclude="/etc/lvm/cache" \
    --exclude="/etc/ssl/certs" \
    "$SOURCE" "/etc" 2>&1

# Check if tar was successful
TAR_STATUS=${PIPESTATUS[0]}

if [ $TAR_STATUS -eq 0 ]; then
    # Get file size
    BACKUP_SIZE="$(du -h "$BACKUP_FILE" | cut -f1)"
    echo "$DATE_STR - Archive created successfully: $BACKUP_FILE (Size: $BACKUP_SIZE)"
    
    # Generate the directory listing after successful backup
    echo "$DATE_STR - Generating directory size listing..."
    generate_directory_list

    # Ensure the backup file is owned by the current user
    if [ -f "$BACKUP_FILE" ]; then
        chown "$CURRENT_USER_ID:$CURRENT_GROUP_ID" "$BACKUP_FILE"
        chmod 644 "$BACKUP_FILE"
    fi
    
    # Ensure the log files are also owned by the current user
    if [ -f "$LOG_FILE" ]; then
        chown "$CURRENT_USER_ID:$CURRENT_GROUP_ID" "$LOG_FILE"
        chmod 644 "$LOG_FILE"
    fi
else
    echo "$DATE_STR - ERROR: Failed to create archive! Exit code: $TAR_STATUS"
    exit 1
fi

# Calculate elapsed time
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))
echo "$DATE_STR - Archive creation took $MINUTES minutes and $SECONDS seconds"

# Check if remote backup is enabled
if [ "$REMOTE_BACKUP" = "true" ]; then
    echo "$DATE_STR - ===== REMOTE TRANSFER ====="
    echo "$DATE_STR - Transferring backup to $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH..."
    echo "$DATE_STR - Starting transfer at $(date)"
    
    TRANSFER_START=$(date +%s)
    scp -v "$BACKUP_FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH" 2>&1
    SCP_STATUS=${PIPESTATUS[0]}

    if [ $SCP_STATUS -eq 0 ]; then
        TRANSFER_END=$(date +%s)
        TRANSFER_TIME=$((TRANSFER_END - TRANSFER_START))
        TRANSFER_MIN=$((TRANSFER_TIME / 60))
        TRANSFER_SEC=$((TRANSFER_TIME % 60))
        
        echo "$DATE_STR - Backup transferred successfully to $REMOTE_HOST:$REMOTE_PATH"
        echo "$DATE_STR - Transfer took $TRANSFER_MIN minutes and $TRANSFER_SEC seconds"
        
        # Also transfer the directory listing log
        echo "$DATE_STR - Transferring directory listing to remote host..."
        scp -v "$DIRS_LOG_FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH" 2>&1
        
        echo "$DATE_STR - Removing local backup file..."
        rm "$BACKUP_FILE"
        echo "$DATE_STR - Local archive $BACKUP_FILE deleted"
        
        # Also transfer the log file
        echo "$DATE_STR - Transferring log file to remote host..."
        scp -v "$LOG_FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH" 2>&1
    else
        echo "$DATE_STR - ERROR: Transfer failed! Exit code: $SCP_STATUS"
        exit 1
    fi
else
    echo "$DATE_STR - No remote backup requested. Backup stored in: $BACKUP_FILE"
    echo "$DATE_STR - Directory listing stored in: $DIRS_LOG_FILE"
    echo "$DATE_STR - To enable remote backup use: $0 --backup-dir <backup_directory> --remote-backup <remote_user> <remote_host> <remote_path>"
fi

echo "$DATE_STR - ===== BACKUP PROCESS COMPLETED ====="
echo "$DATE_STR - Finished at: $(date)"
TOTAL_TIME=$(($(date +%s) - START_TIME))
TOTAL_MIN=$((TOTAL_TIME / 60))
TOTAL_SEC=$((TOTAL_TIME % 60))
echo "$DATE_STR - Total execution time: $TOTAL_MIN minutes and $TOTAL_SEC seconds"