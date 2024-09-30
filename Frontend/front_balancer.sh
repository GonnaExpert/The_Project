#!/bin/bash

#Переменные, где расположена конфига 
#Структура папок  гита
#Имя папки, где будет сделан репо git 
gitDirName='/root/The_Project_git_repo'
typeConfigDirName='Frontend'
gitTypeDirName=$gitDirName/$typeConfigDirName

cpFileName='front_1_to_wikis' 

#0. Приветствие
clear
echo ''
echo "***** Восстанавливаем балансировщик на FRONTEND *****"
echo ''


#1. Копир. файл конфиг в папку конфиг available
#2. Копирую файл конфигурации вместо имеющегося.
#путь к подготовленному и "дефолтному" файлу конфигурации mysqld.cnf МАСТЕР
sourceFile=$gitTypeDirName/$cpFileName
destinDir=/etc/nginx/sites-available
destinFile=$destinDir/$cpFileName
description="конфигурации балансировщика"

if [ -f $destinFile ]
then 
  mv $destinFile $destinFile.bak
fi 

if cp -f $sourceFile $destinFile 
then 
 echo "Изменение $description - OK"
 echo ''
else 
 echo " (!) Изменение $description не прошло"
 echo '!! Скрипт прерывает работу !!'
 exit 12
fi 

#2. Очищаем enabled
rm -f /etc/nginx/sites-enabled/*

#3. Создаем линк на файл в enabled 
ln -s $destinFile /etc/nginx/sites-enabled/$destinFileName

if [ $? -eq 0 ]
  then
      echo "Конфигурация балансировщика подключена  - OK"
      echo '' 
  else
      echo "  (!) Ошибка при создании линка на конфигурацию"
      echo '!! Скрипт прерывает работу !!'
      exit 14
 fi


#4. Проверяем конфигу, если норм - рестартуем nginx
if nginx -t 
then 
   echo ''
   #рестартую nginx сервис.
   for service in nginx
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
else 
      echo " (!) Конфиграция не прошла проверку"
      echo '!! Скрипт прерывает работу !!'
      exit 15
fi  


#5. Проверяем сетев. связность своего срв и двух аплников, доклад

echo 'Проверяем сетевую связность нод по порту 80'
echo '--------------------------------------------' 
if curl 10.0.2.201:80  > /dev/null 2>&1 
 then echo 'Первый аплинк  - OK'
 up1=true  
fi 
if curl 10.0.2.202:80 > /dev/null 2>&1 
 then echo 'Второй аплинк  - OK'
 up2=true
fi  
if curl 10.0.2.203:80 > /dev/null 2>&1 
 then echo 'Балансировщик  - OK'
 up3=true 
fi 

echo ''

if [ "$up1" = true ] &&  [ "$up2" = true ] &&  [ "$up3" = true ] 
then 
  echo 'Связность всех нод - OK'
  echo 'Можно проверять балансировку'  
fi 

#прощание
echo ''
echo '+++ СКРИПТ ВЫПОЛНИЛ ВСЕ ОПЕРАЦИИ И ЗАКОНЧИЛ РАБОТУ +++'
echo ''

