#!/bin/bash

LOG_DIR="./test_log"
BACKUP_DIR="./test_backup"

mkdir -p "$LOG_DIR"
mkdir -p "$BACKUP_DIR"

ARCHIVE_SCRIPT="./laba.sh"
MAX_USAGE=${1:-80}
N=${2:-5}

# Создаем директорию tmpfs с ограничением по памяти
MOUNT_POINT="./limited_memory_folder"
mkdir -p "$MOUNT_POINT"

# Монтируем tmpfs с ограничением на 600 Мб
sudo mount -t tmpfs -o size=600M tmpfs $MOUNT_POINT

# Проверяем, удалось ли смонтировать
if [ $? -ne 0 ]; then
    echo "Ошибка: не удалось смонтировать tmpfs."
    exit 1
fi



fill_disk_usage() {
    cd $MOUNT_POINT
    here=$(pwd)
    rm -rf "$LOG_DIR"
    rm -rf "$BACKUP_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$BACKUP_DIR"
    local usage_target=$1
    echo "Filling up to ${usage_target}%..."
    usage=$(df "$here" | awk 'NR==2 {print $5}' | sed 's/%//')
    while true; do
        current_usage=$(df "$here" | awk '{print $5}' | tail -n 1 | tr -d '%')
        if [ "$current_usage" -ge "$usage_target" ]; then
            break
        fi
        dd if=/dev/urandom of="$LOG_DIR/file_$(date +%s%N).bin" bs=5M count=10 status=none
    done
    echo "Usage: $current_usage%"
    cd -
}

#usage is less than threshhold
test_case_1() {
    #rm -rf "$BACKUP_DIR"
    echo "\ntest1"
    fill_disk_usage $(($MAX_USAGE-2))
    bash "$ARCHIVE_SCRIPT" "$LOG_DIR" "$BACKUP_DIR" "$MAX_USAGE" "$N"
    archive_count=$(ls "$BACKUP_DIR" | grep -c "archive_")
    if [ $archive_count -eq 0 ]; then
        echo "Archiving is not needed "
    fi
}


#usage is greater than threshold
test_case_2() {
    echo "\ntest2"
    #rm -rf "$LOG_DIR"
    #rm -rf "$BACKUP_DIR"
    fill_disk_usage $(($MAX_USAGE+2))
    bash "$ARCHIVE_SCRIPT" "$LOG_DIR" "$BACKUP_DIR" "$MAX_USAGE" "$N"
}


#N < 0 test
test_case_3() {
    echo "\ntest3"
    #rm -rf "$LOG_DIR"
    #rm -rf "$BACKUP_DIR"

    fill_disk_usage $(($MAX_USAGE+2))

    bash "$ARCHIVE_SCRIPT" "$LOG_DIR" "$BACKUP_DIR" "$MAX_USAGE" -10
}

# one big and 10 small files
test_case_4() {
    echo "\ntest4"
    #rm -rf "$LOG_DIR"
    #rm -rf "$BACKUP_DIR"
    fill_disk_usage $(($MAX_USAGE+1))
    i=1
    dd if=/dev/zero of="$LOG_DIR/file_big.log" bs=1000M count=1 status=none
    while [ $i -le 10 ]; do
        dd if=/dev/zero of="$LOG_DIR/file_$i.log" bs=25M count=1 status=none
        i=$(( i+1 ))
    done
    bash "$ARCHIVE_SCRIPT" "$LOG_DIR" "$BACKUP_DIR" "$MAX_USAGE" "$N"
}

test_case_1
test_case_2
test_case_3
test_case_4
