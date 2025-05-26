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
token=$(bash scripts/get_auth_token.sh $1) || {
  echo "Error. Impossible to get auth token"
  exit 1
}

# GET the list of indicators
request_result=$(curl -f -s -k -X GET "${indicators_endpoint}" \
  -H 'accept: */*' \
  -H "Authorization: Bearer ${token}")

if [[ -z $request_result ]]; then
  echo "Error. Failed to get the list of indicators."
  exit 1
fi

echo "$request_result"
exit 0