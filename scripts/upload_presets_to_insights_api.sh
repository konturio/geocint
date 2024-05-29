#!/bin/bash
# $1 - prod, test or dev
# $2 - x_numerator_id - external uuid
# $3 - x_denominator_id - external uuid
# $4 - y_numerator_id - external uuid
# $5 - y_denominator_id - external uuid

# define endpoints
case $1 in
prod)
  preset_endpoint="https://prod-insights-api.k8s-01.konturlabs.com/insights-api/indicators/axis/preset"
  ;;
test)
  preset_endpoint="https://test-insights-api.k8s-01.konturlabs.com/insights-api/indicators/axis/preset"
  ;;
dev)
  preset_endpoint="https://dev-insights-api.k8s-01.konturlabs.com/insights-api/indicators/axis/preset"
  ;;
*)
  echo "Error. Unsupported realm"
  exit 1
  ;;
esac

token=$(bash scripts/get_auth_token.sh $1)

x_numerator_id="$2"
x_denominator_id="$3"
y_numerator_id="$4"
y_denominator_id="$5"

x_numerator_uuid=$(psql -Xqtc "select uuid from (select jsonb_array_elements(j) ->> 'id' as id, jsonb_array_elements(j) ->> 'uuid' as uuid, jsonb_array_elements(j) ->> 'lastUpdated' as last_updated from insights_api_indicators_list_$1) a where id = '$2' order by last_updated asc limit 1;" | xargs)

x_denominator_uuid=$(psql -Xqtc "select uuid from (select jsonb_array_elements(j) ->> 'id' as id, jsonb_array_elements(j) ->> 'uuid' as uuid, jsonb_array_elements(j) ->> 'lastUpdated' as last_updated from insights_api_indicators_list_$1) a where id = '$3' order by last_updated asc limit 1;" | xargs)

y_numerator_uuid=$(psql -Xqtc "select uuid from (select jsonb_array_elements(j) ->> 'id' as id, jsonb_array_elements(j) ->> 'uuid' as uuid, jsonb_array_elements(j) ->> 'lastUpdated' as last_updated from insights_api_indicators_list_$1) a where id = '$4' order by last_updated asc limit 1;" | xargs)

y_denominator_uuid=$(psql -Xqtc "select uuid from (select jsonb_array_elements(j) ->> 'id' as id, jsonb_array_elements(j) ->> 'uuid' as uuid, jsonb_array_elements(j) ->> 'lastUpdated' as last_updated from insights_api_indicators_list_$1) a where id = '$5' order by last_updated asc limit 1;" | xargs)

parameters_json=$(psql -Xqtc "select row_to_json(row)
                                   from (select ord,
                                                '$x_numerator_uuid' as x_numerator_id,
                                                '$x_denominator_uuid' as x_denominator_id,
                                                '$y_numerator_uuid' as y_numerator_id,
                                                '$y_denominator_uuid' as y_denominator_id, 
                                                name, 
                                                active, 
                                                description,
                                                replace(colors::text, '\"', '\"') as colors, 
                                                application, 
                                                is_public 
                                        from bivariate_overlays
                                        where x_numerator = '$x_numerator_id'
                                          and x_denominator = '$x_denominator_id'
                                          and y_numerator = '$y_numerator_id'
                                          and y_denominator = '$y_denominator_id') row;")

curl_request="curl -X POST -w "\":::\"%{http_code}" --request POST ${preset_endpoint} -H 'Content-Type: application/json' --header 'Authorization: Bearer ${token}' -d '${parameters_json}'"

echo $curl_request

# Upload preset

request_result=$(eval $curl_request)

if [[ -z $request_result ]]; then
  echo "Error. Failed to upload preset"
  exit 1
fi

response_status=$(sed 's/.*:::\(.*\)/\1/' <<< $request_result)

if [ $response_status != 200 ]; then
  echo "$(date '+%F %H:%M:%S') Error. Failed to upload/update preset. Status code: $response_status"
  exit 1
fi

echo "$(date '+%F %H:%M:%S') Preset was uploaded/updated successfully"
exit 0
