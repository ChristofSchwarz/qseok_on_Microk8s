#!/bin/bash
source settings.sh
QLIKTOKEN=$(sudo nodejs createjwt.js $QLIK_ADMIN_USER 1)
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
