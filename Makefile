import-planet:
	osm2pgsql --flat-nodes nodes.cache --slim --hstore --extra-attributes --multi-geometry --style default.style ../planet-181217.osm.pbf
	touch $@






env: import start-router-car start-router-foot

data/BY.osm.pbf: | data
	wget http://data.gis-lab.info/osm_dump/dump/latest/BY.osm.pbf -O $@
	
osrm-frontend:
	docker run -p 9966:9966 osrm/osrm-frontend

update-dump: BY.osm.pbf BY.poly
	osmupdate BY.osm.pbf BY2.osm.pbf --verbose
	osmium extract --strategy=smart -p BY.poly --overwrite -o BY.osm.pbf BY2.osm.pbf
	
osrm-backend-car: update-dump
	ln -sf BY.osm.pbf BY-car.osm.pbf
	docker run -t -v `pwd`:/data osrm/osrm-backend osrm-extract -p /data/profiles/car.lua /data/BY-car.osm.pbf
	#docker run -t -v `pwd`:/data osrm/osrm-backend osrm-contract /data/BY-car.osrm
	docker run -t -v `pwd`:/data osrm/osrm-backend osrm-partition /data/BY-car.osrm
	docker run -t -v `pwd`:/data osrm/osrm-backend osrm-customize /data/BY-car.osrm

osrm-backend-foot: update-dump
	ln -sf BY.osm.pbf BY-foot.osm.pbf
	docker run -t -v `pwd`:/data osrm/osrm-backend osrm-extract -p /data/profiles/foot.lua /data/BY-foot.osm.pbf
	docker run -t -v `pwd`:/data osrm/osrm-backend osrm-partition /data/BY-foot.osrm
	docker run -t -v `pwd`:/data osrm/osrm-backend osrm-customize /data/BY-foot.osrm
	
rebuild:
	make update-dump
	make osrm-backend
	
start-router-car: osrm-backend-car
	docker run -p 5000:5000 -v `pwd`:/data osrm/osrm-backend osrm-routed --algorithm ch /data/BY-car.osrm  --max-trip-size 1000000

start-router-foot: osrm-backend-foot
	docker run -p 5001:5000 -v `pwd`:/data osrm/osrm-backend osrm-routed --algorithm mld /data/BY-foot.osrm  --max-trip-size 1000000

data:
	mkdir $@