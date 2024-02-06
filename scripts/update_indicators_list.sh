#!/bin/bash
# $1 - stage - prod, test or dev
# $2 - access token

# define endpoints
case $1 in
prod)
  upload_endpoint="https://prod-insights-api.k8s-01.konturlabs.com/insights-api/indicators"
  ;;
test)
  preset_endpoint="https://test-insights-api.k8s-01.konturlabs.com/insights-api/indicators"
  ;;
dev)
  upload_endpoint="https://dev-insights-api.k8s-01.konturlabs.com/insights-api/indicators"
  ;;
*)
  echo "Error. Unsupported realm"
  exit 1
  ;;
esac

# Prepare inputs
token="$2"

curl_request="curl -s -k -X 'GET' '${preset_endpoint}' -H 'accept: */*' --header 'Authorization: Bearer ${token}'"

# Upload file
request_result=$(eval $curl_request)

if [[ -z $request_result ]]; then
  echo "Error. Failed to upload layer"
  exit 1
fi

response_status=$(sed 's/.*:::\(.*\)/\1/' <<< $request_result)

echo "$request_result"

response_status_length=${#response_status}
exit 0