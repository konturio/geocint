#!/bin/bash
# $1 - stage - prod, test or dev
# $2 - access token
# $3 - numerator_id - external uuid
# $4 - denominator_id - external uuid

# define endpoints
case $1 in
prod)
  upload_endpoint="https://prod-insights-api.k8s-01.konturlabs.com/insights-api/indicators/axis/custom"
  ;;
test)
  preset_endpoint="https://test-insights-api.k8s-01.konturlabs.com/insights-api/indicators/axis/custom"
  ;;
dev)
  upload_endpoint="https://dev-insights-api.k8s-01.konturlabs.com/insights-api/indicators/axis/custom"
  ;;
*)
  echo "Error. Unsupported realm"
  exit 1
  ;;
esac

# Prepare inputs
token="$2"
numerator_id="$3"
denominator_id="$4"

parameters_json=$(psql -Xqtc "select row_to_json(row) from (select a.uuid as numerator_id, b.uuid as denominator_id, c.label, c.min, c.max, c.p25, c.p75 from (select uuid, id from (select jsonb_array_elements(j) ->> 'id' as id, jsonb_array_elements(j) ->> 'uuid' as uuid, jsonb_array_elements(j) ->> 'lastUpdated' as last_updated from insights_api_indicators_list_$1) a where id = '$numerator_id' order by last_updated asc limit 1) a, (select uuid, id from (select jsonb_array_elements(j) ->> 'id' as id, jsonb_array_elements(j) ->> 'uuid' as uuid, jsonb_array_elements(j) ->> 'lastUpdated' as last_updated from insights_api_indicators_list_$1) a where id = '$denominator_id' order by last_updated asc limit 1) b, bivariate_axis_overrides c where a.id = c.numerator_id and b.id = c.denominator_id) row;")

curl_request="curl -k -w "\":::\"%{http_code}" -X 'POST' ${preset_endpoint} --header 'Authorization: Bearer ${token}' -H 'accept: */*' -H 'Content-Type: application/json' -d '${parameters_json}'"

# Upload file
request_result=$(eval $curl_request)

response_status=$(sed 's/.*:::\(.*\)/\1/' <<< $request_result)

echo "$response_status"

response_status_length=${#response_status}
exit 0