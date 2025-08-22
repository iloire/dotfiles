#!/bin/bash

# VS Code launcher script with predefined folder mappings
# Usage: c.sh <folder_name>

# Command definitions: "command:description:path"
declare -a COMMANDS=(
    "calma:Opens lacalmaeduca.com project:$HOME/code/lacalmaeduca.com/www-site"
    "dotfiles:Opens dotfiles directory:$HOME/dotfiles"
    "hosts:Opens hosts file:/etc/hosts"
)

show_help() {
    echo "Usage: c.sh <folder_name>"
    echo "Available folders:"
    for cmd in "${COMMANDS[@]}"; do
        IFS=':' read -r name desc path <<< "$cmd"
        printf "  %-10s - %s\n" "$name" "$desc"
    done
}

if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# Find and execute command
found=false
for cmd in "${COMMANDS[@]}"; do
    IFS=':' read -r name desc path <<< "$cmd"
    if [ "$1" = "$name" ]; then
        code -n "$path"
        found=true
        break
    fi
done

if [ "$found" = false ]; then
    echo "Unknown folder: $1"
    echo
    show_help
    exit 1
fi