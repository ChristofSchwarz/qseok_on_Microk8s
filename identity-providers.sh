#!/bin/bash
# This bash script converts the identity-providers.json file into .yaml format
# It does not output correctly when run with sh, it must run with bash
if [ ${#BASH_VERSION} -gt 0 ]
then
echo "
identity-providers:
  secrets:
    idpConfigs: $(cat identity-providers.json|tr -d '\n'|tr -s ' ')" \
>'~idp.yaml'
echo "written to file ~idp.yaml"
cat '~idp.yaml'
else
echo "It seems that you used sh instead of bash! To run this use bash identity-providers.sh"
fi

