#!/bin/bash



#input check
if [ -z $1 ]; then
    echo "Please, enter directory as an argument"
    exit 1
fi

dir = $1
backup_dir = "./backup"

#/log directory existence check
if [ ! -d $dir ]; then
    echo "Directory $dir does not exist."
    exit 2
fi

#/backup directory existence check
if [ ! -d $backup_dir ]; then
    echo "Directory $backup_dir does not exist."
    exit 2
fi

usage = $(df -h $dir | awk 'NR==2 {print $5}' | sed 's/%//')

#out
echo "Directory $dir storage is $usage percent full."

#threshold input check
if [ -z $2 ]; then
    echo "Percentage threshold not found"
    echo "Default threshold: 70%"
    X=70
else
    X=$2
fi

#threshhold exceeded check
if [ $usage -le $X ]; then
    echo "Usage $usage% does not exceed threshhold $X%
    exit 0
fi

echo "Usage $usage% exceeds threshhold $X%. Starting archiving process."

#N input check
if [ -z $3 ]; then
    echo "Did not find how many files to archive."
    echo "Default quantity: 5 files."
    N = 5
else
    N = $2
fi

#list of N oldest files in the directory
files = $(ls -1t $dir | tail -n $N)
if [ -z $files ]; then
    echo "There are no files to archive in $dir."
    exit 0
fi

#creating archive in /backup directory
archive_path = "$backup_dir/log_backup_$(date +%Y%m%d_%H%M%S).tar.gz
tar -czf $archive_path -C $dir $files

#archive creation check
if [ $?-eq 0 ]; then
    echo "Archive created successfully: $archive_path"
    #Delete files from dir
    for file in $files; do
        rm $dir/$file
    done
    echo "Files are removed from $dir."
else
    echo "Archive creation error."
    exit 3
fi

exit 0
