weekly: deploy/geocint/isochrone_tables

daily: deploy/_all db/table/osm_population_split data/population/population_api_tables.sqld.gz

clean:
	rm -rf data/planet-latest-updated.osm.pbf deploy/ data/tiles
	profile_make_clean data/planet-latest-updated.osm.pbf
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

data/tiles/stat: | data/tiles
	mkdir -p $@

data/population: | data
	mkdir -p $@

data/gadm: | data
	mkdir -p $@

data/population_africa_2018-10-01: | data
	mkdir -p $@

deploy:
	mkdir -p $@

deploy/dollar:
	mkdir -p $@

deploy/geocint:
	mkdir -p $@

deploy/_all: deploy/geocint/osm_quality_bivariate_tiles deploy/dollar/osm_quality_bivariate_tiles deploy/geocint/stats_tiles deploy/geocint/users_tiles
	touch $@

deploy/geocint/isochrone_tables: db/table/osm_road_segments db/index/osm_road_segments_seg_id_node_from_node_to_seg_geom_idx db/index/osm_road_segments_seg_geom_idx
	touch $@

data/planet-latest.osm.pbf: | data
	wget -t inf https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf -O $@
	# TODO: smoke check correctness of file
	touch $@

data/planet-latest-updated.osm.pbf: data/planet-latest.osm.pbf | data
	pyosmium-up-to-date -s 10000 -o data/planet-latest-updated.osm.pbf data/planet-latest.osm.pbf || true
	osmium fileinfo data/planet-latest-updated.osm.pbf -ej > data/planet-latest-updated.osm.pbf.meta.json
	# TODO: smoke check correctness of file
	cp -lf data/planet-latest-updated.osm.pbf data/planet-latest.osm.pbf
	cp -lf data/planet-latest-updated.osm.pbf.meta.json data/planet-latest.osm.pbf.meta.json
	touch $@

db/table/osm: data/planet-latest-updated.osm.pbf | db/table
	psql -c "drop table if exists osm;"
	osmium export -c osmium.config.json -f pg data/planet-latest.osm.pbf  -v --progress | psql -1 -c 'create table osm(geog geography, osm_type text, osm_id bigint, osm_user text, ts timestamptz, way_nodes bigint[], tags jsonb);alter table osm alter geog set storage external, alter osm_type set storage main, alter osm_user set storage main, alter way_nodes set storage external, alter tags set storage external, set (fillfactor=100); copy osm from stdin freeze;'
	psql -c "vacuum analyze osm;"
	psql -c "alter table osm set (parallel_workers=16);"
	touch $@

db/table/osm_meta: data/planet-latest-updated.osm.pbf | db/table
	psql -c "drop table if exists osm_meta;"
	cat data/planet-latest.osm.pbf.meta.json | jq -c . | psql -1 -c 'create table osm_meta(meta jsonb);copy osm_meta from stdin freeze;'
	touch $@

db/function/osm_way_nodes_to_segments: | db/function
	psql -f functions/osm_way_nodes_to_segments.sql
	touch $@

db/function/h3: | db/function
	psql -f functions/h3.sql
	touch $@

db/function/h3_resolustion: | db/function/h3
	psql -f functions/h3_resolustion.sql
	touch $@

db/table/osm_road_segments: db/table/osm db/function/osm_way_nodes_to_segments
	psql -f tables/osm_road_segments.sql
	touch $@

db/index/osm_tags_idx: db/table/osm | db/index
	psql -c "create index osm_tags_idx on osm using gin (tags);"
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

db/table/osm_user_count_grid_h3: db/table/osm db/function/h3
	psql -f tables/osm_user_count_grid_h3.sql
	psql -f tables/osm_users_scatter.sql
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

db/procedure/trim_water_in_osm_population_raw: db/procedure/decimate_admin_level_in_osm_population_raw db/table/osm_water_polygons | db/procedure
	psql -f procedures/trim_water_in_osm_population_raw.sql
	touch $@

db/table/osm_population_split: db/procedure/trim_water_in_osm_population_raw | db/table
	psql -f tables/osm_population_split.sql
	touch $@

data/population_hrsl: | data
	mkdir -p $@

data/population_hrsl/download: | data/population_hrsl
	cd data/population_hrsl; wget -c https://www.ciesin.columbia.edu/repository/hrsl/hrsl_phl_v1.zip
	cd data/population_hrsl; wget -c https://www.ciesin.columbia.edu/repository/hrsl/hrsl_idn_v1.zip
	cd data/population_hrsl; wget -c https://www.ciesin.columbia.edu/repository/hrsl/hrsl_khm_v1.zip
	cd data/population_hrsl; wget -c https://www.ciesin.columbia.edu/repository/hrsl/hrsl_tha_v1.zip
	cd data/population_hrsl; wget -c https://www.ciesin.columbia.edu/repository/hrsl/hrsl_lka_v1.zip
	cd data/population_hrsl; wget -c https://www.ciesin.columbia.edu/repository/hrsl/hrsl_arg_v1.zip
	cd data/population_hrsl; wget -c https://www.ciesin.columbia.edu/repository/hrsl/hrsl_pri_v1.zip
	cd data/population_hrsl; wget -c https://www.ciesin.columbia.edu/repository/hrsl/hrsl_hti_v1.zip
	cd data/population_hrsl; wget -c https://www.ciesin.columbia.edu/repository/hrsl/hrsl_gtm_v1.zip
	cd data/population_hrsl; wget -c https://www.ciesin.columbia.edu/repository/hrsl/hrsl_mex_v1.zip
	touch $@

data/population_hrsl/unzip: data/population_hrsl/download
	rm -rf *tif
	cd data/population_hrsl; ls *zip | parallel "unzip -o {}"
	cd data/population_hrsl; ls *pop.tif | parallel 'gdal_translate -co "TILED=YES" -co "COMPRESS=DEFLATE" {} tiled_{}'
	touch $@

db/table/hrsl_population_raster: data/population_hrsl/unzip | db/table
	psql -c "drop table if exists hrsl_population_raster"
	raster2pgsql -p -M -Y -s 4326 data/population_hrsl/tiled_*pop.tif -t auto hrsl_population_raster | psql -q
	psql -c 'alter table hrsl_population_raster drop CONSTRAINT hrsl_population_raster_pkey;'
	ls data/population_hrsl/tiled_*pop.tif | parallel --eta 'GDAL_CACHEMAX=10000 GDAL_NUM_THREADS=4 raster2pgsql -a -M -Y -s 4326 {} -t 256x256 hrsl_population_raster | psql -q'
	touch $@

db/table/hrsl_population_vector: db/table/hrsl_population_raster
	psql -f tables/hrsl_population_vector.sql
	touch $@

db/table/hrsl_population_boundary: | db/table
	psql -f tables/hrsl_population_boundary.sql
	touch $@

db/table/fb_africa_population_boundary: db/table/gadm_countries_boundary | db/table
	psql -f tables/fb_africa_population_boundary.sql
	touch $@

db/table/fb_population_boundary: db/table/gadm_countries_boundary db/table/fb_country_codes | db/table
	psql -f tables/fb_population_boundary.sql
	touch $@

db/table/population_vector: db/table/hrsl_population_vector db/table/hrsl_population_boundary db/table/ghs_globe_population_vector db/table/fb_africa_population_vector db/table/fb_africa_population_boundary db/table/fb_population_vector db/table/fb_population_boundary | db/table
	psql -f tables/population_vector.sql
	touch $@

db/table/ghs_globe_population_vector: db/table/ghs_globe_population_raster db/procedure/insert_projection_54009 | db/table
	psql -f tables/ghs_globe_population_vector.sql
	touch $@

data/GHS_POP_E2015_GLOBE_R2019A_54009_250_V1_0.zip: | data
	wget http://cidportal.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_MT_GLOBE_R2019A/GHS_POP_E2015_GLOBE_R2019A_54009_250/V1-0/GHS_POP_E2015_GLOBE_R2019A_54009_250_V1_0.zip -O $@

data/GHS_POP_E2015_GLOBE_R2019A_54009_250_V1_0.tif: data/GHS_POP_E2015_GLOBE_R2019A_54009_250_V1_0.zip
	cd data; unzip -o GHS_POP_E2015_GLOBE_R2019A_54009_250_V1_0.zip
	touch $@

db/table/ghs_globe_population_raster: data/GHS_POP_E2015_GLOBE_R2019A_54009_250_V1_0.tif | db/table
	psql -c "drop table if exists ghs_globe_population_raster"
	raster2pgsql -M -Y -s 54009 data/GHS_POP_E2015_GLOBE_R2019A_54009_250_V1_0.tif -t auto ghs_globe_population_raster | psql -q
	psql -c "alter table ghs_globe_population_raster set (parallel_workers=32);"
	touch $@

data/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.zip: | data
	wget https://cidportal.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_SMOD_POP_GLOBE_R2016A/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k/V1-0/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.zip -O $@

data/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.tif: data/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.zip
	cd data; unzip -o GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.zip
	touch $@

db/table/ghs_globe_residential_raster: data/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.tif | db/table
	psql -c "drop table if exists ghs_globe_residential_raster"
	raster2pgsql -M -Y -s 54009 data/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.tif -t 256x256 ghs_globe_residential_raster | psql -q
	touch $@

db/table/ghs_globe_residential_vector: db/table/ghs_globe_residential_raster db/procedure/insert_projection_54009 | db/table
	psql -f tables/ghs_globe_residential_vector.sql
	touch $@

data/population_africa_2018-10-01/population_af_2018-10-01.zip: | data/population_africa_2018-10-01
	wget https://data.humdata.org/dataset/dbd7b22d-7426-4eb0-b3c4-faa29a87f44b/resource/7b3ef0ae-a37d-4a42-a2c9-6b111e592c2c/download/population_af_2018-10-01.zip -O $@

data/population_africa_2018-10-01/population_af_2018-10-01_unzip: data/population_africa_2018-10-01/population_af_2018-10-01.zip
	cd data/population_africa_2018-10-01; unzip -o population_af_2018-10-01.zip
	touch $@

db/table/fb_africa_population_raster: data/population_africa_2018-10-01/population_af_2018-10-01_unzip | db/table
	psql -c "drop table if exists fb_africa_population_raster"
	raster2pgsql -p -M -Y -s 4326 data/population_africa_2018-10-01/*.tif -t auto fb_africa_population_raster | psql -q
	psql -c 'alter table fb_africa_population_raster drop CONSTRAINT fb_africa_population_raster_pkey;'
	ls data/population_africa_2018-10-01/*.tif | parallel --eta 'raster2pgsql -a -M -Y -s 4326 {} -t 256x256 fb_africa_population_raster | psql -q'
	psql -c "alter table fb_africa_population_raster set (parallel_workers=32)"
	touch $@

db/table/fb_africa_population_vector: db/table/fb_africa_population_raster | db/table
	psql -f tables/fb_africa_population_vector.sql
	touch $@

db/table/fb_country_codes: data/population_fb/unzip | db/table
	psql -c "drop table if exists fb_country_codes"
	psql -c "create table fb_country_codes (code varchar(3) not null, primary key (code))"
	cd data/population_fb; ls *tif | parallel -eta psql -c "\"insert into fb_country_codes(code) select upper(substr('{}',12,3)) where not exists (select code from fb_country_codes where code = upper(substr('{}',12,3)))\""
	touch $@

data/population_fb: |data
	mkdir -p $@

data/population_fb/download: | data/population_fb
	cd data/population_fb; curl "https://data.humdata.org/api/3/action/resource_search?query=url:population_" | jq '.result.results[].url' -r | sed -n '/population_[a-z]\{3\}_[a-z_]*[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}_geotiff.zip/p' | parallel --eta "wget -N {}"
	cd data/population_fb; curl "https://data.humdata.org/api/3/action/resource_search?query=url:population_" | jq '.result.results[].url' -r | sed -n '/population_[a-z]\{3\}_[a-z_]*[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.zip/p' | parallel --eta "wget -N {}"
	touch $@

data/population_fb/unzip: data/population_fb/download
	cd data/population_fb; rm -rf *tif
	cd data/population_fb; rm -rf *xml
	cd data/population_fb; ls *zip | parallel "unzip -o {}"
	touch $@

db/table/fb_population_raster: data/population_fb/unzip | db/table
	psql -c "drop table if exists fb_population_raster"
	raster2pgsql -p -M -Y -s 4326 data/population_fb/*.tif -t auto fb_population_raster | psql -q
	psql -c 'alter table fb_population_raster drop CONSTRAINT fb_population_raster_pkey;'
	ls data/population_fb/*.tif | parallel --eta 'raster2pgsql -a -M -Y -s 4326 {} -t 256x256 fb_population_raster | psql -q'
	psql -c "alter table fb_population_raster set (parallel_workers=32)"
	touch $@

db/table/fb_population_vector: db/table/fb_population_raster | db/table
	psql -f tables/fb_population_vector.sql
	touch $@

data/gadm/gadm36_levels_shp.zip: | data/gadm
	wget https://web.archive.org/web/20190829093806if_/https://data.biogeo.ucdavis.edu/data/gadm3.6/gadm36_levels_shp.zip -O $@

data/gadm/gadm36_0.shp: data/gadm/gadm36_levels_shp.zip
	cd data/gadm; unzip -o gadm36_levels_shp.zip || true
	touch $@

db/table/gadm_countries_boundary: data/gadm/gadm36_0.shp | db/table
	psql -c "drop table if exists gadm_countries_boundary"
	shp2pgsql -I -s 4326 data/gadm/gadm36_0.shp gadm_countries_boundary | psql -q
	psql -c "alter table gadm_countries_boundary alter column geom set data type geometry;"
	psql -c "update gadm_countries_boundary set geom = ST_Transform(ST_ClipByBox2D(geom, ST_Transform(ST_TileEnvelope(0,0,0),4326)), 3857);"
	touch $@

data/water-polygons-split-3857.zip: | data
	wget https://osmdata.openstreetmap.de/download/water-polygons-split-3857.zip -O $@

data/water_polygons.shp: data/water-polygons-split-3857.zip
	cd data; unzip -o water-polygons-split-3857.zip
	touch $@

db/table/water_polygons_vector: data/water_polygons.shp | db/table
	psql -c "drop table if exists water_polygons_vector"
	shp2pgsql -I -s 3857 data/water-polygons-split-3857/water_polygons.shp water_polygons_vector | psql -q
	touch $@

db/table/osm_water_lines: db/index/osm_tags_idx | db/table
	psql -f tables/osm_water_lines.sql
	touch $@

db/table/osm_water_polygons: db/index/osm_tags_idx db/table/water_polygons_vector db/table/osm_water_lines | db/table
	psql -f tables/osm_water_polygons.sql
	touch $@

db/procedure/insert_projection_54009: | db/procedure
	psql -f procedures/insert_projection_54009.sql || true
	touch $@

db/table/population_vector_nowater: db/table/population_vector db/table/osm_water_polygons
	psql -f tables/population_vector_nowater.sql
	touch $@

db/table/population_grid_h3: db/table/population_vector_nowater db/function/h3 | db/table 
	psql -f tables/population_grid_h3.sql
	touch $@

db/table/osm_object_count_grid_h3: db/table/osm db/function/h3 | db/table db/index/osm_tags_idx
	psql -f tables/osm_object_count_grid_h3.sql
	touch $@

db/table/osm_object_count_grid_h3_with_population: db/table/osm db/table/population_grid_h3 db/table/osm_object_count_grid_h3 db/table/osm_user_count_grid_h3 db/function/h3 | db/table
	psql -f tables/osm_object_count_grid_h3_with_population.sql
	touch $@

db/table/osm_quality_bivariate_grid_h3: db/table/osm_object_count_grid_h3 db/table/osm_object_count_grid_h3_with_population db/function/h3 | db/table
	psql -f tables/osm_quality_bivariate_grid_h3.sql
	touch $@

db/table/bivariate_axis: db/table/osm_object_count_grid_h3_with_population | data/tiles/stat
	psql -f tables/bivariate_axis.sql
	touch $@

data/tiles/osm_quality_bivariate_tiles.tar.bz2: db/table/osm_quality_bivariate_grid_h3 db/table/osm_meta | data/tiles
	bash ./scripts/generate_tiles.sh osm_quality_bivariate | parallel --eta
	psql -q -X -f scripts/export_osm_quality_bivariate_map_legend.sql | sed s#\\\\\\\\#\\\\#g > data/tiles/osm_quality_bivariate/legend.json
	cd data/tiles/osm_quality_bivariate/; tar cjvf ../osm_quality_bivariate_tiles.tar.bz2 ./

data/tiles/stats_tiles.tar.bz2: db/table/bivariate_axis db/table/osm_object_count_grid_h3_with_population db/table/osm_meta | data/tiles
	bash ./scripts/generate_tiles.sh stats | parallel --eta
	psql -q -X -f scripts/export_osm_bivariate_map_axis.sql | sed s#\\\\\\\\#\\\\#g > data/tiles/stat/stat.json
	cd data/tiles/stats/; tar cjvf ../stats_tiles.tar.bz2 ./

deploy/geocint/stats_tiles: data/tiles/stats_tiles.tar.bz2 | deploy/geocint
	sudo mkdir -p /var/www/tiles; sudo chmod 777 /var/www/tiles
	rm -rf /var/www/tiles/stats_new; mkdir -p /var/www/tiles/stats_new
	cp -a data/tiles/stats/. /var/www/tiles/stats_new/
	rm -rf /var/www/tiles/stats_old
	mv /var/www/tiles/stats /var/www/tiles/stats_old; mv /var/www/tiles/stats_new /var/www/tiles/stats
	touch $@

data/tiles/users_tiles.tar.bz2: db/table/osm_user_count_grid_h3 db/table/osm_meta db/function/h3_resolustion | data/tiles
	bash ./scripts/generate_tiles.sh users | parallel --eta
	cd data/tiles/users/; tar cjvf ../users_tiles.tar.bz2 ./

deploy/geocint/users_tiles: data/tiles/users_tiles.tar.bz2 | deploy/geocint
	sudo mkdir -p /var/www/tiles; sudo chmod 777 /var/www/tiles
	rm -rf /var/www/tiles/users_new; mkdir -p /var/www/tiles/users_new
	cp -a data/tiles/users/. /var/www/tiles/users_new/
	rm -rf /var/www/tiles/users_old
	mv /var/www/tiles/users /var/www/tiles/users_old; mv /var/www/tiles/users_new /var/www/tiles/users
	touch $@

data/population/population_api_tables.sqld.gz: db/table/population_vector db/table/ghs_globe_residential_vector | data/population
	pg_dump -t population_vector -t ghs_globe_residential_vector | pigz > $@

deploy/geocint/osm_quality_bivariate_tiles: data/tiles/osm_quality_bivariate_tiles.tar.bz2 | deploy/geocint
	sudo mkdir -p /var/www/tiles; sudo chmod 777 /var/www/tiles
	rm -rf /var/www/tiles/osm_quality_bivariate_new; mkdir -p /var/www/tiles/osm_quality_bivariate_new
	cp -a data/tiles/osm_quality_bivariate/. /var/www/tiles/osm_quality_bivariate_new/
	rm -rf /var/www/tiles/osm_quality_bivariate_old
	mv /var/www/tiles/osm_quality_bivariate /var/www/tiles/osm_quality_bivariate_old; mv /var/www/tiles/osm_quality_bivariate_new /var/www/tiles/osm_quality_bivariate
	touch $@

deploy/dollar/osm_quality_bivariate_tiles: data/tiles/osm_quality_bivariate_tiles.tar.bz2 | deploy/dollar
	ssh root@dollar.disaster.ninja -C "rm -f osm_quality_bivariate_tiles.tar.bz2"
	scp data/tiles/osm_quality_bivariate_tiles.tar.bz2 root@dollar.disaster.ninja:
	ssh root@dollar.disaster.ninja -C "rm -rf /var/www/tiles/osm_quality_bivariate_new; mkdir -p /var/www/tiles/osm_quality_bivariate_new"
	ssh root@dollar.disaster.ninja -C "tar xvf osm_quality_bivariate_tiles.tar.bz2 -C /var/www/tiles/osm_quality_bivariate_new"
	ssh root@dollar.disaster.ninja -C "rm -rf /var/www/tiles/osm_quality_bivariate_old"
	ssh root@dollar.disaster.ninja -C "mv /var/www/tiles/osm_quality_bivariate /var/www/tiles/osm_quality_bivariate_old; mv /var/www/tiles/osm_quality_bivariate_new /var/www/tiles/osm_quality_bivariate"
	# TODO: remove old when we're sure we don't want to go back
	touch $@
