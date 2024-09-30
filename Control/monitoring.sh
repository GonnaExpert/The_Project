#!/bin/bash
#0. Приветствие
clear
echo ''
echo "***** Настраиваем мониторинг *****"
echo ''

#Переменные, где расположена конфига 
#Структура папок  гита
#Имя папки, где будет сделан репо git 
gitDirName='/root/The_Project_git_repo'
typeConfigDirName='Control'
gitTypeDirName=$gitDirName/$typeConfigDirName





#рестартуем сервисы с проверкой
for service in prometheus prometheus-node-exporter grafana-server
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

# вносим изменения в файл конфигурации Прометея

cpFileName='prometheus.yml' 

#1. Копир. файл конфиг вместо имеющегося
#здесь - файл конфиги Прометея yml с настроенными нодами
sourceFile=$gitTypeDirName/$cpFileName
destinDir=/etc/prometheus
destinFile=$destinDir/$cpFileName
description="конфигурация сервера Prometheus"

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
for service in prometheus
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
