# Qlik Sense Enterprise on MicroK8s/Ubuntu

**repo built in cooperation with Qlik OEM partner <a href="https://www.q-nnect.com/en/index.html>Q-nnect AG, Mannheim/Germany</a>**

Whereas the more wellknown "Minikube" is for test and development purposes, Micro Kubernetes (https://microk8s.io/) is 
an autonomous low-ops Kubernetes for clusters and it works on most flavours of Linux. It can also run on multiple nodes and can scale.

## Purpose

The scripts will
 - install a local NFS (Network Filesystem)
 - Docker Community Edition
 - MicroK8s
 - MongoDB Community Edition
 - A local identity provider (Keycloak https://www.keycloak.org/) and Postgres for persistance
 - QSEoK (Qlik Sense Enterprise on Kubernetes)

## Installation 

 - To get it run `git clone https://github.com/ChristofSchwarz/qseok_on_Microk8s`
 - To launch it go to `cd qseok_on_Microk8s/` 
 - Make sure you edit the `settings.sh` file to match your system.
 - Then run `sudo bash deploy_all.sh`
 
 

