#!/bin/bash
[ -d \"$HOME/Downloads/\" ] && find \"$HOME/Downloads/\" -maxdepth 1 -mtime +4 -type f -delete
