#!/bin/bash
# $1 - prod, test or dev
# $2 - csv file path
# $3 - layer id 
# $4 - layer label
# $5 - layer direction
# $6 - layer isBase
# $7 - layer isPublic
# $8 - layer copyrights
# if properly runned, we have EVENTAPI_USERNAME and EVENTAPI_PASSWORD variable in environment
# define endpoints
case $1 in
prod)
  upload_endpoint="https://prod-insights-api.k8s-01.konturlabs.com/insights-api/indicators/upload"
  auth_endpoint="https://keycloak01.kontur.io/auth/realms/kontur/protocol/openid-connect/token"
  ;;
test)
  upload_endpoint="https://test-insights-api.k8s-01.konturlabs.com/insights-api/indicators/upload"
  auth_endpoint="https://keycloak01.konturlabs.com/auth/realms/test/protocol/openid-connect/token"
  ;;
dev)
  upload_endpoint="https://dev-insights-api.k8s-01.konturlabs.com/insights-api/indicators/upload"
  auth_endpoint="https://keycloak01.konturlabs.com/auth/realms/dev/protocol/openid-connect/token"
  ;;
*)
  echo "Error. Unsupported realm"
  exit 1
  ;;
esac

# Get token
token_request_content=$(curl -d "client_id=kontur_platform&username=${EVENTAPI_USERNAME}&password=${EVENTAPI_PASSWORD}&grant_type=password" -H "Content-Type: application/x-www-form-urlencoded" -X POST ${auth_endpoint})
token=$(jq -r '.access_token // empty' <<<"$token_request_content")
if [[ -z "$token" ]]; then
  echo "Error. Impossible to get auth token"
  exit 1
fi

# Prepare inputs
layer_id="\"$3\""
layer_label="\"$4\""
layer_direction=$5 #$(sed 's/"/\\"/g' <<<"$5")
layer_isbase=$6
layer_ispublic=$7
if [ "$8" == "null" ]; then
  layer_copyrights="null"
else
  layer_copyrights=$8 #(sed 's/"/\\"/g' <<<"$8")
fi

parameters_json="{\"id\": ${layer_id}, \"label\": ${layer_label}, \"direction\": ${layer_direction}, \"isBase\": ${layer_isbase}, \"isPublic\": ${layer_ispublic}, \"copyrights\": ${layer_copyrights}}"
curl_request="curl -w "\":::\"%{http_code}" --location --request POST ${upload_endpoint} --header 'Authorization: Bearer ${token}' --form 'parameters=${parameters_json}' --form 'file=@\"$2\"'"

# Upload file
request_result=$(eval $curl_request)

if [[ -z $request_result ]]; then
  echo "Error. Failed to upload layer"
  exit 1
fi

response_status=$(sed 's/.*:::\(.*\)/\1/' <<< $request_result)

if [ $response_status != 200 ]; then
  echo "Error. Failed to upload layer. Status code: $response_status"
  exit 1
fi

layer_uuid=${request_result::-6}

echo "Layer uploaded succefully. UUID: $layer_uuid"
exit 0