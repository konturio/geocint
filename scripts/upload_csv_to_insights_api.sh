#!/bin/bash
# $1 - environment: prod, test, or dev
# $2 - csv file path (e.g., data/trees.csv)
# $3 - layer id (e.g., "trees")
# $4 - file path to determine last updated timestamp

# Define endpoints based on environment
case $1 in
  prod)
    upload_endpoint="https://prod-insights-api.k8s-01.konturlabs.com/insights-api/indicators/upload"
    upload_check="https://prod-insights-api.k8s-01.konturlabs.com/insights-api/indicators/upload/status"
    ;;
  test)
    upload_endpoint="https://test-insights-api.k8s-01.konturlabs.com/insights-api/indicators/upload"
    upload_check="https://test-insights-api.k8s-01.konturlabs.com/insights-api/indicators/upload/status"
    ;;
  dev)
    upload_endpoint="https://dev-insights-api.k8s-01.konturlabs.com/insights-api/indicators/upload"
    upload_check="https://dev-insights-api.k8s-01.konturlabs.com/insights-api/indicators/upload/status"
    ;;
  *)
    echo "Error: Unsupported environment (use prod, test, or dev)"
    exit 1
    ;;
esac

# Retrieve authentication token
token=$(bash scripts/get_auth_token.sh "$1")

# Fetch multiple parameters in one query, excluding copyrights
params=$(psql -Xqtc "
  select json_build_object(
    'label', param_label,
    'direction', direction::text,
    'is_base', is_base::text,
    'is_public', is_public::text,
    'description', description,
    'coverage', coverage,
    'update_frequency', update_frequency,
    'unit_id', unit_id,
    'emoji', emoji,
    'downscale', downscale
  )::text
  from bivariate_indicators where param_id = '$3';
")

# Parse the JSON response for individual variables
layer_label=$(echo "$params" | jq -r '.label')
layer_direction=$(echo "$params" | jq -r '.direction')
layer_isbase=$(echo "$params" | jq -r '.is_base')
layer_ispublic=$(echo "$params" | jq -r '.is_public')
layer_description=$(echo "$params" | jq -r '.description')
layer_coverage=$(echo "$params" | jq -r '.coverage')
layer_update_freq=$(echo "$params" | jq -r '.update_frequency')
layer_unit_id=$(echo "$params" | jq -r '.unit_id')
layer_emoji=$(echo "$params" | jq -r '.emoji')
layer_downscale=$(echo "$params" | jq -r '.downscale')

# Retrieve and process copyrights separately
layer_copyrights=$(psql -Xqtc "SELECT copyrights::text FROM bivariate_indicators WHERE param_id = '$3';" | sed 's/;/.,/g' | sed 's/, /,/g' | jq -c .)

# Get last updated timestamp
layer_last_updated="\"$(date -r "$4" +'%Y-%m-%dT%H:%M:%SZ')\""

# Check if UUID for the layer exists
indicators_list=$(bash scripts/update_indicators_list.sh "$1")

existed_uuid=$(echo "$indicators_list" | jq -c '.[]' | jq -c 'select(.id == "'"$3"'")' | jq -s '.' | jq 'sort_by(.date)' | jq -r '.[].uuid' | tail -1)

indicator_hash=$(echo "$indicators_list" | jq -c '.[]' | jq -c 'select(.id == "'"$3"'")' | jq -s '.' | jq 'sort_by(.date)' | jq -r '.[].hash' | tail -1)

csv_hash=$(md5sum $2 | awk '{print $1}')

if [ "$indicator_hash" = "$csv_hash" ]; then
  echo "$(date '+%F %H:%M:%S') The upload was stopped because this version of the $3 indicator is already loaded into Insights"
  exit 0
fi

# Set the method and action for the curl request
if [[ -z $existed_uuid ]]; then
  action="upload"
  method="POST"
  parameters_json="{\"id\": \"${3}\", \"label\": \"${layer_label}\", \"direction\": ${layer_direction}, \"isBase\": ${layer_isbase}, \"isPublic\": ${layer_ispublic}, \"copyrights\": ${layer_copyrights}, \"description\": \"${layer_description}\", \"coverage\": \"${layer_coverage}\", \"updateFrequency\": \"${layer_update_freq}\", \"unitId\": \"${layer_unit_id}\", \"emoji\": \"${layer_emoji}\", \"downscale\": \"${layer_downscale}\", \"hash\": \"${csv_hash}\", \"lastUpdated\": ${layer_last_updated}}"
else
  action="update"
  method="PUT"
  parameters_json="{\"id\": \"${3}\", \"label\": \"${layer_label}\", \"uuid\": \"${existed_uuid}\", \"direction\": ${layer_direction}, \"isBase\": ${layer_isbase}, \"isPublic\": ${layer_ispublic}, \"copyrights\": ${layer_copyrights}, \"description\": \"${layer_description}\", \"coverage\": \"${layer_coverage}\", \"updateFrequency\": \"${layer_update_freq}\", \"unitId\": \"${layer_unit_id}\", \"emoji\": \"${layer_emoji}\", \"downscale\": \"${layer_downscale}\", \"hash\": \"${csv_hash}\", \"lastUpdated\": ${layer_last_updated}}"
fi

# Execute the curl request to upload the file
curl_request="curl -k -w ':::%{http_code}' --location --request ${method} ${upload_endpoint} --header 'Authorization: Bearer ${token}' --form 'parameters=${parameters_json}' --form 'file=@\"$2\"'"

# Output the formed request for execution
echo ""
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

upload_id=${request_result::-6}

echo "$(date '+%F %H:%M:%S') got upload id $upload_id"

# wait 5 sec to let upload process start
sleep 5

curl_request="curl -s -w "\":::\"%{http_code}" --location '$upload_check/$upload_id'   -H 'Authorization: Bearer $token'"

echo "$curl_request"

while true; do
    request_result=$(eval $curl_request)
    rc=$(sed 's/.*:::\(.*\)/\1/' <<< $request_result)
    [[ "$rc" != 202 ]] && break
    echo "$(date '+%F %H:%M:%S') $request_result"
    sleep 300
done

echo $request_result

if [ "$rc" != 200 ]; then
  echo "$(date '+%F %H:%M:%S') Error. Failed to $action layer. Upload check failed. $layer_label $layer_id Status code: $rc"
  exit 1
fi

layer_uuid=${request_result::-6}

echo "$(date '+%F %H:%M:%S') Layer $action was successful. $layer_label $layer_id UUID: $layer_uuid"
exit 0
