#!/bin/bash

#Переменные, где расположена конфига 
#Структура папок  гита
#Имя папки, где будет сделан репо git 
gitDirName='/root/The_Project_git_repo'
typeConfigDirName='Backend'
gitTypeDirName=$gitDirName/$typeConfigDirName

basesBackupFile='all-bases-origin.sql' 

dir_app='/var/lib/wikmeup'
dir_site='/var/www/html'
link_site='/var/www/html/wikmeup'
config_app_file='LocalSettings.php' 
config_app_git=$gitTypeDirName/$config_app_file
config_app_work=$dir_app/$config_app_file

#0. Приветствие
clear
echo ''
echo "***** Восстанавливаем БД для WIKI на SLAVE *****"
echo ''

#рестартую mysql сервис.
for service in mysql
do
  echo "--- Ожидание - рестарт $service"
  echo ''
  systemctl restart $service
  systemctl status $service | grep active > /dev/null 2>&1 
  if [ $? -eq 0 ]
  then
      echo "Рестарт $service - OK"
      echo '' 
  else
      echo " (!) $service не запустился"
	    echo '!! Скрипт прерывает работу !!'
      exit 11
  fi
done 

#восстанавливаю базу из бэкапа 
echo "--- Ожидание - восстанавливаем БД из бэкапа $basesBackupFile"
echo ''
mysql -uroot -p'$qw12Prj' < $gitTypeDirName/$basesBackupFile > /dev/null 2>&1 

#если код возврата 0 - доклад, что база воссатновлена, если ошибка - прервать скрипт 
if [ $? -eq 0 ]
then
      echo "Восстановление БД инстанса MySQL  - OK"
      echo '' 
else
    echo "(!) База не восстановилась "
	  echo 'Скрипт прерывает работу!'
      exit 12
fi


#рестартую mysql сервис.
for service in mysql
do
  echo "--- Ожидание - рестарт $service"
  echo ''
  systemctl restart $service
  systemctl status $service | grep active > /dev/null 2>&1 
  if [ $? -eq 0 ]
  then
      echo "Рестарт $service - OK"
      echo '' 
  else
      echo " (!) $service не запустился"
	    echo '!! Скрипт прерывает работу !!'
      exit 14
  fi
done 


echo '' 
echo "***** Восстанавливаем приложение WIKI на SLAVE *****"
echo ''


#проверка, существует ли  папка приложен. , если нет - доклад  и прерывание 
if  [ -d $dir_app ]
then
   echo "Директория приложения WIKI $dir_app - OK"
   echo ''
else    
   echo "! Директория WIKI  $dir_app не найдена ! "
   echo 'Скрипт прерывает работу!'
   exit 15
fi


#копируем конфигу приложения
if [ -f $config_app_work ]
then 
  mv $config_app_work $config_app_work.bak
fi 

if cp $config_app_git $config_app_work 
  then 
    echo "Конфигурация приложения WIKI  - OK"
    echo ''
  else    
   echo "! Конфигрурация приложения не перенесена! "
   echo 'Скрипт прерывает работу!'
   exit 16
fi


# проверяю, если сервис apache2 запущен, останавливаю его
echo "Проверка сервиса mysql"
service=apache2 
ps -afx |  grep -v 'color' |  grep "/usr/sbin/$service" > /dev/null 2>&1 

if [ $? -eq 0 ]
then 
  echo "Cервис $service активен" 
  systemctl stop $service
  if [ $? -eq 0 ]
  then
      echo "Остановка $service - OK"
      echo '' 
  else
      echo " (!) $service не остановлен"
	    echo '!! Скрипт прерывает работу !!'
      exit 17
  fi
else
  echo "Cервис $service не найден в запущенных процессах" 
fi

#проверка, существует ли папка сайта, если нет - доклад  и прерывание 
if  [ -d $dir_site ]
then
   echo "Директория виртуального сервера Appache $dir_site - OK"
   echo ''
else    
   echo "! Директория сайта Appache  $dir_site не найдена ! "
   echo 'Скрипт прерывает работу!'
   exit 18
fi

#очистим дир сайта 
rm -rf $dir_site/*


#создаем софтлинк для приложения к веб-серверу 
ln -s /var/lib/wikmeup/ /var/www/html/wikmeup

#если код возврата 0 - доклад, что ссылка сделана, если ошибка - прервать скрипт 
if [ $? -eq 0 ]
then
      echo "Приложение подключено к web-серверу  - OK"
      echo '' 
else
      echo "! Софтлинк не создан ! "
	  echo 'Скрипт прерывает работу!'
      exit 19
fi

#рестартую apache2 сервис.
for service in apache2
do
  systemctl restart $service
  systemctl status $service | grep active > /dev/null 2>&1 
  if [ $? -eq 0 ]
  then
      echo "Рестарт $service - OK"
      echo '' 
  else
      echo " (!) $service не запустился"
	    echo '!! Скрипт прерывает работу !!'
      exit 22
  fi
done 


#Приветствие репликации 
echo ''
echo "***** Настраиваем репликацию на SLAVE *****"
echo ''

# 1.  Проверяю, если сервис mysql запущен, останавливаю его
echo "Проверка сервиса mysql"
service=mysql 
ps -afx |  grep -v 'color' |  grep "/usr/sbin/$service" > /dev/null 2>&1 

if [ $? -eq 0 ]
then 
  echo "Cервис $service активен" 
  systemctl stop $service
  if [ $? -eq 0 ]
  then
      echo "Остановка $service - OK"
      echo '' 
  else
      echo " (!) $service не остановлен"
	    echo '!! Скрипт прерывает работу !!'
      exit 31
  fi
else
  echo "Cервис $service не найден в запущенных процессах" 
fi 

#1.5 удаляю файл с UUID инстанса, столько раз всего клонировалось, что уже и не вспомню
mv  /var/lib/mysql/auto.cnf  /var/lib/mysql/auto.cnf.bak
  if [ $? -eq 0 ]
  then
      echo "Удалил старый UUID инстанса - OK"
      echo '' 
  else
      echo " (!) старый UUID не удалился"
	    echo '!! Скрипт прерывает работу !!'
      exit 33
  fi


#2. Копирую файл конфигурации вместо имеющегося.
#путь к подготовленному и "дефолтному" файлу конфигурации mysqld.cnf SLAVE
changed_config=$gitTypeDirName/mysqld.cnf.slave
origin_config=/etc/mysql/mysql.conf.d/mysqld.cnf
description_config="конфигурации mysql SLAVE"

mv $origin_config $origin_config.bak
if cp -f $changed_config $origin_config
then 
 echo "Изменение $description_config - OK"
 echo ''
else 
 echo " (!) Изменение $description_config не прошло"
 echo '!! Скрипт прерывает работу !!'
 exit 34
fi 


#рестартую mysql сервис.
for service in mysql
do
  echo "--- Ожидание - рестарт $service"
  echo ''
  systemctl restart $service
  systemctl status $service | grep active > /dev/null 2>&1 
  if [ $? -eq 0 ]
  then
      echo "Рестарт $service - OK"
      echo '' 
  else
      echo " (!) $service не запустился"
	    echo '!! Скрипт прерывает работу !!'
      exit 35
  fi
done 


##4. Прямо в шелле запускаю команды SQL для настройки репликации
if mysql -uroot -p'$qw12Prj' -e "stop replica; reset replica all;" > /dev/null 2>&1 
then 
 echo "Остановка и сброс настроек репликации - OK"
 echo ''
else 
  echo "Проблема с остановкой репликации"
  echo '!! Скрипт прерывает работу !!'
  exit 36
fi 


if mysql -uroot -p'$qw12Prj' -e "CHANGE REPLICATION SOURCE TO SOURCE_HOST='10.0.2.201', SOURCE_USER='dbl', SOURCE_PASSWORD='dem12',  SOURCE_AUTO_POSITION = 1, GET_SOURCE_PUBLIC_KEY = 1;" > /dev/null 2>&1 
then 
 echo "Назначение источника репликации - OK"
 echo ''
else 
  echo "Проблема с назначением источника репликации"
  echo '!! Скрипт прерывает работу !!'
  exit 37
fi 

if mysql -uroot -p'$qw12Prj' -e "start replica;" > /dev/null 2>&1 
then 
 echo "Запуск репликации - OK"
 echo ''
else 
  echo "Проблема с запуском репликации"
  echo '!! Скрипт прерывает работу !!'
  exit 38
fi 

echo 'Просмотр ошибок репликации:'
echo '---------------------------'
mysql -uroot -p'$qw12Prj' -e "SHOW REPLICA STATUS \G" > /root/DEPLOY/rep_status.txt
grep -i 'err'  /root/DEPLOY/rep_status.txt
echo '' 


#рестартую mysql сервис.
for service in mysql
do
  echo "--- Ожидание - рестарт $service"
  echo ''
  systemctl restart $service
  systemctl status $service | grep active > /dev/null 2>&1 
  if [ $? -eq 0 ]
  then
      echo "Рестарт $service - OK"
      echo '' 
  else
      echo " (!) $service не запустился"
	    echo '!! Скрипт прерывает работу !!'
      exit 39
  fi
done 

#Приветствие
echo ''
echo "***** Настраиваем задания cron для регулярного бэкапа БД на SLAVE *****"
echo ''

# проверяем кронтаб на возможные наши старые джобы по работе с бэкапом 
grep -i 'slave' /etc/crontab  > /dev/null 2>&1 

if  [ $? -eq 0 ]
then
 echo 'Удаление  старой записи с заданием для бэкапа - OK' 
 echo '' 
 sed -i '/slave/d' /etc/crontab 
fi

#создаем папку для хранения скрипта 
if  ! [ -d  /var/jobs]
then 
 mkdir /var/jobs
fi   

#добавляем задание - раз в три минуты делаем бэкап
if cp $gitTypeDirName/slave_backup_db_cron.sh /var/jobs/
then 
  echo 'Перенос скрипта автоматического бэкап - OK'
  echo ''
  echo -e  "*/3 *  *  *   *  root    /var/jobs/slave_backup_db_cron.sh" >> /etc/crontab
  if  [ $? -eq 0 ]
  then
   echo 'Добаваление новой записи задания для бэкапа в crontab - OK   '  
   echo ''
  else 
    echo " (!) Задание добавить не получилось"
    echo '!! Скрипт прерывает работу !!'
    exit 10
   fi
else
    echo " (!) Отсутствует файл для выплонения задания"
	 echo '!! Скрипт прерывает работу !!'
    exit 11
fi 

#рестартую cron сервис.
for service in cron
do
  echo "--- Ожидание - рестарт $service"
  echo ''
  systemctl restart $service
  systemctl status $service | grep active > /dev/null 2>&1 
  if [ $? -eq 0 ]
  then
      echo "Рестарт $service - OK"
      echo '' 
  else
      echo " (!) $service не запустился"
	    echo '!! Скрипт прерывает работу !!'
      exit 12
  fi
done 

#Визуальный контроль
echo 'Добавлены следующие строки заданий:'
echo '-----------------------------------'
grep -i 'slave' /etc/crontab 


#прощание
echo ''
echo '+++ СКРИПТ ВЫПОЛНИЛ ВСЕ ОПЕРАЦИИ И ЗАКОНЧИЛ РАБОТУ +++'
echo ''
