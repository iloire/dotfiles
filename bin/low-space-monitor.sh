#!/bin/bash
# Purpose: Monitor disk space and send an email alert to $ADMIN_EMAIL

ALERT=92 # alert level
LOGFILENAME="$HOME/low-space-monitor.log"

if [ -z "$ADMIN_EMAIL" ]; then
	echo "ADMIN_EMAIL env variable not defined"
	exit 1
fi

# Detect OS and set command paths
if [[ "$OSTYPE" == "darwin"* ]]; then
	# macOS
	DATE_CMD="/bin/date"
	DF_CMD="/bin/df"
else
	# Linux and others
	DATE_CMD="/usr/bin/date"
	DF_CMD="/usr/bin/df"
fi

echo "----------------------------" >>$LOGFILENAME
echo "$($DATE_CMD "+%Y-%m-%d %H:%M:%S")" >>$LOGFILENAME

$DF_CMD -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 }' | while read -r output; do
	echo "$output" >>$LOGFILENAME
	usep=$(echo "$output" | awk '{ print $1}' | cut -d'%' -f1)
	partition=$(echo "$output" | awk '{ print $2 }')
	lockname=$(echo $partition | tr / _)
	# Check if usep is a valid integer (handle macOS df output differences)
	if [[ "$usep" =~ ^[0-9]+$ ]] && [ $usep -ge $ALERT ]; then
		msg="Running out of space \"$partition ($usep%)\" on $(hostname) as on $($DATE_CMD)"
		echo "$msg" >>$LOGFILENAME
		$HOME/dotfiles/bin/send-ses.sh "Alert on $(hostname): Almost out of disk space $usep% (ALERT AT $ALERT%)" "$msg"
	fi
done
