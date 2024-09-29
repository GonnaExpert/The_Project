#!/bin/bash
#  Проверяю, что сервис mysql запущен
service=mysql 
ps -afx |  grep -v 'color' |  grep "/usr/sbin/$service" > /dev/null 2>&1 
if ! [ $? -eq 0 ]
then 
  exit 11
fi 

#строка - метка времени
now=$(date +"%Y-%m-%d-%H-%M-%S")

#имя папки текущего бэкапа 
backdir='/var/mysql_backup'

if ! [ -d $backdir ]
then
   mkdir $backdir
fi 

#имя папки для хранения архивов (может оставаться условно "постоянно" )   
arcdir=$backdir/archives_db

if ! [ -d $arcdir ]
then
   mkdir $arcdir
fi 

basesBackupFile="all_bases_$now" 

mysqldump -uroot -p'$qw12Prj' --set-gtid-purged=OFF  --all-databases > $backdir/$basesBackupFile.sql  2>/dev/null  

if ! [ $? -eq 0 ]
then
    exit 39
fi


if  [ -f $backdir/$basesBackupFile.sql ]
then 
 gzip -cvf -9 $backdir/$basesBackupFile.sql  > $arcdir/$basesBackupFile.gz 
fi 
