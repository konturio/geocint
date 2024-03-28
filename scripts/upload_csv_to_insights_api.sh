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
# $13 - layer emoji ("🌳")
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
token=$(bash scripts/get_auth_token.sh $1)
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
layer_emoji="\"$13\""
layer_last_updated="\"${14}\""

existed_uuid=$(psql -Xqtc "select uuid from (select jsonb_array_elements(j) ->> 'id' as id, jsonb_array_elements(j) ->> 'uuid' as uuid, jsonb_array_elements(j) ->> 'lastUpdated' as last_updated from insights_api_indicators_list_$1) a where id = '$3' order by last_updated asc limit 1;" | xargs)

if [[ -z $existed_uuid ]]; then
  action="upload"
  metod="POST"

  parameters_json="{\"id\": ${layer_id}, \"label\": ${layer_label}, \"direction\": ${layer_direction}, \"isBase\": ${layer_isbase}, \"isPublic\": ${layer_ispublic}, \"copyrights\": ${layer_copyrights}, \"description\": ${layer_description}, \"coverage\": ${layer_coverage}, \"updateFrequency\": ${layer_update_freq}, \"unitId\": ${layer_unit_id}, \"emoji\": ${layer_emoji}, \"lastUpdated\": ${layer_last_updated}}"
else
  action="update"
  metod="PUT"

  parameters_json="{\"id\": ${layer_id}, \"label\": ${layer_label}, \"uuid\": \"${existed_uuid}\", \"direction\": ${layer_direction}, \"isBase\": ${layer_isbase}, \"isPublic\": ${layer_ispublic}, \"copyrights\": ${layer_copyrights}, \"description\": ${layer_description}, \"coverage\": ${layer_coverage}, \"updateFrequency\": ${layer_update_freq}, \"unitId\": ${layer_unit_id}, \"emoji\": ${layer_emoji}, \"lastUpdated\": ${layer_last_updated}}"
fi

curl_request="curl -k -w "\":::\"%{http_code}" --location --request ${metod} ${upload_endpoint} --header 'Authorization: Bearer ${token}' --form 'parameters=${parameters_json}' --form 'file=@\"$2\"'"

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