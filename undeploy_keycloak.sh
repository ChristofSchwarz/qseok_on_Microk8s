#!/bin/bash
while true
do
  read -r -p "Are you sure you want to purge entire Keycloak and Postgres deployment? [Y/n] " input
  case $input in
     [yY]|[yY])
    sudo kubectl delete ingress keycloak-ingress
    sudo kubectl delete svc keycloak-svc
    sudo kubectl delete deployment keycloak
    sudo kubectl delete svc postgres-svc
    sudo kubectl delete deployment postgres
    sudo kubectl delete configmap postgres-config
    sudo kubectl delete pvc pvc-postgres
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
