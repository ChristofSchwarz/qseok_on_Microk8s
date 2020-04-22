# Qlik Sense Enterprise on Micro Kubernetes

**repo built in cooperation with Qlik OEM partner Q-nnect AG, Mannheim/Germany**

Whereas the more wellknown "Minikube" is for test and development purposes, Micro Kubernetes (https://microk8s.io/) is 
an autonomous low-ops Kubernetes for clusters and it works on most flavours of Linux. It can also run on multiple nodes and can scale.

## Edit settings.sh

Before you start the silent install <a href="deploy_all.sh">deploy_all.sh</a>, make sure you reviewed and corrected the 
settings.sh, which will be used throughout the installation processes

The scripts will
 - install a local NFS 
 - Docker
 - Microkubernetes
 - MongoDB
 - Postgres DB 
 - Keycloak Identity Provider
 - QSEoK (Qlik Sense Enterprise on Kubernetes)


