
#!/bin/bash
#0. Приветствие
clear
echo "***** Начинаем восстановление конфигурации mysql на MASTER *****"
echo ''

#0.5 Переменные, где расположена конфига 
#Структура папок  гита
typeConfigDirName=Backend
gitDirName=/root/The_Project_git_repo
gitTypeDirName=$gitDirName/$typeConfigDirName


# 1. Проверяю, что сервис mysql запущен и и ОК.
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
      exit 21
  fi
else
  echo "Cервис $service не найден в запущенных процессах" 
fi 


#2. Копирую файл конфигурации вместо имеющегося.
#путь к подготовленному и "дефолтному" файлу конфигурации mysqld.cnf МАСТЕР
changed_config=$gitDirName/$typeConfigDirName/mysqld.cnf.master
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
 exit 22
fi 


#2.5. Рестартую mysql сервис.
for service in mysql
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
      exit 26
  fi
done 


#3. Прямо в шелле запускаю команды SQL для настройки репликации
if mysql -uroot -p'$qw12Prj' -sN -e "CREATE USER dbl@'%' IDENTIFIED WITH 'caching_sha2_password' BY 'dem12'" > /dev/null 2>&1 
then 
 echo '' 
 echo "Создание пользователя для репликации - OK"
 echo ''
else 
  echo "Пользователь для репликации не создан"
  echo '!! Скрипт прерывает работу !!'
  exit 23
fi 

if mysql -uroot -p'$qw12Prj' -sN -e "GRANT REPLICATION SLAVE ON *.* TO dbl@'%'; FLUSH PRIVILEGES;" > /dev/null 2>&1 
then 
 echo "Заданы права учетной записи на репликацию  - OK"
 echo ''
else 
  echo "Проблема с назначением прав пользователю на репликацию"
  echo '!! Скрипт прерывает работу !!'
  exit 24
fi 


#5. Рестартую mysql сервис.
for service in mysql
do
  systemctl restart $service
  systemctl status $service | grep active
  echo ''
  if [ $? -eq 0 ]
  then
      echo '' 
  else
      echo " (!) $service не запустился"
	    echo '!! Скрипт прерывает работу !!'
      exit 29
  fi
done
