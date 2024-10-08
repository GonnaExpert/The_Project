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

#Установка московского времени 
timedatectl set-timezone Europe/Moscow
echo 'Установлена единая в инфраструктуре временная зона (Европа, Москва) - Ok'
#проверить  какое сейчас 
echo "Время на $(hostname)" 
date 
echo '' 


#1. Копир. файл конфиг вместо имеющегося
#здесь - файл конфиги балансировщика в сайтс-эвейлебл nginx
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
   for service in  prometheus-node-exporter nginx
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
 else echo 'Нет связности c первым аплинком - ERROR' 
fi 
if curl 10.0.2.202:80 > /dev/null 2>&1 
 then echo 'Второй аплинк  - OK'
 up2=true
 else echo 'Нет связности cо вторым аплинком - ERROR' 
fi  
if curl 10.0.2.203:80 > /dev/null 2>&1 
 then echo 'Балансировщик  - OK'
 up3=true 
 else echo 'Проблемы с доступом к веб-серверу на этой ноде - ERROR' 
fi 

echo ''

if [ "$up1" = true ] &&  [ "$up2" = true ] &&  [ "$up3" = true ] 
then 
  echo 'Связность всех нод - OK'
  echo 'Можно проверять балансировку'  
else echo 'Обнаружены проблемы с сетевыми подключениями к нодам, требуется их устранение!'
fi 

#прощание
echo ''
echo '+++ СКРИПТ ВЫПОЛНИЛ ВСЕ ОПЕРАЦИИ И ЗАКОНЧИЛ РАБОТУ +++'
echo ''

