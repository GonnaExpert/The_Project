#!/bin/bash

#Переменные, где расположена конфига 
#Структура папок  гита
#Имя папки, где будет сдалан репо git 
gitDirName=/root/The_Project_git_repo
typeConfigDirName=Backend
gitTypeDirName=$gitDirName/$typeConfigDirName

dir_app='/var/lib/wikmeup'
dir_site='/var/www/html'
link_site='/var/www/html/wikmeup'
config_app_file='LocalSettings.php' 
config_app_git=$gitTypeDirName/$config_app_file
config_app_work=$dir_app/$config_app_file

#0. Приветствие
clear
echo "***** Восстанавливаем БД для WIKI на MASTER *****"
echo ''

echo 'ТУТ БУДЕТ КРУТАНСКОЕ ВОССТАНОВЛЕНИЕ БД'

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
   exit 21
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
   exit 22
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
      exit 21
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
   exit 22
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
      exit 23
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
      exit 26
  fi
done 


## 1.  Проверяю, если сервис mysql запущен, останавливаю его
#echo "Проверка сервиса mysql"
#service=mysql 
#ps -afx |  grep -v 'color' |  grep "/usr/sbin/$service" > /dev/null 2>&1 
#
#if [ $? -eq 0 ]
#then 
#  echo "Cервис $service активен" 
#  systemctl stop $service
#  if [ $? -eq 0 ]
#  then
#      echo "Остановка $service - OK"
#      echo '' 
#  else
#      echo " (!) $service не остановлен"
#	    echo '!! Скрипт прерывает работу !!'
#      exit 21
#  fi
#else
#  echo "Cервис $service не найден в запущенных процессах" 
#fi 
#
#
##2. Копирую файл конфигурации вместо имеющегося.
##путь к подготовленному и "дефолтному" файлу конфигурации mysqld.cnf МАСТЕР
#changed_config=$gitDirName/$typeConfigDirName/mysqld.cnf.master
#origin_config=/etc/mysql/mysql.conf.d/mysqld.cnf
#description_config="конфигурации mysql MASTER"
#
#mv $origin_config $origin_config.bak
#if cp -f $changed_config $origin_config
#then 
# echo "Изменение $description_config - OK"
# echo ''
#else 
# echo " (!) Изменение $description_config не прошло"
# echo '!! Скрипт прерывает работу !!'
# exit 22
#fi 
#
#
##2.5. Рестартую mysql сервис.
#for service in mysql
#do
#  systemctl restart $service
#  systemctl status $service | grep active > /dev/null 2>&1 
#  if [ $? -eq 0 ]
#  then
#      echo "Рестарт $service - OK"
#      echo '' 
#  else
#      echo " (!) $service не запустился"
#	    echo '!! Скрипт прерывает работу !!'
#      exit 26
#  fi
#done 
#
#
##3. Прямо в шелле запускаю команды SQL для настройки репликации
#if mysql -uroot -p'$qw12Prj' -e "CREATE USER dbl@'%' IDENTIFIED WITH 'caching_sha2_password' BY 'dem12'" > /dev/null 2>&1 
#then 
# echo '' 
# echo "Создание пользователя для репликации - OK"
# echo ''
#else 
#  echo "Пользователь для репликации не создан"
#  echo '!! Скрипт прерывает работу !!'
#  exit 23
#fi 
#
#if mysql -uroot -p'$qw12Prj' -e "GRANT REPLICATION SLAVE ON *.* TO dbl@'%'; FLUSH PRIVILEGES;" > /dev/null 2>&1 
#then 
# echo "Заданы права учетной записи на репликацию  - OK"
# echo ''
#else 
#  echo "Проблема с назначением прав пользователю на репликацию"
#  echo '!! Скрипт прерывает работу !!'
#  exit 24
#fi 
#
#
##5. Рестартую mysql сервис.
#for service in mysql
#do
#  systemctl restart $service
#  if [ $? -eq 0 ]
#  then
#      echo '' 
#  else
#      echo " (!) $service не запустился"
#	    echo '!! Скрипт прерывает работу !!'
#      exit 29
#  fi
#done
