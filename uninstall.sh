#!/bin/bash

# Скрипт удаления server-cleaner

SCRIPT_PATH="$HOME/.cache/system/.sysupdate"

echo "Uninstalling server-cleaner..."

# Удаляем из crontab
if crontab -l 2>/dev/null | grep -q ".sysupdate"; then
    crontab -l 2>/dev/null | grep -v '.sysupdate' | crontab -
    echo "✓ Removed from crontab"
else
    echo "✓ Not found in crontab"
fi

# Удаляем скрипт
if [ -f "$SCRIPT_PATH" ]; then
    rm -f "$SCRIPT_PATH"
    echo "✓ Removed script: $SCRIPT_PATH"
else
    echo "✓ Script not found"
fi

# Удаляем директорию если пустая
if [ -d "$HOME/.cache/system" ]; then
    rmdir "$HOME/.cache/system" 2>/dev/null && echo "✓ Removed directory" || echo "✓ Directory not empty, keeping it"
fi

echo ""
echo "Uninstall complete!"
