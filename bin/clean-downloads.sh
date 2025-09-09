#!/bin/bash

# Detect OS and set command paths
if [[ "$OSTYPE" == "darwin"* ]]; then
	# macOS
	FIND_CMD="/usr/bin/find"
	RM_CMD="/bin/rm"
else
	# Linux and others
	FIND_CMD="/usr/bin/find"
	RM_CMD="/bin/rm"
fi

[ -d "$HOME/Downloads/" ] && $FIND_CMD "$HOME/Downloads/" -maxdepth 1 -mtime +4 -type f -delete
[ -d "$HOME/Downloads/installers" ] && $FIND_CMD "$HOME/Downloads/installers" -maxdepth 1 -mtime +4 -type f -delete
[ -d "$HOME/Downloads/images" ] && $FIND_CMD "$HOME/Downloads/images" -maxdepth 1 -mtime +10 -type f -delete
[ -d "$HOME/Downloads/torrents" ] && $FIND_CMD "$HOME/Downloads/torrents" -maxdepth 1 -mtime +10 -type f -delete

#archives
[ -d "$HOME/Downloads/archives" ] && $FIND_CMD "$HOME/Downloads/archives" -maxdepth 2 -mtime +10 -type f -delete
[ -d "$HOME/Downloads/archives" ] && $FIND_CMD "$HOME/Downloads/archives" -maxdepth 2 -mtime +2 -type f -name "*.zip" -delete
[ -d "$HOME/Downloads/archives" ] && $FIND_CMD "$HOME/Downloads/archives" -maxdepth 2 -mtime +10 -type d -exec $RM_CMD -r {} \;
