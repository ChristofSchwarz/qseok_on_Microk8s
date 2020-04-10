
#!/bin/bash
set -xe

###############################################################################
# Qlik-Kubernetes-Deployment
###############################################################################
#
# @author      Matthias Greiner
# @contact     Matthias.Greiner@q-nnect.com
# @link        https://q-nnect.com
# @copyright   Copyright (c) 2008-2020 Q-nnect AG <service@q-nnect.com>
# @license         https://q-nnect.com
#

###############################################################################
# Settings / Parameters
###############################################################################
source settings.sh

###############################################################################
### Install Docker
###############################################################################
# Install requirements
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Add repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# edge channel for the currently used distro (latest: disco)
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# Install docker package
sudo apt update
sudo apt install -y docker-ce

# Logout and login again to reload group configuration for current user
# (otherwise user will not be able to run docker)

# sudo usermod -aG docker $USER
sudo usermod -aG docker $(getent passwd "1000" | cut -d: -f1)
sudo systemctl enable docker

# Enable insecure registries for kubernetes
sudo /usr/bin/tee "/etc/docker/daemon.json" > /dev/null <<EOF
{
    "insecure-registries" : ["localhost:32000"]
}
EOF
sudo systemctl restart docker

###############################################################################
### Install NFS service for kubernetes local-nfs storage class
###############################################################################

echo 'Prepare local NFS shares'
sudo apt-get -y update && sudo apt-get install -y nfs-kernel-server

# Create NFS shares
sudo mkdir -p /export/k8s
sudo mkdir -p /export/src
sudo chown nobody:nogroup /export/k8s

# backup the old exports file (when a backup exists, append it)
sudo cat /etc/exports | sudo tee -a /etc/exports.bak
sudo /usr/bin/tee "/etc/exports" > /dev/null <<EOF
/export/k8s   *(rw,sync,no_subtree_check,no_root_squash)
/export/src  *(rw,sync,no_subtree_check,no_root_squash)
/export       *(rw,fsid=0,no_subtree_check,sync)
EOF

echo "Starting NFS Kernel server"
sudo service nfs-kernel-server restart

###############################################################################
### Install NodeJS
###############################################################################
# echo "Installing Node JS ..."
# sudo apt-get install nodejs -y
# echo "Installing Node Package Manager npm ..."
# sudo apt-get install npm -y
# echo "Installing Json Query tool 'jq' ..."
# sudo apt-get install jq -y

# mkdir ~/api
# cp -R /vagrant/api/* ~/api
# cd ~/api

# echo "Creating private/public key pair in ~/api folder"
# openssl genrsa -out ~/api/private.key 1024
# openssl rsa -in ~/api/private.key -pubout -out ~/api/public.key

# echo "Installing NodeJS packages fs, jsonwebtoken"
# npm install -g fs
# npm install -g jsonwebtoken

###############################################################################
### Install Kubernetes
###############################################################################

# TODO:
# WARNING:  IPtables FORWARD policy is DROP. Consider enabling traffic forwarding with: sudo iptables -P FORWARD ACCEPT
# The change can be made persistent with: sudo apt-get install iptables-persistent

sudo snap install microk8s --classic --channel=$KUBERNETES_VERSION/stable
sudo microk8s.status --wait-ready

# Allow current user to manage kubernetes cluster
sudo usermod -a -G microk8s $USER

# Enable DNS-Service within kubernetes
sudo microk8s.enable dns
sleep 2
sudo microk8s.status --wait-ready

# Enable Storage-Service within kubernetes
sudo microk8s.enable storage
sudo microk8s.status --wait-ready

# Allow easy access for root and the current user
sudo snap alias microk8s.kubectl kubectl
sudo chown -R $USER:$USER $HOME/.kube
sudo microk8s.kubectl config view --raw | tee $HOME/.kube/config

# Copy the config to allow root to access cluster
sudo mkdir -p /root/.kube
sudo microk8s.kubectl config view --raw | sudo tee /root/.kube/config

# configure kube-api-server
# more info https://microk8s.io/docs/configuring-services
if [ -z "$(sudo cat /var/snap/microk8s/current/args/kube-apiserver | grep -e '--service-node-port-range=80-32767')" ]; then
    echo '--service-node-port-range=80-32767' | sudo tee -a /var/snap/microk8s/current/args/kube-apiserver
fi
sudo systemctl restart snap.microk8s.daemon-apiserver.service
sudo microk8s.status --wait-ready


if [ -z "$(cat ~/.bashrc | grep -e 'source <(kubectl completion bash)')" ]; then
    # source <(kubectl completion bash)
    echo "source <(kubectl completion bash)" >> ~/.bashrc

    # source <(kubectl completion zsh)
    echo "if [ $commands[kubectl] ]; then source <(kubectl completion zsh); fi" >> ~/.zshrc
fi

# Give kubernetes some time to complete installation.
# somethimes helm receives a kubernetes api-access timeout, this attempts to fix it
sleep 10

###############################################################################
### Install Helm
###############################################################################
curl -s https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | sudo bash
helm init --wait --upgrade
helm repo update

###############################################################################
### Install JQ
###############################################################################
# JQ makes life easy with parsing JSON reponses when we'll talk to APIs like
# Keycloak later

sudo apt-get install jq -y

