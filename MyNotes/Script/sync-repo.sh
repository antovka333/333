#!/bin/bash
# sync-repo.sh - Синхронизация содержимого между Git репозиториями

set -euo pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Функция для вывода сообщений
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Функция для проверки пути
check_path() {
    local path=$1
    local path_type=$2
    
    if [[ -z "$path" ]]; then
        print_message "$RED" "Ошибка: $path_type не указан"
        return 1
    fi
    
    if [[ ! -d "$path" ]]; then
        print_message "$RED" "Ошибка: $path_type '$path' не существует"
        return 1
    fi
    
    print_message "$GREEN" "✓ $path_type проверен: $path"
    return 0
}

# Функция для проверки Git репозитория
check_git_repo() {
    local repo_path=$1
    local repo_name=$2
    
    if [[ ! -d "$repo_path/.git" ]]; then
        print_message "$RED" "Ошибка: $repo_name не является Git репозиторием"
        return 1
    fi
    
    print_message "$GREEN" "✓ $repo_name является Git репозиторием"
    return 0
}

# Функция для синхронизации с удаленным репозиторием
sync_with_remote() {
    local repo_path=$1
    local repo_name=$2
    local do_push=${3:-false}
    
    print_message "$BLUE" "Синхронизация $repo_name с удаленным репозиторием..."
    
    cd "$repo_path" || return 1
    
    # Проверка на незакоммиченные изменения
    if [[ -n $(git status --porcelain) ]]; then
        print_message "$YELLOW" "Предупреждение: В $repo_name есть незакоммиченные изменения"
        read -p "Хотите продолжить? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # Получение текущей ветки
    current_branch=$(git branch --show-current)
    print_message "$BLUE" "Текущая ветка: $current_branch"
    
    # Pull изменений
    print_message "$BLUE" "Выполняется git pull..."
    if git pull origin "$current_branch"; then
        print_message "$GREEN" "✓ Pull выполнен успешно"
    else
        print_message "$RED" "✗ Ошибка при выполнении pull"
        return 1
    fi
    
    # Push изменений (опционально)
    if [[ "$do_push" == true ]]; then
        print_message "$BLUE" "Выполняется git push..."
        if git push origin "$current_branch"; then
            print_message "$GREEN" "✓ Push выполнен успешно"
        else
            print_message "$RED" "✗ Ошибка при выполнении push"
            return 1
        fi
    fi
    
    return 0
}

# Функция для копирования содержимого без .git
copy_without_git() {
    local source_dir=$1
    local dest_dir=$2
    
    print_message "$BLUE" "Копирование содержимого из $source_dir в $dest_dir..."
    
    # Создание временного файла для исключений
    local exclude_file=$(mktemp)
    echo ".git" > "$exclude_file"
    echo ".gitignore" >> "$exclude_file"  # Опционально: исключить .gitignore
    
    # Копирование с исключением .git
    if rsync -av --exclude-from="$exclude_file" "$source_dir/" "$dest_dir/"; then
        print_message "$GREEN" "✓ Копирование выполнено успешно"
        rm -f "$exclude_file"
        return 0
    else
        print_message "$RED" "✗ Ошибка при копировании"
        rm -f "$exclude_file"
        return 1
    fi
}

# Функция для обработки приватных репозиториев
check_private_repo() {
    local repo_path=$1
    
    cd "$repo_path" || return 1
    
    # Проверка наличия удаленного репозитория
    if ! git remote -v | grep -q "origin"; then
        print_message "$YELLOW" "Репозиторий не имеет remote 'origin'"
        return 1
    fi
    
    # Попытка получить URL
    local remote_url=$(git remote get-url origin)
    
    # Проверка на приватность (по наличию SSH или HTTPS с учетными данными)
    if [[ "$remote_url" =~ ^git@ ]] || [[ "$remote_url" =~ ^https://.*@ ]]; then
        print_message "$YELLOW" "Обнаружен приватный репозиторий"
        return 0
    fi
    
    return 0
}

# Функция для отображения справки
show_help() {
    cat << EOF
Использование: $0 [ОПЦИИ]

Синхронизация содержимого между Git репозиториями

ОПЦИИ:
    -s, --source PATH       Путь к исходному репозиторию
    -d, --dest PATH         Путь к целевому репозиторию
    -p, --push              Выполнить git push в целевом репозитории
    --skip-private          Пропустить приватные репозитории
    --no-pull               Пропустить git pull в исходном репозитории
    --terminal              Запустить в отдельном терминале
    -h, --help              Показать эту справку

ПРИМЕРЫ:
    $0 -s ~/projects/source -d ~/projects/dest
    $0 -s ~/projects/source -d ~/projects/dest -p --skip-private
    $0 --terminal -s ~/projects/source -d ~/projects/dest -p

EOF
}

# Основная функция
main() {
    local source_repo=""
    local dest_repo=""
    local do_push=false
    local skip_private=false
    local skip_pull=false
    local run_in_terminal=false
    
    # Парсинг аргументов
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--source)
                source_repo="$2"
                shift 2
                ;;
            -d|--dest)
                dest_repo="$2"
                shift 2
                ;;
            -p|--push)
                do_push=true
                shift
                ;;
            --skip-private)
                skip_private=true
                shift
                ;;
            --no-pull)
                skip_pull=true
                shift
                ;;
            --terminal)
                run_in_terminal=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_message "$RED" "Неизвестная опция: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Проверка обязательных параметров
    if [[ -z "$source_repo" ]] || [[ -z "$dest_repo" ]]; then
        print_message "$RED" "Ошибка: Необходимо указать source и dest репозитории"
        show_help
        exit 1
    fi
    
    # Запуск в отдельном терминале
    if [[ "$run_in_terminal" == true ]]; then
        local script_path="$0"
        local args="$@"
        
        # Определение терминала
        if [[ -n "$TERM_PROGRAM" ]] || [[ -n "$WT_SESSION" ]]; then
            # Windows Terminal или WSL
            if command -v wt.exe &> /dev/null; then
                wt.exe bash -c "$script_path $args; echo 'Нажмите Enter для выхода...'; read"
                exit 0
            fi
        elif [[ -n "$DISPLAY" ]] && command -v gnome-terminal &> /dev/null; then
            # GNOME Terminal
            gnome-terminal -- bash -c "$script_path $args; echo 'Нажмите Enter для выхода...'; read"
            exit 0
        elif command -v xterm &> /dev/null; then
            # Xterm
            xterm -e "bash -c '$script_path $args; echo \"Нажмите Enter для выхода...\"; read'"
            exit 0
        else
            print_message "$YELLOW" "Не удалось открыть отдельный терминал, продолжаем в текущем"
        fi
    fi
    
    # Проверка путей
    print_message "$BLUE" "=== Начало синхронизации ==="
    
    if ! check_path "$source_repo" "Исходный репозиторий"; then
        exit 1
    fi
    
    if ! check_path "$dest_repo" "Целевой репозиторий"; then
        exit 1
    fi
    
    # Проверка Git репозиториев
    if ! check_git_repo "$source_repo" "Исходный репозиторий"; then
        exit 1
    fi
    
    if ! check_git_repo "$dest_repo" "Целевой репозиторий"; then
        exit 1
    fi
    
    # Проверка приватности (опционально)
    if [[ "$skip_private" == true ]]; then
        if check_private_repo "$source_repo"; then
            print_message "$YELLOW" "Пропуск приватного репозитория"
            exit 0
        fi
    fi
    
    # Синхронизация с удаленным репозиторием
    if [[ "$skip_pull" == false ]]; then
        if ! sync_with_remote "$source_repo" "Исходный репозиторий" false; then
            exit 1
        fi
    fi
    
    # Копирование содержимого
    if ! copy_without_git "$source_repo" "$dest_repo"; then
        exit 1
    fi
    
    # Опциональный push в целевом репозитории
    if [[ "$do_push" == true ]]; then
        if ! sync_with_remote "$dest_repo" "Целевой репозиторий" true; then
            exit 1
        fi
    fi
    
    print_message "$GREEN" "=== Синхронизация успешно завершена ==="
}

# Запуск основной функции
main "$@"