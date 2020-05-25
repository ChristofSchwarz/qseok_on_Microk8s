#!/bin/bash
# This script puts a Qlik License for the current tenant using /api/v1/tenants/ZZZ/licenseDefinition
source settings.sh
QLIKTOKEN=$(sudo nodejs createjwt.js $QLIK_ADMIN_USER 1)
# The answer of /api/v1/tenants/me will be a html with a redirect in this format:
# Redirecting to <a href="https://172.20.16.193/api/v1/tenants/ERKF5lOB5yrBP0Go6a2vXBP7Z2rT9nTD"> ...
# need to grep the part between 'tenants/' and '"' and save into variable QLIKTENANT
QLIKTENANT=$(curl -s --insecure -X GET https://$HOSTNAME/api/v1/tenants/me -H "Authorization: Bearer $QLIKTOKEN"|grep -Po 'tenants/\K.*(?=")')
echo "Current hostname is $HOSTNAME"
echo "Current API token is $QLIKTOKEN"
echo "Current tenant is $QLIKTENANT"
curl -X PUT https://$HOSTNAME/api/v1/tenants/$QLIKTENANT/licenseDefinition \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $QLIKTOKEN" \
  --data-raw "{\"key\":\"$QLIKLICENSE\"}" \
  --insecure
echo ""
