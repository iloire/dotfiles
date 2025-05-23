#!/bin/bash

# Script to analyze tar archive contents and generate directory listing
# Usage: list-tar-contents.sh <tar_file> <output_log_file>

# Configuration variables
TOP_DIRS_COUNT=50     # Number of top largest directories to display
SIZE_THRESHOLD=1048576  # Size threshold for directory listing (1MB = 1048576 bytes)

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
echo "COMPLETE DIRECTORY SIZE ANALYSIS:" >> "$DIRS_LOG_FILE"
echo "-------------------" >> "$DIRS_LOG_FILE"

# Extract all unique directories from the tar file
# First, get all file paths
cat "$TEMP_DIR/tar_contents.txt" | awk '{print $6}' | sort > "$TEMP_DIR/all_paths.txt"

# Generate a list of all directories (including subdirectories)
{
  # Include explicitly listed directories (those with a 'd' prefix in tar output)
  grep -E '^d' "$TEMP_DIR/tar_contents.txt" | awk '{print $6}' 
  
  # Extract implied directories from file paths
  cat "$TEMP_DIR/all_paths.txt" | grep '/' | 
  while read -r path; do
    # Break path into components and reconstruct directory paths
    # For example, path "a/b/c/file.txt" generates "a", "a/b", "a/b/c"
    parts=$(echo "$path" | tr '/' ' ')
    current=""
    for part in $parts; do
      if [ -z "$current" ]; then
        current="$part"
      else
        current="$current/$part"
      fi
      # Output each directory component except the last one (which is the file itself)
      if [ "$current" != "$path" ]; then
        echo "$current"
      fi
    done
  done
} | sort | uniq > "$TEMP_DIR/all_dirs.txt"

# Calculate sizes for each directory
echo "# Directory, Size (bytes), Human-readable size" > "$TEMP_DIR/dir_sizes.csv"

# For each directory, calculate the total size of all files directly within it
cat "$TEMP_DIR/all_dirs.txt" | while read -r dir; do
    if [ -n "$dir" ]; then
        # Find all files directly in this directory (not in subdirectories)
        # We match the exact directory pattern to avoid counting files in subdirectories
        # e.g., for 'dir1/dir2', we want to match 'dir1/dir2/file' but not 'dir1/dir2/subdir/file'
        grep -E "^-" "$TEMP_DIR/tar_contents.txt" | grep -E "^.* $dir/[^/]+$" > "$TEMP_DIR/dir_files.txt" || true
        
        # Calculate total size
        dir_size=0
        while read -r file_line; do
            file_size=$(echo "$file_line" | awk '{print $3}')
            dir_size=$((dir_size + file_size))
        done < "$TEMP_DIR/dir_files.txt"
        
        # Convert to human-readable and add to CSV
        if [ -n "$dir" ]; then
            human_size=$(numfmt --to=iec-i --suffix=B --format="%.2f" "$dir_size")
            echo "$dir,$dir_size,$human_size" >> "$TEMP_DIR/dir_sizes.csv"
        fi
    fi
done

# Sort the directories by size (largest first) for display
sort -t, -k2 -nr "$TEMP_DIR/dir_sizes.csv" > "$TEMP_DIR/dir_sizes_sorted.csv"

# Output all directory sizes above threshold
echo "NOTE: Only showing directories 1MB or larger" >> "$DIRS_LOG_FILE"
while IFS=, read -r dir size human_size; do
    # Skip the header line and check size threshold
    if [ "$dir" != "# Directory" ] && [ "$size" -ge "$SIZE_THRESHOLD" ]; then
        echo "$human_size  $dir/" >> "$DIRS_LOG_FILE"
    fi
done < "$TEMP_DIR/dir_sizes_sorted.csv"

# Count and report filtered directories
total_dirs=$(grep -v "^# " "$TEMP_DIR/dir_sizes_sorted.csv" | wc -l)
displayed_dirs=$(grep -v "^# " "$TEMP_DIR/dir_sizes_sorted.csv" | awk -F, -v threshold="$SIZE_THRESHOLD" '$2 >= threshold {count++} END {print count}')
echo "Showing $displayed_dirs of $total_dirs directories (filtered out $(($total_dirs - $displayed_dirs)) directories smaller than 1MB)" >> "$DIRS_LOG_FILE"

echo "" >> "$DIRS_LOG_FILE"
echo "TOP $TOP_DIRS_COUNT LARGEST DIRECTORIES:" >> "$DIRS_LOG_FILE"
echo "-------------------" >> "$DIRS_LOG_FILE"

# Output top directories based on the configured count
head -n $((TOP_DIRS_COUNT + 1)) "$TEMP_DIR/dir_sizes_sorted.csv" | tail -n $TOP_DIRS_COUNT | while IFS=, read -r dir size human_size; do
    echo "$human_size  $dir/" >> "$DIRS_LOG_FILE"
done

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
implied_dirs=$(cat "$TEMP_DIR/all_dirs.txt" | wc -l)
echo "Total files: $total_files" >> "$DIRS_LOG_FILE"
echo "Total explicit directories: $total_dirs" >> "$DIRS_LOG_FILE"
echo "Total directories (including implied): $implied_dirs" >> "$DIRS_LOG_FILE"
echo "Total entries: $((total_files + implied_dirs))" >> "$DIRS_LOG_FILE"

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