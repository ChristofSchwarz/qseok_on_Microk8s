#!/bin/bash
set -xe

###############################################################################
# Qlik-Kubernetes-Deployment
###############################################################################
#
# @author      Matthias Greiner, Christof Schwarz
# @contact     Matthias.Greiner@q-nnect.com, csw@qlik.com
# @link        https://q-nnect.com
# @copyright   Copyright (c) 2008-2020 Q-nnect AG <service@q-nnect.com>
# @license         https://q-nnect.com
#

###############################################################################
# Settings / Parameters
###############################################################################
source settings.sh


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

# create file identity-providers.json
echo "[
    {
        \"hostname\":\"$HOSTNAME\",
        \"discoveryUrl\":\"https://$HOSTNAME/auth/realms/master/.well-known/openid-configuration\",
        \"postLogoutRedirectUri\":\"https://$HOSTNAME/\",
        \"realm\":\"keycloak\",
        \"claimsMapping\":{
            \"groups\":[
                \"groupmemberships\"
            ],
            \"name\":[
                \"name\",
                \"preferred_username\"
            ],
            \"sub\":[
                \"preferred_username\"
            ]
        },
        \"clientId\":\"qliklogin\",
        \"clientSecret\":\"$KEYCLOAKCLIENTSECRET\",
        \"clockToleranceSec\":3660,
        \"primary\":true,
        \"scope\":\"openid profile\"
    },
    {
        \"hostname\":\"$HOSTNAME\",
        \"issuerConfig\":{
            \"issuer\":\"https://qlik.api.internal\"
        },
        \"primary\":false,
        \"realm\":\"keycloak\",
        \"staticKeys\":[
            {
                \"kid\":\"my-key-identifier\",
                \"pem\":\"$(cat certs/public.key | tr "\n" "%" |sed 's/%/\\n/g')\"
            }
        ]
    }
]">identity-providers.json


# Deploy specific version of qlik
# cat <<EOF | helm upgrade --install qlik $QLIK_RELEASE/qliksense --version 1.31.17 -f -

echo "
engine:
  acceptEULA: \"yes\"

global:
  persistence:
    storageClass: localnfs

mongodb:
  uri: mongodb://$MONGO_USER:$MONGO_PWD@mongo-mongodb.default.svc.cluster.local:27017/qsefe?ssl=false

edge-auth:
  config:
    # needed for self-signed certificate
    enforceTLS: false
    secureCookies: false
    
elastic-infra:
  nginx-ingress:
    controller:
      service:
        nodePorts:
          https: 443
        type: NodePort  
" >qliksense.yaml

# Create separate file idp.yaml
echo "
identity-providers:
  secrets:
    idpConfigs: $(cat identity-providers.json|tr -d '\n'|tr -s ' ')
" >'~idp.yaml'

helm upgrade --install qlik $QLIK_RELEASE/qliksense -f qliksense.yaml -f '~idp.yaml'

# in order for Edge-Auth to accept an IPD (Keycloak) over https with a self-signed certificate
# we need to patch its deployment and set environment variable NODE_TLS_REJECT_UNAUTHORIZED=0

sudo kubectl patch deployment qlik-edge-auth -p '{"spec":{"template":{"spec":{"containers":[{"name":"edge-auth", "env":[{"name":"NODE_TLS_REJECT_UNAUTHORIZED","value":"0"}]}]}}}}'
