fileToRemove=/etc/prometheus/prometheus.yml
if [ -f $fileToRemove ]
 then rm -f $fileToRemove  ;
fi 

systemctl restart prometheus
