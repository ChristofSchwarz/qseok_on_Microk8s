#################################################################
# Global settings which are loaded by all deploy*.sh scripts
#################################################################

KUBERNETES_VERSION="1.15"  # Choose which kubernetes version should be used
#KUBLET_VERSION="1.15.11-00"
NAMESPACE="default" # 2020-05-25 Christof: prepared for future versions, not picked up
HOSTNAME="172.20.16.146"
QLIK_LICENSE=eyZZZ.eyZZZ.ZZZ
QLIK_RELEASE="qlik-stable"  # can be "qlik-stable" or "qlik-edge" 
QLIK_ADMIN_USER="admin"
QLIK_ADMIN_PWD="Qlik1234"
MONGO_USER="qlik"
MONGO_PWD="Qlik1234"
MONGO_ROOT_PWD="secretpassword"
POSTGRES_USER="pgadmin"
POSTGRES_PWD="pgadmin"

# In the next lines, settings will be automatically added. No need to change.
# for example deploy_2 script will add KEYCLOAKCLIENTSECRET below
