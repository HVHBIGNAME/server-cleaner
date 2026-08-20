# Server Cleaner

Скрипт для очистки логов и истории команд на Linux серверах.

## ⚠️ Предупреждение

Этот скрипт удаляет:
- Историю команд bash (пользователя и root)
- Системные логи (auth.log, syslog, kern.log, dpkg.log)
- Логи входов на сервер (wtmp, btmp, lastlog)
- Журналы systemd (journald)

**Используйте только на своих серверах и под свою ответственность!**

## Запуск в одну строку (без сохранения скрипта)

```bash
curl -fsSL https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/clean.sh | sudo bash
```

или с wget:

```bash
wget -qO- https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/clean.sh | sudo bash
```

## Добавление в автозапуск (crontab)

Чтобы скрипт запускался автоматически каждый день в 00:00:

```bash
(crontab -l 2>/dev/null; echo "0 0 * * * curl -fsSL https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/clean.sh | sudo bash") | crontab -
```

Проверить установленные задачи cron:

```bash
crontab -l
```

Удалить задачу из crontab:

```bash
crontab -e
# Удалите строку с server-cleaner и сохраните
```

## Ручная установка

```bash
# Скачать скрипт
wget https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/clean.sh

# Дать права на выполнение
chmod +x clean.sh

# Запустить
sudo ./clean.sh
```

## Что очищает скрипт

### История команд
- `~/.bash_history` — история команд текущего пользователя
- `/root/.bash_history` — история команд root

### Системные логи
- `/var/log/auth.log` — логи аутентификации
- `/var/log/syslog` — основной системный лог
- `/var/log/kern.log` — логи ядра
- `/var/log/dpkg.log` — логи установки пакетов

### Логи входов
- `/var/log/wtmp` — история входов (команда `last`)
- `/var/log/btmp` — неудачные попытки входа (команда `lastb`)
- `/var/log/lastlog` — последний вход каждого пользователя (команда `lastlog`)

### Journald
- Ротация и очистка журналов systemd

## Лицензия

MIT
