#!/bin/bash
while true
do
  read -r -p "Are you sure you want to purge entire qlik deployment? [Y/n] " input
  case $input in
     [yY]|[yY])
    helm delete qlik --purge
    sudo kubectl delete pvc redis-data-qlik-dcaas-redis-master-0
    sudo kubectl delete pvc redis-data-qlik-redis-master-0
    sudo kubectl delete pvc redis-data-qlik-redis-user-state-master-0
    sudo kubectl delete pvc redis-data-qlik-redis-user-state-slave-0
    sudo kubectl delete pvc redis-data-qlik-redis-user-state-slave-1
    break
    ;;
     [nN]|[nN])
    break
        ;;
    *)
    echo "Invalid input..."
   ;;
  esac
done
