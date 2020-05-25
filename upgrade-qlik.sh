#!/bin/bash
# This bash script upgrades the helm deployment qlik. It uses the yaml file
# qliksense.yaml and identity-providers.json, which first must be converted into
# a yaml format, too. To do that correctly it must run bash, not with sh
if [ ${#BASH_VERSION} -gt 0 ]
then
source settings.sh
cat <<EOF | sudo helm upgrade qlik $QLIK_RELEASE/qliksense -f qliksense.yaml -f -
identity-providers:
  secrets:
    idpConfigs: $(cat identity-providers.json|tr -d '\n'|tr -s ' ')
EOF
echo 'Maybe you need to restart some pods to pick up new configuration.'
echo 'Try: sh deletepod.sh "auth\|ident"'
else
echo "It seems that you used sh instead of bash! To run this use bash upgrade-qlik.sh"
fi
