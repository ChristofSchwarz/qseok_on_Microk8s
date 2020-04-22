#################################################################
# Global settings which are loaded by all deploy*.sh scripts
#################################################################

# Choose which kubernetes version should be used
KUBERNETES_VERSION="1.15"
HOSTNAME="172.20.16.146"
QLIK_RELEASE="qlik-stable" # can be "qlik-stable" or "qlik-edge" 
QLIK_ADMIN_USER="admin"
QLIK_ADMIN_PWD="Qlik1234"

# In the next lines, settings will be automatically added. No need to change.
# for example deploy_2 script will add KEYCLOAKCLIENTSECRET below
