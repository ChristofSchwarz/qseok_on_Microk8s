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
          value: "admin"
        - name: KEYCLOAK_PASSWORD
          value: "admin"
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

