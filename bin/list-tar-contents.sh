#!/bin/bash

# Script to analyze tar archive contents and generate directory listing
# Usage: list-tar-contents.sh <tar_file> <output_log_file>

if [ $# -lt 2 ]; then
    echo "ERROR: Missing required parameters"
    echo "Usage: $0 <tar_file> <output_log_file> [source_dir]"
    exit 1
fi

TAR_FILE="$1"
DIRS_LOG_FILE="$2"
SOURCE_DIR="${3:-Unknown}"

# Check if input file exists
if [ ! -f "$TAR_FILE" ]; then
    echo "ERROR: Tar file does not exist: $TAR_FILE"
    exit 1
fi

# Store the current user information
CURRENT_USER=$(whoami)
CURRENT_USER_ID=$(id -u)
CURRENT_GROUP_ID=$(id -g)

echo "===== BACKUP ARCHIVE CONTENTS =====" > "$DIRS_LOG_FILE"
echo "Generated on: $(date)" >> "$DIRS_LOG_FILE"
echo "Source directory: $SOURCE_DIR" >> "$DIRS_LOG_FILE"
echo "Archive file: $TAR_FILE ($(du -h "$TAR_FILE" | cut -f1))" >> "$DIRS_LOG_FILE"
echo "" >> "$DIRS_LOG_FILE"

echo "Analyzing contents of archive file..."

# Create a temporary directory for analysis
TEMP_DIR=$(mktemp -d)

echo "TOP-LEVEL DIRECTORIES AND FILES:" >> "$DIRS_LOG_FILE"
echo "-------------------" >> "$DIRS_LOG_FILE"

# Extract directory structure (without extracting files)
# List all entries in the tar file and sort them
tar -tvf "$TAR_FILE" | sort > "$TEMP_DIR/tar_contents.txt"

# Process the tar contents to generate directory statistics
# First, get top-level directories
echo "Extracting top-level directories from archive..."
grep -E '^d' "$TEMP_DIR/tar_contents.txt" | grep -v '/' | sort | while read -r line; do
    echo "$line" | awk '{print $6, "(directory)"}' >> "$DIRS_LOG_FILE"
done

grep -E '^-' "$TEMP_DIR/tar_contents.txt" | grep -v '/' | sort | while read -r line; do
    size=$(echo "$line" | awk '{print $3}')
    name=$(echo "$line" | awk '{print $6}')
    human_size=$(numfmt --to=iec-i --suffix=B --format="%.2f" "$size")
    echo "$human_size  $name" >> "$DIRS_LOG_FILE"
done

echo "" >> "$DIRS_LOG_FILE"
echo "DIRECTORY SIZES (Approximate):" >> "$DIRS_LOG_FILE"
echo "-------------------" >> "$DIRS_LOG_FILE"

# Extract unique directories (first level)
cat "$TEMP_DIR/tar_contents.txt" | awk '{print $6}' | grep '/' | sed 's|/.*||' | sort | uniq > "$TEMP_DIR/top_dirs.txt"

# For each top directory, calculate size
while read -r dir; do
    if [ -n "$dir" ]; then
        # Get all files in this directory (and subdirectories)
        grep -E "^-" "$TEMP_DIR/tar_contents.txt" | grep "^-" | grep -E "$dir/" > "$TEMP_DIR/dir_files.txt" || true
        
        # Calculate total size
        total_size=0
        while read -r file_line; do
            file_size=$(echo "$file_line" | awk '{print $3}')
            total_size=$((total_size + file_size))
        done < "$TEMP_DIR/dir_files.txt"
        
        # Convert to human-readable
        if [ $total_size -gt 0 ]; then
            human_size=$(numfmt --to=iec-i --suffix=B --format="%.2f" "$total_size")
            echo "$human_size  $dir/" >> "$DIRS_LOG_FILE"
        fi
    fi
done < "$TEMP_DIR/top_dirs.txt"

echo "" >> "$DIRS_LOG_FILE"
echo "TOP 20 LARGEST FILES IN ARCHIVE:" >> "$DIRS_LOG_FILE"
echo "-------------------" >> "$DIRS_LOG_FILE"

# Find the largest files
grep -E "^-" "$TEMP_DIR/tar_contents.txt" | sort -k3 -n -r | head -20 | while read -r line; do
    size=$(echo "$line" | awk '{print $3}')
    name=$(echo "$line" | awk '{print $6}')
    human_size=$(numfmt --to=iec-i --suffix=B --format="%.2f" "$size")
    echo "$human_size  $name" >> "$DIRS_LOG_FILE"
done

echo "" >> "$DIRS_LOG_FILE"
echo "COMPRESSION RATIO:" >> "$DIRS_LOG_FILE"
echo "-------------------" >> "$DIRS_LOG_FILE"

# Calculate total uncompressed size
total_uncompressed=0
grep -E "^-" "$TEMP_DIR/tar_contents.txt" | while read -r line; do
    file_size=$(echo "$line" | awk '{print $3}')
    total_uncompressed=$((total_uncompressed + file_size))
done

# Get compressed size
compressed_size=$(stat -c %s "$TAR_FILE")

# Calculate ratio if uncompressed is not zero
if [ $total_uncompressed -gt 0 ]; then
    ratio=$(echo "scale=2; $compressed_size / $total_uncompressed" | bc)
    echo "Uncompressed size: $(numfmt --to=iec-i --suffix=B --format="%.2f" "$total_uncompressed")" >> "$DIRS_LOG_FILE"
    echo "Compressed size: $(numfmt --to=iec-i --suffix=B --format="%.2f" "$compressed_size")" >> "$DIRS_LOG_FILE"
    echo "Compression ratio: $ratio (lower is better)" >> "$DIRS_LOG_FILE"
else
    echo "Unable to calculate compression ratio - no regular files found" >> "$DIRS_LOG_FILE"
fi

echo "" >> "$DIRS_LOG_FILE"
echo "TOTALS:" >> "$DIRS_LOG_FILE"
echo "-------------------" >> "$DIRS_LOG_FILE"

# Count total number of files and directories
total_files=$(grep -E "^-" "$TEMP_DIR/tar_contents.txt" | wc -l)
total_dirs=$(grep -E "^d" "$TEMP_DIR/tar_contents.txt" | wc -l)
echo "Total files: $total_files" >> "$DIRS_LOG_FILE"
echo "Total directories: $total_dirs" >> "$DIRS_LOG_FILE"
echo "Total entries: $((total_files + total_dirs))" >> "$DIRS_LOG_FILE"

echo "" >> "$DIRS_LOG_FILE"
echo "===== END OF ARCHIVE CONTENT ANALYSIS =====" >> "$DIRS_LOG_FILE"

# Clean up temporary directory
rm -rf "$TEMP_DIR"

# Ensure the directory list file is owned by the current user
if [ -f "$DIRS_LOG_FILE" ]; then
    chown "$CURRENT_USER_ID:$CURRENT_GROUP_ID" "$DIRS_LOG_FILE"
    chmod 644 "$DIRS_LOG_FILE"
fi

echo "Archive contents analysis generated: $DIRS_LOG_FILE" 