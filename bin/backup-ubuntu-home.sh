#!/bin/bash

# Backup script for home directory with selective exclusions, including dev-related dirs

echo "===== HOME DIRECTORY BACKUP SCRIPT ====="
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
echo "Backup will be saved as: $BACKUP_FILE"

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

# Create the tar.gz archive with exclusions
tar -czvf "$BACKUP_FILE" \
    --exclude-ignore=.tarignore \
    --exclude-ignore=.gitignore \
    --exclude="$HOME/.cache" \
    --exclude="$HOME/.local/share/Trash" \
    --exclude="$HOME/.local/share/torbrowser" \
    --exclude="$HOME/.local/share/nvim" \
    --exclude="$HOME/.thumbnails" \
    --exclude="*.bak" \
    --exclude="*.tmp" \
    --exclude="$HOME/backup" \
    --exclude="$HOME/.npm" \
    --exclude="$HOME/.nvm" \
    --exclude="$HOME/.vagrant.d" \
    --exclude="$HOME/.steam" \
    --exclude="$HOME/.local/share/Steam" \
    --exclude="$HOME/.local/lib" \
    --exclude="$HOME/.googleearth" \
    --exclude="$HOME/.wine" \
    --exclude="$HOME/.dbus" \
    --exclude="$HOME/.Xauthority" \
    --exclude="$HOME/.ICEauthority" \
    --exclude="$HOME/.config/unity" \
    --exclude="$HOME/.config/unityhub" \
    --exclude="$HOME/.config/unity3d" \
    --exclude="$HOME/*/Cache" \
    --exclude="$HOME/.config/*/Cache" \
    --exclude="$HOME/.config/*/CachedData" \
    --exclude="$HOME/.config/*/CacheStorage" \
    --exclude="$HOME/.config/*/cache" \
    --exclude="$HOME/.config/google-chrome" \
    --exclude="$HOME/.config/BraveSoftware" \
    --exclude="$HOME/.compiz" \
    --exclude="$HOME/.var" \
    --exclude="$HOME/.tastytrade" \
    --exclude="$HOME/.cache/compizconfig-1" \
    --exclude="$HOME/.local/share/unity" \
    --exclude="$HOME/.config/dconf" \
    --exclude="$HOME/Downloads" \
    --exclude="$HOME/snap" \
    --exclude="$HOME/miniconda3" \
    --exclude=".git" \
    --exclude="node_modules" \
    --exclude="venv" \
    --exclude=".venv" \
    "$SOURCE"

# Check if tar was successful
if [ $? -eq 0 ]; then
    # Get file size
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "Archive created successfully: $BACKUP_FILE (Size: $BACKUP_SIZE)"
else
    echo "ERROR: Failed to create archive!"
    exit 1
fi

# Calculate elapsed time
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))
echo "Archive creation took $MINUTES minutes and $SECONDS seconds"

# Check if enough parameters are provided for transfer (at least 3: user, host, path)
if [ "$#" -ge 3 ]; then
    REMOTE_USER="$1"
    REMOTE_HOST="$2"
    REMOTE_PATH="$3"

    echo "===== REMOTE TRANSFER ====="
    echo "Transferring backup to $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH..."
    echo "Starting transfer at $(date)"
    
    TRANSFER_START=$(date +%s)
    scp -v "$BACKUP_FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH"

    if [ $? -eq 0 ]; then
        TRANSFER_END=$(date +%s)
        TRANSFER_TIME=$((TRANSFER_END - TRANSFER_START))
        TRANSFER_MIN=$((TRANSFER_TIME / 60))
        TRANSFER_SEC=$((TRANSFER_TIME % 60))
        
        echo "Backup transferred successfully to $REMOTE_HOST:$REMOTE_PATH"
        echo "Transfer took $TRANSFER_MIN minutes and $TRANSFER_SEC seconds"
        
        echo "Removing local backup file..."
        rm "$BACKUP_FILE"
        echo "Local archive $BACKUP_FILE deleted"
    else
        echo "ERROR: Transfer failed!"
        exit 1
    fi
else
    echo "No transfer requested or insufficient parameters. Backup stored in: $BACKUP_FILE"
    echo "Usage for transfer: $0 <remote_user> <remote_host> <remote_path>"
fi

echo "===== BACKUP PROCESS COMPLETED ====="
echo "Finished at: $(date)"
TOTAL_TIME=$(($(date +%s) - START_TIME))
TOTAL_MIN=$((TOTAL_TIME / 60))
TOTAL_SEC=$((TOTAL_TIME % 60))
echo "Total execution time: $TOTAL_MIN minutes and $TOTAL_SEC seconds"