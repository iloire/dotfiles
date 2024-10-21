#!/bin/bash
[ -d "$HOME/Downloads/" ] && find "$HOME/Downloads/" -maxdepth 1 -mtime +4 -type f -delete
[ -d "$HOME/Downloads/installers" ] && find "$HOME/Downloads/installers" -maxdepth 1 -mtime +4 -type f -delete
[ -d "$HOME/Downloads/images" ] && find "$HOME/Downloads/images" -maxdepth 1 -mtime +10 -type f -delete
[ -d "$HOME/Downloads/torrents" ] && find "$HOME/Downloads/torrents" -maxdepth 1 -mtime +10 -type f -delete
[ -d "$HOME/Downloads/archives" ] && find "$HOME/Downloads/archives" -maxdepth 2 -mtime +10 -type f -delete
[ -d "$HOME/Downloads/archives" ] && find "$HOME/Downloads/archives" -maxdepth 2 -mtime +10 -type d -exec rm -r {} \;
