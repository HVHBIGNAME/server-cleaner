#!/bin/sh
# SPDX-License-Identifier: MIT

installer_message() {
    message_ru=$1 message_en=$2
    shift 2
    if [ "$INSTALL_LANG" = ru ]; then printf "$message_ru\n" "$@"; else printf "$message_en\n" "$@"; fi
}

installer_error() {
    installer_message "$@" >&2
    exit 1
}

installer_help() {
    cat <<'EOF'
Server Cleaner installer

Usage: sh install.sh [OPTIONS]
  --prefix DIR        Install to DIR/bin (absolute path)
  --system            Install to /usr/local; requires root
  --from DIR          Offline install from a checkout with SHA256SUMS
  --ref REF           Git commit / tag / branch to download (default: main)
  --schedule daily    Opt-in maintenance at 03:17; requires root and crontab
  --auto-cron         Alias for --schedule daily
  --auto-run          Opt-in cleanup after installation
  --migrate-legacy    Remove the current user's v1 .sysupdate installation
  -y, --yes           Confirm optional cleanup / legacy migration
  -q, --quiet         Less output (--silent is an alias, with no extra actions)
  --lang ru|en        Installer language
  -h, --help          This help

Default prefix: ~/.local for users, /usr/local for root.
Installation alone does not clean anything or schedule a job.
EOF
}

installer_parse() {
    while [ "$#" -gt 0 ]; do
        case $1 in
            --prefix|--from|--ref|--schedule|--lang)
                [ "$#" -ge 2 ] && [ -n "$2" ] || installer_error 'Отсутствует значение %s.' 'Missing value for %s.' "$1"
                case $1 in
                    --prefix) PREFIX=$2 ;;
                    --from) SOURCE_DIR=$2 ;;
                    --ref) REF=$2 ;;
                    --schedule)
                        [ "$2" = daily ] || installer_error 'Допустимое расписание: daily.' 'Supported schedule: daily.'
                        SCHEDULE=1
                        ;;
                    --lang)
                        case $2 in ru|en) INSTALL_LANG=$2 ;; *) installer_error 'Язык: ru или en.' 'Language must be ru or en.' ;; esac
                        ;;
                esac
                shift
                ;;
            --system)
                [ "$INSTALL_UID" -eq 0 ] || installer_error 'Для --system нужен root.' '--system requires root.'
                PREFIX=/usr/local
                ;;
            --auto-cron) SCHEDULE=1 ;;
            --auto-run) AUTO_RUN=1 ;;
            --migrate-legacy) MIGRATE=1 ;;
            -y|--yes) INSTALL_YES=1 ;;
            -q|--quiet|--silent) INSTALL_QUIET=1 ;;
            -h|--help) installer_help; exit 0 ;;
            *) installer_error 'Неизвестный аргумент: %s.' 'Unknown argument: %s.' "$1" ;;
        esac
        shift
    done
}

installer_validate() {
    case $(uname -s) in
        Linux|Darwin|FreeBSD|OpenBSD|NetBSD) ;;
        *) installer_error 'Нужна система Linux, macOS или BSD. Для Windows используйте WSL.' 'Linux, macOS or BSD required. On Windows, use WSL.' ;;
    esac
    case $PREFIX in /*) ;; *) installer_error 'Путь --prefix должен быть абсолютным.' '--prefix must be an absolute path.' ;; esac
    case $PREFIX in
        *'
'*|*'%'*) installer_error 'Путь установки не должен содержать перевод строки или %%.' 'Install path must not contain a newline or %%.' ;;
    esac
    if printf '%s' "$PREFIX" | LC_ALL=C grep -q '[[:cntrl:]]'; then
        installer_error 'Путь содержит управляющие символы.' 'Install path contains control characters.'
    fi
    case $REF in ''|*[!a-zA-Z0-9_./-]*|*..*) installer_error 'Недопустимый Git ref.' 'Invalid Git ref.' ;; esac
    PREFIX=${PREFIX%/}
    [ -n "$PREFIX" ] || installer_error 'Нельзя устанавливать в /.' 'Cannot install into /.'
    if [ -d "$PREFIX" ]; then PREFIX=$(CDPATH='' cd -P "$PREFIX" && pwd -P); fi
    [ "$PREFIX" != / ] || installer_error 'Нельзя устанавливать в /.' 'Cannot install into /.'
    if [ "$SCHEDULE" -eq 1 ]; then
        [ "$INSTALL_UID" -eq 0 ] || installer_error 'Расписание системной очистки требует root.' 'Scheduling system maintenance requires root.'
        command -v crontab >/dev/null 2>&1 || installer_error 'Установите и запустите cron перед --schedule daily.' 'Install and start cron before using --schedule daily.'
    fi
    if [ -f "${HOME:-}/.cache/system/.sysupdate" ] && [ "$MIGRATE" -eq 0 ]; then
        installer_error 'Найдена v1. Повторите установку с --migrate-legacy для удаления старой задачи.' 'v1 found. Re-run with --migrate-legacy to remove its old job.'
    fi
}

installer_cleanup() {
    if [ -n "$INSTALL_STAGE" ]; then rm -rf "$INSTALL_STAGE"; fi
    if [ -n "$BIN_STAGE" ]; then rm -f "$BIN_STAGE"; fi
    if [ "$INSTALL_LOCKED" -eq 1 ]; then rmdir "$INSTALL_LOCK"; fi
}

download_file() {
    download_name=$1
    if [ -n "$SOURCE_DIR" ]; then
        cp "$SOURCE_DIR/$download_name" "$INSTALL_STAGE/$download_name" || installer_error 'Не удалось прочитать %s.' 'Cannot read %s.' "$download_name"
    elif command -v curl >/dev/null 2>&1; then
        curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
            --connect-timeout 15 --max-time 120 --retry 2 \
            "$BASE_URL/$download_name" -o "$INSTALL_STAGE/$download_name" || installer_error 'Не удалось скачать %s.' 'Download failed: %s.' "$download_name"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -T 60 -O "$INSTALL_STAGE/$download_name" "$BASE_URL/$download_name" || installer_error 'Не удалось скачать %s.' 'Download failed: %s.' "$download_name"
    else
        installer_error 'Нужен curl или wget, либо локальная установка --from DIR.' 'Install curl or wget, or use an offline --from DIR installation.'
    fi
}

file_sha256() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    elif command -v sha256 >/dev/null 2>&1; then
        sha256 -q "$1"
    else
        installer_error 'Нужна утилита sha256sum, shasum или sha256.' 'A SHA-256 tool is required: sha256sum, shasum or sha256.'
    fi
}

verify_downloads() {
    for verify_name in clean.sh uninstall.sh anti-monitoring.sh; do
        expected_hash=$(awk -v name="$verify_name" '$2 == name && NF == 2 {print $1; found++} END {if(found != 1) exit 1}' "$INSTALL_STAGE/SHA256SUMS") || \
            installer_error 'Некорректный SHA256SUMS: %s.' 'Invalid SHA256SUMS entry: %s.' "$verify_name"
        case $expected_hash in ''|*[!0-9a-f]*) installer_error 'Некорректная контрольная сумма.' 'Invalid checksum.' ;; esac
        [ "${#expected_hash}" -eq 64 ] || installer_error 'Некорректная длина SHA-256.' 'Invalid SHA-256 length.'
        actual_hash=$(file_sha256 "$INSTALL_STAGE/$verify_name") || exit 1
        [ "$expected_hash" = "$actual_hash" ] || installer_error 'Проверка SHA-256 не пройдена: %s. Повторите скачивание.' 'SHA-256 mismatch: %s. Retry the download.' "$verify_name"
        sh -n "$INSTALL_STAGE/$verify_name" || installer_error 'Ошибка синтаксиса: %s.' 'Shell syntax check failed: %s.' "$verify_name"
    done
    if grep -Fqx '# server-cleaner:managed:clean' "$INSTALL_STAGE/clean.sh" &&
        grep -Fqx '# server-cleaner:managed:uninstall' "$INSTALL_STAGE/uninstall.sh" &&
        grep -Fqx '# server-cleaner:managed:agents' "$INSTALL_STAGE/anti-monitoring.sh"; then
        return 0
    else
        installer_error 'Некорректный комплект установки.' 'Invalid installation bundle.'
    fi
}

check_target() {
    if [ -L "$1" ]; then installer_error 'Отказ перезаписать ссылку: %s.' 'Refusing to overwrite a symlink: %s.' "$1"; fi
    if [ -e "$1" ]; then
        if [ ! -f "$1" ] || ! grep -Fqx "# server-cleaner:managed:$2" "$1"; then
            installer_error 'Файл не принадлежит Server Cleaner: %s.' 'File is not managed by Server Cleaner: %s.' "$1"
        fi
    fi
}

install_binary() {
    BIN_STAGE=$(mktemp "$BINDIR/.server-cleaner.XXXXXXXX") || installer_error 'Не удалось создать временный файл в %s.' 'Cannot stage a file in %s.' "$BINDIR"
    if cp "$INSTALL_STAGE/$1" "$BIN_STAGE" && chmod 755 "$BIN_STAGE" && mv -f "$BIN_STAGE" "$BINDIR/$2"; then
        BIN_STAGE=''
    else
        installer_error 'Не удалось установить %s.' 'Failed to install %s.' "$2"
    fi
}

read_install_cron() {
    if crontab -l > "$1" 2> "$INSTALL_STAGE/cron.error"; then return 0; fi
    if [ ! -s "$1" ] && grep -Eq '(no crontab for|can.t open .*: No such file or directory)' "$INSTALL_STAGE/cron.error"; then return 0; fi
    cat "$INSTALL_STAGE/cron.error" >&2
    installer_error 'Не удалось прочитать crontab; изменения отменены.' 'Cannot read crontab; no cron changes made.'
}

install_schedule() {
    read_install_cron "$INSTALL_STAGE/cron.before"
    SC_CRON_BEGIN="# BEGIN server-cleaner $PREFIX" SC_CRON_END="# END server-cleaner $PREFIX"
    export SC_CRON_BEGIN SC_CRON_END
    awk 'BEGIN {begin=ENVIRON["SC_CRON_BEGIN"]; end=ENVIRON["SC_CRON_END"]}
        $0==begin {if (inside) exit 2; inside=1; next}
        $0==end {if (!inside) exit 2; inside=0; next}
        !inside {print}
        END {if (inside) exit 2}' "$INSTALL_STAGE/cron.before" > "$INSTALL_STAGE/cron.after" ||
        installer_error 'Повреждён блок Server Cleaner в crontab.' 'Malformed Server Cleaner crontab block.'
    cron_command=$(printf '%s' "$BINDIR/server-cleaner" | sed "s/'/'\\\\''/g")
    {
        printf '%s\n' "$SC_CRON_BEGIN"
        printf "17 3 * * * PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /bin/sh '%s' --apply --yes --no-color\n" "$cron_command"
        printf '%s\n' "$SC_CRON_END"
    } >> "$INSTALL_STAGE/cron.after"
    read_install_cron "$INSTALL_STAGE/cron.current"
    cmp -s "$INSTALL_STAGE/cron.before" "$INSTALL_STAGE/cron.current" ||
        installer_error 'Crontab изменился параллельно. Повторите установку расписания.' 'Crontab changed concurrently. Retry scheduling.'
    crontab "$INSTALL_STAGE/cron.after" || installer_error 'Не удалось установить расписание.' 'Failed to install the schedule.'
    installer_message 'Расписание: ежедневно в 03:17 по времени сервера. Демон cron должен быть запущен.' 'Scheduled daily at 03:17 server time. The cron daemon must be running.'
}

installer_main() {
    set -eu
    case ${LC_ALL:-${LC_MESSAGES:-${LANG:-en}}} in ru*) INSTALL_LANG=ru ;; *) INSTALL_LANG=en ;; esac
    INSTALL_UID=$(id -u)
    if [ "$INSTALL_UID" -eq 0 ]; then PREFIX=/usr/local; else PREFIX=${HOME:?HOME is required}/.local; fi
    SOURCE_DIR='' REF=main SCHEDULE=0 AUTO_RUN=0 MIGRATE=0 INSTALL_YES=0 INSTALL_QUIET=0
    INSTALL_STAGE='' BIN_STAGE='' INSTALL_LOCKED=0
    installer_parse "$@"
    LC_ALL=C
    export LC_ALL
    installer_validate
    INSTALL_STAGE=$(umask 077; mktemp -d "${TMPDIR:-/tmp}/server-cleaner-install.XXXXXXXX")
    trap 'installer_cleanup' 0
    trap 'exit 130' INT
    trap 'exit 143' TERM
    trap 'exit 129' HUP
    BASE_URL=https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/$REF
    for source_file in SHA256SUMS clean.sh uninstall.sh anti-monitoring.sh; do download_file "$source_file"; done
    verify_downloads
    mkdir -p "$PREFIX"
    PREFIX=$(CDPATH='' cd -P "$PREFIX" && pwd -P)
    [ "$PREFIX" != / ] || installer_error 'Нельзя устанавливать в /.' 'Cannot install into /.'
    BINDIR=$PREFIX/bin
    [ ! -L "$BINDIR" ] || installer_error 'Каталог bin не должен быть ссылкой: %s.' 'bin must not be a symlink: %s.' "$BINDIR"
    check_target "$BINDIR/server-cleaner" clean
    check_target "$BINDIR/server-cleaner-uninstall" uninstall
    check_target "$BINDIR/server-cleaner-agents" agents
    if [ "$MIGRATE" -eq 1 ]; then
        if [ "$INSTALL_YES" -eq 1 ]; then
            sh "$INSTALL_STAGE/uninstall.sh" --legacy --yes
        else
            sh "$INSTALL_STAGE/uninstall.sh" --legacy
        fi
    fi
    mkdir -p "$BINDIR"
    INSTALL_LOCK=$BINDIR/.server-cleaner-install-lock
    mkdir "$INSTALL_LOCK" 2>/dev/null || installer_error 'Установка уже запущена или каталог недоступен: %s.' 'Another installation is running or the directory is not writable: %s.' "$INSTALL_LOCK"
    INSTALL_LOCKED=1
    install_binary clean.sh server-cleaner
    install_binary uninstall.sh server-cleaner-uninstall
    install_binary anti-monitoring.sh server-cleaner-agents
    if [ "$SCHEDULE" -eq 1 ]; then install_schedule; fi
    if [ "$INSTALL_QUIET" -eq 0 ]; then
        installer_message '\nServer Cleaner установлен: %s\nЗапуск: "%s"\nСправка: "%s" --help' '\nServer Cleaner installed: %s\nRun: "%s"\nHelp: "%s" --help' "$BINDIR" "$BINDIR/server-cleaner" "$BINDIR/server-cleaner"
        case :$PATH: in
            *:"$BINDIR":*) ;;
            *) installer_message 'Добавьте %s в PATH или запускайте по полному пути.' 'Add %s to PATH or run the full path above.' "$BINDIR" ;;
        esac
    fi
    if [ "$AUTO_RUN" -eq 1 ]; then
        if [ "$INSTALL_YES" -eq 1 ]; then "$BINDIR/server-cleaner" --apply --yes --lang "$INSTALL_LANG";
        else "$BINDIR/server-cleaner" --apply --lang "$INSTALL_LANG"; fi
    fi
}

installer_main "$@"
