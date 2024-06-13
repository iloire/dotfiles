#!/bin/bash

# Function to display usage
usage() {
	echo "Usage: $0 [directory]"
	exit 1
}

# Check if a directory is provided as an argument; otherwise, use the current directory
DIRECTORY="${1:-.}"

# Check if the provided directory exists
if [ ! -d "$DIRECTORY" ]; then
	echo "Error: Directory $DIRECTORY does not exist."
	usage
fi

# Function to apply colors based on size
colorize_size() {
	SIZE=$1
	ITEM=$2

	# Remove trailing size indicator (K, M, G, T)
	SIZE_NUMBER=$(echo $SIZE | sed 's/[KMGTP]//')

	# Determine the color based on size
	if [[ $SIZE == *K ]]; then
		COLOR="\e[1;32m" # Green for Kilobytes
	elif [[ $SIZE == *M ]]; then
		COLOR="\e[1;33m" # Yellow for Megabytes
	elif [[ $SIZE == *G ]]; then
		COLOR="\e[1;31m" # Red for Gigabytes
	elif [[ $SIZE == *T ]]; then
		COLOR="\e[1;35m" # Magenta for Terabytes
	else
		COLOR="\e[1;34m" # Blue for other cases
	fi

	# Print the colored output
	echo -e "${COLOR}${SIZE}\t${ITEM}\e[0m"
}

# List the space taken in the directory with a nice format and colors
echo -e "\e[1;34mSpace taken in directory: $DIRECTORY\e[0m"
du -h --max-depth=1 "$DIRECTORY" | sort -h | while read size item; do
	colorize_size "$size" "$item"
done
