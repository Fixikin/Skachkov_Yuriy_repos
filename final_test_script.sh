#!/bin/bash

LOG_DIR="./test_log"
BACKUP_DIR="./test_backup"

mkdir -p "$LOG_DIR"
mkdir -p "$BACKUP_DIR"

ARCHIVE_SCRIPT="./laba.sh"
MAX_USAGE=${1:-55}
N=${2:-5}

if [ -z $1 ] || [ -z $2]; then
    echo "If you want to use your threshold and N-parameter, please enter them as arguments"
    echo "Defaults are: 55% ; N = 5"
fi

#function to create and fill ./log with files
fill_disk_usage() {
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
}

#usage is less than threshhold
test_case_1() {
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
    fill_disk_usage $(($MAX_USAGE+2))
    bash "$ARCHIVE_SCRIPT" "$LOG_DIR" "$BACKUP_DIR" "$MAX_USAGE" "$N"
}


#N < 0 test
test_case_3() {
    echo "\ntest N < 0"
    fill_disk_usage $(($MAX_USAGE+2))

    bash "$ARCHIVE_SCRIPT" "$LOG_DIR" "$BACKUP_DIR" "$MAX_USAGE" -1
}

#threshold (<0 | >100) test
test_case_0() {
    echo "\ntest threshold < 0"
    fill_disk_usage $(($MAX_USAGE+2))

    bash "$ARCHIVE_SCRIPT" "$LOG_DIR" "$BACKUP_DIR" -10 "$N"
}


# one big and 10 small files
test_case_4() {
    echo "\ntest4"
    fill_disk_usage $(($MAX_USAGE+1))
    i=1
    DANGER=91
    echo "Throwing in some more files..."
    dd if=/dev/zero of="$LOG_DIR/file_big.log" bs=100M count=1 status=none
    while [ $i -le 10 ]; do
        dd if=/dev/zero of="$LOG_DIR/file_$i.log" bs=20M count=1 status=none
        i=$(( i+1 ))
        current_usage=$(df "$here" | awk '{print $5}' | tail -n 1 | tr -d '%')
        if [ "$current_usage" -ge "$DANGER" ]; then
            break
        fi

    done
    bash "$ARCHIVE_SCRIPT" "$LOG_DIR" "$BACKUP_DIR" "$MAX_USAGE" "$N"
}

test_case_0
test_case_1
test_case_2
test_case_3
test_case_4
