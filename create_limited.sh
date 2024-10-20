#!/bin/bash

# Создаем директорию tmpfs с ограничением по памяти
MOUNT_POINT="./limited_memory_folder"
mkdir -p "$MOUNT_POINT"

# Монтируем tmpfs с ограничением на 600 Мб
sudo mount -o size=1536M -t tmpfs none $MOUNT_POINT

# Проверяем, удалось ли смонтировать
if [ $? -ne 0 ]; then
    echo "Ошибка: не удалось смонтировать tmpfs."
    exit 1
fi
