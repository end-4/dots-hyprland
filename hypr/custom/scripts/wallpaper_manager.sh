#!/bin/bash

# Путь к вашему основному скрипту восстановления обоев
RESTORE_SCRIPT="$HOME/.config/hypr/custom/scripts/__restore_video_wallpaper.sh"

# Бесконечный цикл
while true; do
    # Запускаем скрипт установки обоев в фоновом режиме
    # Убеждаемся, что он существует и является исполняемым
    if [ -x "$RESTORE_SCRIPT" ]; then
        bash "$RESTORE_SCRIPT" &
    else
        # Если скрипта нет, выходим из цикла, чтобы не создавать лишнюю нагрузку
        exit 1
    fi
    
    # Ждем 30 минут (1800 секунд)
    sleep 1800
    
    # Принудительно завершаем все процессы mpvpaper перед следующим запуском
    pkill -f -9 mpvpaper || true
done