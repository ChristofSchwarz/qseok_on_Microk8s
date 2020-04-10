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
QLIK_RELEASE="qlik-stable"
HOSTNAME="qlik-shared-vm.q-nnect.net"
KEYCLOAKCLIENTSECRET=$(cat keycloakclientsecret.txt)  # text file created in deploy_2_
echo "Using Keycloak Client Secret $KEYCLOAKCLIENTSECRET"

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
identity-providers:
  secrets:
    idpConfigs:
      - hostname: "$HOSTNAME"
        realm: "keycloak"
        primary: true
        #discoveryUrl: "http://192.168.56.234:32080/auth/realms/master/.well-known/openid-configuration"
        discoveryUrl: "https://$HOSTNAME/auth/realms/master/.well-known/openid-configuration"
        postLogoutRedirectUri: "https://$HOSTNAME/"
        clientId: "qliklogin"
        clientSecret: "$KEYCLOAKCLIENTSECRET"  # set to the secret you get after creating client in keycloak
        clockToleranceSec: 3660
        scope: "openid profile"
        # useClaimsFromIdToken: true
        claimsMapping:
          name: ["name", "preferred_username"]
          sub: ["preferred_username"]
          groups: ["groupmemberships"]
# the 2nd entry in idpConfigs is for API access using JWT tokens. Not needed for keycloak
#      - hostname: "qlik-shared-vm.q-nnect.net"
#        realm: "keycloak"
#        primary: false
#        issuerConfig:
#          issuer: "https://qlik.api.internal"
#        staticKeys:
#        - kid: "my-key-identifier"
#          # leave "pem :|-" unchanged and as the last line. The public key will added at
#          # the end of this file. If you change anything do it above, not below next line!
#          pem: |-
EOF

# in order for Keycloak to work on https with a self-signed certificate, we need to patch
# edge-auth deployment and set an environment variable NODE_TLS_REJECT_UNAUTHORIZED=0

kubectl patch deployment qlik-edge-auth -p '{"spec":{"template":{"spec":{"containers":[{"name":"edge-auth", "env":[{"name":"NODE_TLS_REJECT_UNAUTHORIZED","value":"0"}]}]}}}}'
