#!/bin/bash
# docker-monitor.sh - пока не работает как надо!

THRESHOLD_CPU=10  # Понизим для теста
THRESHOLD_MEM=10  # Понизим для теста
LOG_FILE="alerts.log"

echo "🔍 Мониторинг Docker контейнеров"
echo "📊 Пороги: CPU > ${THRESHOLD_CPU}%, MEM > ${THRESHOLD_MEM}%"
echo "📝 Логи: $LOG_FILE"
echo "⏰ Интервал: 10 секунд"
echo "🛑 Остановка: Ctrl+C"
echo "========================================"

# Создаем лог файл
touch "$LOG_FILE"

# Функция для обработки Ctrl+C
cleanup() {
    echo -e "\n\n👋 Остановка мониторинга..."
    echo "📁 Лог файл: $LOG_FILE"
    exit 0
}

trap cleanup INT TERM

while true; do
    # Получаем текущее время
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Получаем статистику
    docker stats --no-stream --format "{{.Name}}|{{.CPUPerc}}|{{.MemPerc}}" 2>/dev/null | \
    sed 's/%//g' | \
    while IFS='|' read -r name cpu mem; do
        # Пропускаем заголовки и пустые строки
        if [[ -z "$name" ]] || [[ "$name" == "NAME" ]]; then
            continue
        fi

        # Проверяем CPU
        if (( $(echo "$cpu > $THRESHOLD_CPU" | bc -l 2>/dev/null) )); then
            echo "[$timestamp] ⚠️  CPU: $name - ${cpu}%"
            echo "[$timestamp] CPU ALERT: $name - ${cpu}%" >> "$LOG_FILE"
        fi

        # Проверяем память
        if (( $(echo "$mem > $THRESHOLD_MEM" | bc -l 2>/dev/null) )); then
            echo "[$timestamp] ⚠️  MEM: $name - ${mem}%"
            echo "[$timestamp] MEM ALERT: $name - ${mem}%" >> "$LOG_FILE"
        fi
    done

    # Прогресс бар
    echo -n "."
    sleep 10
done