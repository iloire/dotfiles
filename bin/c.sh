#!/bin/bash

# VS Code launcher script with predefined folder mappings
# Usage: c.sh <folder_name>

if [ $# -eq 0 ]; then
    echo "Usage: c.sh <folder_name>"
    echo "Available folders:"
    echo "  dotfiles - Opens $HOME/dotfiles"
    echo "  hosts    - Opens /etc/hosts"
    exit 1
fi

case "$1" in
    "calma")
        code -n "$HOME/code/lacalmaeduca.com/www-site"
        ;;
    "dotfiles")
        code -n "$HOME/dotfiles"
        ;;
    "hosts")
        code -n "/etc/hosts"
        ;;
    *)
        echo "Unknown folder: $1"
        echo "Available folders:"
        echo "  dotfiles - Opens $HOME/dotfiles"
        echo "  hosts    - Opens /etc/hosts"
        exit 1
        ;;
esac