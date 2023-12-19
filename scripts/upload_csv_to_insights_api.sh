#!/bin/bash
# $1 - prod, test or dev
# $2 - csv file path (data/trees.csv)
# $3 - layer id ("trees")
# $4 - layer label ("layer with trees")
# $5 - layer direction ("[[\"neutral\"], [\"neutral\"]]")
# $6 - layer isBase (true)
# $7 - layer isPublic (false)
# $8 - layer copyrights ("[\"Kontur.io\",\"OSM Contributors\"]")
# $9 - layer description ("very cool trees layer produced by Kontur")
# $10 - layer coverage ("World")
# $11 - layer update frequency ("daily")
# $12 - layer unit_id ("n")
# $13 - layer last_updated

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
  auth_endpoint="https://dev-keycloak.k8s-01.konturlabs.com/auth/realms/dev/protocol/openid-connect/token"
  ;;
*)
  echo "Error. Unsupported realm"
  exit 1
  ;;
esac

# Get token
token_request_content=$(curl -d "client_id=kontur_platform&username=$DN_USERNAME&grant_type=password" \
                        --data-urlencode "password=$DN_PASSWORD" \
                        -H "Content-Type: application/x-www-form-urlencoded" \
                        -X POST ${auth_endpoint})
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
layer_description="\"$9\""
layer_coverage="\"${10}\""
layer_update_freq="\"${11}\""
layer_unit_id="\"${12}\""
layer_last_updated="\"${13}\""

parameters_json="{\"id\": ${layer_id}, \"label\": ${layer_label}, \"direction\": ${layer_direction}, \"isBase\": ${layer_isbase}, \"isPublic\": ${layer_ispublic}, \"copyrights\": ${layer_copyrights}, \"description\": ${layer_description}, \"coverage\": ${layer_coverage}, \"updateFrequency\": ${layer_update_freq}, \"unitId\": ${layer_unit_id}, \"lastUpdated\": ${layer_last_updated}}"
curl_request="curl -w "\":::\"%{http_code}" --location --request POST ${upload_endpoint} --header 'Authorization: Bearer ${token}' --form 'parameters=${parameters_json}' --form 'file=@\"$2\"'"

# Upload file
request_result=$(eval $curl_request)

if [[ -z $request_result ]]; then
  echo "Error. Failed to upload layer"
  exit 1
fi

response_status=$(sed 's/.*:::\(.*\)/\1/' <<< $request_result)
response_status_length=${#response_status}

if [ $response_status_length != 3 ]; then
  echo "$(date '+%F %H:%M:%S') Error. Failed to upload layer. $layer_label $layer_id Message: $response_status"
  exit 1
fi

if [ $response_status != 200 ]; then
  echo "$(date '+%F %H:%M:%S') Error. Failed to upload layer. $layer_label $layer_id Status code: $response_status"
  exit 1
fi

layer_uuid=${request_result::-6}

echo "$(date '+%F %H:%M:%S') Layer uploaded successfully. $layer_label $layer_id UUID: $layer_uuid"
exit 0