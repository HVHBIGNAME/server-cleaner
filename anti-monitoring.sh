#!/bin/sh
# server-cleaner:managed:agents
# SPDX-License-Identifier: MIT

agent_installed() {
    if command -v dpkg-query >/dev/null 2>&1; then
        agent_status=$(dpkg-query -W -f='${db:Status-Status}' "$1" 2>/dev/null) || return 1
        [ "$agent_status" = installed ]
    elif command -v rpm >/dev/null 2>&1; then
        rpm -q --quiet "$1" >/dev/null 2>&1
    elif command -v apk >/dev/null 2>&1; then
        apk info -e "$1" >/dev/null 2>&1
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Q "$1" >/dev/null 2>&1
    elif command -v pkg >/dev/null 2>&1; then
        pkg info -e "$1" >/dev/null 2>&1
    else
        return 1
    fi
}

agents_main() {
    set -u
    for agent_arg do
        case $agent_arg in
            --dry-run) ;;
            -h|--help)
                cat <<'EOF'
Usage: server-cleaner-agents [--dry-run]

Read-only inventory of known guest / cloud integration packages.
No root required. Package names are checked exactly, not by substring.
This is the replacement for the v1 bulk-removal anti-monitoring script.

Список установленных гостевых и облачных агентов (только чтение).
Управляйте нужными пакетами через пакетный менеджер своей ОС.
EOF
                return 0
                ;;
            *) printf 'Unknown option: %s. This tool is read-only; see --help.\n' "$agent_arg" >&2; return 2 ;;
        esac
    done
    query_tool=''
    for query_candidate in dpkg-query rpm apk pacman pkg; do
        if command -v "$query_candidate" >/dev/null 2>&1; then query_tool=$query_candidate; break; fi
    done
    if [ -z "$query_tool" ]; then
        printf 'No supported package database / Нет поддерживаемой базы пакетов.\n' >&2
        return 3
    fi
    printf 'Server Cleaner / guest & cloud integrations\nRead-only inventory / Только чтение\n\n'
    agents_found=0
    for agent_package in \
        qemu-guest-agent cloud-init open-vm-tools virtualbox-guest-utils \
        hyperv-daemons amazon-cloudwatch-agent amazon-ssm-agent \
        google-guest-agent google-osconfig-agent walinuxagent waagent \
        digitalocean-agent do-agent vultr-guest-agent landscape-client; do
        if agent_installed "$agent_package"; then
            printf '  installed  %s\n' "$agent_package"
            agents_found=$((agents_found + 1))
        fi
    done
    printf '\nFound / Найдено: %s\n' "$agents_found"
    printf 'Package inventory only; manually installed agents may not appear.\n'
    printf 'Инвентаризация пакетов; агенты, установленные вручную, могут не отображаться.\n'
}

agents_main "$@"
