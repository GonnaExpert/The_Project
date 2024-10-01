#!/bin/bash
#0. Приветствие
clear
echo ''
echo "***** Настраиваем сервер Elasticsearch *****"
echo ''

#Переменные, где расположена конфига 
#Структура папок  гита
#Имя папки, где будет сделан репо git 
gitDirName='/root/The_Project_git_repo'
typeConfigDirName='Control'
gitTypeDirName=$gitDirName/$typeConfigDirName

#Установка московского времени 
timedatectl set-timezone Europe/Moscow
echo 'Установлена единая в инфраструктуре временная зона (Европа, Москва) - Ok'
#проверить  какое сейчас 
echo "Время на $(hostname)" 
date 
echo '' 


#1. вносим изменения в файл конфигурации Elasticsearch  /etc/elasticsearch/elasticsearch.yml
cpFileName='elasticsearch.yml' 

# Копир. файл конфиг вместо имеющегося
sourceFile=$gitTypeDirName/$cpFileName
destinDir=/etc/elasticsearch
destinFile=$destinDir/$cpFileName
description="конфигурации сервиса Prometheus"
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



#рестартуем сервисы с проверкой
for service in  prometheus-node-exporter elasticsearch 
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

#прощание
echo ''
echo '+++ СКРИПТ ВЫПОЛНИЛ ВСЕ ОПЕРАЦИИ И ЗАКОНЧИЛ РАБОТУ +++'
echo ''
