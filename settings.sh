#################################################################
# Global settings which are loaded by all deploy*.sh scripts
#################################################################

KUBERNETES_VERSION="1.15"  # Choose which kubernetes version should be used
KUBLET_VERSION="1.15.11-00"
NAMESPACE="default" # 2020-05-25 Christof: prepared for future versions, not picked up
HOSTNAME="172.20.16.146"
QLIKLICENSE=eyJhbGciOiJSUzUxMiIsInR5cCI6IkpXVCIsImtpZCI6ImEzMzdhZDE3LTk1ODctNGNhOS05M2I3LTBiMmI5ZTNlOWI0OCJ9.eyJqdGkiOiJmYTZhMTc3ZS01MGRiLTRjNDQtOGJiNi04NTBiOTMyOTQ0OGIiLCJsaWNlbnNlIjoiOTk5OTAwMDAwMDAwMTcwNiJ9.P0lyZGMkS40YOQYogr5qGfKoqOoxQoLTjdIHkYfDnH_eeKHjF-qnsFl72D77CAo_aV7OCH5uNez3Idjf8yY9bxuRVmp4h7rE00jK9gdt5-ALyviKjn8n8JhKuWz8u3CtdYXrHt5gocKf2cJqX1xYiV3tlQsadYhIHJQ9k05IqYv1EbBjXEZWHvGHzttzo1RuGhihY64J4hqdbX_P8FWsKj-Eqw0fYQipTkZE8kBkKkWPRVpNEqw_a8GrPkdbUGfC_TlP0BlOvbrgWCsjb-ubkbjqL0k1w8nozfXUMxv98HXVbhW12RXrikf0AY5zFFzMbP0K-t0t5njlq06_XTsZ7Q
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
