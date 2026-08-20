#!/bin/bash

# === ИСТОРИЯ КОМАНД ===
# Bash
cat /dev/null > ~/.bash_history 2>/dev/null
if [ -n "$BASH_VERSION" ]; then
    history -c 2>/dev/null
    history -w 2>/dev/null
fi
sudo sh -c 'cat /dev/null > /root/.bash_history' 2>/dev/null
sudo sh -c 'history -c' 2>/dev/null

# Zsh
cat /dev/null > ~/.zsh_history 2>/dev/null
sudo sh -c 'cat /dev/null > /root/.zsh_history' 2>/dev/null

# Fish
rm -f ~/.local/share/fish/fish_history 2>/dev/null

# === СЛЕДЫ РЕДАКТОРОВ ===
rm -f ~/.viminfo 2>/dev/null
rm -f ~/.lesshst 2>/dev/null
rm -f ~/.nano_history 2>/dev/null
sudo rm -f /root/.viminfo 2>/dev/null
sudo rm -f /root/.lesshst 2>/dev/null

# === СИСТЕМНЫЕ ЛОГИ ===
sudo truncate -s 0 /var/log/auth.log 2>/dev/null
sudo truncate -s 0 /var/log/syslog 2>/dev/null
sudo truncate -s 0 /var/log/kern.log 2>/dev/null
sudo truncate -s 0 /var/log/dpkg.log 2>/dev/null
sudo truncate -s 0 /var/log/apt/history.log 2>/dev/null
sudo truncate -s 0 /var/log/apt/term.log 2>/dev/null
sudo truncate -s 0 /var/log/secure 2>/dev/null
sudo truncate -s 0 /var/log/messages 2>/dev/null

# Ротированные логи
sudo truncate -s 0 /var/log/auth.log.* 2>/dev/null
sudo truncate -s 0 /var/log/syslog.* 2>/dev/null

# === ЛОГИ ВХОДОВ ===
sudo truncate -s 0 /var/log/wtmp 2>/dev/null
sudo truncate -s 0 /var/log/btmp 2>/dev/null
sudo truncate -s 0 /var/log/lastlog 2>/dev/null

# === ЛОГИ СЕРВИСОВ ===
# Fail2ban
sudo truncate -s 0 /var/log/fail2ban.log 2>/dev/null

# Nginx
sudo truncate -s 0 /var/log/nginx/access.log 2>/dev/null
sudo truncate -s 0 /var/log/nginx/error.log 2>/dev/null

# Apache
sudo truncate -s 0 /var/log/apache2/access.log 2>/dev/null
sudo truncate -s 0 /var/log/apache2/error.log 2>/dev/null

# MySQL
sudo truncate -s 0 /var/log/mysql/error.log 2>/dev/null
sudo truncate -s 0 /var/log/mysql.log 2>/dev/null

# PostgreSQL
sudo truncate -s 0 /var/log/postgresql/*.log 2>/dev/null

# Redis
sudo truncate -s 0 /var/log/redis/*.log 2>/dev/null

# === DOCKER (только логи, без удаления образов) ===
if command -v docker &> /dev/null; then
    # Очистка логов контейнеров
    sudo sh -c 'truncate -s 0 /var/lib/docker/containers/*/*-json.log' 2>/dev/null
fi

# === AUDIT ЛОГИ ===
sudo truncate -s 0 /var/log/audit/audit.log 2>/dev/null
sudo service auditd restart 2>/dev/null

# === SYSTEMD JOURNAL ===
sudo journalctl --rotate 2>/dev/null
sudo journalctl --vacuum-size=1M 2>/dev/null
sudo journalctl --vacuum-time=1s 2>/dev/null

# === COREDUMPS ===
sudo rm -rf /var/lib/systemd/coredump/* 2>/dev/null

# === КЕШ ПАКЕТНЫХ МЕНЕДЖЕРОВ ===
# APT
sudo apt-get clean 2>/dev/null
sudo rm -rf /var/cache/apt/archives/* 2>/dev/null

# YUM/DNF
sudo yum clean all 2>/dev/null
sudo dnf clean all 2>/dev/null

# === ВРЕМЕННЫЕ ФАЙЛЫ ===
sudo rm -rf /tmp/* 2>/dev/null
sudo rm -rf /var/tmp/* 2>/dev/null
sudo rm -rf /var/cache/apt/*.bin 2>/dev/null

# === ОЧИСТКА ТЕКУЩЕЙ СЕССИИ ===
if [ -n "$BASH_VERSION" ]; then
    history -c 2>/dev/null
fi

exit 0
