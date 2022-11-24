# SET THE URL TO POLY FILE FOR EXTRACT
URL="https://download.geofabrik.de/africa/tanzania.poly"

DIR=data/in/mapaction-country
FILE=$(basename $URL)
# COUNTRY=$(basename $FILE .poly)

# DOWNLOAD THIS POLY FILE
curl -s -o $DIR/$FILE $URL

# GENERATING clipwith.json FOR `osmium extract` COMMAND
# SET EXTRACT DIRECTORY TO $DIR
# SET THE NAME FOR RESULT EXTRACT FILE TO osm-extract.osm.pbf
head -n -2 $DIR/$FILE | tail -n +3 | \
 awk -v directory="$DIR" 'BEGIN { print "{ \"directory\": \""directory"\", \"extracts\":[{\"output\":\"osm-extract.osm.pbf\", \"polygon\": [[" } { print "[" $1 "," $2 "]," } ' | \
 sed '$ s/\(.*\),)*/\1/' | awk '{ print } END { print "]]}]}" }' > $DIR/clipwith.json

# EXTRACTING FROM planet-latest.osm.pbf TO osm-extract.osm.pbf
# osmium extract -v -c $DIR/clipwith.json -O data/planet-latest.osm.pbf