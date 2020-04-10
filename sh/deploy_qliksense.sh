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
# Select release (qlik-stable or qlik-edge)
QLIK_RELEASE="qlik-edge"

###############################################################################
### Deploy Qliksense
###############################################################################

echo 'Adding stable and edge repo from qlik.bintray.com'
helm repo add qlik-stable https://qlik.bintray.com/stable
helm repo add qlik-edge https://qlik.bintray.com/edge
helm init
helm repo update

echo "installing qliksense-init from $QLIK_RELEASE repo using helm ..."
helm upgrade --install qlikinit "$QLIK_RELEASE/qliksense-init"

# Deploy specific version of qlik
# cat <<EOF | helm upgrade --install qlik $QLIK_RELEASE/qliksense --version 1.31.17 -f -

cat <<EOF | helm upgrade --install qlik $QLIK_RELEASE/qliksense -f -
# This yaml starts qlik-sense with the built-in simple-oidc provider
# To use it, you must connect to qlik sense with hostname elastic.example ...
# update your hosts. and add this line (without the hash#)
# 192.168.56.234 elastic.example

engine:
  acceptEULA: "yes"

global:
  persistence:
    storageClass: localnfs

mongodb:
  uri: mongodb://qlik:Qlik1234@mongo-mongodb.default.svc.cluster.local:27017/qsefe?ssl=false

edge-auth:
  oidc:
    # next line: true = use built-in simple-oidc, false = use IDP
    enabled: true
    redirectUri: https://elastic.example/login/callback
#    redirectUri: https://elastic.example:32443/login/callback

elastic-infra:
  nginx-ingress:
    controller:
      service:
        type: NodePort
        nodePorts:
          https: 443
#          https: 32443
      extraArgs.report-node-internal-ip-address: ""

hub:
  ingress:
    annotations:
      nginx.ingress.kubernetes.io/auth-signin: https://$host/login?returnto=$request_uri

management-console:
  ingress:
    annotations:
      nginx.ingress.kubernetes.io/auth-signin: https://$host/login?returnto=$request_uri
EOF

