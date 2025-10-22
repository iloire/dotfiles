#!/bin/bash
# Purpose: Monitor disk space and send an email alert to $ADMIN_EMAIL

# Parse command line arguments
VERBOSE=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--verbose) VERBOSE=true ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -v, --verbose    Enable verbose output"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

ALERT=92 # alert level
LOGFILENAME="$HOME/low-space-monitor.log"

# Output functions
info() {
    if [ "$VERBOSE" = true ]; then
        echo "$1"
    fi
}

alert() {
    if [ "$VERBOSE" = true ]; then
        echo "ALERT: $1"
    fi
}

error() {
    echo "ERROR: $1" >&2
}

if [ -z "$ADMIN_EMAIL" ]; then
	error "ADMIN_EMAIL env variable not defined"
	exit 1
fi

# Detect OS and set command paths
if [[ "$OSTYPE" == "darwin"* ]]; then
	# macOS
	DATE_CMD="/bin/date"
	DF_CMD="/bin/df"
	HOSTNAME_CMD="/bin/hostname"
else
	# Linux and others
	DATE_CMD="/usr/bin/date"
	DF_CMD="/usr/bin/df"
	HOSTNAME_CMD="/usr/bin/hostname"
fi

# Verify commands exist
for cmd in "$DATE_CMD" "$DF_CMD" "$HOSTNAME_CMD"; do
	if [ ! -x "$cmd" ]; then
		error "Command not found or not executable: $cmd"
		exit 1
	fi
done

# Log timestamp
echo "----------------------------" >>$LOGFILENAME
echo "$($DATE_CMD "+%Y-%m-%d %H:%M:%S")" >>$LOGFILENAME

info "Checking disk space (alert threshold: $ALERT%)..."
info "Hostname: $($HOSTNAME_CMD)"

# Check disk usage
alert_triggered=false
$DF_CMD -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 }' | while read -r output; do
	echo "$output" >>$LOGFILENAME
	usep=$(echo "$output" | awk '{ print $1}' | cut -d'%' -f1)
	partition=$(echo "$output" | awk '{ print $2 }')

	info "  $partition: $usep% used"

	# Skip devfs on macOS (always shows 100%)
	if [[ "$partition" == "devfs" ]]; then
		continue
	fi

	# Check if usep is a valid integer (handle macOS df output differences)
	if [[ "$usep" =~ ^[0-9]+$ ]] && [ $usep -ge $ALERT ]; then
		alert_triggered=true
		hostname_value="$($HOSTNAME_CMD)"
		current_date="$($DATE_CMD)"
		msg="Running out of space \"$partition ($usep%)\" on $hostname_value as on $current_date"
		echo "$msg" >>$LOGFILENAME
		alert "Disk space: $partition is at $usep% (threshold: $ALERT%)"
		info "Sending alert email..."
		$HOME/dotfiles/bin/send-ses.sh "Alert on $hostname_value: Almost out of disk space $usep% (ALERT AT $ALERT%)" "$msg"
		if [ $? -eq 0 ]; then
			info "Alert email sent successfully"
		else
			error "Failed to send alert email"
		fi
	fi
done

info "Disk space check completed"
