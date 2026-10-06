#!/bin/sh
# server-cleaner:managed:clean
# SPDX-License-Identifier: MIT

SC_VERSION=2.0.0

text() {
    text_key=$1
    shift
    case "$LANGUAGE:$text_key" in
        ru:preview) text_format='Предварительный просмотр: изменений нет.' ;;
        *:preview) text_format='Preview: no changes are made.' ;;
        ru:apply) text_format='Выполнение выбранных действий.' ;;
        *:apply) text_format='Running the selected tasks.' ;;
        ru:confirm) text_format='Выполнить этот план? [y/N]: ' ;;
        *:confirm) text_format='Apply this plan? [y/N]: ' ;;
        ru:cancelled) text_format='Отменено.' ;;
        *:cancelled) text_format='Cancelled.' ;;
        ru:tty) text_format='Для подтверждения без терминала укажите --yes.' ;;
        *:tty) text_format='Non-interactive confirmation requires --yes.' ;;
        ru:confirm_uninstall) text_format='Удалить Server Cleaner и его автозапуск? [y/N]: ' ;;
        *:confirm_uninstall) text_format='Uninstall Server Cleaner and its autostart job? [y/N]: ' ;;
        ru:confirm_migrate) text_format='Удалить старую установку v1 и её задачу cron? [y/N]: ' ;;
        *:confirm_migrate) text_format='Remove the old v1 installation and its cron job? [y/N]: ' ;;
        ru:unknown) text_format='Неизвестный аргумент: %s. См. --help.' ;;
        *:unknown) text_format='Unknown argument: %s. See --help.' ;;
        ru:value) text_format='Недопустимое или отсутствующее значение %s.' ;;
        *:value) text_format='Invalid or missing value for %s.' ;;
        ru:unsupported) text_format='Система %s не поддерживается. Используйте Linux, macOS или BSD; в Windows — WSL.' ;;
        *:unsupported) text_format='Unsupported system: %s. Use Linux, macOS or BSD; on Windows use WSL.' ;;
        ru:missing) text_format='Недоступен инструмент: %s.' ;;
        *:missing) text_format='Tool unavailable: %s.' ;;
        ru:root) text_format='Нужны права root. Запустите выбранное действие через sudo.' ;;
        *:root) text_format='Root required. Run the selected task with sudo.' ;;
        ru:root_hint) text_format=' [нужен root]' ;;
        *:root_hint) text_format=' [root required]' ;;
        ru:packages) text_format='Кеш пакетов: %s (установленные пакеты сохраняются).' ;;
        *:packages) text_format='Package cache: %s (installed packages are kept).' ;;
        ru:no_packages) text_format='Поддерживаемый очиститель кеша пакетов не найден.' ;;
        *:no_packages) text_format='No supported package-cache cleaner found.' ;;
        ru:brew_root) text_format='Homebrew нужно запускать от обычного пользователя.' ;;
        *:brew_root) text_format='Run Homebrew as a regular user.' ;;
        ru:journal) text_format='Архивные журналы systemd старше %s дней.' ;;
        *:journal) text_format='Archived systemd journals older than %s days.' ;;
        ru:temp) text_format='Временные файлы по возрастным правилам systemd-tmpfiles.' ;;
        *:temp) text_format='Temporary files according to systemd-tmpfiles age policies.' ;;
        ru:coredumps) text_format='Дампы по возрастным правилам systemd-tmpfiles.' ;;
        *:coredumps) text_format='Core dumps according to systemd-tmpfiles age policies.' ;;
        ru:logs) text_format='Плановая ротация по конфигурации %s.' ;;
        *:logs) text_format='Scheduled log rotation according to %s configuration.' ;;
        ru:no_logs) text_format='Штатный инструмент или конфигурация ротации не найдены.' ;;
        *:no_logs) text_format='Native log rotation tool or configuration unavailable.' ;;
        ru:docker) text_format='Неиспользуемый кеш сборки локального Docker старше %s дней.' ;;
        *:docker) text_format='Unused local Docker build cache older than %s days.' ;;
        ru:docker_context) text_format='Не удалось определить локальный Docker endpoint.' ;;
        *:docker_context) text_format='Could not determine the local Docker endpoint.' ;;
        ru:docker_remote) text_format='Удалённый Docker endpoint пропущен: %s.' ;;
        *:docker_remote) text_format='Remote Docker endpoint skipped: %s.' ;;
        ru:history) text_format='Сохранённые файлы истории текущего пользователя; история открытых оболочек остаётся в памяти.' ;;
        *:history) text_format='Saved history files of the current user; open shells keep their in-memory history.' ;;
        ru:no_history) text_format='Сохранённых файлов истории не найдено.' ;;
        *:no_history) text_format='No saved history files found.' ;;
        ru:unsafe_home) text_format='HOME должен быть собственным приватным каталогом текущего пользователя.' ;;
        *:unsafe_home) text_format='HOME must be a private directory owned by the current user.' ;;
        ru:unsafe_path) text_format='Небезопасный путь (ссылка, чужой владелец или общий доступ): %s.' ;;
        *:unsafe_path) text_format='Unsafe path (link, different owner or shared write access): %s.' ;;
        ru:failed) text_format='Команда завершилась с кодом %s.' ;;
        *:failed) text_format='Command exited with status %s.' ;;
        ru:lock) text_format='Не удалось получить блокировку: %s. Проверьте другой запуск и права; для устаревшей блокировки сначала проверьте PID.' ;;
        *:lock) text_format='Cannot acquire lock: %s. Check other runs and permissions; verify the PID before removing a stale lock.' ;;
        ru:state) text_format='Не удалось создать приватный каталог состояния: %s.' ;;
        *:state) text_format='Cannot create a private state directory: %s.' ;;
        ru:summary) text_format='Готово: %s | План: %s | Пропущено: %s | Ошибки: %s' ;;
        *:summary) text_format='Completed: %s | Planned: %s | Skipped: %s | Failed: %s' ;;
        ru:before) text_format='Диск / до   ' ;;
        *:before) text_format='Disk / before' ;;
        ru:after) text_format='Диск / после' ;;
        *:after) text_format='Disk / after ' ;;
        ru:delta) text_format='Изменение доступного места на /: %s KiB (включая активность других процессов).' ;;
        *:delta) text_format='Available-space change on /: %s KiB (includes other processes).' ;;
        ru:menu) text_format='  1  Посмотреть план (по умолчанию)\n  2  Выполнить стандартную очистку\n  3  Показать все действия\n  0  Выйти\n\nВыбор [1]: ' ;;
        *:menu) text_format='  1  Preview the plan (default)\n  2  Run standard maintenance\n  3  Show all tasks\n  0  Exit\n\nChoice [1]: ' ;;
        *) text_format='%s' ;;
    esac
    # All format strings are defined above; arguments are never evaluated as code.
    printf "$text_format" "$@"
}

fail() {
    printf 'server-cleaner: %s\n' "$1" >&2
    exit "${2:-1}"
}

usage() {
    if [ "$LANGUAGE" = ru ]; then
        cat <<'EOF'
Server Cleaner — обслуживание Linux, macOS и BSD

Использование: server-cleaner [ПАРАМЕТРЫ]

Очистка:
  --dry-run          Только показать план (по умолчанию)
  --apply            Выполнить выбранные действия после подтверждения
  -y, --yes          Подтверждать выбранные действия без вопроса
  --only СПИСОК      Действия через запятую, например packages,journal
  --keep-days N      Срок хранения journal / Docker / Homebrew (1..3650; 14)
  --list             Показать все действия и доступность инструментов
  --json             JSON-отчёт очистки; сообщения команд в stderr

Установка и автоматизация:
  --install          Установить или обновить единственную команду server-cleaner
  --update           Обновить текущую установку (синоним --install)
  --uninstall        Удалить программу и её автозапуск
  --autostart РЕЖИМ  daily | weekly | boot | off | status
  --at ЧЧ:ММ         Время daily / weekly (по умолчанию 03:17; weekly — воскресенье)
  --prefix КАТАЛОГ   Префикс установки (по умолчанию ~/.local или /usr/local для root)
  --system           Префикс /usr/local; нужны права root
  --from КАТАЛОГ     Установка из локальных clean.sh + SHA256SUMS
  --ref REF          Git commit / tag / branch для скачивания (по умолчанию main)
  --migrate-legacy   При --install удалить распознанную установку v1
  --agents           Показать установленные гостевые / облачные пакеты (только чтение)

Общие:
  -q, --quiet        Убрать обычный интерфейс; ошибки остаются видимыми
  --no-color         Отключить ANSI-цвета (также поддерживается NO_COLOR)
  --lang ru|en       Язык интерфейса (по умолчанию — язык окружения)
  -h, --help         Эта справка
  --version          Версия

Стандартные: packages, journal, temp, logs, coredumps.
Только по запросу: docker (кеш сборки), history (сохранённая история своего пользователя).
Временные файлы и дампы очищаются по правилам ОС, логи — по конфигурации ротации.
Автозапуск использует cron и сохраняет --only, --keep-days, --lang и --quiet.
--install можно совместить с --autostart и --apply; без --apply очистка сразу не запускается.

Пример: server-cleaner --autostart daily --at 04:00 --only packages,journal --keep-days 30
EOF
    else
        cat <<'EOF'
Server Cleaner — Linux, macOS and BSD maintenance

Usage: server-cleaner [OPTIONS]

Cleanup:
  --dry-run          Preview only (default)
  --apply            Execute selected tasks after confirmation
  -y, --yes          Confirm requested actions without a prompt
  --only LIST        Comma-separated tasks, e.g. packages,journal
  --keep-days N      Journal / Docker / Homebrew retention (1..3650; default 14)
  --list             Show all tasks and tool availability
  --json             Cleanup report as JSON; native command output on stderr

Installation and automation:
  --install          Install or update the single server-cleaner command
  --update           Update the current installation (alias for --install)
  --uninstall        Remove the program and its autostart job
  --autostart MODE   daily | weekly | boot | off | status
  --at HH:MM         Time for daily / weekly (default 03:17; weekly runs on Sunday)
  --prefix DIR       Install prefix (default ~/.local, or /usr/local for root)
  --system           Use /usr/local; requires root
  --from DIR         Offline installation from clean.sh + SHA256SUMS
  --ref REF          Git commit / tag / branch to download (default main)
  --migrate-legacy   With --install, remove a recognized v1 installation
  --agents           Read-only guest / cloud package inventory

General:
  -q, --quiet        Hide the regular UI; errors remain visible
  --no-color         Disable ANSI colors (also honors NO_COLOR)
  --lang ru|en       UI language (default: environment locale)
  -h, --help         This help
  --version          Version

Default: packages, journal, temp, logs, coredumps.
Opt-in: docker (build cache), history (your own saved history files).
Temporary files / core dumps follow OS age policies; logs follow rotation config.
Autostart uses cron and preserves --only, --keep-days, --lang and --quiet.
Combine --install with --autostart and --apply; cleanup only runs now with --apply.

Example: server-cleaner --autostart daily --at 04:00 --only packages,journal --keep-days 30
EOF
    fi
}

has() { command -v "$1" >/dev/null 2>&1; }

json_string() {
    SC_JSON_VALUE=$1 awk 'BEGIN {
        s = ENVIRON["SC_JSON_VALUE"];
        printf "\"";
        for (i = 1; i <= length(s); i++) {
            c = substr(s, i, 1);
            if (c == "\\") printf "\\\\";
            else if (c == "\"") printf "\\\"";
            else if (c == "\n") printf "\\n";
            else if (c == "\r") printf "\\r";
            else if (c == "\t") printf "\\t";
            else {
                control = 0;
                for (j = 1; j < 32; j++) {
                    if (c == sprintf("%c", j)) { printf "\\u%04x", j; control = 1; break; }
                }
                if (!control) printf "%s", c;
            }
        }
        printf "\"";
    }'
}

json_args() {
    printf '['
    arg_separator=''
    for arg do
        printf '%s' "$arg_separator"
        json_string "$arg"
        arg_separator=,
    done
    printf ']'
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case $1 in
            --dry-run) MODE=preview; EXPLICIT_PREVIEW=1 ;;
            --apply) MODE=apply ;;
            -y|--yes) YES=1 ;;
            --json) JSON=1 ;;
            -q|--quiet|--silent) QUIET=1 ;;
            --no-color) COLOR=0 ;;
            --list) LIST=1 ;;
            --only)
                TASK_OPTIONS=1
                [ "$#" -ge 2 ] || fail "$(text value --only)" 2
                case $2 in ''|,*|*,|*,,*|*[!a-z,]*) fail "$(text value --only)" 2 ;; esac
                TASKS=$(printf '%s' "$2" | tr ',' ' ')
                for selected_task in $TASKS; do
                    case $selected_task in
                        packages|journal|temp|logs|coredumps|docker|history) ;;
                        *) fail "$(text value --only)" 2 ;;
                    esac
                done
                TASKS=$(printf '%s\n' "$TASKS" | awk '{ for (i=1;i<=NF;i++) if (!seen[$i]++) printf "%s ", $i }')
                shift
                ;;
            --keep-days)
                TASK_OPTIONS=1
                [ "$#" -ge 2 ] || fail "$(text value --keep-days)" 2
                case $2 in ''|0*|*[!0-9]*) fail "$(text value --keep-days)" 2 ;; esac
                [ "${#2}" -le 4 ] && [ "$2" -le 3650 ] || fail "$(text value --keep-days)" 2
                KEEP_DAYS=$2
                shift
                ;;
            --lang)
                [ "$#" -ge 2 ] || fail "$(text value --lang)" 2
                case $2 in ru|en) LANGUAGE=$2 ;; *) fail "$(text value --lang)" 2 ;; esac
                shift
                ;;
            --install|--update) set_action install ;;
            --uninstall) set_action uninstall ;;
            --agents) set_action agents ;;
            --system) PREFIX=/usr/local; SYSTEM_PREFIX=1; PREFIX_SET=1 ;;
            --migrate-legacy) MIGRATE=1 ;;
            --prefix|--from|--ref|--autostart|--at)
                [ "$#" -ge 2 ] && [ -n "$2" ] || fail "$(text value "$1")" 2
                case $1 in
                    --prefix) PREFIX=$2; PREFIX_SET=1 ;;
                    --from) SOURCE_DIR=$2 ;;
                    --ref) REF=$2; REF_SET=1 ;;
                    --autostart)
                        case $2 in daily|weekly|boot|off|status) AUTOSTART=$2 ;; *) fail "$(text value --autostart)" 2 ;; esac
                        ;;
                    --at)
                        case $2 in [0-2][0-9]:[0-5][0-9]) ;; *) fail "$(text value --at)" 2 ;; esac
                        [ "${2%:*}" -le 23 ] || fail "$(text value --at)" 2
                        SCHEDULE_TIME=$2; TIME_SET=1
                        ;;
                esac
                shift
                ;;
            --version) printf '%s\n' "$SC_VERSION"; exit 0 ;;
            -h|--help) usage; exit 0 ;;
            *) fail "$(text unknown "$1")" 2 ;;
        esac
        shift
    done
    if [ "$LIST" -eq 1 ]; then
        [ "$MODE" != apply ] || fail "$(text value '--list + --apply')" 2
        MODE=capabilities
        TASKS="$DEFAULT_TASKS docker history"
    fi
    validate_flags
}

set_action() {
    [ "$ACTION" = clean ] || [ "$ACTION" = "$1" ] || fail "$(text value 'conflicting actions')" 2
    ACTION=$1
}

validate_flags() {
    if [ "$ACTION" != clean ] || [ -n "$AUTOSTART" ]; then
        [ "$JSON" -eq 0 ] && [ "$LIST" -eq 0 ] && [ "$EXPLICIT_PREVIEW" -eq 0 ] ||
            fail "$(text value '--json/--list/--dry-run are cleanup options')" 2
    fi
    if [ "$ACTION" != install ]; then
        [ -z "$SOURCE_DIR" ] && [ "$REF_SET" -eq 0 ] && [ "$MIGRATE" -eq 0 ] || fail "$(text value '--from/--ref/--migrate-legacy require --install')" 2
    fi
    case $ACTION in
        uninstall|agents)
            [ -z "$AUTOSTART" ] && [ "$MODE" != apply ] && [ "$TASK_OPTIONS" -eq 0 ] || fail "$(text value 'conflicting actions')" 2
            ;;
    esac
    if [ "$ACTION" = agents ] && [ "$PREFIX_SET" -eq 1 ]; then fail "$(text value '--prefix/--system are installation options')" 2; fi
    if [ "$TIME_SET" -eq 1 ]; then
        case $AUTOSTART in daily|weekly) ;; *) fail "$(text value '--at requires daily or weekly')" 2 ;; esac
    fi
    case $AUTOSTART in
        off|status) [ "$TASK_OPTIONS" -eq 0 ] && [ "$MODE" != apply ] || fail "$(text value 'off/status do not run cleanup')" 2 ;;
    esac
    if [ "$ACTION" = install ] && [ "$TASK_OPTIONS" -eq 1 ] && [ -z "$AUTOSTART" ] && [ "$MODE" != apply ]; then
        fail "$(text value 'cleanup parameters require --apply or --autostart')" 2
    fi
    if [ "$PREFIX_SET" -eq 1 ] && [ "$ACTION" = clean ] && [ -z "$AUTOSTART" ]; then
        fail "$(text value '--prefix/--system require a management action')" 2
    fi
}

detect_platform() {
    OS=$(uname -s) || fail 'uname failed.'
    case $OS in Linux|Darwin|FreeBSD|OpenBSD|NetBSD) ;; *) fail "$(text unsupported "$OS")" 3 ;; esac
    USER_ID=$(id -u) || fail 'id failed.'
    PM=none
    case $OS in
        Darwin) has brew && PM=brew ;;
        FreeBSD) has pkg && PM=pkg ;;
        Linux)
            for candidate in apt-get dnf5 dnf microdnf yum zypper paccache pacman apk xbps-remove eclean-pkg eopkg; do
                if has "$candidate"; then PM=$candidate; break; fi
            done
            ;;
    esac
    TMPFILES=''
    for candidate in systemd-tmpfiles systemd-tmpfiles.standalone; do
        if has "$candidate"; then TMPFILES=$candidate; break; fi
    done
    return 0
}

private_path() {
    [ ! -L "$1" ] && [ -e "$1" ] || return 1
    path_meta=$(stat -c '%u %a' "$1" 2>/dev/null) || path_meta=$(stat -f '%u %Lp' "$1" 2>/dev/null) || return 1
    path_owner=${path_meta%% *}
    path_mode=${path_meta#* }
    [ "$path_owner" = "$USER_ID" ] || return 1
    case $path_mode in ''|*[!0-7]*) return 1 ;; esac
    [ "$((0$path_mode & 0022))" -eq 0 ]
}

resolve_home() {
    case ${HOME:-} in /*) ;; *) return 1 ;; esac
    HOME_REAL=$(CDPATH='' cd -P "$HOME" 2>/dev/null && pwd -P) || return 1
    [ "$HOME_REAL" != / ] && private_path "$HOME_REAL" && [ -d "$HOME_REAL" ]
}

acquire_lock() {
    resolve_home || fail "$(text unsafe_home)"
    STATE_BASE=${XDG_STATE_HOME:-$HOME_REAL/.local/state}
    case $STATE_BASE in /*) ;; *) fail "$(text state "$STATE_BASE")" ;; esac
    STATE_DIR=$STATE_BASE/server-cleaner
    [ ! -L "$STATE_DIR" ] || fail "$(text unsafe_path "$STATE_DIR")"
    (umask 077; mkdir -p "$STATE_DIR") || fail "$(text state "$STATE_DIR")"
    private_path "$STATE_DIR" || fail "$(text unsafe_path "$STATE_DIR")"
    LOCK_DIR=$STATE_DIR/lock
    (umask 077; mkdir "$LOCK_DIR") 2>/dev/null || fail "$(text lock "$LOCK_DIR")" 75
    LOCK_HELD=1
    trap 'release_lock' 0
    trap 'exit 130' INT
    trap 'exit 143' TERM
    trap 'exit 129' HUP
    printf '%s\n' "$$" > "$LOCK_DIR/pid" || fail "$(text lock "$LOCK_DIR")"
}

release_lock() {
    if [ "$LOCK_HELD" -eq 1 ]; then
        rm -f "$LOCK_DIR/pid" && rmdir "$LOCK_DIR"
        LOCK_HELD=0
    fi
}

reset_results() {
    RESULTS=''
    RESULT_SEPARATOR=''
    COMPLETED=0
    PLANNED=0
    SKIPPED=0
    FAILED=0
}

record() {
    result_task=$1 result_status=$2 result_detail=$3 result_root=$4 result_command=$5
    case $result_status in
        completed) COMPLETED=$((COMPLETED + 1)) ;;
        planned) PLANNED=$((PLANNED + 1)) ;;
        skipped) SKIPPED=$((SKIPPED + 1)) ;;
        failed) FAILED=$((FAILED + 1)) ;;
    esac
    RESULTS="$RESULTS$RESULT_SEPARATOR{\"id\":$(json_string "$result_task"),\"status\":$(json_string "$result_status"),\"detail\":$(json_string "$result_detail"),\"requires_root\":$result_root,\"command\":$result_command}"
    RESULT_SEPARATOR=,
    if [ "$JSON" -eq 0 ] && [ "$QUIET" -eq 0 ]; then
        printf '  %s%-9s%s %-10s %s\n' "$ACCENT" "$result_status" "$RESET" "$result_task" "$result_detail"
        if [ "$result_status" = planned ]; then printf '              %s\n' "$result_command"; fi
    elif [ "$result_status" = failed ]; then
        printf '%s: %s\n' "$result_task" "$result_detail" >&2
    fi
}

skip() { record "$1" skipped "$2" false '[]'; }

perform() {
    action_task=$1 action_root=$2 action_description=$3
    shift 3
    action_command=$(json_args "$@")
    if [ "$MODE" = apply ] && [ "$action_root" = true ] && [ "$USER_ID" -ne 0 ]; then
        record "$action_task" failed "$(text root)" true "$action_command"
    elif [ "$RUN_MODE" != apply ]; then
        if [ "$action_root" = true ] && [ "$USER_ID" -ne 0 ]; then
            action_description="$action_description$(text root_hint)"
        fi
        record "$action_task" planned "$action_description" "$action_root" "$action_command"
    elif "$@" </dev/null >&2; then
        record "$action_task" completed "$action_description" "$action_root" "$action_command"
    else
        action_status=$?
        record "$action_task" failed "$(text failed "$action_status")" "$action_root" "$action_command"
    fi
}

task_packages() {
    package_description=$(text packages "$PM")
    case $PM in
        apt-get) perform packages true "$package_description" apt-get clean ;;
        dnf5|dnf|yum) perform packages true "$package_description" "$PM" clean packages ;;
        microdnf) perform packages true "$package_description" microdnf clean all ;;
        zypper) perform packages true "$package_description" zypper --non-interactive clean ;;
        paccache) perform packages true "$package_description" paccache -r -k 2 ;;
        pacman) perform packages true "$package_description" pacman --sync --clean --noconfirm ;;
        apk) perform packages true "$package_description" apk cache clean ;;
        xbps-remove) perform packages true "$package_description" xbps-remove -O ;;
        eclean-pkg) perform packages true "$package_description" eclean-pkg ;;
        eopkg) perform packages true "$package_description" eopkg delete-cache ;;
        pkg) perform packages true "$package_description" pkg clean -y ;;
        brew)
            if [ "$USER_ID" -eq 0 ]; then
                skip packages "$(text brew_root)"
            else
                perform packages false "$package_description" env HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1 brew cleanup "--prune=$KEEP_DAYS"
            fi
            ;;
        *) skip packages "$(text no_packages)" ;;
    esac
}

task_journal() {
    if has journalctl; then
        perform journal true "$(text journal "$KEEP_DAYS")" journalctl "--vacuum-time=${KEEP_DAYS}d"
    else
        skip journal "$(text missing journalctl)"
    fi
}

task_tmpfiles() {
    if [ -z "$TMPFILES" ]; then
        skip "$1" "$(text missing systemd-tmpfiles)"
    elif [ "$1" = temp ]; then
        perform temp true "$(text temp)" "$TMPFILES" --clean --prefix=/tmp --prefix=/var/tmp
    else
        perform coredumps true "$(text coredumps)" "$TMPFILES" --clean --prefix=/var/lib/systemd/coredump
    fi
}

task_logs() {
    if has logrotate && [ -f /etc/logrotate.conf ]; then
        perform logs true "$(text logs logrotate)" logrotate /etc/logrotate.conf
    elif has newsyslog; then
        perform logs true "$(text logs newsyslog)" newsyslog
    else
        skip logs "$(text no_logs)"
    fi
}

task_docker() {
    if ! has docker; then skip docker "$(text missing docker)"; return; fi
    if [ -n "${DOCKER_CONTEXT:-}" ] || [ -z "${DOCKER_HOST:-}" ]; then
        docker_endpoint=$(docker context inspect --format '{{.Endpoints.docker.Host}}' 2>/dev/null) || {
            record docker failed "$(text docker_context)" false '[]'
            return
        }
    else
        docker_endpoint=$DOCKER_HOST
    fi
    case $docker_endpoint in
        unix:///*) perform docker false "$(text docker "$KEEP_DAYS")" docker builder prune --force --filter "until=$((KEEP_DAYS * 24))h" ;;
        *) skip docker "$(text docker_remote "$docker_endpoint")" ;;
    esac
}

task_history() {
    if ! resolve_home; then
        record history failed "$(text unsafe_home)" false '[]'
        return
    fi
    set --
    for history_relative in .bash_history .zsh_history .local/share/fish/fish_history .viminfo .lesshst .nano_history; do
        history_file=$HOME_REAL/$history_relative
        if [ ! -e "$history_file" ] && [ ! -L "$history_file" ]; then continue; fi
        history_parent=$history_file
        while [ "$history_parent" != "$HOME_REAL" ]; do
            if ! private_path "$history_parent"; then
                record history failed "$(text unsafe_path "$history_parent")" false '[]'
                return
            fi
            history_parent=${history_parent%/*}
        done
        if [ ! -f "$history_file" ]; then
            record history failed "$(text unsafe_path "$history_file")" false '[]'
            return
        fi
        set -- "$@" "$history_file"
    done
    if [ "$#" -eq 0 ]; then
        skip history "$(text no_history)"
    else
        perform history false "$(text history)" rm -f "$@"
    fi
}

run_tasks() {
    for task_id in $TASKS; do
        case $task_id in
            packages) task_packages ;;
            journal) task_journal ;;
            temp|coredumps) task_tmpfiles "$task_id" ;;
            logs) task_logs ;;
            docker) task_docker ;;
            history) task_history ;;
        esac
    done
}

disk_snapshot() {
    snapshot=$(df -Pk / 2>/dev/null | awk 'NR > 1 && $2 ~ /^[0-9]+$/ && $3 ~ /^[0-9]+$/ && $4 ~ /^-?[0-9]+$/ {
        printf "{\"size_kib\":%.0f,\"used_kib\":%.0f,\"available_kib\":%.0f}", $2, $3, $4; exit
    }')
    printf '%s' "${snapshot:-null}"
}

disk_bar() {
    printf '%s' "$2" | awk -v label="$1" -F '[:,}]' '
        /size_kib/ {
            total=$2; used=$4; available=$6;
            percent=(used+available > 0) ? int(100*used/(used+available)) : 0;
            if (percent < 0) percent=0; if (percent > 100) percent=100;
            bar=""; for (i=0;i<20;i++) bar=bar ((i < int(percent/5)) ? "#" : "-");
            printf "  %s [%s] %3d%% | %.2f GiB available\n", label, bar, percent, available/1048576;
        }'
}

report() {
    DISK_DELTA=null
    if [ "$MODE" = apply ] && [ "$DISK_BEFORE" != null ] && [ "$DISK_AFTER" != null ]; then
        DISK_DELTA=$(printf '%s\n%s\n' "$DISK_BEFORE" "$DISK_AFTER" | awk -F '[:,}]' 'NR==1 {before=$6} NR==2 {printf "%.0f", $6-before}')
    fi
    if [ "$JSON" -eq 1 ]; then
        printf '{"schema_version":1,"version":"%s","mode":"%s","platform":%s,"package_manager":%s,"keep_days":%s,"tasks":[%s],"summary":{"completed":%s,"planned":%s,"skipped":%s,"failed":%s},"disk":{"path":"/","before":%s,"after":%s,"available_delta_kib":%s}}\n' \
            "$SC_VERSION" "$MODE" "$(json_string "$OS")" "$(json_string "$PM")" "$KEEP_DAYS" "$RESULTS" \
            "$COMPLETED" "$PLANNED" "$SKIPPED" "$FAILED" "$DISK_BEFORE" "$DISK_AFTER" "$DISK_DELTA"
    elif [ "$QUIET" -eq 0 ]; then
        printf '\n%s\n\n' "$(text summary "$COMPLETED" "$PLANNED" "$SKIPPED" "$FAILED")"
        disk_bar "$(text before)" "$DISK_BEFORE"
        if [ "$MODE" = apply ]; then
            disk_bar "$(text after)" "$DISK_AFTER"
            if [ "$DISK_DELTA" != null ]; then printf '\n%s\n' "$(text delta "$DISK_DELTA")"; fi
        fi
    fi
}

open_terminal() { [ -t 1 ] && ( : <> /dev/tty ) 2>/dev/null; }

menu() {
    printf '\n%sServer Cleaner / %s%s\n\n' "$ACCENT" "$SC_VERSION" "$RESET" > /dev/tty
    text menu > /dev/tty
    IFS= read -r menu_choice < /dev/tty || exit 0
    case $menu_choice in
        ''|1) MODE=preview ;;
        2) MODE=apply ;;
        3) MODE=capabilities; TASKS="$DEFAULT_TASKS docker history" ;;
        0) exit 0 ;;
        *) fail "$(text value menu)" 2 ;;
    esac
}

confirm_plan() {
    [ "$YES" -eq 0 ] || return 0
    ( : <> /dev/tty ) 2>/dev/null || fail "$(text tty)" 2
    text "${1:-confirm}" > /dev/tty
    IFS= read -r answer < /dev/tty || answer=''
    case $answer in
        y|Y|yes|YES|д|Д|да|Да) return 0 ;;
        *) printf '%s\n' "$(text cancelled)" >&2; exit 0 ;;
    esac
}

management_message() {
    message_ru=$1 message_en=$2
    shift 2
    if [ "$LANGUAGE" = ru ]; then printf "$message_ru\n" "$@"; else printf "$message_en\n" "$@"; fi
}

management_error() { management_message "$@" >&2; exit 1; }

installation_paths() {
    if [ -z "$PREFIX" ]; then
        if [ "$USER_ID" -eq 0 ]; then PREFIX=/usr/local; else PREFIX=${HOME:?HOME is required}/.local; fi
        case $0 in */server-cleaner) PREFIX=$(CDPATH='' cd -P "$(dirname "$0")/.." && pwd -P) ;; esac
    fi
    case $PREFIX in /*) ;; *) fail "$(text value --prefix)" 2 ;; esac
    case $PREFIX in *'
'*|*'%'*) fail "$(text value --prefix)" 2 ;; esac
    if printf '%s' "$PREFIX" | grep -q '[[:cntrl:]]'; then fail "$(text value --prefix)" 2; fi
    PREFIX=${PREFIX%/}
    [ -n "$PREFIX" ] || fail "$(text value --prefix)" 2
    if [ -d "$PREFIX" ]; then PREFIX=$(CDPATH='' cd -P "$PREFIX" && pwd -P); fi
    [ "$PREFIX" != / ] || fail "$(text value --prefix)" 2
    BINDIR=$PREFIX/bin
    PROGRAM=$BINDIR/server-cleaner
    [ ! -L "$BINDIR" ] || fail "$(text unsafe_path "$BINDIR")"
    case $REF in ''|*[!a-zA-Z0-9_./-]*|*..*) fail "$(text value --ref)" 2 ;; esac
}

check_program() {
    [ ! -L "$PROGRAM" ] || fail "$(text unsafe_path "$PROGRAM")"
    if [ -e "$PROGRAM" ]; then
        if [ ! -f "$PROGRAM" ] || ! grep -Fqx '# server-cleaner:managed:clean' "$PROGRAM"; then
            management_error 'Файл не принадлежит Server Cleaner: %s.' 'File is not managed by Server Cleaner: %s.' "$PROGRAM"
        fi
    fi
}

management_cleanup() {
    if [ -n "$BIN_STAGE" ]; then rm -f "$BIN_STAGE"; fi
    if [ "$INSTALL_LOCKED" -eq 1 ]; then rmdir "$INSTALL_LOCK"; fi
    if [ -n "$MANAGE_DIR" ]; then rm -rf "$MANAGE_DIR"; fi
}

download_file() {
    download_name=$1
    if [ -n "$SOURCE_DIR" ]; then
        cp "$SOURCE_DIR/$download_name" "$MANAGE_DIR/$download_name" ||
            management_error 'Не удалось прочитать %s.' 'Cannot read %s.' "$download_name"
    elif has curl; then
        curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
            --connect-timeout 15 --max-time 120 --retry 2 \
            "$BASE_URL/$download_name" -o "$MANAGE_DIR/$download_name" ||
            management_error 'Не удалось скачать %s.' 'Download failed: %s.' "$download_name"
    elif has wget; then
        wget -q -T 60 -O "$MANAGE_DIR/$download_name" "$BASE_URL/$download_name" ||
            management_error 'Не удалось скачать %s.' 'Download failed: %s.' "$download_name"
    else
        management_error 'Нужен curl, wget или --from КАТАЛОГ.' 'Use curl, wget or --from DIR.'
    fi
}

file_sha256() {
    if has sha256sum; then sha256sum "$1" | awk '{print $1}';
    elif has shasum; then shasum -a 256 "$1" | awk '{print $1}';
    elif has sha256; then sha256 -q "$1";
    else management_error 'Нужна утилита sha256sum, shasum или sha256.' 'A SHA-256 tool is required: sha256sum, shasum or sha256.'; fi
}

verify_download() {
    expected_hash=$(awk '$2 == "clean.sh" && NF == 2 {print $1; found++} END {if(found != 1) exit 1}' "$MANAGE_DIR/SHA256SUMS") ||
        management_error 'Некорректный SHA256SUMS.' 'Invalid SHA256SUMS entry.'
    case $expected_hash in ''|*[!0-9a-f]*) fail 'Invalid SHA-256.' ;; esac
    [ "${#expected_hash}" -eq 64 ] || fail 'Invalid SHA-256 length.'
    actual_hash=$(file_sha256 "$MANAGE_DIR/clean.sh")
    [ "$expected_hash" = "$actual_hash" ] || management_error 'Проверка SHA-256 не пройдена.' 'SHA-256 mismatch.'
    sh -n "$MANAGE_DIR/clean.sh" || management_error 'Ошибка синтаксиса clean.sh.' 'Shell syntax check failed: clean.sh.'
    grep -Fqx '# server-cleaner:managed:clean' "$MANAGE_DIR/clean.sh" || fail 'Invalid installation bundle.'
}

remove_old_helpers() {
    for helper_kind in uninstall agents; do
        helper_path=$BINDIR/server-cleaner-$helper_kind
        if [ ! -L "$helper_path" ] && [ -f "$helper_path" ] && grep -Fqx "# server-cleaner:managed:$helper_kind" "$helper_path"; then
            rm -f "$helper_path"
        fi
    done
}

read_cron() {
    if crontab -l > "$1" 2> "$MANAGE_DIR/cron.error"; then return 0; fi
    if [ ! -s "$1" ] && grep -Eq '(no crontab for|can.t open .*: No such file or directory)' "$MANAGE_DIR/cron.error"; then return 0; fi
    cat "$MANAGE_DIR/cron.error" >&2
    management_error 'Не удалось прочитать crontab; изменения отменены.' 'Cannot read crontab; no cron changes made.'
}

same_crontab() {
    cron_left=$(cat "$1" && printf '.') || return 1
    cron_right=$(cat "$2" && printf '.') || return 1
    [ "$cron_left" = "$cron_right" ]
}

filter_cron() {
    SC_CRON_BEGIN="# BEGIN server-cleaner $PREFIX" SC_CRON_END="# END server-cleaner $PREFIX"
    export SC_CRON_BEGIN SC_CRON_END
    awk 'BEGIN {begin=ENVIRON["SC_CRON_BEGIN"]; end=ENVIRON["SC_CRON_END"]}
        $0==begin {if (inside) exit 2; inside=1; next}
        $0==end {if (!inside) exit 2; inside=0; next}
        !inside {print}
        END {if (inside) exit 2}' "$MANAGE_DIR/cron.before" > "$MANAGE_DIR/cron.after" ||
        management_error 'Повреждён блок Server Cleaner в crontab.' 'Malformed Server Cleaner crontab block.'
}

write_cron() {
    if same_crontab "$MANAGE_DIR/cron.before" "$MANAGE_DIR/cron.after"; then return 0; fi
    read_cron "$MANAGE_DIR/cron.current"
    same_crontab "$MANAGE_DIR/cron.before" "$MANAGE_DIR/cron.current" ||
        management_error 'Crontab изменился параллельно; повторите команду.' 'Crontab changed concurrently; retry the command.'
    crontab "$MANAGE_DIR/cron.after" || management_error 'Не удалось обновить crontab.' 'Failed to update crontab.'
}

shell_quote() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }

preflight_autostart() (
    has crontab || fail "$(text missing crontab)"
    resolve_home || fail "$(text unsafe_home)"
    MODE=apply RUN_MODE=preview QUIET=1
    reset_results
    run_tasks
    [ "$FAILED" -eq 0 ]
)

autostart_line() {
    cron_hour=$(printf '%s' "${SCHEDULE_TIME%:*}" | awk '{printf "%d", $0}')
    cron_minute=$(printf '%s' "${SCHEDULE_TIME#*:}" | awk '{printf "%d", $0}')
    case $AUTOSTART in
        daily) printf '%s %s * * * ' "$cron_minute" "$cron_hour" ;;
        weekly) printf '%s %s * * 0 ' "$cron_minute" "$cron_hour" ;;
        boot) printf '@reboot ' ;;
    esac
    printf '/usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/homebrew/bin '
    shell_quote "HOME=$HOME_REAL"
    printf ' '
    shell_quote "XDG_STATE_HOME=${XDG_STATE_HOME:-$HOME_REAL/.local/state}"
    printf ' /bin/sh '
    shell_quote "$PROGRAM"
    task_csv=$(printf '%s\n' "$TASKS" | awk '{$1=$1; gsub(/ /, ","); print}')
    printf ' --apply --yes --no-color --only %s --keep-days %s --lang %s' "$task_csv" "$KEEP_DAYS" "$LANGUAGE"
    if [ "$QUIET" -eq 1 ]; then printf ' --quiet'; fi
    printf '\n'
}

configure_autostart() {
    if ! has crontab; then
        case $AUTOSTART in
            off|status) if [ "$QUIET" -eq 0 ]; then management_message 'Автозапуск: выключен (нет cron).' 'Autostart: off (cron unavailable).'; fi; return ;;
            *) fail "$(text missing crontab)" ;;
        esac
    fi
    read_cron "$MANAGE_DIR/cron.before"
    filter_cron
    if [ "$AUTOSTART" = status ]; then
        if same_crontab "$MANAGE_DIR/cron.before" "$MANAGE_DIR/cron.after"; then
            management_message 'Автозапуск: выключен.' 'Autostart: off.'
        else
            awk '$0==ENVIRON["SC_CRON_BEGIN"] {inside=1; next} $0==ENVIRON["SC_CRON_END"] {inside=0; next} inside {print}' "$MANAGE_DIR/cron.before"
        fi
        return
    fi
    if [ "$AUTOSTART" != off ]; then
        [ -f "$PROGRAM" ] && [ -x "$PROGRAM" ] ||
            management_error 'Сначала выполните --install.' 'Run --install first.'
        private_path "$PROGRAM" || fail "$(text unsafe_path "$PROGRAM")"
        resolve_home || fail "$(text unsafe_home)"
        case ${XDG_STATE_HOME:-$HOME_REAL/.local/state} in /*) ;; *) fail "$(text value XDG_STATE_HOME)" 2 ;; esac
        cron_line=$(autostart_line)
        case $cron_line in *'%'*|*'
'*) management_error 'Пути автозапуска не должны содержать %% или перевод строки.' 'Autostart paths must not contain %% or a newline.' ;; esac
        {
            printf '%s\n%s\n%s\n' "$SC_CRON_BEGIN" "$cron_line" "$SC_CRON_END"
        } >> "$MANAGE_DIR/cron.after"
    fi
    write_cron
    if [ "$QUIET" -eq 0 ]; then management_message 'Автозапуск: %s. Состояние: --autostart status.' 'Autostart: %s. Inspect with --autostart status.' "$AUTOSTART"; fi
}

check_legacy() {
    resolve_home || fail "$(text unsafe_home)"
    LEGACY_FILE=$HOME/.cache/system/.sysupdate
    for legacy_path in "$HOME/.cache" "$HOME/.cache/system" "$LEGACY_FILE"; do
        [ ! -L "$legacy_path" ] || fail "$(text unsafe_path "$legacy_path")"
    done
    if [ -e "$LEGACY_FILE" ]; then
        if [ ! -f "$LEGACY_FILE" ] || ! grep -Fq 'cat /dev/null > ~/.bash_history' "$LEGACY_FILE" || ! grep -Fq '/var/log/auth.log' "$LEGACY_FILE"; then
            management_error 'Нераспознанный файл v1: %s.' 'Unrecognized v1 file: %s.' "$LEGACY_FILE"
        fi
    fi
}

remove_legacy() {
    if has crontab; then
        read_cron "$MANAGE_DIR/cron.before"
        SC_OLD_CRON="0 0 * * * /bin/bash $LEGACY_FILE >/dev/null 2>&1"
        export SC_OLD_CRON
        awk '$0 != ENVIRON["SC_OLD_CRON"] && $0 != "0 0 * * * /bin/bash ~/.cache/system/.sysupdate >/dev/null 2>&1"' \
            "$MANAGE_DIR/cron.before" > "$MANAGE_DIR/cron.after"
        write_cron
    fi
    rm -f "$LEGACY_FILE"
}

install_program() {
    BASE_URL=https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/$REF
    download_file SHA256SUMS
    download_file clean.sh
    verify_download
    mkdir -p "$PREFIX"
    installation_paths
    check_program
    mkdir -p "$BINDIR"
    INSTALL_LOCK=$BINDIR/.server-cleaner-install-lock
    mkdir "$INSTALL_LOCK" 2>/dev/null || fail "$(text lock "$INSTALL_LOCK")" 75
    INSTALL_LOCKED=1
    BIN_STAGE=$(mktemp "$BINDIR/.server-cleaner.XXXXXXXX")
    cp "$MANAGE_DIR/clean.sh" "$BIN_STAGE"
    chmod 755 "$BIN_STAGE"
    mv -f "$BIN_STAGE" "$PROGRAM"
    BIN_STAGE=''
    remove_old_helpers
    if [ "$MIGRATE" -eq 1 ]; then remove_legacy; fi
    if [ "$QUIET" -eq 0 ]; then
        management_message 'Установлено: %s — справка: --help' 'Installed: %s — help: --help' "$PROGRAM"
        case :$PATH: in *:"$BINDIR":*) ;; *) management_message 'Добавьте %s в PATH или используйте полный путь.' 'Add %s to PATH or use the full path.' "$BINDIR" ;; esac
    fi
}

run_installed_cleanup() {
    task_csv=$(printf '%s\n' "$TASKS" | awk '{$1=$1; gsub(/ /, ","); print}')
    set -- "$PROGRAM" --apply --only "$task_csv" --keep-days "$KEEP_DAYS" --lang "$LANGUAGE"
    if [ "$YES" -eq 1 ]; then set -- "$@" --yes; fi
    if [ "$QUIET" -eq 1 ]; then set -- "$@" --quiet; fi
    if [ "$COLOR" -eq 0 ]; then set -- "$@" --no-color; fi
    "$@"
}

manage() (
    set -eu
    MANAGE_DIR='' BIN_STAGE='' INSTALL_LOCKED=0
    installation_paths
    check_program
    if [ "$SYSTEM_PREFIX" -eq 1 ] && [ "$USER_ID" -ne 0 ]; then fail "$(text root)"; fi
    case $AUTOSTART in daily|weekly|boot) preflight_autostart ;; esac
    if [ "$ACTION" = install ]; then
        if [ -e "${HOME:-}/.cache/system/.sysupdate" ] && [ "$MIGRATE" -eq 0 ]; then
            management_error 'Найдена v1. Используйте --install --migrate-legacy.' 'v1 found. Use --install --migrate-legacy.'
        fi
        if [ "$MIGRATE" -eq 1 ]; then check_legacy; confirm_plan confirm_migrate; fi
    elif [ "$ACTION" = uninstall ]; then
        confirm_plan confirm_uninstall
    fi
    MANAGE_DIR=$(umask 077; mktemp -d "${TMPDIR:-/tmp}/server-cleaner-manage.XXXXXXXX")
    trap 'management_cleanup' 0
    trap 'exit 130' INT
    trap 'exit 143' TERM
    trap 'exit 129' HUP
    if [ "$ACTION" = uninstall ]; then
        AUTOSTART=off
        configure_autostart
        rm -f "$PROGRAM"
        remove_old_helpers
        if [ "$QUIET" -eq 0 ]; then management_message 'Server Cleaner удалён.' 'Server Cleaner uninstalled.'; fi
        exit 0
    fi
    if [ "$ACTION" = install ]; then install_program; fi
    if [ -n "$AUTOSTART" ]; then configure_autostart; fi
    if [ "$MODE" = apply ]; then run_installed_cleanup; fi
)

agent_installed() {
    case $query_tool in
        dpkg-query) agent_status=$(dpkg-query -W -f='${db:Status-Status}' "$1" 2>/dev/null) || return 1; [ "$agent_status" = installed ] ;;
        rpm) rpm -q --quiet "$1" >/dev/null 2>&1 ;;
        apk) apk info -e "$1" >/dev/null 2>&1 ;;
        pacman) pacman -Q "$1" >/dev/null 2>&1 ;;
        pkg) pkg info -e "$1" >/dev/null 2>&1 ;;
    esac
}

list_agents() {
    query_tool=''
    for query_candidate in dpkg-query rpm apk pacman pkg; do
        if has "$query_candidate"; then query_tool=$query_candidate; break; fi
    done
    if [ -z "$query_tool" ]; then
        printf 'No supported package database / Нет поддерживаемой базы пакетов.\n' >&2
        return 3
    fi
    management_message 'Гостевые и облачные пакеты (только чтение):' 'Guest and cloud packages (read-only):'
    agents_found=0
    for agent_package in qemu-guest-agent cloud-init open-vm-tools virtualbox-guest-utils hyperv-daemons \
        amazon-cloudwatch-agent amazon-ssm-agent google-guest-agent google-osconfig-agent walinuxagent \
        waagent digitalocean-agent do-agent vultr-guest-agent landscape-client; do
        if agent_installed "$agent_package"; then printf '  installed  %s\n' "$agent_package"; agents_found=$((agents_found + 1)); fi
    done
    printf '\nFound / Найдено: %s\n' "$agents_found"
    management_message 'Показаны известные пакеты; ручные установки могут не отображаться.' 'Known packages only; manual installations may not appear.'
}

main() {
    set -u
    case ${LC_ALL:-${LC_MESSAGES:-${LANG:-en}}} in ru*) LANGUAGE=ru ;; *) LANGUAGE=en ;; esac
    DEFAULT_TASKS='packages journal temp logs coredumps'
    TASKS=$DEFAULT_TASKS
    MODE=preview YES=0 JSON=0 QUIET=0 COLOR=1 LIST=0 KEEP_DAYS=14 LOCK_HELD=0
    ACTION=clean PREFIX='' PREFIX_SET=0 SYSTEM_PREFIX=0 SOURCE_DIR='' REF=main REF_SET=0 MIGRATE=0
    AUTOSTART='' SCHEDULE_TIME=03:17 TIME_SET=0 TASK_OPTIONS=0 EXPLICIT_PREVIEW=0
    ACCENT='' RESET=''
    initial_arg_count=$#
    parse_args "$@"
    LC_ALL=C
    export LC_ALL
    has awk || fail "$(text missing awk)" 3
    detect_platform
    if [ "$ACTION" = agents ]; then list_agents; return $?; fi
    if [ "$ACTION" != clean ] || [ -n "$AUTOSTART" ]; then manage; return $?; fi
    if [ "$COLOR" -eq 1 ] && [ -t 1 ] && [ -z "${NO_COLOR+x}" ] && [ "${TERM:-dumb}" != dumb ]; then
        ACCENT=$(printf '\033[1;32m') RESET=$(printf '\033[0m')
    fi
    if [ "$initial_arg_count" -eq 0 ] && open_terminal; then menu; fi
    if [ "$JSON" -eq 1 ] && [ "$MODE" = apply ] && [ "$YES" -eq 0 ]; then fail "$(text tty)" 2; fi
    DISK_BEFORE=$(disk_snapshot)
    reset_results
    RUN_MODE=preview
    if [ "$JSON" -eq 0 ] && [ "$QUIET" -eq 0 ]; then
        printf '\n%sServer Cleaner %s%s / %s / %s\n%s\n\n' "$ACCENT" "$SC_VERSION" "$RESET" "$OS" "$PM" "$(text preview)"
    fi
    run_tasks
    if [ "$MODE" = apply ]; then
        # Refuse an invalid preflight before executing any other selected task.
        if [ "$FAILED" -eq 0 ]; then
            confirm_plan
            acquire_lock
            reset_results
            RUN_MODE=apply
            if [ "$JSON" -eq 0 ] && [ "$QUIET" -eq 0 ]; then printf '\n%s\n\n' "$(text apply)"; fi
            run_tasks
        fi
        DISK_AFTER=$(disk_snapshot)
    else
        DISK_AFTER=null
    fi
    report
    [ "$FAILED" -eq 0 ]
}

main "$@"
