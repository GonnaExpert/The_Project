#!/bin/bash

#Переменные, где расположена конфига 
#Структура папок  гита
#Имя папки, где будет сдалан репо git 
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
echo "***** Восстанавливаем БД для WIKI на MASTER *****"
echo ''

#Установка московского времени 
timedatectl set-timezone Europe/Moscow
echo 'Установлена единая в инфраструктуре временная зона (Европа, Москва) - Ok'
#проверить  какое сейчас 
echo "Время на $(hostname)" 
date 
echo '' 

#рестартую mysql сервис.

for service in  prometheus-node-exporter mysql 
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
echo "***** Восстанавливаем приложение WIKI на MASTER *****"
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

#прощание
echo ''
echo '+++ СКРИПТ ВЫПОЛНИЛ ВСЕ ОПЕРАЦИИ И ЗАКОНЧИЛ РАБОТУ +++'
echo ''
