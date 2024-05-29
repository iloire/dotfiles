#!/bin/bash
# Purpose: Monitor Linux disk space and send an email alert to $ADMIN_EMAIL

ALERT=92 # alert level
LOGFILENAME="$HOME/low-space-monitor.log"

if [ -z "$ADMIN_EMAIL" ]; then
	echo "ADMIN_EMAIL env variable not defined"
	exit 1
fi

echo "----------------------------" >>$LOGFILENAME
echo "$(date "+%Y-%m-%d %H:%M:%S")" >>$LOGFILENAME

df -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 }' | while read -r output; do
	echo "$output" >>$LOGFILENAME
	usep=$(echo "$output" | awk '{ print $1}' | cut -d'%' -f1)
	partition=$(echo "$output" | awk '{ print $2 }')
	lockname=$(echo $partition | tr / _)
	if [ $usep -ge $ALERT ]; then
		msg="Running out of space \"$partition ($usep%)\" on $(hostname) as on $(date)"
		echo "$msg" >>$LOGFILENAME
		$HOME/dotfiles/bin/send-ses.sh "Alert on $(hostname): Almost out of disk space $usep% (ALERT AT $ALERT%)" "$msg"
	fi
done
