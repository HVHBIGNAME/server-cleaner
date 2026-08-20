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

# Очистка логов входов на сервер
sudo truncate -s 0 /var/log/wtmp
sudo truncate -s 0 /var/log/btmp
sudo truncate -s 0 /var/log/lastlog

# Очистка ротированных логов (если есть)
sudo truncate -s 0 /var/log/auth.log.* 2>/dev/null
sudo truncate -s 0 /var/log/syslog.* 2>/dev/null

# Очистка journald
sudo journalctl --rotate
sudo journalctl --vacuum-size=1M
sudo journalctl --rotate
sudo journalctl --vacuum-time=1s

# Очистка истории текущей сессии
history -c

echo "Logs and history cleaned successfully"
