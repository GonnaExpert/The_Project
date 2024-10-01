fileToRemove=/etc/elasticsearch/elasticsearch.yml
if [ -f $fileToRemove ]
 then rm -f $fileToRemove  ;
fi 

systemctl stop elasticsearch.service 
systemctl start elasticsearch.service 

