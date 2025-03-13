#!/bin/bash
# $1 - min range value
# $2 - max range value
# $3 - output file

min=$1
max=$2
output_file="$3"

fetch_population_data() {
    local min_range=$1
    local max_range=$2
    local out_file=$3

    # NB! Notice `seq 2` here. First, wget triggers query execution which might take some time.
    # In most cases the process works fine, but with thousands of rows a timeout during downloading may occur.
    # So we run wget twice because for the second time it uses cached query.

    seq 2 | xargs -I JUSTAPLACEHOLDER wget -nv "https://query.wikidata.org/sparql?query=SELECT \
                    ?country \
                    ?population \
                    ?census_date \
                    WHERE { \
                        ?country p:P1082 ?population_statement . \
                        ?population_statement ps:P1082 ?population . \
                        OPTIONAL { ?population_statement pq:P585 ?census_date . } \
                        FILTER (${min_range} <= ?population %26%26 ?population < ${max_range}) . \
                        FILTER NOT EXISTS { \
                            ?country p:P1082 ?other_statement . \
                            ?other_statement ps:P1082 ?other_population . \
                            ?other_statement pq:P585 ?other_date . \
                            FILTER (?other_date > ?census_date) \
                        }}" \
        --header "Accept: text/csv" \
        -O "$out_file" || true
}

for i in {0..10}; do
    echo "Attempt $i"
    fetch_population_data "$min" "$max" $output_file

    # Check for TimeoutException in the output file and stop loop if complete result was achieved
    if ! grep -q "java.util.concurrent" "$output_file" && [ -f "$output_file" ] && [ $(cat "$output_file" | wc -l) -gt 0 ]; then
        break
    else
        echo  "Loding error"
    fi

    # Wait 1 minute until wikidata will remove cashed response with error 
    sleep 60
done

exit 0
