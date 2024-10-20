#!/bin/bash

#input check
if [ -z $1 ]; then
    echo "Please, enter directory as an argument"
    exit 1
fi
if [ -z $2 ]; then
    echo "Please, enter backup directory as an argument"
    exit 1
fi


dir=$1
backup_dir=$2

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

usage=$(df -h $dir | awk 'NR==2 {print $5}' | sed 's/%//')

#out
echo "Directory $dir storage is $usage percent full."

#threshold input check
if [ -z $3 ]; then
    echo "Percentage threshold not found"
    echo "Default threshold: 70%"
    X=70
else
    X=$3
fi

if [ $X -lt 0 ] || [ $X -gt 100 ]; then
    echo "Percent is integer in segment [0;100]"
    exit 1
fi

#threshhold exceeded check

if [ $usage -le $X ]; then
    echo "Usage $usage% does not exceed threshhold $X%"
    exit 0
fi


#N input check
if [ -z $4 ]; then
    echo "Default quantity of files to archive: N = 7"
    N=3
else
    N=$4
fi
if [ $N -lt 0 ]; then
    echo "N has to be >=0"
    exit 1
fi

echo "Usage $usage% exceeds threshhold $X%. Starting archiving process."

#list of N oldest files in the directory
files=$(ls -1t $dir | tail -n $N)
if [ -z "$files" ]; then
    echo "There are no files to archive in $dir."
    exit 0
fi

#creating archive in /backup directory
archive_path="$backup_dir/log_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf $archive_path -C $dir $files

#archive creation check
if [ $? -eq 0 ]; then
    echo "Archive created successfully: $archive_path"
    #Delete files from dir
    for file in $files; do
        echo "$file"
        rm $dir/$file
    done
    echo "Those files were removed from $dir."
else
    echo "Archive creation error."
    exit 3
fi
exit 0
