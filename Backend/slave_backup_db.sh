#!/bin/bash

#0. Приветствие
clear
echo ''
echo "***** Создание полного бэкапа БД инстанса MySQL *****"
echo ''

#  Проверяю, что сервис mysql запущен
echo "Проверка сервиса mysql"
service=mysql 
ps -afx |  grep -v 'color' |  grep "/usr/sbin/$service" > /dev/null 2>&1 

if [ $? -eq 0 ]
then 
  echo "Cервис $service активен - OK" 
  echo ''
else
   echo " (!) $service не запущен"
	 echo '!! Скрипт прерывает работу !!'
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

echo "--- Ожидание - выгружаем бэкап баз инстанса в  $backdir/$basesBackupFile "
echo ''
mysqldump -uroot -p'$qw12Prj' --set-gtid-purged=OFF  --all-databases > $backdir/$basesBackupFile.sql  2>/dev/null 

if  [ -f $backdir/$basesBackupFile.sql ]
then 
 echo "--- Ожидание - архивируем выгруженные базы и копируем в папку для архивов $arcdir"  
 echo ''
 gzip -cvf -9 $backdir/$basesBackupFile.sql  > $arcdir/$basesBackupFile.gz
 echo ''
else  
  echo 'Не найден файл бэкапа'
fi 

echo 'Последние пять выгрузок бэкапов:'
echo '----------------------------------'
ls -laht $backdir/*.sql  | head -n 5
echo ''

echo 'Последние пять архивов бэкапов:'
echo '----------------------------------'
ls -laht $arcdir/*.gz  | head -n 5
echo '' 

#прощание
echo ''
echo '+++ СКРИПТ ВЫПОЛНИЛ ВСЕ ОПЕРАЦИИ И ЗАКОНЧИЛ РАБОТУ +++'
echo ''


#echo -e '0 */8 * * * команда_на_исполнение' | sudo crontab -
#
#но уже следующее задание или запускалось командой sudo crontab -e, надо добавлять так:
#sudo sh -c "echo '0 */8 * * * команда_на_исполнение' >> /var/spool/cron/crontabs/root"
#и перезапуск cron
#sudo /etc/init.d/cron restart

