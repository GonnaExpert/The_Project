#!/bin/bash
#!/bin/bash
#0. Приветствие
clear
echo ''
echo "***** Меняем логотип для WIKI на SLAVE для демонстрации балансировки *****"
echo ''

wiki_logo=/var/lib/wikmeup/resources/assets/change-your-logo.svg

new_logo=/root/The_Project_git_repo/Backend/graduate5.svg

if  cp -f $new_logo  $wiki_logo
then 
 echo "Копирование нового логотипа  - OK"
 echo ''
else 
 echo " (!) Копирование логотипа не прошло"
 echo '!! Скрипт прерывает работу !!'
 exit 22
fi 

#прощание
echo ''
echo '+++ СКРИПТ ВЫПОЛНИЛ ВСЕ ОПЕРАЦИИ И ЗАКОНЧИЛ РАБОТУ +++'
echo ''
