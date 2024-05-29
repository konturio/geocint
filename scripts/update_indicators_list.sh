#!/bin/bash
# $1 - stage - prod, test or dev

# define endpoints
case $1 in
prod)
  indicators_endpoint="https://prod-insights-api.k8s-01.konturlabs.com/insights-api/indicators"
  ;;
test)
  indicators_endpoint="https://test-insights-api.k8s-01.konturlabs.com/insights-api/indicators"
  ;;
dev)
  indicators_endpoint="https://dev-insights-api.k8s-01.konturlabs.com/insights-api/indicators"
  ;;
*)
  echo "Error. Unsupported realm"
  exit 1
  ;;
esac

# Prepare inputs
token=$(bash scripts/get_auth_token.sh $1)

curl_request="curl -s -k -X 'GET' '${indicators_endpoint}' -H 'accept: */*' --header 'Authorization: Bearer ${token}'"

# GET the list of indicators
request_result=$(eval $curl_request)

if [[ -z $request_result ]]; then
  echo "Error. Failed to get the list of indicators."
  exit 1
fi

echo "$request_result"
exit 0