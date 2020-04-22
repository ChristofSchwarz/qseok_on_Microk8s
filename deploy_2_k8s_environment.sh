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
# get global settings from file
source settings.sh 
#HOSTNAME="qlik-shared-vm.q-nnect.net" 


###############################################################################
### Add NFS storageClass to Kubernetes
###############################################################################
helm install -n nfs stable/nfs-client-provisioner \
                      --set nfs.server="$(cat /etc/hostname)" \
                      --set nfs.path="/export/k8s" \
                      --set storageClass.name="localnfs"

echo 'Deploy PVC on above storageClass'
cat <<EOF | sudo kubectl apply -f -
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc-qse
  annotations:
    volume.beta.kubernetes.io/storage-class: localnfs
spec:
  storageClassName: localnfs
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
EOF

###############################################################################
### Deploy MongoDB on Kubernetes
###############################################################################
echo 'Creating PVC for MongoDB'
cat <<EOF | sudo kubectl apply -f -
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc-mongo
  annotations:
    volume.beta.kubernetes.io/storage-class: localnfs
spec:
  storageClassName: localnfs
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi

EOF

echo 'Installing MongoDB chart'
cat <<EOF | helm install -n mongo stable/mongodb -f -
persistence:
  enabled: true
  existingClaim: pvc-mongo
usePassword: true
mongodbRootPassword: secretpassword
mongodbUsername: qlik
mongodbPassword: Qlik1234
mongodbDatabase: qsefe
EOF

###############################################################################
### Deploy Keycloak on Kubernetes
###############################################################################
echo "Deploying postgres ..."
cat <<EOF | sudo kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-postgres
  labels:
    app: postgres
spec:
  storageClassName: localnfs
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
EOF

cat <<EOF | sudo kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  labels:
    app: postgres
data:
  POSTGRES_DB: postgresdb
  POSTGRES_USER: pgadmin
  POSTGRES_PASSWORD: pgadmin
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres
          imagePullPolicy: "IfNotPresent"
          ports:
            - containerPort: 5432
          envFrom:
            - configMapRef:
                name: postgres-config
          volumeMounts:
            - mountPath: /var/lib/postgresql/data
              name: postgredb
      volumes:
        - name: postgredb
          persistentVolumeClaim:
            claimName: pvc-postgres
EOF

cat <<EOF | sudo kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: postgres-svc
  labels:
    app: postgres
spec:
  type: ClusterIP
  ports:
    - port: 5432
  selector:
   app: postgres
EOF

echo 'Waiting until postgres is ready ...'
sudo kubectl wait --for=condition=available --timeout=3600s deployment/postgres

echo "Deploying keycloak ..."
cat <<EOF | sudo kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keycloak
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: keycloak
  template:
    metadata:
      labels:
        app: keycloak
    spec:
      volumes:
      - name: syncfolder
        hostPath:
          path: /home/vagrant/keycloak/qliktheme
      containers:
      - name: keycloak
        image: jboss/keycloak:7.0.1
        volumeMounts:
          - name: syncfolder
            mountPath: /opt/jboss/keycloak/themes/qliktheme
        env:
        - name: KEYCLOAK_USER
          value: "$QLIK_ADMIN_USER"
        - name: KEYCLOAK_PASSWORD
          value: "$QLIK_ADMIN_PWD"
        - name: PROXY_ADDRESS_FORWARDING
          value: "true"
        - name: DB_VENDOR
          value: "postgres"
        - name: DB_DATABASE
          value: "postgresdb"
        - name: DB_USER
          value: "pgadmin"
        - name: DB_PASSWORD
          value: "pgadmin"
        - name: DB_ADDR
          value: postgres-svc
        ports:
        - name: http
          containerPort: 8080
        - name: https
          containerPort: 8443
#        readinessProbe:
#          httpGet:
#            path: /auth/realms/master
#            port: 8080
EOF

cat <<EOF | sudo kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: keycloak-svc
  labels:
    app: keycloak
spec:
  ports:
  - name: http
    port: 8080
    targetPort: 8080
    nodePort: 32080
#  - name: https
#    port: 8443
#    targetPort: 8443
#    nodePort: 32083
  selector:
    app: keycloak
  type: NodePort
#  type: LoadBalancer
EOF

echo 'Waiting until keycloak is ready ...'
sudo kubectl wait --for=condition=available --timeout=3600s deployment/keycloak

echo 'Configuring ingress route /auth to Keycloak ...'
cat <<EOF | sudo kubectl apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: keycloak-ingress
  annotations:
    kubernetes.io/ingress.class: qlik-nginx
spec:
  rules:
    - http:
        paths:
          - path: /auth(/|$)(.*)
            backend:
              serviceName: keycloak-svc
              servicePort: 8080
EOF

####################################################################################
### Configure Keycloak using API
####################################################################################

KEYCLOAKURL="http://localhost:32080"

echo "Keycloak should now be ready on $KEYCLOAKURL ..."
until $(curl -s --output /dev/null --connect-timeout 5 --max-time 6 --head --fail $KEYCLOAKURL/auth); do
    echo "waiting for response at $KEYCLOAKURL/auth"
    sleep 5
done
echo 'Keycloak is now ready.'


echo "Get keycloak access_token $KEYCLOAKURL ..."
TKN=$(curl -s \
  -X POST "$KEYCLOAKURL/auth/realms/master/protocol/openid-connect/token" \
  -d "username=$QLIK_ADMIN_USER" \
  -d "password=$QLIK_ADMIN_PWD" \
  -d "client_id=admin-cli" \
  -d "grant_type=password" | jq '.access_token' -r)

#echo "Changing theme to qliktheme"
#curl -s \
#  -X PUT "$KEYCLOAKURL/auth/admin/realms/master" \
#  -H "Authorization: Bearer $TKN" \
#  -H "Content-Type: application/json" \
#  -d '{"loginTheme":"qliktheme"}'

echo "Creating Keycloak Client ..."
# remove newline from .json
#CLIENTJSON=$(tr -d '\r\n' <keycloak-client-settings.json)

curl -s \
  -X POST "$KEYCLOAKURL/auth/admin/realms/master/clients" \
  -H "Authorization: Bearer $TKN" \
  -H "Content-Type: application/json" \
  -d "{ \
        \"clientId\": \"qliklogin\", \
        \"name\": \"Login for Qlik Sense on Kubernetes\",  \
        \"description\": \"\",  \
        \"surrogateAuthRequired\": false,  \
        \"enabled\": true,  \
        \"clientAuthenticatorType\": \"client-secret\",  \
        \"redirectUris\": [  \
            \"https://$HOSTNAME/login/callback\"  \
        ],  \
        \"webOrigins\": [],  \
        \"notBefore\": 0,  \
        \"bearerOnly\": false,  \
        \"consentRequired\": false,  \
        \"standardFlowEnabled\": true,  \
        \"implicitFlowEnabled\": true,  \
        \"directAccessGrantsEnabled\": true,  \
        \"serviceAccountsEnabled\": true,  \
        \"publicClient\": false,  \
        \"frontchannelLogout\": false,  \
        \"protocol\": \"openid-connect\",  \
        \"attributes\": {  \
            \"saml.assertion.signature\": \"false\",  \
            \"saml.force.post.binding\": \"false\",  \
            \"saml.multivalued.roles\": \"false\",  \
            \"saml.encrypt\": \"false\",  \
            \"saml.server.signature\": \"false\",  \
            \"saml.server.signature.keyinfo.ext\": \"false\",  \
            \"exclude.session.state.from.auth.response\": \"false\",  \
            \"saml_force_name_id_format\": \"false\",  \
            \"saml.client.signature\": \"false\",  \
            \"tls.client.certificate.bound.access.tokens\": \"false\",  \
            \"saml.authnstatement\": \"false\",  \
            \"display.on.consent.screen\": \"false\",  \
            \"saml.onetimeuse.condition\": \"false\"  \
        },  \
        \"authenticationFlowBindingOverrides\": {},  \
        \"fullScopeAllowed\": true,  \
        \"nodeReRegistrationTimeout\": -1,  \
        \"protocolMappers\": [  \
            {  \
                \"name\": \"Groups Mapper\",  \
                \"protocol\": \"openid-connect\",  \
                \"protocolMapper\": \"oidc-group-membership-mapper\",  \
                \"consentRequired\": false,  \
                \"config\": {  \
                    \"full.path\": \"false\",  \
                    \"id.token.claim\": \"true\",  \
                    \"access.token.claim\": \"true\",  \
                    \"claim.name\": \"groupmemberships\",  \
                    \"userinfo.token.claim\": \"true\"  \
                }  \
            },  \
            {  \
                \"name\": \"email\",  \
                \"protocol\": \"openid-connect\",  \
                \"protocolMapper\": \"oidc-usermodel-property-mapper\",  \
                \"consentRequired\": false,  \
                \"config\": {  \
                    \"userinfo.token.claim\": \"true\",  \
                    \"user.attribute\": \"email\",  \
                    \"id.token.claim\": \"true\",  \
                    \"access.token.claim\": \"true\",  \
                    \"claim.name\": \"email\",  \
                    \"jsonType.label\": \"String\"  \
                }  \
            }  \
        ],  \
        \"defaultClientScopes\": [  \
            \"web-origins\",  \
            \"role_list\",  \
            \"roles\",  \
            \"profile\",  \
            \"email\"  \
        ],  \
        \"optionalClientScopes\": [  \
            \"address\",  \
            \"phone\",  \
            \"offline_access\",  \
            \"microprofile-jwt\"  \
        ],  \
        \"access\": {  \
            \"view\": true,  \
            \"configure\": true,  \
            \"manage\": true  \
        }  \
    }"
    
echo "get new client's id ..."
# it is using jq library which we installed above.
CLIENTID=$(curl -s \
  -X GET "$KEYCLOAKURL/auth/admin/realms/master/clients?clientId=qliklogin" \
  -H "Authorization: Bearer $TKN" \
 | jq '.[0].id' -r)

echo "Get secret of client $CLIENTID"

CLIENTSECRET=$(curl -s \
  -X GET "$KEYCLOAKURL/auth/admin/realms/master/clients/$CLIENTID/client-secret" \
  -H "Authorization: Bearer $TKN" \
 | jq '.value' -r)

echo "New secret is $CLIENTSECRET"
echo "KEYCLOAKCLIENTSECRET=\"$CLIENTSECRET\"" >>settings.sh

