#!/bin/bash

#Переменные, где расположена конфига 
#Структура папок  гита
#Имя папки, где будет сдалан репо git 
gitDirName='/root/The_Project_git_repo'
typeConfigDirName='Backend'
gitTypeDirName=$gitDirName/$typeConfigDirName

#Приветствие
clear
echo ''
echo "***** Настраиваем репликацию на MASTER *****"
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
      exit 11
  fi
else
  echo "Cервис $service не найден в запущенных процессах" 
fi 


#2. Копирую файл конфигурации вместо имеющегося.
#путь к подготовленному и "дефолтному" файлу конфигурации mysqld.cnf МАСТЕР
changed_config=$gitTypeDirName/mysqld.cnf.master
origin_config=/etc/mysql/mysql.conf.d/mysqld.cnf
description_config="конфигурации mysql MASTER"

mv $origin_config $origin_config.bak
if cp -f $changed_config $origin_config
then 
 echo "Изменение $description_config - OK"
 echo ''
else 
 echo " (!) Изменение $description_config не прошло"
 echo '!! Скрипт прерывает работу !!'
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


#3. Прямо в шелле запускаю команды SQL для настройки репликации
if mysql -uroot -p'$qw12Prj' -e "CREATE USER dbl@'%' IDENTIFIED WITH 'caching_sha2_password' BY 'dem12'" > /dev/null 2>&1 
then 
 echo '' 
 echo "Создание пользователя для репликации - OK"
 echo ''
else 
  echo "Пользователь для репликации не создан"
  echo '!! Скрипт прерывает работу !!'
  exit 21
fi 

if mysql -uroot -p'$qw12Prj' -e "GRANT REPLICATION SLAVE ON *.* TO dbl@'%'; FLUSH PRIVILEGES;" > /dev/null 2>&1 
then 
 echo "Заданы права учетной записи на репликацию  - OK"
 echo ''
else 
  echo "Проблема с назначением прав пользователю на репликацию"
  echo '!! Скрипт прерывает работу !!'
  exit 22
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

#прощание
echo ''
echo '+++ СКРИПТ ВЫПОЛНИЛ ВСЕ ОПЕРАЦИИ И ЗАКОНЧИЛ РАБОТУ +++'
echo ''
