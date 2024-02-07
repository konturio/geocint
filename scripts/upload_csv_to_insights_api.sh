#!/bin/bash
# $1 - prod, test or dev
# $2 - access token
# $3 - csv file path (data/trees.csv)
# $4 - layer id ("trees")
# $5 - layer label ("layer with trees")
# $6 - layer direction ("[[\"neutral\"], [\"neutral\"]]")
# $7 - layer isBase (true)
# $8 - layer isPublic (false)
# $9 - layer copyrights ("[\"Kontur.io\",\"OSM Contributors\"]")
# $10 - layer description ("very cool trees layer produced by Kontur")
# $11 - layer coverage ("World")
# $12 - layer update frequency ("daily")
# $13 - layer unit_id ("n")
# $14 - layer last_updated

# define endpoints
case $1 in
prod)
  upload_endpoint="https://prod-insights-api.k8s-01.konturlabs.com/insights-api/indicators/upload"
  ;;
test)
  upload_endpoint="https://test-insights-api.k8s-01.konturlabs.com/insights-api/indicators/upload"
  ;;
dev)
  upload_endpoint="https://dev-insights-api.k8s-01.konturlabs.com/insights-api/indicators/upload"
  ;;
*)
  echo "Error. Unsupported realm"
  exit 1
  ;;
esac

# Prepare inputs
token="$2"
layer_id="\"$4\""
layer_label="\"$5\""
layer_direction=$6 #$(sed 's/"/\\"/g' <<<"$5")
layer_isbase=$7
layer_ispublic=$8
if [ "$9" == "null" ]; then
  layer_copyrights="null"
else
  layer_copyrights=$9 #(sed 's/"/\\"/g' <<<"$8")
fi
layer_description="\"$10\""
layer_coverage="\"${11}\""
layer_update_freq="\"${12}\""
layer_unit_id="\"${13}\""
layer_last_updated="\"${14}\""

existed_uuid=$(psql -Xqtc "select uuid from (select jsonb_array_elements(j) ->> 'id' as id, jsonb_array_elements(j) ->> 'uuid' as uuid, jsonb_array_elements(j) ->> 'lastUpdated' as last_updated from insights_api_indicators_list_$1) a where id = '$4' order by last_updated asc limit 1;" | xargs)

if [[ -z $existed_uuid ]]; then
  action="upload"

  parameters_json="{\"id\": ${layer_id}, \"label\": ${layer_label}, \"direction\": ${layer_direction}, \"isBase\": ${layer_isbase}, \"isPublic\": ${layer_ispublic}, \"copyrights\": ${layer_copyrights}, \"description\": ${layer_description}, \"coverage\": ${layer_coverage}, \"updateFrequency\": ${layer_update_freq}, \"unitId\": ${layer_unit_id}, \"lastUpdated\": ${layer_last_updated}}"

  curl_request="curl -k -w "\":::\"%{http_code}" --location --request POST ${upload_endpoint} --header 'Authorization: Bearer ${token}' --form 'parameters=${parameters_json}' --form 'file=@\"$3\"'"
else
  action="update"

  parameters_json="{\"id\": ${layer_id}, \"label\": ${layer_label}, \"uuid\": \"${existed_uuid}\", \"direction\": ${layer_direction}, \"isBase\": ${layer_isbase}, \"isPublic\": ${layer_ispublic}, \"copyrights\": ${layer_copyrights}, \"description\": ${layer_description}, \"coverage\": ${layer_coverage}, \"updateFrequency\": ${layer_update_freq}, \"unitId\": ${layer_unit_id}, \"lastUpdated\": ${layer_last_updated}}"

  curl_request="curl -k -w "\":::\"%{http_code}" --location --request PUT ${upload_endpoint} --header 'Authorization: Bearer ${token}' --form 'parameters=${parameters_json}' --form 'file=@\"$3\"'"
fi

echo "$curl_request"

# Upload file
request_result=$(eval $curl_request)

if [[ -z $request_result ]]; then
  echo "Error. Failed to $action layer"
  exit 1
fi

response_status=$(sed 's/.*:::\(.*\)/\1/' <<< $request_result)
response_status_length=${#response_status}

if [ $response_status_length != 3 ]; then
  echo "$(date '+%F %H:%M:%S') Error. Failed to $action layer. $layer_label $layer_id Message: $response_status"
  exit 1
fi

if [ $response_status != 200 ]; then
  echo "$(date '+%F %H:%M:%S') Error. Failed to $action layer. $layer_label $layer_id Status code: $response_status"
  exit 1
fi

layer_uuid=${request_result::-6}

echo "$(date '+%F %H:%M:%S') Layer $action was successful. $layer_label $layer_id UUID: $layer_uuid"
exit 0