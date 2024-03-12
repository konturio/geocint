#!/bin/bash
# $1 - stage - prod, test or dev

# define endpoints
case $1 in
prod)
  auth_endpoint="https://keycloak01.kontur.io/realms/kontur/protocol/openid-connect/token"
  ;;
test)
  auth_endpoint="https://keycloak01.konturlabs.com/realms/test/protocol/openid-connect/token"
  ;;
dev)
  auth_endpoint="https://dev-keycloak.k8s-01.konturlabs.com/realms/dev/protocol/openid-connect/token"
  ;;
*)
  echo "Error. Unsupported realm"
  exit 1
  ;;
esac

# Get token
token_request_content=$(curl -s -d "client_id=kontur_platform&username=$DN_USERNAME&grant_type=password" \
                        --data-urlencode "password=$DN_PASSWORD" \
                        -H "Content-Type: application/x-www-form-urlencoded" \
                        -X POST ${auth_endpoint})
token=$(jq -r '.access_token // empty' <<<"$token_request_content")
if [[ -z "$token" ]]; then
  echo "Error. Impossible to get auth token"
  exit 1
fi

echo "$token"

exit 0