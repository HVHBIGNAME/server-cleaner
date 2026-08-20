#!/bin/bash

set -e  # Остановка при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_VERSION="1.0.0"
HIDDEN_DIR="$HOME/.cache/system"
SCRIPT_NAME=".sysupdate"
SCRIPT_PATH="$HIDDEN_DIR/$SCRIPT_NAME"

# Функция вывода сообщений
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# Проверка существования скрипта
check_installation() {
    if [ ! -f "$SCRIPT_PATH" ]; then
        log_warn "Script not found at: $SCRIPT_PATH"
        return 1
    fi
    return 0
}

# Удаление из crontab
remove_from_cron() {
    if ! command -v crontab &> /dev/null; then
        log_info "crontab not installed, skipping"
        return 0
    fi
    
    if crontab -l 2>/dev/null | grep -qF "$SCRIPT_PATH"; then
        crontab -l 2>/dev/null | grep -vF "$SCRIPT_PATH" | crontab - 2>/dev/null || {
            log_error "Failed to remove from crontab"
            return 1
        }
        log_success "Removed from crontab"
    else
        log_info "Not found in crontab"
    fi
}

# Удаление скрипта
remove_script() {
    if [ -f "$SCRIPT_PATH" ]; then
        rm -f "$SCRIPT_PATH" 2>/dev/null || {
            log_error "Failed to remove script: $SCRIPT_PATH"
            return 1
        }
        log_success "Removed script: $SCRIPT_PATH"
    else
        log_info "Script not found"
    fi
}

# Удаление директории
remove_directory() {
    if [ -d "$HIDDEN_DIR" ]; then
        # Проверяем, пустая ли директория
        if [ -z "$(ls -A $HIDDEN_DIR 2>/dev/null)" ]; then
            rmdir "$HIDDEN_DIR" 2>/dev/null && log_success "Removed directory: $HIDDEN_DIR" || log_warn "Failed to remove directory"
        else
            log_info "Directory not empty, keeping it: $HIDDEN_DIR"
        fi
    else
        log_info "Directory not found"
    fi
}

# Последняя очистка (опционально)
final_cleanup() {
    echo ""
    read -p "Run final cleanup before uninstall? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "$SCRIPT_PATH" ] && [ -x "$SCRIPT_PATH" ]; then
            log_info "Running final cleanup..."
            bash "$SCRIPT_PATH" 2>/dev/null || log_warn "Cleanup failed"
        else
            log_warn "Script not executable, skipping cleanup"
        fi
    fi
}

# Основная функция
main() {
    echo "======================================"
    echo "  Server Cleaner Uninstaller v${SCRIPT_VERSION}"
    echo "======================================"
    echo ""
    
    if ! check_installation; then
        log_warn "Server Cleaner doesn't appear to be installed"
        echo ""
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Uninstall cancelled"
            exit 0
        fi
    fi
    
    # Спрашиваем подтверждение
    echo ""
    read -p "Are you sure you want to uninstall? (y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Uninstall cancelled"
        exit 0
    fi
    
    final_cleanup
    
    log_info "Uninstalling..."
    echo ""
    
    remove_from_cron
    remove_script
    remove_directory
    
    echo ""
    log_success "Uninstall complete!"
    log_info "To reinstall: curl -fsSL https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/install.sh | bash"
}

main
