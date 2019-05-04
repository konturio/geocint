all: deploy/geocint/isochrone_tables db/table/osm_population_split deploy/_all data/population/population_api_tables.sqld.gz db/table/fb_africa_population_vector

clean:
	rm -rf db/ data/planet-latest-updated.osm.pbf deploy/ data/tiles
	psql -f scripts/clean.sql

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

data/population: | data
	mkdir -p $@

data/population_africa_2018-10-01: | data
	mkdir -p $@

deploy:
	mkdir -p $@

deploy/dollar:
	mkdir -p $@

deploy/geocint:
	mkdir -p $@

deploy/_all: deploy/geocint/osm_quality_bivariate_tiles
	touch $@

deploy/geocint/isochrone_tables: db/table/osm_road_segments db/index/osm_road_segments_seg_id_node_from_node_to_seg_geom_idx db/index/osm_road_segments_seg_geom_idx
	touch $@

data/planet-latest.osm.pbf: | data
	wget https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf -O $@
	# TODO: smoke check correctness of file
	touch $@

data/planet-latest-updated.osm.pbf: data/planet-latest.osm.pbf | data
	osmupdate data/planet-latest.osm.pbf data/planet-latest-updated.osm.pbf
	osmium fileinfo data/planet-latest-updated.osm.pbf -ej > data/planet-latest-updated.osm.pbf.meta.json
	# TODO: smoke check correctness of file
	cp data/planet-latest-updated.osm.pbf data/planet-latest.osm.pbf
	cp data/planet-latest-updated.osm.pbf.meta.json data/planet-latest.osm.pbf.meta.json
	touch $@

db/table/osm: data/planet-latest-updated.osm.pbf | db/table
	psql -c "drop table if exists osm;"
	osmium export -c osmium.config.json -f pg data/planet-latest.osm.pbf  -v --progress | psql -1 -c 'create table osm(geog geography, osm_type text, osm_id bigint, way_nodes bigint[], tags jsonb);copy osm from stdin freeze;'
	psql -c "vacuum analyze osm;"
	touch $@

db/table/osm_meta: data/planet-latest-updated.osm.pbf | db/table
	psql -c "drop table if exists osm_meta;"
	cat data/planet-latest.osm.pbf.meta.json | jq -c . | psql -1 -c 'create table osm_meta(meta jsonb);copy osm_meta from stdin freeze;'
	touch $@

db/function/osm_way_nodes_to_segments: | db/function
	psql -f functions/osm_way_nodes_to_segments.sql
	touch $@

db/function/TileBBox: | db/function
	psql -f functions/TileBBox.sql
	touch $@

db/function/ST_Pixel: | db/function
	psql -f functions/ST_Pixel.sql
	touch $@

db/table/osm_road_segments: db/table/osm db/function/osm_way_nodes_to_segments
	psql -f tables/osm_road_segments.sql
	touch $@

db/index/osm_tags_idx: db/table/osm | db/index
	psql -c "create index osm_tags_idx on osm using gin (tags);"
	touch $@

db/index/osm_geog_idx: db/table/osm | db/index
	psql -c "create index osm_geog_idx on osm using gist (geog);"
	touch $@

db/index/osm_road_segments_seg_id_node_from_node_to_seg_geom_idx: db/table/osm_road_segments | db/index
	psql -c "create index osm_road_segments_seg_id_node_from_node_to_seg_geom_idx on osm_road_segments (seg_id, node_from, node_to, seg_geom);"
	touch $@

db/index/osm_road_segments_seg_geom_idx: db/table/osm_road_segments | db/index
	psql -c "create index osm_road_segments_seg_geom_idx on osm_road_segments using gist (seg_geom);"
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

data/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.zip: | data
	wget https://cidportal.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_SMOD_POP_GLOBE_R2016A/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k/V1-0/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.zip -O $@

data/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.tif: data/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.zip
	cd data; unzip -o GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.zip
	touch $@

db/table/ghs_globe_residential_raster: data/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.tif | db/table
	psql -c "drop table if exists ghs_globe_residential_raster"
	raster2pgsql -M -Y -s 54009 data/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.tif -t auto ghs_globe_residential_raster | psql -q
	touch $@

db/table/ghs_globe_residential_vector: db/table/ghs_globe_residential_raster db/procedure/insert_projection_54009 | db/table
	psql -f tables/ghs_globe_residential_vector.sql
	touch $@

data/population_africa_2018-10-01/population_af_2018-10-01.zip: | data/population_africa_2018-10-01
	wget https://data.humdata.org/dataset/dbd7b22d-7426-4eb0-b3c4-faa29a87f44b/resource/7b3ef0ae-a37d-4a42-a2c9-6b111e592c2c/download/population_af_2018-10-01.zip -O $@

data/population_africa_2018-10-01/population_af_2018-10-01_unzip: data/population_africa_2018-10-01/population_af_2018-10-01.zip
	cd data/population_africa_2018-10-01; unzip -o population_af_2018-10-01.zip
	touch $@

data/population_africa_2018-10-01/population_af_2018-10-01_convert: data/population_africa_2018-10-01/population_af_2018-10-01_unzip
	cd data/population_africa_2018-10-01
	ls *.tif | parallel --eta 'gdalwarp -srcnodata NaN -dstnodata 0 {} 0_{}'
	touch $@

db/table/fb_africa_population_raster: data/population_africa_2018-10-01/population_af_2018-10-01_convert | db/table
	psql -c "drop table if exists fb_africa_population_raster"
	raster2pgsql -p -M -Y -s 4326 data/population_africa_2018-10-01/*.tif -t auto fb_africa_population_raster | psql -q
	ls data/population_africa_2018-10-01/0_*.tif | parallel --eta 'raster2pgsql -a -M -Y -s 4326 {} -t auto fb_africa_population_raster | psql -q'
	touch $@

db/table/fb_africa_population_vector: db/table/fb_africa_population_raster | db/table
	psql -f tables/fb_africa_population_vector.sql
	touch $@

db/procedure/insert_projection_54009: | db/procedure
	psql -f procedures/insert_projection_54009.sql || true
	touch $@

db/table/ghs_population_grid_1000: db/table/ghs_globe_population_vector db/function/ST_Pixel | db/table
	psql -f tables/ghs_population_grid_1000.sql
	touch $@

db/table/osm_object_count_grid_1000: db/table/osm db/function/ST_Pixel | db/table
	psql -f tables/osm_object_count_grid_1000.sql
	touch $@

db/table/osm_object_count_grid_1000_with_population: db/table/osm db/table/ghs_population_grid_1000 db/table/osm_object_count_grid_1000 db/function/ST_Pixel | db/table
	psql -f tables/osm_object_count_grid_1000_with_population.sql
	touch $@

db/table/osm_quality_bivariate_grid_1000: db/table/osm_object_count_grid_1000 db/table/osm_object_count_grid_1000_with_population | db/table
	psql -f tables/osm_quality_bivariate_grid_1000.sql
	touch $@

data/tiles/osm_quality_bivariate_tiles.tar.bz2: db/function/TileBBox db/table/osm_quality_bivariate_grid_1000 db/table/osm_meta | data/tiles
	bash ./scripts/generate_bivariate_class_tiles.sh | parallel --eta
	psql -q -X -f scripts/export_osm_quality_bivariate_map_legend.sql | sed s#\\\\\\\\#\\\\#g > data/tiles/osm_quality_bivariate/legend.json
	cd data/tiles/osm_quality_bivariate/; tar cjvf ../osm_quality_bivariate_tiles.tar.bz2 ./

data/population/population_api_tables.sqld.gz: db/table/ghs_globe_population_vector db/table/ghs_globe_residential_vector | data/population
	pg_dump -o -d gis -h localhost -p 5432 -U gis -t ghs_globe_population_vector -t ghs_globe_residential_vector -f data/population/population_api_tables.sqld
	gzip data/population/population_api_tables.sqld

deploy/geocint/osm_quality_bivariate_tiles: data/tiles/osm_quality_bivariate_tiles.tar.bz2 | deploy/geocint
	sudo mkdir -p /var/www/tiles; sudo chmod 777 /var/www/tiles
	rm -rf /var/www/tiles/osm_quality_bivariate_new; mkdir -p /var/www/tiles/osm_quality_bivariate_new
	cp -a data/tiles/osm_quality_bivariate/. /var/www/tiles/osm_quality_bivariate_new/
	rm -rf /var/www/tiles/osm_quality_bivariate_old
	mv /var/www/tiles/osm_quality_bivariate /var/www/tiles/osm_quality_bivariate_old; mv /var/www/tiles/osm_quality_bivariate_new /var/www/tiles/osm_quality_bivariate
	touch $@

deploy/dollar/osm_quality_bivariate_tiles: data/tiles/osm_quality_bivariate_tiles.tar.bz2 | deploy/dollar
	ssh root@disaster.ninja -C "rm -f osm_quality_bivariate_tiles.tar.bz2"
	scp data/tiles/osm_quality_bivariate_tiles.tar.bz2 root@disaster.ninja:
	ssh root@disaster.ninja -C "rm -rf /var/www/tiles/osm_quality_bivariate_new; mkdir -p /var/www/tiles/osm_quality_bivariate_new"
	ssh root@disaster.ninja -C "tar xvf osm_quality_bivariate_tiles.tar.bz2 -C /var/www/tiles/osm_quality_bivariate_new"
	ssh root@disaster.ninja -C "rm -rf /var/www/tiles/osm_quality_bivariate_old"
	ssh root@disaster.ninja -C "mv /var/www/tiles/osm_quality_bivariate /var/www/tiles/osm_quality_bivariate_old; mv /var/www/tiles/osm_quality_bivariate_new /var/www/tiles/osm_quality_bivariate"
	# TODO: remove old when we're sure we don't want to go back
	touch $@
