#!/bin/bash

# Backup script for home directory plus system directories with selective exclusions

# Check if running with sudo/root privileges


echo "===== SYSTEM AND HOME DIRECTORY BACKUP SCRIPT ====="
echo "Starting backup process at $(date)"

# Source directory (your home directory)
SOURCE="$HOME"
echo "Source directory: $SOURCE"

# Define backup directory
BACKUP_DIR="$HOME/backup"

# Create backup directory if it doesn't exist
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Creating backup directory at $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
fi

# Temporary backup file name with date (e.g., home_backup_2025-03-16.tar.gz)
DATE=$(date +%Y-%m-%d)
BACKUP_FILE="$BACKUP_DIR/home_backup_$DATE.tar.gz"
LOG_FILE="$BACKUP_DIR/home_backup_$DATE.log"
echo "Backup will be saved as: $BACKUP_FILE"
echo "Log will be saved as: $LOG_FILE"

# Start logging
exec > >(tee -a "$LOG_FILE") 2>&1
echo "===== BACKUP LOG: $(date) =====" | tee -a "$LOG_FILE"
echo "Source directory: $SOURCE" | tee -a "$LOG_FILE"

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

echo "$(date +"%Y-%m-%d %H:%M:%S") - Starting tar archive creation..." | tee -a "$LOG_FILE"

# Create the tar.gz archive with exclusions
sudo tar -czvf "$BACKUP_FILE" \
    --exclude="*.bak" \
    --exclude="*.tmp" \
    --exclude=".git" \
    --exclude="$HOME/.nv" \
    --exclude="$HOME/.arduinoIDE" \
    --exclude="$HOME/.arduino15" \
    --exclude="$HOME/.cache" \
    --exclude="$HOME/.cache/compizconfig-1" \
    --exclude="$HOME/.compiz" \
    --exclude="$HOME/.config/BraveSoftware" \
    --exclude="$HOME/.config/dconf" \
    --exclude="$HOME/.config/google-chrome" \
    --exclude="$HOME/.config/unity" \
    --exclude="$HOME/.config/unity3d" \
    --exclude="$HOME/.config/unityhub" \
    --exclude="$HOME/.config/*/Cache" \
    --exclude="$HOME/.config/*/CachedData" \
    --exclude="$HOME/.config/*/CacheStorage" \
    --exclude="$HOME/.config/*/cache" \
    --exclude="$HOME/.config/balena-etcher" \
    --exclude="$HOME/.code/*/build" \
    --exclude="$HOME/.code/*/dist" \
    --exclude="$HOME/.code/*/node_modules" \
    --exclude="$HOME/.code/*/out" \
    --exclude="$HOME/.code/*/release" \
    --exclude="$HOME/.code/*/cache" \
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
    --exclude="$HOME/VirtualBox VMs" \
    --exclude="$HOME/vms" \
    --exclude="$HOME/*/Cache" \
    --exclude="$HOME/backup" \
    --exclude="$HOME/Downloads" \
    --exclude="$HOME/Unity" \
    --exclude="$HOME/miniconda3" \
    --exclude="/root/miniconda3" \
    --exclude="$HOME/snap" \
    --exclude="venv" \
    --exclude=".venv" \
    --exclude="/etc/alternatives" \
    --exclude="/etc/cache" \
    --exclude="/etc/lvm/cache" \
    --exclude="/etc/ssl/certs" \
    "$SOURCE" "/etc" "/root" 2>&1 | tee -a "$LOG_FILE"

# Check if tar was successful
TAR_STATUS=${PIPESTATUS[0]}
if [ $TAR_STATUS -eq 0 ]; then
    # Get file size
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Archive created successfully: $BACKUP_FILE (Size: $BACKUP_SIZE)" | tee -a "$LOG_FILE"
else
    echo "$(date +"%Y-%m-%d %H:%M:%S") - ERROR: Failed to create archive! Exit code: $TAR_STATUS" | tee -a "$LOG_FILE"
    exit 1
fi

# Calculate elapsed time
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))
echo "$(date +"%Y-%m-%d %H:%M:%S") - Archive creation took $MINUTES minutes and $SECONDS seconds" | tee -a "$LOG_FILE"

# Check if enough parameters are provided for transfer (at least 3: user, host, path)
if [ "$#" -ge 3 ]; then
    REMOTE_USER="$1"
    REMOTE_HOST="$2"
    REMOTE_PATH="$3"

    echo "$(date +"%Y-%m-%d %H:%M:%S") - ===== REMOTE TRANSFER =====" | tee -a "$LOG_FILE"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Transferring backup to $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH..." | tee -a "$LOG_FILE"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Starting transfer at $(date)" | tee -a "$LOG_FILE"
    
    TRANSFER_START=$(date +%s)
    scp -v "$BACKUP_FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH" 2>&1 | tee -a "$LOG_FILE"
    SCP_STATUS=${PIPESTATUS[0]}

    if [ $SCP_STATUS -eq 0 ]; then
        TRANSFER_END=$(date +%s)
        TRANSFER_TIME=$((TRANSFER_END - TRANSFER_START))
        TRANSFER_MIN=$((TRANSFER_TIME / 60))
        TRANSFER_SEC=$((TRANSFER_TIME % 60))
        
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Backup transferred successfully to $REMOTE_HOST:$REMOTE_PATH" | tee -a "$LOG_FILE"
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Transfer took $TRANSFER_MIN minutes and $TRANSFER_SEC seconds" | tee -a "$LOG_FILE"
        
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Removing local backup file..." | tee -a "$LOG_FILE"
        rm "$BACKUP_FILE"
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Local archive $BACKUP_FILE deleted" | tee -a "$LOG_FILE"
        
        # Also transfer the log file
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Transferring log file to remote host..." | tee -a "$LOG_FILE"
        scp -v "$LOG_FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH" 2>&1 | tee -a "$LOG_FILE"
    else
        echo "$(date +"%Y-%m-%d %H:%M:%S") - ERROR: Transfer failed! Exit code: $SCP_STATUS" | tee -a "$LOG_FILE"
        exit 1
    fi
else
    echo "$(date +"%Y-%m-%d %H:%M:%S") - No transfer requested or insufficient parameters. Backup stored in: $BACKUP_FILE" | tee -a "$LOG_FILE"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Usage for transfer: $0 <remote_user> <remote_host> <remote_path>" | tee -a "$LOG_FILE"
fi

echo "$(date +"%Y-%m-%d %H:%M:%S") - ===== BACKUP PROCESS COMPLETED =====" | tee -a "$LOG_FILE"
echo "$(date +"%Y-%m-%d %H:%M:%S") - Finished at: $(date)" | tee -a "$LOG_FILE"
TOTAL_TIME=$(($(date +%s) - START_TIME))
TOTAL_MIN=$((TOTAL_TIME / 60))
TOTAL_SEC=$((TOTAL_TIME % 60))
echo "$(date +"%Y-%m-%d %H:%M:%S") - Total execution time: $TOTAL_MIN minutes and $TOTAL_SEC seconds" | tee -a "$LOG_FILE"