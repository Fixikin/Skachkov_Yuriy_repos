#!/bin/bash


LOG_DIR="../log"
BACKUP_DIR="./backup"
ARCHIVE_SCRIPT="./my_script.sh"
MAX_USAGE=${1:-80}
N=${2:-5}

#echo $MAX_USAGE
#echo $N


fill_disk_usage() {
local usage_target=$1
echo "Заполнение до ${usage_target}%..."
while [ "$(df -h | awk 'NR==3 {print $5}' | sed 's/%//')" -lt "$usage_target" ]; do
dd if=/dev/zero of="$LOG_DIR/file_$(date +%s).log" bs=100M count=1 status=none
done
echo "Текущая заполненность - $(df -h | awk 'NR==3 {print $5}')"
} 


# проверяем, что при заполнении папки на 75% архивация не происходит
test_case_1() {
rm -rf "$LOG_DIR"/* "$BACKUP_DIR"/*

fill_disk_usage 75


bash "$ARCHIVE_SCRIPT" "$LOG_DIR" "$MAX_USAGE" "$N"

archive_count=$(ls "$BACKUP_DIR" | grep -c "archive_")
if [ $archive_count -eq 0 ]; then
echo "архив не был создан "
else
echo "архив был создан почему-то "
fi
} 


# проверяем, что при заполнении папки на 80-85% архивация происходит
test_case_2() {

rm -rf "$LOG_DIR"/* "$BACKUP_DIR"/*


fill_disk_usage $(($MAX_USAGE+2)) 

bash "$ARCHIVE_SCRIPT" "$LOG_DIR" "$MAX_USAGE" "$N"

archive_count=$(ls "$BACKUP_DIR" | grep -c "archive_")
if [ $archive_count -gt 0 ]; then
echo "архив был создан"
else
echo "архив не был создан"
fi
}


# проверяем, что архивируются N самых старых файлов
test_case_3() {
rm -rf "$LOG_DIR"/* "$BACKUP_DIR"/*


touch -t 202201010101 "$LOG_DIR/old_file_1.log"
touch -t 202202010101 "$LOG_DIR/old_file_2.log"
touch -t 202203010101 "$LOG_DIR/old_file_3.log"

fill_disk_usage $(($MAX_USAGE+2)) 

bash "$ARCHIVE_SCRIPT" "$LOG_DIR" "$MAX_USAGE" "$N"

}


# создаю один большой и несколько маленьких
test_case_4() {
rm -rf "$LOG_DIR"/* "$BACKUP_DIR"/*


dd if=/dev/zero of="$LOG_DIR/file_big.log" bs=1500M count=1 status=none
for i in {1..10}; do
dd if=/dev/zero of="$LOG_DIR/file_$i.log" bs=100M count=1 status=none 
done

fill_disk_usage $(($MAX_USAGE+4))

bash "$ARCHIVE_SCRIPT" "$LOG_DIR" "$MAX_USAGE" "$N"



}

test_case_1
test_case_2
test_case_3
test_case_4
