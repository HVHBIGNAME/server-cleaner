#!/bin/sh
# server-cleaner:managed:uninstall
# SPDX-License-Identifier: MIT

uninstall_error() { printf 'server-cleaner-uninstall: %s\n' "$1" >&2; exit 1; }

uninstall_help() {
    cat <<'EOF'
Usage: server-cleaner-uninstall [OPTIONS]
  --prefix DIR   Installation prefix (default: inferred from installed command,
                 otherwise ~/.local for users or /usr/local for root)
  --system       Use /usr/local (requires root)
  --legacy       Remove ONLY the current user's v1 ~/.cache/system/.sysupdate
  -y, --yes      Uninstall without a confirmation prompt
  -h, --help     This help

Removes managed binaries and their exact cron block. Does not run cleanup.
Удаляет установленные команды и их задачу cron. Очистку системы не запускает.
EOF
}

uninstall_parse() {
    while [ "$#" -gt 0 ]; do
        case $1 in
            --prefix)
                [ "$#" -ge 2 ] && [ -n "$2" ] || uninstall_error 'Missing --prefix value.'
                PREFIX=$2
                shift
                ;;
            --system)
                [ "$(id -u)" -eq 0 ] || uninstall_error '--system requires root.'
                PREFIX=/usr/local
                ;;
            --legacy) LEGACY=1 ;;
            -y|--yes) UNINSTALL_YES=1 ;;
            -h|--help) uninstall_help; exit 0 ;;
            *) uninstall_error "Unknown argument: $1" ;;
        esac
        shift
    done
}

check_managed_file() {
    [ ! -L "$1" ] || uninstall_error "Refusing a symlink: $1"
    if [ -e "$1" ]; then
        if [ ! -f "$1" ] || ! grep -Fqx "# server-cleaner:managed:$2" "$1"; then
            uninstall_error "Not a Server Cleaner file: $1"
        fi
    fi
}

read_uninstall_cron() {
    if crontab -l > "$1" 2> "$UNINSTALL_STAGE/cron.error"; then return 0; fi
    if [ ! -s "$1" ] && grep -Eq '(no crontab for|can.t open .*: No such file or directory)' "$UNINSTALL_STAGE/cron.error"; then return 0; fi
    cat "$UNINSTALL_STAGE/cron.error" >&2
    uninstall_error 'Cannot read crontab; installation kept.'
}

remove_schedule() {
    command -v crontab >/dev/null 2>&1 || return 0
    read_uninstall_cron "$UNINSTALL_STAGE/cron.before"
    if [ "$LEGACY" -eq 1 ]; then
        SC_OLD_CRON="0 0 * * * /bin/bash $LEGACY_FILE >/dev/null 2>&1"
        export SC_OLD_CRON
        awk '$0 != ENVIRON["SC_OLD_CRON"] && $0 != "0 0 * * * /bin/bash ~/.cache/system/.sysupdate >/dev/null 2>&1"' \
            "$UNINSTALL_STAGE/cron.before" > "$UNINSTALL_STAGE/cron.after"
    else
        SC_CRON_BEGIN="# BEGIN server-cleaner $PREFIX" SC_CRON_END="# END server-cleaner $PREFIX"
        export SC_CRON_BEGIN SC_CRON_END
        awk 'BEGIN {begin=ENVIRON["SC_CRON_BEGIN"]; end=ENVIRON["SC_CRON_END"]}
            $0==begin {if (inside) exit 2; inside=1; next}
            $0==end {if (!inside) exit 2; inside=0; next}
            !inside {print}
            END {if (inside) exit 2}' "$UNINSTALL_STAGE/cron.before" > "$UNINSTALL_STAGE/cron.after" ||
            uninstall_error 'Malformed Server Cleaner cron block; installation kept.'
    fi
    if cmp -s "$UNINSTALL_STAGE/cron.before" "$UNINSTALL_STAGE/cron.after"; then return 0; fi
    read_uninstall_cron "$UNINSTALL_STAGE/cron.current"
    cmp -s "$UNINSTALL_STAGE/cron.before" "$UNINSTALL_STAGE/cron.current" || uninstall_error 'Crontab changed concurrently; retry uninstalling.'
    crontab "$UNINSTALL_STAGE/cron.after" || uninstall_error 'Cannot remove cron job; installation kept.'
}

check_legacy() {
    case ${HOME:-} in /*) ;; *) uninstall_error 'An absolute HOME is required.' ;; esac
    LEGACY_FILE=$HOME/.cache/system/.sysupdate
    for legacy_path in "$HOME" "$HOME/.cache" "$HOME/.cache/system" "$LEGACY_FILE"; do
        [ ! -L "$legacy_path" ] || uninstall_error "Refusing a legacy symlink: $legacy_path"
    done
    if [ -e "$LEGACY_FILE" ]; then
        if [ ! -f "$LEGACY_FILE" ] || ! grep -Fq 'cat /dev/null > ~/.bash_history' "$LEGACY_FILE" ||
            ! grep -Fq '/var/log/auth.log' "$LEGACY_FILE"; then
            uninstall_error "Unrecognized v1 file: $LEGACY_FILE"
        fi
    fi
}

uninstall_main() {
    set -eu
    LC_ALL=C
    export LC_ALL
    if [ "$(id -u)" -eq 0 ]; then PREFIX=/usr/local; else PREFIX=${HOME:?HOME is required}/.local; fi
    case $0 in
        */server-cleaner-uninstall)
            PREFIX=$(CDPATH='' cd -P "$(dirname "$0")/.." && pwd -P)
            ;;
    esac
    LEGACY=0 UNINSTALL_YES=0 UNINSTALL_STAGE=''
    uninstall_parse "$@"
    case $PREFIX in /*) ;; *) uninstall_error '--prefix must be absolute.' ;; esac
    case $PREFIX in *'
'*) uninstall_error 'Newlines are not allowed in --prefix.' ;; esac
    PREFIX=${PREFIX%/}
    [ -n "$PREFIX" ] || uninstall_error 'Refusing prefix /.'
    if [ -d "$PREFIX" ]; then PREFIX=$(CDPATH='' cd -P "$PREFIX" && pwd -P); fi
    [ "$PREFIX" != / ] || uninstall_error 'Refusing prefix /.'
    BINDIR=$PREFIX/bin
    [ ! -L "$BINDIR" ] || uninstall_error "Refusing a bin symlink: $BINDIR"
    if [ "$LEGACY" -eq 1 ]; then
        check_legacy
        printf 'Remove v1 installation / Удалить v1: %s\n' "$LEGACY_FILE"
    else
        check_managed_file "$BINDIR/server-cleaner" clean
        check_managed_file "$BINDIR/server-cleaner-uninstall" uninstall
        check_managed_file "$BINDIR/server-cleaner-agents" agents
        printf 'Uninstall / Удалить Server Cleaner: %s\n' "$BINDIR"
    fi
    if [ "$UNINSTALL_YES" -eq 0 ]; then
        ( : <> /dev/tty ) 2>/dev/null || uninstall_error 'Use --yes in a non-interactive session.'
        printf 'Continue / Продолжить? [y/N]: ' > /dev/tty
        IFS= read -r uninstall_answer < /dev/tty || uninstall_answer=''
        case $uninstall_answer in y|Y|yes|YES|д|Д|да|Да) ;; *) printf 'Cancelled / Отменено.\n'; exit 2 ;; esac
    fi
    UNINSTALL_STAGE=$(umask 077; mktemp -d "${TMPDIR:-/tmp}/server-cleaner-uninstall.XXXXXXXX")
    trap 'rm -rf "$UNINSTALL_STAGE"' 0
    trap 'exit 130' INT
    trap 'exit 143' TERM
    trap 'exit 129' HUP
    remove_schedule
    if [ "$LEGACY" -eq 1 ]; then
        rm -f "$LEGACY_FILE"
    else
        rm -f "$BINDIR/server-cleaner" "$BINDIR/server-cleaner-agents" "$BINDIR/server-cleaner-uninstall"
    fi
    printf 'Uninstalled / Удалено.\n'
}

uninstall_main "$@"
