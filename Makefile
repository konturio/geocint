all: db/function/isochrone db/index/osm_geog_idx db/table/osm_population_split deploy/dollar/osm_quality_bivariate_tiles

clean:
	rm -rf db/ data/planet-latest-updated.osm.pbf

data:
	mkdir -p $@

db:
	mkdir -p $@

db/function: | db
	mkdir -p $@

db/table: | db
	mkdir -p $@

db/index: | db
	mkdir -p $@

data/tiles: | data
	mkdir -p $@

deploy:
	mkdir -p $@

deploy/dollar:
	mkdir -p $@

deploy/geocint:
	mkdir -p $@

data/planet-latest.osm.pbf: | data
	wget https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf -O $@
	# TODO: smoke check correctness of file
	touch $@

data/planet-latest-updated.osm.pbf: data/planet-latest.osm.pbf | data
	osmupdate data/planet-latest.osm.pbf data/planet-latest-updated.osm.pbf
	# TODO: smoke check correctness of file
	mv data/planet-latest-updated.osm.pbf data/planet-latest.osm.pbf
	touch $@

db/table/osm: data/planet-latest-updated.osm.pbf | db/table
	psql -c "drop table if exists osm;"
	osmium export -c osmium.config.json -f pg data/planet-latest.osm.pbf  -v --progress | psql -1 -c 'create table osm(geog geography, osm_type text, osm_id bigint, way_nodes bigint[], tags jsonb);copy osm from stdin freeze;'
	psql -c "vacuum analyze osm;"
	touch $@

db/function/osm_way_nodes_to_segments: | db/function
	psql -f functions/osm_way_nodes_to_segments.sql
	touch $@

db/function/ST_ClosestPointWithZ: | db/function
	psql -f functions/ST_ClosestPointWithZ.sql
	touch $@

db/table/osm_road_segments: db/table/osm db/function/ST_ClosestPointWithZ db/function/osm_way_nodes_to_segments
	psql -f tables/osm_road_segments.sql
	touch $@

db/index/osm_tags_idx: db/table/osm | db/index
	psql -c "create index osm_tags_idx on osm using gin (tags);"
	touch $@

db/index/osm_geog_idx: db/table/osm | db/index
	psql -c "create index osm_geog_idx on osm using gist (geog);"
	touch $@

db/index/osm_road_segments_osm_id_node_from_node_to_seg_geom_idx: db/table/osm_road_segments | db/index
	psql -c "create index osm_road_segments_osm_id_node_from_node_to_seg_geom_idx on osm_road_segments (osm_id, node_from, node_to, seg_geom);"
	touch $@

db/index/osm_road_segments_seg_geom_idx: db/table/osm_road_segments | db/index
	psql -c "create index osm_road_segments_seg_geom_idx on osm_road_segments using gist (seg_geom);"
	touch $@

db/function/isochrone: db/function/TileBBox db/table/osm_road_segments db/index/osm_road_segments_osm_id_node_from_node_to_seg_geom_idx db/index/osm_road_segments_seg_geom_idx db/function/ST_ClosestPointWithZ
	psql -f functions/isochrone.sql
	touch $@

db/function/TileBBox: | db/function
	psql -f functions/TileBBox.sql
	touch $@

db/table/osm_population_raw: db/table/osm db/index/osm_tags_idx | db/table
	psql -f tables/osm_population_raw.sql
	touch $@

db/procedure: | db
	mkdir -p $@

db/procedure/decimate_admin_level_in_osm_population_raw: db/table/osm_population_raw | db/procedure
	psql -f procedures/decimate_admin_level_in_osm_population_raw.sql -v current_level=2
	psql -f procedures/decimate_admin_level_in_osm_population_raw.sql -v current_level=3
	psql -f procedures/decimate_admin_level_in_osm_population_raw.sql -v current_level=4
	psql -f procedures/decimate_admin_level_in_osm_population_raw.sql -v current_level=5
	psql -f procedures/decimate_admin_level_in_osm_population_raw.sql -v current_level=6
	psql -f procedures/decimate_admin_level_in_osm_population_raw.sql -v current_level=7
	psql -f procedures/decimate_admin_level_in_osm_population_raw.sql -v current_level=8
	psql -f procedures/decimate_admin_level_in_osm_population_raw.sql -v current_level=9
	psql -f procedures/decimate_admin_level_in_osm_population_raw.sql -v current_level=10
	psql -f procedures/decimate_admin_level_in_osm_population_raw.sql -v current_level=11
	touch $@

db/table/osm_population_split: db/procedure/decimate_admin_level_in_osm_population_raw | db/table
	psql -f tables/osm_population_split.sql
	touch $@

db/table/ghs_globe_population_vector: db/table/ghs_globe_population_raster db/procedure/insert_projection_54009 | db/table
	psql -f tables/ghs_globe_population_vector.sql
	touch $@

data/GHS_POP_GPW42015_GLOBE_R2015A_54009_250_v1_0.zip: | data
	wget https://cidportal.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GPW4_GLOBE_R2015A/GHS_POP_GPW42015_GLOBE_R2015A_54009_250/V1-0/GHS_POP_GPW42015_GLOBE_R2015A_54009_250_v1_0.zip -O $@

data/GHS_POP_GPW42015_GLOBE_R2015A_54009_250_v1_0/GHS_POP_GPW42015_GLOBE_R2015A_54009_250_v1_0.tif: data/GHS_POP_GPW42015_GLOBE_R2015A_54009_250_v1_0.zip
	cd data; unzip -o GHS_POP_GPW42015_GLOBE_R2015A_54009_250_v1_0.zip
	touch $@

db/table/ghs_globe_population_raster: data/GHS_POP_GPW42015_GLOBE_R2015A_54009_250_v1_0/GHS_POP_GPW42015_GLOBE_R2015A_54009_250_v1_0.tif | db/table
	psql -c "drop table if exists ghs_globe_population_raster"
	raster2pgsql -M -Y -s 54009 data/GHS_POP_GPW42015_GLOBE_R2015A_54009_250_v1_0/GHS_POP_GPW42015_GLOBE_R2015A_54009_250_v1_0.tif -t auto ghs_globe_population_raster | psql -q
	touch $@

db/procedure/insert_projection_54009: | db/procedure
	psql -f procedures/insert_projection_54009.sql || true
	touch $@

db/table/ghs_population_grid_1000: db/table/ghs_globe_population_vector | db/table
	psql -f tables/ghs_population_grid_1000.sql
	touch $@

db/table/osm_object_count_grid_1000: db/table/osm | db/table
	psql -f tables/osm_object_count_grid_1000.sql
	touch $@

db/table/osm_quality_bivariate_grid_1000: db/table/ghs_population_grid_1000 db/table/osm_object_count_grid_1000 | db/table
	psql -f tables/osm_quality_bivariate_grid_1000.sql
	touch $@

db/table/osm_quality_bivariate_tiles: db/table/osm_quality_bivariate_grid_1000 | db/table
	psql -f tables/osm_quality_bivariate_tiles.sql
	touch $@

data/tiles/osm_quality_bivariate_tiles.tar.bz2: db/table/osm_quality_bivariate_tiles db/function/TileBBox | data/tiles
	bash ./scripts/generate_bivariate_class_tiles.sh | parallel --eta
	cd data/tiles/osm_quality_bivariate/; tar cjvf ../../osm_quality_bivariate_tiles.tar.bz2 ./

deploy/geocint/osm_quality_bivariate_tiles: data/tiles/osm_quality_bivariate_tiles.tar.bz2 | deploy/geocint
	rm -rf /var/www/tiles/osm_quality_bivariate_new; mkdir -p /var/www/tiles/osm_quality_bivariate_new
	cp data/tiles/osm_quality_bivariate /var/www/tiles/osm_quality_bivariate_new
	rm -rf /var/www/tiles/osm_quality_bivariate_old
	mv /var/www/tiles/osm_quality_bivariate /var/www/tiles/osm_quality_bivariate_old; mv /var/www/tiles/osm_quality_bivariate_new /var/www/tiles/osm_quality_bivariate

deploy/dollar/osm_quality_bivariate_tiles: data/tiles/osm_quality_bivariate_tiles.tar.bz2 | deploy/dollar
	ssh root@disaster.ninja -C "rm -f osm_quality_bivariate_tiles.tar.bz2"
	scp data/tiles/osm_quality_bivariate_tiles.tar.bz2 root@disaster.ninja:
	ssh root@disaster.ninja -C "rm -rf /var/www/tiles/osm_quality_bivariate_new; mkdir -p /var/www/tiles/osm_quality_bivariate_new"
	ssh root@disaster.ninja -C "tar xvf osm_quality_bivariate_tiles.tar.bz2 -C /var/www/tiles/osm_quality_bivariate_new"
	ssh root@disaster.ninja -C "rm -rf /var/www/tiles/osm_quality_bivariate_old"
	ssh root@disaster.ninja -C "mv /var/www/tiles/osm_quality_bivariate /var/www/tiles/osm_quality_bivariate_old; mv /var/www/tiles/osm_quality_bivariate_new /var/www/tiles/osm_quality_bivariate"
	# TODO: remove old when we're sure we don't want to go back
	touch $@
