#!/bin/bash
#
# Download GPS tracks from Flymaster and organize into folders by year/month
#
# Usage:
#   download-gps-tracks.sh              # Download from GPS and organize
#   download-gps-tracks.sh download     # Only download from GPS to current directory
#   download-gps-tracks.sh organize     # Only organize files in current directory
#

set -euo pipefail

# Configuration
GPS_DUMP="/Users/ivan/bin/GpsDumpMac64.1.15"
USB_DEVICE="usbmodem0000001"
BASE_DIR="/Users/ivan/Google Drive/My Drive/other/paragliding/paragliding flights"

# Month names for folder creation
declare -a MONTHS=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")

show_usage() {
    echo "Usage: $(basename "$0") <command>"
    echo ""
    echo "Commands:"
    echo "  all        Download from GPS and organize into folders"
    echo "  download   Only download tracks from GPS to current directory"
    echo "  organize   Only organize .igc files from current directory into folders"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") all          # Full workflow: download + organize"
    echo "  $(basename "$0") download     # Just download to current dir"
    echo "  $(basename "$0") organize     # Organize existing .igc files"
}

download_tracks() {
    # Validate GPS dump tool exists
    if [[ ! -x "$GPS_DUMP" ]]; then
        echo "Error: GpsDump tool not found or not executable: $GPS_DUMP"
        echo ""
        echo "Please ensure GpsDumpMac64.1.15 is installed at the specified path."
        return 1
    fi

    # Check if USB device exists
    if [[ ! -e "/dev/cu.${USB_DEVICE}" ]]; then
        echo "Error: USB device not found: /dev/cu.${USB_DEVICE}"
        echo ""
        echo "Possible causes:"
        echo "  - GPS is not connected via USB"
        echo "  - GPS is not powered on"
        echo "  - USB cable is not properly connected"
        echo "  - Device name has changed (check 'ls /dev/cu.usbmodem*')"
        return 1
    fi

    echo "Connecting to GPS on /dev/cu.${USB_DEVICE}..."
    echo "Downloading tracks..."

    if ! "$GPS_DUMP" -L -gy -cu.${USB_DEVICE}; then
        echo "Error: Failed to download tracks from GPS"
        echo ""
        echo "Possible causes:"
        echo "  - GPS is not in the correct mode for data transfer"
        echo "  - Communication error with the device"
        echo "  - Try disconnecting and reconnecting the GPS"
        return 1
    fi

    echo "Download complete."
}

organize_tracks() {
    # Validate base directory exists
    if [[ ! -d "$BASE_DIR" ]]; then
        echo "Error: Base directory does not exist: $BASE_DIR"
        echo ""
        echo "Possible causes:"
        echo "  - Google Drive is not mounted or syncing"
        echo "  - The path has changed"
        echo "  - You need to grant Full Disk Access to Terminal in System Preferences > Privacy & Security"
        return 1
    fi

    # Check if any .igc files exist
    shopt -s nullglob
    files=(*.igc)
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "No .igc files found in current directory."
        return 0
    fi

    echo "Found ${#files[@]} track(s). Organizing into folders..."

    # Process each file
    for file in *.igc; do
        # Extract date from filename (format: YYYY-MM-DD_HH-MM.igc)
        if [[ $file =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})_ ]]; then
            year="${BASH_REMATCH[1]}"
            month="${BASH_REMATCH[2]}"

            # Convert month number to name (01 -> Jan, etc.)
            month_index=$((10#$month - 1))
            month_name="${MONTHS[$month_index]}"

            # Create target folder structure: YYYY/MonYYYY/
            target_dir="${BASE_DIR}/${year}/${month_name}${year}"

            if [[ ! -d "$target_dir" ]]; then
                echo "Creating folder: $target_dir"
                mkdir -p "$target_dir"
            fi

            target_file="${target_dir}/${file}"

            if [[ -f "$target_file" ]]; then
                echo "Skipping (already exists): $file"
            else
                echo "Moving: $file -> ${year}/${month_name}${year}/"
                mv "$file" "$target_file"
            fi
        else
            echo "Warning: Could not parse date from filename: $file"
        fi
    done

    echo "Organization complete."
}

# Main
case "${1:-}" in
    download)
        download_tracks
        ;;
    organize)
        organize_tracks
        ;;
    all)
        # Full workflow: download to temp dir, then organize
        TEMP_DIR=$(mktemp -d)
        cleanup() {
            rm -rf "$TEMP_DIR"
        }
        trap cleanup EXIT

        cd "$TEMP_DIR"
        download_tracks
        organize_tracks
        echo "Done!"
        ;;
    -h|--help|help|"")
        show_usage
        ;;
    *)
        echo "Error: Unknown command '$1'"
        echo ""
        show_usage
        exit 1
        ;;
esac
