#!/bin/bash

# Paths to the files
HOSTS_FILE="/etc/hosts"
BLACKLIST_FILE="$HOME/myconfig/hosts-google-blacklist.txt"
TEMP_FILE="/tmp/hosts_filtered"

# Ensure the blacklist file exists
if [[ ! -f "$BLACKLIST_FILE" ]]; then
	echo "Blacklist file not found: $BLACKLIST_FILE"
	exit 1
fi

# Function to remove blacklisted entries
remove_blacklisted_entries() {
	# Create a temporary file to store the filtered hosts
	>"$TEMP_FILE"

	# Use grep to filter out lines present in the blacklist
	grep -v -F -x -f "$BLACKLIST_FILE" "$HOSTS_FILE" >"$TEMP_FILE"

	# Replace the original hosts file with the filtered content
	mv "$TEMP_FILE" "$HOSTS_FILE"

	echo "Blacklisted entries removed from hosts file successfully."
}

# Function to add blacklisted entries
add_blacklisted_entries() {
	# Append the blacklist entries to the hosts file
	cat "$BLACKLIST_FILE" >>"$HOSTS_FILE"

	echo "Blacklisted entries added to hosts file successfully."
}

# Check the parameter passed to the script
case "$1" in
"whitelist")
	remove_blacklisted_entries
	;;
"blacklist")
	add_blacklisted_entries
	;;
*)
	echo "Invalid parameter. Use 'whitelist' to remove entries or 'blacklist' to add entries."
	exit 1
	;;
esac
