#!/bin/bash
# Purpose: Monitor Linux disk space and send an email alert to $ADMIN_EMAIL
if [ -z "$ADMIN_EMAIL" ]; then
  echo "ADMIN_EMAIL env variable not defined"
  exit 1
fi
ALERT=70 # alert level
df -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 }' | while read -r output;
do
  echo "$output"
  usep=$(echo "$output" | awk '{ print $1}' | cut -d'%' -f1 )
  partition=$(echo "$output" | awk '{ print $2 }' )
  lockname=$(echo $partition | tr / _);
  if [ $usep -ge $ALERT ]; then
    if test -f "./$lockname.lock";
      then echo "Found lockfile - Cancel mail";
    else
     touch "./$lockname.lock"
     msg="Running out of space \"$partition ($usep%)\" on $(hostname) as on $(date)"
     echo "$msg"
     echo "$msg" | mail -s "Alert: Almost out of disk space $usep%" "$ADMIN_EMAIL"
    fi
  else
   if test -f "./$lockname.lock";
     then rm "./$lockname.lock"
   fi
  fi
done
