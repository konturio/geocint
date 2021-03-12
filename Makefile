dev: deploy/geocint/belarus-latest.osm.pbf deploy/geocint/stats_tiles deploy/geocint/users_tiles deploy/zigzag/stats_tiles deploy/zigzag/users_tiles deploy/sonic/stats_tiles deploy/sonic/users_tiles deploy/geocint/isochrone_tables deploy/zigzag/population_api_tables deploy/sonic/population_api_tables deploy/s3/test/osm_addresses_minsk data/population/population_api_tables.sqld.gz data/kontur_population.gpkg.gz db/table/covid19 db/table/population_grid_h3_r8_osm_scaled data/morocco data/planet-check-refs ## [FINAL] Builds all targets for development. Run on every branch.

prod: deploy/lima/stats_tiles deploy/lima/users_tiles deploy/lima/population_api_tables deploy/lima/osrm-backend-by-car deploy/geocint/global_fires_h3_r8_13months.csv.gz deploy/s3/osm_buildings_minsk deploy/s3/osm_addresses_minsk deploy/s3/osm_admin_boundaries ## [FINAL] Deploys artifacts to production. Runs only on master branch.

clean: ## [FINAL] Cleans the worktree for next nightly run. Does not clean non-repeating targets.
	if [ -f data/planet-is-broken ]; then rm -rf data/planet-latest.osm.pbf ; fi
	rm -rf deploy/ data/tiles data/tile_logs/index.html data/planet-is-broken
	profile_make_clean data/planet-latest-updated.osm.pbf data/covid19/_csv data/tile_logs/_download data/global_fires/download_new_updates db/table/morocco_buildings_manual db/table/morocco_buildings_manual_roofprints data/covid19/covid19_cases_us_counties.csv
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

data/wb: | data
	mkdir -p $@

data/wb/gdp: | data/wb
	mkdir -p $@

data/gebco_2020_geotiff: | data
	mkdir -p $@

deploy:
	mkdir -p $@

deploy/lima: | deploy
	mkdir -p $@

# We use sonic.kontur.io as a staging server to test the software before setting it live at lima.kontur.io.
deploy/sonic: | deploy
	mkdir -p $@

deploy/zigzag: | deploy
	mkdir -p $@

deploy/geocint: | deploy
	mkdir -p $@

deploy/s3:
	mkdir -p $@/test

deploy/geocint/isochrone_tables: db/table/osm_road_segments db/table/osm_road_segments_new db/index/osm_road_segments_new_seg_id_node_from_node_to_seg_geom_idx db/index/osm_road_segments_new_seg_geom_idx
	touch $@

deploy/geocint/belarus-latest.osm.pbf: data/belarus-latest.osm.pbf | deploy/geocint
	cp data/belarus-latest.osm.pbf ~/public_html/belarus-latest.osm.pbf
	touch $@

deploy/lima/osrm-backend-by-car: deploy/geocint/belarus-latest.osm.pbf | deploy/lima
	aws sqs send-message --output json --region eu-central-1 --queue-url https://sqs.eu-central-1.amazonaws.com/001426858141/PuppetmasterInbound.fifo --message-body '{"jsonrpc":"2.0","method":"rebuildDockerImage","params":{"imageName":"kontur-osrm-backend-by-car","osmPbfUrl":"https://geocint.kontur.io/gis/belarus-latest.osm.pbf"},"id":"'`uuid`'"}' --message-group-id rebuildDockerImage--kontur-osrm-backend-by-car
	touch $@

data/planet-latest.osm.pbf: | data
	rm -f data/planet-*.osm.pbf data/planet-latest.seq data/planet-latest.osm.pbf.meta.json
	cd data; aria2c https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf.torrent --seed-time=0
	mv data/planet-*.osm.pbf $@
	rm -f data/planet-*.osm.pbf.torrent
	# TODO: smoke check correctness of file
	touch $@

data/planet-latest-updated.osm.pbf: data/planet-latest.osm.pbf | data
	rm -f data/planet-diff.osc
	if [ -f data/planet-latest.seq ]; then pyosmium-get-changes -vv -s 50000 --server "https://planet.osm.org/replication/hour/" -f data/planet-latest.seq -o data/planet-diff.osc; else pyosmium-get-changes -vv -s 50000 --server "https://planet.osm.org/replication/hour/" -O data/planet-latest.osm.pbf -f data/planet-latest.seq -o data/planet-diff.osc; fi ||true
	rm -f data/planet-latest-updated.osm.pbf data/planet-latest-updated.osm.pbf.meta.json
	osmium apply-changes data/planet-latest.osm.pbf data/planet-diff.osc -f pbf,pbf_compression=false -o data/planet-latest-updated.osm.pbf
	# TODO: smoke check correctness of file
	cp -lf data/planet-latest-updated.osm.pbf data/planet-latest.osm.pbf
	touch $@

data/planet-check-refs: data/planet-latest-updated.osm.pbf | data
	osmium check-refs -r --no-progress data/planet-latest.osm.pbf || touch data/planet-is-broken
	touch $@

data/belarus-latest.osm.pbf: data/planet-latest-updated.osm.pbf data/belarus_boundary.geojson | data
	osmium extract -v -s smart -p data/belarus_boundary.geojson data/planet-latest-updated.osm.pbf -o data/belarus-latest.osm.pbf --overwrite
	touch $@

data/covid19: | data
	mkdir -p $@

data/covid19/_csv: | data/covid19
	wget "https://data.humdata.org/hxlproxy/api/data-preview.csv?url=https%3A%2F%2Fraw.githubusercontent.com%2FCSSEGISandData%2FCOVID-19%2Fmaster%2Fcsse_covid_19_data%2Fcsse_covid_19_time_series%2Ftime_series_covid19_confirmed_global.csv&filename=time_series_covid19_confirmed_global.csv" -O data/covid19/time_series_confirmed.csv
	wget "https://data.humdata.org/hxlproxy/api/data-preview.csv?url=https%3A%2F%2Fraw.githubusercontent.com%2FCSSEGISandData%2FCOVID-19%2Fmaster%2Fcsse_covid_19_data%2Fcsse_covid_19_time_series%2Ftime_series_covid19_deaths_global.csv&filename=time_series_covid19_deaths_global.csv" -O data/covid19/time_series_deaths.csv
	wget "https://data.humdata.org/hxlproxy/api/data-preview.csv?url=https%3A%2F%2Fraw.githubusercontent.com%2FCSSEGISandData%2FCOVID-19%2Fmaster%2Fcsse_covid_19_data%2Fcsse_covid_19_time_series%2Ftime_series_covid19_recovered_global.csv&filename=time_series_covid19_recovered_global.csv" -O data/covid19/time_series_recovered.csv
	touch $@

db/table/covid19: data/covid19/_csv db/table/kontur_population_h3 db/index/osm_tags_idx
	psql -c 'drop table if exists covid19_in;'
	psql -c 'create table covid19_in (province text, country text, lat float, lon float, date timestamptz, value int, status text);'
	rm -f data/covid19/*_normalized.csv
	ls data/covid19/time_series_* | parallel "python3 scripts/covid19_normalization.py {}"
	cat data/covid19/time_series_confirmed_normalized.csv | tail -n +1 | psql -c "set time zone utc;copy covid19_in (province, country, lat, lon, date, value) from stdin with csv header;"
	psql -c "update covid19_in set status='confirmed' where status is null;"
	cat data/covid19/time_series_deaths_normalized.csv | tail -n +1 | psql -c "set time zone utc;copy covid19_in (province, country, lat, lon, date, value) from stdin with csv header;"
	psql -c "update covid19_in set status='dead' where status is null;"
	cat data/covid19/time_series_recovered_normalized.csv | tail -n +1 | psql -c "set time zone utc;copy covid19_in (province, country, lat, lon, date, value) from stdin with csv header;"
	psql -c "update covid19_in set status='recovered' where status is null;"
	psql -f tables/covid19.sql
	touch $@

data/covid19/covid19_cases_us_counties.csv: | data/covid19
	wget -q "https://delphi.cmu.edu/csv?signal=indicator-combination:confirmed_7dav_incidence_prop&start_day=2021-01-01&end_day=$(shell date +%Y-%m-%d)&geo_type=county" -O $@

db/table/covid19_cases_us_counties: data/covid19/covid19_cases_us_counties.csv db/table/us_counties_boundary | db/table
	psql -c "drop table if exists covid19_cases_us_counties_csv"
	psql -c "create table covid19_cases_us_counties_csv (id integer, geo_value text, signal text, time_value date, issue date, lag integer, value float, stderr text, sample_size text, geo_type text, data_source text);"
	cat data/covid19/covid19_cases_us_counties.csv | psql -c "copy covid19_cases_us_counties_csv (id, geo_value, signal, time_value, issue, lag, value, stderr, sample_size, geo_type, data_source) from stdin with csv header delimiter ',';"
	psql -f tables/covid19_cases_us_counties.sql
	touch $@

db/table/us_counties_boundary: data/gadm/gadm36_shp_files | db/table
	psql -c 'drop table if exists gadm_us_counties_boundary;'
	ogr2ogr -f PostgreSQL PG:"dbname=gis" data/gadm/gadm36_2.shp -sql "select name_1, name_2, gid_2, hasc_2 from gadm36_2 where gid_0 = 'USA'" -nln gadm_us_counties_boundary -nlt MULTIPOLYGON -lco GEOMETRY_NAME=geom
	ogr2ogr -append -f PostgreSQL PG:"dbname='gis'" data/gadm/gadm36_1.shp -sql "select name_0 as name_1, name_1 as name_2, gid_1 as gid_2, hasc_1 as hasc_2 from gadm36_1 where gid_0 = 'PRI'" -nln gadm_us_counties_boundary -nlt MULTIPOLYGON -lco GEOMETRY_NAME=geom
	psql -c 'drop table if exists us_counties_fips_codes;'
	psql -c 'create table us_counties_fips_codes (state text, county text, hasc_code text, fips_code text);'
	cat data/counties_fips_hasc.csv | psql -c "copy us_counties_fips_codes (state, county, hasc_code, fips_code) from stdin with csv header delimiter ',';"
	psql -c 'drop table if exists us_counties_boundary;'
	psql -c 'create table us_counties_boundary as (select gid_2 as gid, geom, state, county, hasc_code, fips_code from gadm_us_counties_boundary join us_counties_fips_codes on hasc_2 = hasc_code);'
	touch $@

db/table/covid19_cases_us_counties_h3: db/table/covid19_cases_us_counties
	psql -f tables/covid19_cases_us_counties_h3.sql
	touch $@

data/covid19/vaccination: | data/covid19
	mkdir -p $@

data/covid19/vaccination/vaccine_acceptance_us_counties.csv: | data/covid19/vaccination
	wget -q "https://delphi.cmu.edu/csv?signal=fb-survey:smoothed_accept_covid_vaccine&start_day=2021-01-01&end_day=$(shell date +%F)&geo_type=county" -O $@

db/table/covid19_vaccine_accept_us_counties: data/covid19/vaccination/vaccine_acceptance_us_counties.csv db/table/us_counties_boundary
	psql -c 'drop table if exists covid19_vaccine_accept_us;'
	psql -c 'create table covid19_vaccine_accept_us (ogc_fid serial not null, geo_value text, signal text, time_value timestamptz, issue timestamptz, lag int, value float, stderr float, sample_size float, geo_type text, data_source text);'
	cat data/covid19/vaccination/vaccine_acceptance_us_counties.csv | psql -c 'copy covid19_vaccine_accept_us (ogc_fid, geo_value, signal, time_value, issue, lag, value, stderr, sample_size, geo_type, data_source) from stdin with csv header;'
	psql -f tables/covid19_vaccine_accept_us_counties.sql
	touch $@

db/table/covid19_vaccine_accept_us_counties_h3: db/table/covid19_vaccine_accept_us_counties
	psql -f tables/covid19_vaccine_accept_us_counties_h3.sql
	touch $@

db/table/osm: data/planet-latest-updated.osm.pbf | db/table
	psql -c "drop table if exists osm;"
	OSMIUM_POOL_THREADS=8 OSMIUM_MAX_INPUT_QUEUE_SIZE=100 OSMIUM_MAX_OSMDATA_QUEUE_SIZE=100 OSMIUM_MAX_OUTPUT_QUEUE_SIZE=100 OSMIUM_MAX_WORK_QUEUE_SIZE=100 numactl --preferred=1 -N 1 osmium export -i dense_mmap_array -c osmium.config.json -f pg data/planet-latest.osm.pbf  -v --progress | psql -1 -c 'create table osm(geog geography, osm_type text, osm_id bigint, osm_user text, ts timestamptz, way_nodes bigint[], tags jsonb);alter table osm alter geog set storage external, alter osm_type set storage main, alter osm_user set storage main, alter way_nodes set storage external, alter tags set storage external, set (fillfactor=100); copy osm from stdin freeze;'
	touch $@

db/table/osm_meta: data/planet-latest-updated.osm.pbf | db/table
	psql -c "drop table if exists osm_meta;"
	rm -f data/planet-latest-updated.osm.pbf.meta.json
	osmium fileinfo data/planet-latest.osm.pbf -ej > data/planet-latest.osm.pbf.meta.json
	cat data/planet-latest.osm.pbf.meta.json | jq -c . | psql -1 -c 'create table osm_meta(meta jsonb); copy osm_meta from stdin freeze;'
	touch $@

data/belarus_boundary.geojson: db/table/osm db/index/osm_tags_idx
	psql -q -X -c "\copy (select ST_AsGeoJSON(belarus) from (select geog::geometry as polygon from osm where osm_type = 'relation' and osm_id = 59065 and tags @> '{\"boundary\":\"administrative\"}') belarus) to stdout" | jq -c . > data/belarus_boundary.geojson
	touch $@

db/function/osm_way_nodes_to_segments: | db/function
	psql -f functions/osm_way_nodes_to_segments.sql
	touch $@

db/function/h3: | db/function
	psql -f functions/h3.sql
	touch $@

db/function/calculate_h3_res: db/function/h3
	psql -f functions/calculate_h3_res.sql
	touch $@

db/function/h3_raster_sum_to_h3: | db/function
	psql -f functions/h3_raster_sum_to_h3.sql
	touch $@

db/table/osm_roads: db/table/osm db/index/osm_tags_idx
	psql -f tables/osm_roads.sql
	touch $@

db/table/osm_road_segments_new: db/function/osm_way_nodes_to_segments db/table/osm_roads
	psql -f tables/osm_road_segments.sql
	touch $@

db/index/osm_tags_idx: db/table/osm | db/index
	psql -c "create index osm_tags_idx on osm using gin (tags);"
	touch $@

db/index/osm_road_segments_new_seg_id_node_from_node_to_seg_geom_idx: db/table/osm_road_segments_new | db/index
	psql -c "create index osm_road_segments_new_seg_id_node_from_node_to_seg_geom_idx on osm_road_segments_new (seg_id, node_from, node_to, seg_geom);"
	touch $@

db/index/osm_road_segments_new_seg_geom_idx: db/table/osm_road_segments_new | db/index
	psql -c "create index osm_road_segments_new_seg_geom_walk_time_idx on osm_road_segments_new using brin (seg_geom, walk_time);"
	touch $@

db/table/osm_road_segments: db/table/osm_road_segments_new db/index/osm_road_segments_new_seg_geom_idx db/index/osm_road_segments_new_seg_id_node_from_node_to_seg_geom_idx | db/table
	psql -1 -c "drop table if exists osm_road_segments; alter table osm_road_segments_new rename to osm_road_segments;"
	psql -c "alter index if exists osm_road_segments_new_seg_geom_walk_time_idx rename to osm_road_segments_seg_geom_walk_time_idx;"
	psql -c "alter index if exists osm_road_segments_new_seg_id_node_from_node_to_seg_geom_idx rename to osm_road_segments_seg_id_node_from_node_to_seg_geom_idx;"
	touch $@

db/table/osm_user_count_grid_h3: db/table/osm db/function/h3
	psql -f tables/osm_user_count_grid_h3.sql
	touch $@

db/table/osm_users_hex: db/table/osm_user_count_grid_h3 db/table/osm_local_active_users
	psql -f tables/osm_users_hex.sql
	touch $@

db/procedure: | db
	mkdir -p $@

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
	cd data/population_hrsl; ls *.zip | parallel "unzip -o {}"
	cd data/population_hrsl; ls *pop.tif | parallel 'gdal_translate -co "TILED=YES" -co "COMPRESS=DEFLATE" {} tiled_{}'
	touch $@

db/table/hrsl_population_raster: data/population_hrsl/unzip | db/table
	psql -c "drop table if exists hrsl_population_raster"
	raster2pgsql -p -M -Y -s 4326 data/population_hrsl/tiled_*pop.tif -t auto hrsl_population_raster | psql -q
	psql -c 'alter table hrsl_population_raster drop CONSTRAINT hrsl_population_raster_pkey;'
	ls data/population_hrsl/tiled_*pop.tif | parallel --eta 'GDAL_CACHEMAX=10000 GDAL_NUM_THREADS=4 raster2pgsql -a -M -Y -s 4326 {} -t 256x256 hrsl_population_raster | psql -q'
	touch $@

db/table/hrsl_population_grid_h3_r8: db/table/hrsl_population_raster db/function/h3_raster_sum_to_h3
	psql -f tables/hrsl_population_grid_h3_r8.sql
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

db/table/osm_unpopulated: db/index/osm_tags_idx | db/table
	psql -f tables/osm_unpopulated.sql
	touch $@

db/table/ghs_globe_population_grid_h3_r8: db/table/ghs_globe_population_raster db/procedure/insert_projection_54009 db/function/h3_raster_sum_to_h3 | db/table
	psql -f tables/ghs_globe_population_grid_h3_r8.sql
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

db/table/ghs_globe_residential_vector: db/table/ghs_globe_residential_raster db/procedure/insert_projection_54009 db/function/h3_raster_sum_to_h3 | db/table
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

db/table/fb_africa_population_grid_h3_r8: db/table/fb_africa_population_raster db/function/h3_raster_sum_to_h3 | db/table
	psql -f tables/fb_africa_population_grid_h3_r8.sql
	touch $@

db/table/fb_country_codes: data/population_fb/unzip | db/table
	psql -c "drop table if exists fb_country_codes"
	psql -c "create table fb_country_codes (code varchar(3) not null, primary key (code))"
	cd data/population_fb; ls *.tif | parallel -eta psql -c "\"insert into fb_country_codes(code) select upper(substr('{}',12,3)) where not exists (select code from fb_country_codes where code = upper(substr('{}',12,3)))\""
	touch $@

data/copernicus_landcover: | data
	mkdir -p $@

data/copernicus_landcover/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.tif: data/copernicus_landcover
	cd data/copernicus_landcover; wget -c -nc https://zenodo.org/record/3939050/files/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.tif

db/table/copernicus_landcover_raster: data/copernicus_landcover/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.tif | db/table
	psql -c "drop table if exists copernicus_landcover_raster"
	raster2pgsql -M -Y -s 4326 data/copernicus_landcover/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.tif -t auto copernicus_landcover_raster | psql -q
	touch $@

db/table/copernicus_builtup_raster_h3_r8: db/table/copernicus_landcover_raster | db/table
	psql -f tables/copernicus_builtup_raster_h3_r8.sql
	touch $@

data/population_fb: | data
	mkdir -p $@

data/population_fb/download: | data/population_fb
	cd data/population_fb; curl "https://data.humdata.org/api/3/action/resource_search?query=url:population_" | jq '.result.results[].url' -r | sed -n '/population_[a-z]\{3\}_[a-z_]*[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}_geotiff.zip/p' | parallel --eta "wget -N {}"
	cd data/population_fb; curl "https://data.humdata.org/api/3/action/resource_search?query=url:population_" | jq '.result.results[].url' -r | sed -n '/population_[a-z]\{3\}_[a-z_]*[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.zip/p' | parallel --eta "wget -N {}"
	touch $@

data/population_fb/unzip: data/population_fb/download
	cd data/population_fb; rm -rf *.tif
	cd data/population_fb; rm -rf *.xml
	cd data/population_fb; ls *.zip | parallel "unzip -o {}"
	touch $@

db/table/osm_residential_landuse: db/index/osm_tags_idx
	psql -f tables/osm_residential_landuse.sql
	touch $@

db/table/fb_population_raster: data/population_fb/unzip | db/table
	psql -c "drop table if exists fb_population_raster"
	raster2pgsql -p -M -Y -s 4326 data/population_fb/*.tif -t auto fb_population_raster | psql -q
	psql -c 'alter table fb_population_raster drop CONSTRAINT fb_population_raster_pkey;'
	ls data/population_fb/*.tif | parallel --eta 'raster2pgsql -a -M -Y -s 4326 {} -t 256x256 fb_population_raster | psql -q'
	psql -c "alter table fb_population_raster set (parallel_workers=32)"
	touch $@

data/gebco_2020_geotiff/gebco_2020_geotiff.zip: | data/gebco_2020_geotiff
	wget "https://www.bodc.ac.uk/data/open_download/gebco/gebco_2020/geotiff/" -O $@

data/gebco_2020_geotiff/gebco_2020_geotiffs_unzip: data/gebco_2020_geotiff/gebco_2020_geotiff.zip
	cd data/gebco_2020_geotiff; unzip -o gebco_2020_geotiff.zip
	rm -f data/gebco_2020_geotiff/*.pdf
	touch $@

data/gebco_2020_geotiff/gebco_2020_merged.vrt: data/gebco_2020_geotiff/gebco_2020_geotiffs_unzip
	gdalbuildvrt $@ data/gebco_2020_geotiff/gebco_2020_n*.tif

data/gebco_2020_geotiff/gebco_2020_merged_3857.vrt: data/gebco_2020_geotiff/gebco_2020_merged.vrt
	gdalwarp -s_srs EPSG:4326 -t_srs epsg:3857 -r bilinear -of VRT data/gebco_2020_geotiff/gebco_2020_merged.vrt $@

data/gebco_2020_geotiff/gebco_2020_merged_3857_slope.tif: data/gebco_2020_geotiff/gebco_2020_merged_3857.vrt
	gdaldem slope -of GTiff data/gebco_2020_geotiff/gebco_2020_merged_3857.vrt $@
	rm -f data/gebco_2020_geotiff/*.vrt

data/gebco_2020_geotiff/gebco_2020_merged_4326_slope.tif: data/gebco_2020_geotiff/gebco_2020_merged_3857_slope.tif
	gdalwarp -s_srs EPSG:3395 -t_srs EPSG:4326 -of COG -co TILED=YES data/gebco_2020_geotiff/gebco_2020_merged_3857_slope.tif $@
	rm -f data/gebco_2020_geotiff/gebco_2020_merged_3857_slope.tif

db/table/gebco_2020_slopes: data/gebco_2020_geotiff/gebco_2020_merged_4326_slope.tif | db/table
	psql -c "drop table if exists gebco_2020_slopes"
	raster2pgsql -M -Y -s 4326 data/gebco_2020_geotiff/gebco_2020_merged_4326_slope.tif -t auto gebco_2020_slopes | psql -q
	rm -f data/gebco_2020_geotiff/gebco_2020_merged_4326_slope.tif
	touch $@

db/table/gebco_2020_slopes_h3: db/table/gebco_2020_slopes | db/table
	psql -f tables/gebco_2020_slopes_h3.sql
	touch $@

db/table/osm_building_count_grid_h3_r8: db/table/osm_buildings | db/table
	psql -f tables/osm_building_count_grid_h3_r8.sql
	touch $@

db/table/building_count_grid_h3: db/table/osm_building_count_grid_h3_r8 db/table/us_microsoft_buildings_h3 db/table/morocco_urban_pixel_mask_h3 db/table/morocco_buildings_h3 db/table/copernicus_builtup_raster_h3_r8 db/table/canada_microsoft_buildings_h3 db/table/africa_microsoft_buildings_h3 | db/table
	psql -f tables/building_count_grid_h3.sql
	touch $@

db/table/fb_population_grid_h3_r8: db/table/fb_population_raster db/function/h3_raster_sum_to_h3 | db/table
	psql -f tables/fb_population_grid_h3_r8.sql
	touch $@

data/gadm/gadm36_levels_shp.zip: | data/gadm
	wget https://web.archive.org/web/20190829093806if_/https://data.biogeo.ucdavis.edu/data/gadm3.6/gadm36_levels_shp.zip -O $@

data/gadm/gadm36_shp_files: data/gadm/gadm36_levels_shp.zip
	cd data/gadm; unzip -o gadm36_levels_shp.zip || true
	touch $@

db/table/gadm_countries_boundary: data/gadm/gadm36_shp_files | db/table
	psql -c "drop table if exists gadm_countries_boundary"
	shp2pgsql -I -s 4326 data/gadm/gadm36_0.shp gadm_countries_boundary | psql -q
	psql -c "alter table gadm_countries_boundary alter column geom set data type geometry;"
	psql -c "update gadm_countries_boundary set geom = ST_Transform(ST_ClipByBox2D(geom, ST_Transform(ST_TileEnvelope(0,0,0),4326)), 3857);"
	touch $@

data/wb/gdp/wb_gdp.zip: | data/wb/gdp
	wget http://api.worldbank.org/v2/en/indicator/NY.GDP.MKTP.CD?downloadformat=xml -O $@

data/wb/gdp/wb_gdp.xml: data/wb/gdp/wb_gdp.zip
	cd data/wb/gdp; unzip -o wb_gdp.zip
	cat data/wb/gdp/API_NY*.xml | tr -d '\n\r\t' | sed 's/^.\{1\}//' >> data/wb/gdp/wb_gdp.xml
	touch $@

db/table/wb_gdp: data/wb/gdp/wb_gdp.xml | db/table
	psql -c "drop table if exists temp_xml;"
	psql -c "create table temp_xml ( value text );"
	cat data/wb/gdp/wb_gdp.xml | psql -c "COPY temp_xml(value) FROM stdin DELIMITER E'\t' CSV QUOTE '''';"
	psql -f tables/wb_gdp.sql
	psql -c "drop table if exists temp_xml;"
	touch $@

db/table/wb_gadm_gdp_countries: db/table/wb_gdp db/table/gadm_countries_boundary
	psql -f tables/wb_gadm_gdp_countries.sql
	touch $@

db/table/gdp_h3: db/table/kontur_population_h3 db/table/wb_gadm_gdp_countries
	psql -f tables/gdp_h3.sql
	touch $@

data/water-polygons-split-3857.zip: | data
	wget https://osmdata.openstreetmap.de/download/water-polygons-split-3857.zip -O $@

data/water_polygons.shp: data/water-polygons-split-3857.zip
	cd data; unzip -o water-polygons-split-3857.zip
	touch $@

db/table/water_polygons_vector: data/water_polygons.shp | db/table
	psql -c "drop table if exists water_polygons_vector"
	shp2pgsql -I -s 3857 data/water-polygons-split-3857/water_polygons.shp water_polygons_vector | psql -q
	psql -f tables/water_polygons_vector.sql
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

db/table/population_grid_h3_r8: db/table/hrsl_population_grid_h3_r8 db/table/hrsl_population_boundary db/table/ghs_globe_population_grid_h3_r8 db/table/fb_africa_population_grid_h3_r8 db/table/fb_africa_population_boundary db/table/fb_population_grid_h3_r8 db/table/fb_population_boundary | db/table
	psql -f tables/population_grid_h3_r8.sql
	touch $@

db/table/osm_local_active_users: db/function/h3 db/table/osm_user_count_grid_h3 | db/table
	psql -f tables/osm_local_active_users.sql
	touch $@

db/table/user_hours_h3: db/function/h3 db/table/osm_user_count_grid_h3 db/table/osm_local_active_users | db/table
	psql -f tables/user_hours_h3.sql
	touch $@

db/table/osm_object_count_grid_h3: db/table/osm db/function/h3 db/table/osm_meta | db/table
	psql -f tables/osm_object_count_grid_h3.sql
	touch $@

data/global_fires: | data
	mkdir -p $@

data/global_fires/download_new_updates: | data/global_fires
	mkdir -p data/global_fires/new_updates
	rm -f data/global_fires/new_updates/*.csv
	cd data/global_fires/new_updates; wget https://firms.modaps.eosdis.nasa.gov/data/active_fire/c6/csv/MODIS_C6_Global_48h.csv
	cd data/global_fires/new_updates; wget https://firms.modaps.eosdis.nasa.gov/data/active_fire/suomi-npp-viirs-c2/csv/SUOMI_VIIRS_C2_Global_48h.csv
	cd data/global_fires/new_updates; wget https://firms.modaps.eosdis.nasa.gov/data/active_fire/noaa-20-viirs-c2/csv/J1_VIIRS_C2_Global_48h.csv
	cp data/global_fires/new_updates/*.csv data/global_fires/
	touch $@

data/global_fires/copy_old_data: | data/global_fires
	cp data/firms/old_tables/*.csv data/global_fires/
	touch $@

db/table/global_fires: data/global_fires/download_new_updates data/global_fires/copy_old_data |  db/table
	psql -c "create table if not exists global_fires (id serial primary key, latitude float, longitude float, brightness float, bright_ti4 float, scan float, track float, satellite text, instrument text, confidence text, version text, bright_t31 float, bright_ti5 float, frp float, daynight text, acq_datetime timestamptz, hash text, h3_r8 h3index GENERATED ALWAYS AS (h3_geo_to_h3(ST_SetSrid(ST_Point(longitude, latitude), 4326), 8)) STORED);"
	rm -f data/global_fires/*_proc.csv
	ls data/global_fires/*.csv | parallel "python3 scripts/normalize_global_fires.py {}"
	ls data/global_fires/*_proc.csv | parallel "cat {} | psql -c \"set time zone utc; copy global_fires (latitude, longitude, brightness, bright_ti4, scan, track, satellite, confidence, version, bright_t31, bright_ti5, frp, daynight, acq_datetime, hash) from stdin with csv header;\" "
	psql -c "create index if not exists global_fires_hash_idx on global_fires (hash);"
	psql -c "create index if not exists global_fires_acq_datetime_idx on global_fires using brin (acq_datetime);"
	psql -c "delete from global_fires where id in(select id from(select id, row_number() over(partition by hash order by id) as row_num from global_fires) t where t.row_num > 1);"
	rm data/global_fires/*.csv
	touch $@

db/table/global_fires_stat_h3: db/table/global_fires
	psql -f tables/global_fires_stat_h3.sql
	touch $@

data/global_fires/global_fires_h3_r8_13months.csv.gz: db/table/global_fires
	rm -rf $@
	psql -q -X -c "set timezone to utc; copy (select h3_r8, acq_datetime from global_fires where acq_datetime > (select max(acq_datetime) from global_fires) - interval '13 months' order by 1,2) to stdout with csv;" | pigz > $@

deploy/geocint/global_fires_h3_r8_13months.csv.gz: data/global_fires/global_fires_h3_r8_13months.csv.gz | deploy/geocint
	cp -vp data/global_fires/global_fires_h3_r8_13months.csv.gz ~/public_html/global_fires_h3_r8_13months.csv.gz
	touch $@

db/table/morocco_urban_pixel_mask: data/morocco_urban_pixel_mask.gpkg | db/table
	ogr2ogr -f PostgreSQL PG:"dbname=gis" data/morocco_urban_pixel_mask.gpkg
	touch $@

db/table/morocco_urban_pixel_mask_h3: db/table/morocco_urban_pixel_mask
	psql -f tables/morocco_urban_pixel_mask_h3.sql
	touch $@

db/table/morocco_buildings_h3: db/table/morocco_buildings | db/table
	psql -f tables/morocco_buildings_h3.sql
	touch $@

data/africa_buildings: | data
	mkdir -p $@

data/africa_buildings/download: | data/africa_buildings
	cd data/africa_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/tanzania-uganda-buildings/Uganda_2019-09-16.zip
	cd data/africa_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/tanzania-uganda-buildings/Tanzania_2019-09-16.zip
	touch $@

data/africa_buildings/unzip: data/africa_buildings/download
	cd data/africa_buildings; ls *.zip | parallel "unzip -o {}"
	touch $@

db/table/africa_microsoft_buildings: data/africa_buildings/unzip | db/table
	psql -c "drop table if exists africa_microsoft_buildings"
	psql -c "create table africa_microsoft_buildings (ogc_fid serial not null, wkb_geometry geometry)"
	cd data/africa_buildings; ls *.geojson | parallel 'ogr2ogr -append -f PostgreSQL PG:"dbname=gis" {} -nln africa_microsoft_buildings'
	touch $@

db/table/africa_microsoft_buildings_h3: db/table/africa_microsoft_buildings | db/table
	psql -f tables/africa_microsoft_buildings_h3.sql
	touch $@

data/canada_buildings: | data
	mkdir -p $@

data/canada_buildings/download: | data/canada_buildings
	cd data/canada_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/Alberta.zip
	cd data/canada_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/BritishColumbia.zip
	cd data/canada_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/Manitoba.zip
	cd data/canada_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/NewBrunswick.zip
	cd data/canada_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/NewfoundlandAndLabrador.zip
	cd data/canada_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/NorthwestTerritories.zip
	cd data/canada_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/NovaScotia.zip
	cd data/canada_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/Nunavut.zip
	cd data/canada_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/Ontario.zip
	cd data/canada_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/PrinceEdwardIsland.zip
	cd data/canada_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/Quebec.zip
	cd data/canada_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/Saskatchewan.zip
	cd data/canada_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/YukonTerritory.zip
	touch $@

data/canada_buildings/unzip: data/canada_buildings/download
	cd data/canada_buildings; ls *.zip | parallel "unzip -o {}"
	touch $@

db/table/canada_microsoft_buildings: data/canada_buildings/unzip | db/table
	psql -c "drop table if exists canada_microsoft_buildings"
	psql -c "create table canada_microsoft_buildings (ogc_fid serial not null, wkb_geometry geometry)"
	cd data/canada_buildings; ls *.geojson | parallel 'ogr2ogr -append -f PostgreSQL PG:"dbname=gis" {} -nln canada_microsoft_buildings'
	touch $@

db/table/canada_microsoft_buildings_h3: db/table/canada_microsoft_buildings | db/table
	psql -f tables/canada_microsoft_buildings_h3.sql
	touch $@

data/us_buildings: | data
	mkdir -p $@

data/us_buildings/download: | data/us_buildings
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Alabama.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Alaska.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Arizona.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Arkansas.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/California.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Colorado.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Connecticut.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Delaware.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/DistrictofColumbia.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Florida.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Georgia.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Hawaii.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Idaho.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Illinois.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Indiana.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Iowa.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Kansas.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Kentucky.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Louisiana.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Maine.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Maryland.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Massachusetts.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Michigan.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Minnesota.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Mississippi.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Missouri.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Montana.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Nebraska.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Nevada.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/NewHampshire.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/NewJersey.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/NewMexico.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/NewYork.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/NorthCarolina.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/NorthDakota.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Ohio.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Oklahoma.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Oregon.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Pennsylvania.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/RhodeIsland.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/SouthCarolina.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/SouthDakota.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Tennessee.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Texas.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Utah.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Vermont.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Virginia.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Washington.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/WestVirginia.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Wisconsin.zip
	cd data/us_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Wyoming.zip
	touch $@

data/us_buildings/unzip: data/us_buildings/download
	cd data/us_buildings; ls *.zip | parallel "unzip -o {}"
	touch $@

db/table/us_microsoft_buildings: data/us_buildings/unzip | db/table
	psql -c "drop table if exists us_microsoft_buildings"
	psql -c "create table us_microsoft_buildings (ogc_fid serial not null, wkb_geometry geometry)"
	cd data/us_buildings; ls *.geojson | parallel 'ogr2ogr -append -f PostgreSQL PG:"dbname=gis" {} -nln us_microsoft_buildings'
	touch $@

db/table/us_microsoft_buildings_h3: db/table/us_microsoft_buildings | db/table
	psql -f tables/us_microsoft_buildings_h3.sql
	touch $@

db/table/kontur_population_h3: db/table/osm_residential_landuse db/table/population_grid_h3_r8 db/table/building_count_grid_h3 db/table/osm_unpopulated db/table/osm_water_polygons db/function/h3 db/table/morocco_urban_pixel_mask_h3 db/index/osm_tags_idx | db/table
	psql -f tables/kontur_population_h3.sql
	touch $@

data/kontur_population.gpkg.gz: db/table/kontur_population_h3
	rm -f $@
	rm -f data/kontur_population.gpkg
	ogr2ogr -f GPKG data/kontur_population.gpkg PG:'dbname=gis' -sql "select geom, population from kontur_population_h3 where population>0 and resolution=8 order by h3" -lco "SPATIAL_INDEX=NO" -nln kontur_population
	cd data/; pigz kontur_population.gpkg

db/table/osm_population_raw: db/table/osm db/index/osm_tags_idx | db/table
	psql -f tables/osm_population_raw.sql
	touch $@

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

db/table/morocco_buildings_manual_roofprints: data/morocco_buildings/morocco_buildings_manual_roof_20201030.geojson
	psql -c "drop table if exists morocco_buildings_manual_roofprints;"
	ogr2ogr -f PostgreSQL PG:"dbname=gis" data/morocco_buildings/morocco_buildings_manual_roof_20201030.geojson -nln morocco_buildings_manual_roofprints
	psql -c "alter table morocco_buildings_manual_roofprints rename column wkb_geometry to geom;"
	psql -c "alter table morocco_buildings_manual_roofprints alter column geom type geometry;"
	psql -c "update morocco_buildings_manual_roofprints set geom = ST_Transform(geom, 3857);"
	touch $@

db/table/morocco_buildings_manual: data/morocco_buildings/morocco_buildings_manual_20201030.geojson
	psql -c "drop table if exists morocco_buildings_manual;"
	ogr2ogr -f PostgreSQL PG:"dbname=gis" data/morocco_buildings/morocco_buildings_manual_20201030.geojson -nln morocco_buildings_manual
	psql -c "alter table morocco_buildings_manual rename column wkb_geometry to geom;"
	psql -c "alter table morocco_buildings_manual alter column geom type geometry;"
	psql -c "update morocco_buildings_manual set geom = ST_CollectionExtract(ST_MakeValid(ST_Transform(geom, 3857)), 3) where ST_SRID(geom) != 3857 or not ST_IsValid(geom);"
	touch $@

db/table/morocco_buildings: data/morocco_buildings/geoalert_morocco_stage_3.gpkg | db/table
	psql -c "drop table if exists morocco_buildings;"
	ogr2ogr -f PostgreSQL PG:"dbname=gis" data/morocco_buildings/geoalert_morocco_stage_3.gpkg "buildings_3" -nln morocco_buildings
	psql -f tables/morocco_buildings.sql
	touch $@

data/morocco_buildings/morocco_buildings_footprints_phase3.geojson.gz: db/table/morocco_buildings
	rm -f $@ data/morocco_buildings/morocco_buildings_footprints_phase3.geojson
	ogr2ogr -f GeoJSON data/morocco_buildings/morocco_buildings_footprints_phase3.geojson PG:"dbname=gis" -sql "select ST_Transform(geom, 4326) as footprint, building_height, height_confidence, is_residential, imagery_vintage, height_is_valid from morocco_buildings_date" -nln morocco_buildings_footprints_phase3
	cd data/morocco_buildings; pigz morocco_buildings_footprints_phase3.geojson

db/table/morocco_buildings_benchmark: data/morocco_buildings/phase_3/footprints/agadir_footprints_benchmark_ph3.geojson data/morocco_buildings/phase_3/footprints/casablanca_footprints_benchmark_ph3.geojson data/morocco_buildings/phase_3/footprints/chefchaouen_footprints_benchmark_ph3.geojson data/morocco_buildings/phase_3/footprints/fes_footprints_benchmark_ph3.geojson data/morocco_buildings/phase_3/footprints/meknes_footprints_benchmark_ph3.geojson | db/table
	psql -c "drop table if exists morocco_buildings_benchmark;"
	ogr2ogr -f PostgreSQL PG:"dbname=gis" data/morocco_buildings/phase_3/footprints/agadir_footprints_benchmark_ph3.geojson -nln morocco_buildings_benchmark
	psql -c "alter table morocco_buildings_benchmark add column city text;"
	psql -c "alter table morocco_buildings_benchmark alter column wkb_geometry type geometry;"
	psql -c "update morocco_buildings_benchmark set city = 'Agadir' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" data/morocco_buildings/phase_3/footprints/casablanca_footprints_benchmark_ph3.geojson -nln morocco_buildings_benchmark
	psql -c "update morocco_buildings_benchmark set city = 'Casablanca' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" data/morocco_buildings/phase_3/footprints/chefchaouen_footprints_benchmark_ph3.geojson -nln morocco_buildings_benchmark
	psql -c "update morocco_buildings_benchmark set city = 'Chefchaouen' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" data/morocco_buildings/phase_3/footprints/fes_footprints_benchmark_ph3.geojson -nln morocco_buildings_benchmark
	psql -c "update morocco_buildings_benchmark set city = 'Fes' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" data/morocco_buildings/phase_3/footprints/meknes_footprints_benchmark_ph3.geojson -nln morocco_buildings_benchmark
	psql -c "update morocco_buildings_benchmark set city = 'Meknes' where city is null;"
	psql -f tables/morocco_buildings_benchmark.sql -v morocco_buildings=morocco_buildings_benchmark
	touch $@

db/table/morocco_buildings_benchmark_roofprints: data/morocco_buildings/phase_3/roofprints/agadir_roofptints_benchmark_ph3.geojson data/morocco_buildings/phase_3/roofprints/casablanca_roofptints_benchmark_ph3.geojson data/morocco_buildings/phase_3/roofprints/chefchaouen_roofptints_benchmark_ph3.geojson data/morocco_buildings/phase_3/roofprints/fes_roofptints_benchmark_ph3.geojson data/morocco_buildings/phase_3/roofprints/meknes_roofptints_benchmark_ph3.geojson | db/table
	psql -c "drop table if exists morocco_buildings_benchmark_roofprints;"
	ogr2ogr -f PostgreSQL PG:"dbname=gis" data/morocco_buildings/phase_3/roofprints/agadir_roofptints_benchmark_ph3.geojson -nln morocco_buildings_benchmark_roofprints
	psql -c "alter table morocco_buildings_benchmark_roofprints add column city text;"
	psql -c "alter table morocco_buildings_benchmark_roofprints alter column wkb_geometry type geometry;"
	psql -c "update morocco_buildings_benchmark_roofprints set city = 'Agadir' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" data/morocco_buildings/phase_3/roofprints/casablanca_roofptints_benchmark_ph3.geojson -nln morocco_buildings_benchmark_roofprints
	psql -c "update morocco_buildings_benchmark_roofprints set city = 'Casablanca' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" data/morocco_buildings/phase_3/roofprints/chefchaouen_roofptints_benchmark_ph3.geojson -nln morocco_buildings_benchmark_roofprints
	psql -c "update morocco_buildings_benchmark_roofprints set city = 'Chefchaouen' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" data/morocco_buildings/phase_3/roofprints/fes_roofptints_benchmark_ph3.geojson -nln morocco_buildings_benchmark_roofprints
	psql -c "update morocco_buildings_benchmark_roofprints set city = 'Fes' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" data/morocco_buildings/phase_3/roofprints/meknes_roofptints_benchmark_ph3.geojson -nln morocco_buildings_benchmark_roofprints
	psql -c "update morocco_buildings_benchmark_roofprints set city = 'Meknes' where city is null;"
	psql -f tables/morocco_buildings_benchmark.sql -v morocco_buildings=morocco_buildings_benchmark_roofprints
	touch $@

db/table/morocco_buildings_extents: data/morocco_buildings/extents/agadir_extents.geojson data/morocco_buildings/extents/casablanca_extents.geojson data/morocco_buildings/extents/chefchaouen_extents.geojson data/morocco_buildings/extents/fes_extents.geojson data/morocco_buildings/extents/meknes_extents.geojson | db/table
	psql -c "drop table if exists morocco_buildings_extents;"
	ogr2ogr -f PostgreSQL PG:"dbname=gis" data/morocco_buildings/extents/agadir_extents.geojson -a_srs EPSG:3857 -nln morocco_buildings_extents
	psql -c "alter table morocco_buildings_extents add column city text;"
	psql -c "alter table morocco_buildings_extents alter column wkb_geometry type geometry;"
	psql -c "update morocco_buildings_extents set city = 'Agadir' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" data/morocco_buildings/extents/casablanca_extents.geojson -a_srs EPSG:3857 -nln morocco_buildings_extents
	psql -c "update morocco_buildings_extents set city = 'Casablanca' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" data/morocco_buildings/extents/chefchaouen_extents.geojson -a_srs EPSG:3857 -nln morocco_buildings_extents
	psql -c "update morocco_buildings_extents set city = 'Chefchaouen' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" data/morocco_buildings/extents/fes_extents.geojson -a_srs EPSG:3857 -nln morocco_buildings_extents
	psql -c "update morocco_buildings_extents set city = 'Fes' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" data/morocco_buildings/extents/meknes_extents.geojson -a_srs EPSG:3857 -nln morocco_buildings_extents
	psql -c "update morocco_buildings_extents set city = 'Meknes' where city is null;"
	psql -c "alter table morocco_buildings_extents rename column wkb_geometry to geom; update morocco_buildings_extents set geom = ST_Transform(geom, 3857);"
	touch $@

db/table/morocco_buildings_footprints_phase3_clipped: db/table/morocco_buildings db/table/morocco_buildings_extents
	psql -c "drop table if exists morocco_buildings_footprints_phase3_clipped;"
	psql -c "create table morocco_buildings_footprints_phase3_clipped as (select a.* from morocco_buildings a join morocco_buildings_extents b on ST_Intersects(a.geom, ST_Transform(b.geom, 4326)));"
	psql -c "update morocco_buildings_footprints_phase3_clipped set geom = ST_CollectionExtract(ST_MakeValid(ST_Transform(geom, 3857)), 3) where ST_SRID(geom) != 3857 or not ST_IsValid(geom);"
	touch $@

db/table/morocco_buildings_manual_roofprints_phase3: data/morocco_buildings/phase_3/fes_meknes_height_patch.geojson db/table/morocco_buildings_manual_roofprints | db/table
	psql -c "drop table if exists morocco_buildings_manual_roofprints_phase3;"
	psql -c "create table morocco_buildings_manual_roofprints_phase3 as (select * from morocco_buildings_manual_roofprints);"
	psql -c "drop table if exists fes_meknes_height_patch;"
	ogr2ogr -f PostgreSQL PG:"dbname=gis" data/morocco_buildings/phase_3/fes_meknes_height_patch.geojson -nln fes_meknes_height_patch
	psql -c "alter table fes_meknes_height_patch alter column wkb_geometry type geometry;"
	psql -c "update fes_meknes_height_patch set wkb_geometry = ST_Transform(wkb_geometry, 3857);"
	psql -c "update morocco_buildings_manual_roofprints_phase3 a set building_height = machine_height, is_confident = true from fes_meknes_height_patch b where ST_Intersects(ST_PointOnSurface(a.geom), wkb_geometry) and better = 'robo';"
	psql -c "update morocco_buildings_manual_roofprints_phase3 a set is_confident = false from fes_meknes_height_patch b where ST_Intersects(ST_PointOnSurface(a.geom), wkb_geometry) and better = 'wtf';"
	psql -c "update morocco_buildings_manual_roofprints_phase3 a set is_confident = true from fes_meknes_height_patch b where ST_Intersects(ST_PointOnSurface(a.geom), wkb_geometry) and better = 'man';"
	psql -c "update morocco_buildings_manual_roofprints_phase3 set geom = ST_CollectionExtract(ST_MakeValid(ST_Transform(geom, 3857)), 3) where ST_SRID(geom) != 3857 or not ST_IsValid(geom);"
	touch $@

db/table/morocco_buildings_iou: db/table/morocco_buildings_benchmark_roofprints db/table/morocco_buildings_benchmark db/table/morocco_buildings_manual_roofprints db/table/morocco_buildings_manual db/table/morocco_buildings_extents db/table/morocco_buildings_footprints_phase3_clipped db/table/morocco_buildings_manual_roofprints_phase3
	rm -f data/morocco_buildings/metric_storage.csv
	psql -f tables/morocco_buildings_iou.sql -v reference_buildings_table=morocco_buildings_manual_roofprints_phase3 -v examinee_buildings_table=morocco_buildings_benchmark_roofprints -v benchmark_clip_table=morocco_buildings_extents -v type=roof
	echo "morocco_buildings_manual_roofprints_phase3 & morocco_buildings_benchmark_roofprints tables, type=roof" > data/morocco_buildings/metric_storage.csv
	psql -q -c '\crosstabview' -A -F "," -c "select city, metric, value from metrics_storage order by 1;" | head -6 >> data/morocco_buildings/metric_storage.csv
	psql -f tables/morocco_buildings_iou.sql -v reference_buildings_table=morocco_buildings_manual -v examinee_buildings_table=morocco_buildings_benchmark -v benchmark_clip_table=morocco_buildings_extents -v type=foot
	echo "morocco_buildings_manual & morocco_buildings_benchmark tables, type=foot" >> data/morocco_buildings/metric_storage.csv
	psql -q -c '\crosstabview' -A -F "," -c "select city, metric, value from metrics_storage order by 1;" | head -6 >> data/morocco_buildings/metric_storage.csv
	echo "morocco_buildings_manual & morocco_buildings_footprints_phase3_clipped tables, type=foot" >> data/morocco_buildings/metric_storage.csv
	psql -f tables/morocco_buildings_iou.sql -v reference_buildings_table=morocco_buildings_manual -v examinee_buildings_table=morocco_buildings_footprints_phase3_clipped -v benchmark_clip_table=morocco_buildings_extents -v type=foot
	psql -q -c '\crosstabview' -A -F "," -c "select city, metric, value from metrics_storage order by 1;" | head -6 >> data/morocco_buildings/metric_storage.csv
	touch $@

data/morocco_buildings/morocco_buildings_manual_phase2.geojson.gz: db/table/morocco_buildings_iou db/table/morocco_buildings_manual
	rm -f $@
	ogr2ogr -f GeoJSON data/morocco_buildings/morocco_buildings_manual_phase2.geojson PG:'dbname=gis' -sql 'select ST_Transform(footprint, 4326), building_height, city, is_confident from morocco_buildings_manual_extent' -nln morocco_buildings_manual_phase2
	cd data/morocco_buildings; pigz morocco_buildings_manual_phase2.geojson

data/morocco_buildings/morocco_buildings_manual_roofprints_phase2.geojson.gz: db/table/morocco_buildings_iou db/table/morocco_buildings_manual_roofprints
	rm -f $@
	ogr2ogr -f GeoJSON data/morocco_buildings/morocco_buildings_manual_roofprints_phase2.geojson PG:'dbname=gis' -sql 'select ST_Transform(geom, 4326), building_height, city, is_confident from morocco_buildings_manual_roofprints_extent' -nln morocco_buildings_manual_roofprints_phase2
	cd data/morocco_buildings; pigz morocco_buildings_manual_roofprints_phase2.geojson

data/morocco_buildings/morocco_buildings_benchmark_phase2.geojson.gz: db/table/morocco_buildings_benchmark
	rm -f $@
	ogr2ogr -f GeoJSON data/morocco_buildings/morocco_buildings_benchmark_phase2.geojson PG:'dbname=gis' -sql 'select ST_Transform(geom, 4326), building_height, city, height_confidence, is_residential from morocco_buildings_benchmark' -nln morocco_buildings_benchmark
	cd data/morocco_buildings; pigz morocco_buildings_benchmark_phase2.geojson

data/morocco_buildings/morocco_buildings_benchmark_roofprints_phase2.geojson.gz: db/table/morocco_buildings_benchmark_roofprints
	rm -f $@
	ogr2ogr -f GeoJSON data/morocco_buildings/morocco_buildings_benchmark_roofprints_phase2.geojson PG:'dbname=gis' -sql 'select ST_Transform(geom, 4326), building_height, city, height_confidence, is_residential from morocco_buildings_benchmark_roofprints' -nln morocco_buildings_benchmark_roofprints
	cd data/morocco_buildings; pigz morocco_buildings_benchmark_roofprints_phase2.geojson

data/morocco: data/morocco_buildings/morocco_buildings_footprints_phase3.geojson.gz data/morocco_buildings/morocco_buildings_benchmark_roofprints_phase2.geojson.gz data/morocco_buildings/morocco_buildings_benchmark_phase2.geojson.gz data/morocco_buildings/morocco_buildings_footprints_phase2.geojson.gz data/morocco_buildings/morocco_buildings_manual_roofprints_phase2.geojson.gz data/morocco_buildings/morocco_buildings_manual_phase2.geojson.gz | data
	touch $@

db/table/osm_population_raw_idx: db/table/osm_population_raw
	psql -c "create index on osm_population_raw using gist(geom)"
	touch $@

db/table/population_grid_h3_r8_osm_scaled: db/table/population_grid_h3_r8 db/procedure/decimate_admin_level_in_osm_population_raw db/table/osm_population_raw_idx
	psql -f tables/population_grid_h3_r8_osm_scaled.sql
	touch $@

db/table/osm_landuses: db/table/osm db/index/osm_tags_idx | db/table
	psql -f tables/osm_landuses.sql
	touch $@

db/index/osm_landuses_geom_idx: db/table/osm_landuses | db/index
	psql -c "create index on osm_landuses using brin (geom)"
	touch $@

db/table/osm_landuses_minsk: db/table/osm_landuses db/index/osm_landuses_geom_idx | db/table
	psql -f tables/osm_landuses_minsk.sql
	touch $@

db/table/osm_buildings_minsk: db/index/osm_buildings_geom_idx db/table/osm_landuses_minsk db/index/osm_landuses_geom_idx | db/table
	psql -f tables/osm_buildings_minsk.sql
	touch $@

data/osm_buildings_minsk.geojson.gz: db/table/osm_buildings_minsk
	rm -f $@
	rm -f data/osm_buildings_minsk.geojson*
	ogr2ogr -f GeoJSON data/osm_buildings_minsk.geojson PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, name, geom from osm_buildings_minsk' -nln osm_buildings_minsk
	cd data/; pigz osm_buildings_minsk.geojson

deploy/s3/osm_buildings_minsk: data/osm_buildings_minsk.geojson.gz | deploy/s3
	aws s3api put-object --bucket geodata-us-east-1-kontur --key public/geocint/osm_buildings_minsk.geojson.gz --body data/osm_buildings_minsk.geojson.gz --content-type "application/json" --content-encoding "gzip" --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers
	touch $@

db/table/osm_addresses: db/table/osm db/index/osm_tags_idx | db/table
	psql -f tables/osm_addresses.sql
	touch $@

db/index/osm_addresses_geom_idx: db/table/osm_addresses | db/index
	psql -c "create index on osm_addresses using brin (geom)"
	touch $@

db/table/osm_addresses_minsk: db/index/osm_addresses_geom_idx db/table/osm_addresses | db/table
	psql -f tables/osm_addresses_minsk.sql
	touch $@

data/osm_addresses_minsk.geojson.gz: db/table/osm_addresses_minsk
	rm -vf data/osm_addresses_minsk.geojson*
	ogr2ogr -f GeoJSON data/osm_addresses_minsk.geojson PG:'dbname=gis' -sql "select * from osm_addresses_minsk" -lco "SPATIAL_INDEX=NO" -nln osm_addresses_minsk
	pigz data/osm_addresses_minsk.geojson
	touch $@

deploy/s3/test/osm_addresses_minsk: data/osm_addresses_minsk.geojson.gz | deploy/s3
	aws s3api copy-object --copy-source geodata-us-east-1-kontur/public/geocint/test/osm_addresses_minsk.geojson.gz --bucket geodata-us-east-1-kontur --key public/geocint/test/osm_addresses_minsk.geojson.gz.bak --content-type "application/json" --content-encoding "gzip" --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers
	aws s3api put-object --bucket geodata-us-east-1-kontur --key public/geocint/test/osm_addresses_minsk.geojson.gz --body data/osm_addresses_minsk.geojson.gz --content-type "application/json" --content-encoding "gzip" --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers
	touch $@

deploy/s3/osm_addresses_minsk: data/osm_addresses_minsk.geojson.gz | deploy/s3
	aws s3api copy-object --copy-source geodata-us-east-1-kontur/public/geocint/osm_addresses_minsk.geojson.gz --bucket geodata-us-east-1-kontur --key public/geocint/osm_addresses_minsk.geojson.gz.bak --content-type "application/json" --content-encoding "gzip" --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers
	aws s3api put-object --bucket geodata-us-east-1-kontur --key public/geocint/osm_addresses_minsk.geojson.gz --body data/osm_addresses_minsk.geojson.gz --content-type "application/json" --content-encoding "gzip" --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers
	touch $@

db/table/osm_admin_boundaries: db/table/osm db/index/osm_tags_idx | db/table
	psql -f tables/osm_admin_boundaries.sql
	touch $@

data/osm_admin_boundaries.geojson.gz: db/table/osm_admin_boundaries
	rm -vf data/osm_admin_boundaries.geojson*
	ogr2ogr -f GeoJSON data/osm_admin_boundaries.geojson PG:'dbname=gis' -sql "select * from osm_admin_boundaries" -lco "SPATIAL_INDEX=NO" -nln osm_admin_boundaries
	pigz data/osm_admin_boundaries.geojson
	touch $@

deploy/s3/osm_admin_boundaries: data/osm_admin_boundaries.geojson.gz | deploy/s3
	aws s3api put-object --bucket geodata-us-east-1-kontur --key public/geocint/osm_admin_boundaries.geojson.gz --body data/osm_admin_boundaries.geojson.gz --content-type "application/json" --content-encoding "gzip" --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers
	touch $@

db/index/osm_buildings_geom_idx: db/table/osm_buildings | db/index
	psql -c "create index on osm_buildings using brin (geom)"
	touch $@

db/table/osm_buildings: db/index/osm_tags_idx | db/table
	psql -f tables/osm_buildings.sql
	touch $@

db/table/residential_pop_h3: db/table/kontur_population_h3 db/table/ghs_globe_residential_vector | db/table
	psql -f tables/residential_pop_h3.sql
	touch $@

db/table/stat_h3: db/table/osm_object_count_grid_h3 db/table/residential_pop_h3 db/table/gdp_h3 db/table/user_hours_h3 db/table/tile_logs db/table/global_fires_stat_h3 db/table/building_count_grid_h3 db/table/covid19_vaccine_accept_us_counties_h3 db/table/covid19_cases_us_counties_h3 db/table/gebco_2020_slopes_h3| db/table
	psql -f tables/stat_h3.sql
	touch $@

db/table/bivariate_axis: db/table/bivariate_indicators db/table/stat_h3 | data/tiles/stat
	psql -f tables/bivariate_axis.sql
	psql -f tables/bivariate_axis_correlation.sql
	touch $@

db/table/bivariate_overlays: db/table/osm_meta | db/table
	psql -f tables/bivariate_overlays.sql
	touch $@

db/table/bivariate_indicators: db/table/stat_h3 | db/table
	psql -f tables/bivariate_indicators.sql
	touch $@

db/table/bivariate_colors: db/table/stat_h3 | db/table
	psql -f tables/bivariate_colors.sql
	touch $@

data/tile_logs: | data
	mkdir -p $@

data/tile_logs/_download: | data/tile_logs data
	cd data/tile_logs/ && wget -A xz -r -l 1 -nd -np -nc https://planet.openstreetmap.org/tile_logs/
	touch $@

db/table/tile_logs: data/tile_logs/_download | db/table
	psql -c "drop table if exists tile_logs;"
	psql -c "create table tile_logs (tile_date timestamptz, z int, x int, y int, view_count int, geom geometry generated always as (ST_Transform(ST_TileEnvelope(z, x, y), 4326)) stored);"
	find data/tile_logs/ -type f -size +10M | sort -r | head -30 | parallel "xzcat {} | python3 scripts/import_osm_tile_logs.py {} | psql -c 'copy tile_logs from stdin with csv'"
	psql -f tables/tile_stats.sql
	psql -f tables/tile_logs_h3.sql
	touch $@

data/tiles/stats_tiles.tar.bz2: db/table/bivariate_axis db/table/bivariate_overlays db/table/bivariate_indicators db/table/bivariate_colors db/table/stat_h3 db/table/osm_meta | data/tiles
	bash ./scripts/generate_tiles.sh stats | parallel --eta
	psql -q -X -f scripts/export_osm_bivariate_map_axis.sql | sed s#\\\\\\\\#\\\\#g > data/tiles/stats/stat.json
	cd data/tiles/stats/; tar cvf ../stats_tiles.tar.bz2 --use-compress-prog=pbzip2 ./

deploy/geocint/stats_tiles: data/tiles/stats_tiles.tar.bz2 | deploy/geocint
	sudo mkdir -p /var/www/tiles; sudo chmod 777 /var/www/tiles
	rm -rf /var/www/tiles/stats_new; mkdir -p /var/www/tiles/stats_new
	cp -a data/tiles/stats/. /var/www/tiles/stats_new/
	rm -rf /var/www/tiles/stats_old
	mv /var/www/tiles/stats /var/www/tiles/stats_old; mv /var/www/tiles/stats_new /var/www/tiles/stats
	touch $@

deploy/zigzag/stats_tiles: data/tiles/stats_tiles.tar.bz2 | deploy/zigzag
	ansible zigzag_live_dashboard -m file -a 'path=$$HOME/tmp state=directory mode=0770'
	ansible zigzag_live_dashboard -m copy -a 'src=data/tiles/stats_tiles.tar.bz2 dest=$$HOME/tmp/stats_tiles.tar.bz2'
	ansible zigzag_live_dashboard -m shell -a 'warn:false' -a ' \
		set -e; \
		set -o pipefail; \
		mkdir -p "$$HOME/public_html/tiles/stats"; \
		tar -cjf "$$HOME/tmp/stats_tiles_prev.tar.bz2" -C "$$HOME/public_html/tiles/stats" . ; \
		TMPDIR=$$(mktemp -d -p "$$HOME/tmp"); \
		function on_exit { rm -rf "$$TMPDIR"; }; \
		trap on_exit EXIT; \
		tar -xf "$$HOME/tmp/stats_tiles.tar.bz2" -C "$$TMPDIR"; \
		find "$$TMPDIR" -type d -exec chmod 0775 "{}" "+"; \
		find "$$TMPDIR" -type f -exec chmod 0664 "{}" "+"; \
		renameat2 -e "$$TMPDIR" "$$HOME/public_html/tiles/stats"; \
		rm -f "$$HOME/tmp/stats_tiles.tar.bz2"; \
	'
	touch $@

deploy/sonic/stats_tiles: data/tiles/stats_tiles.tar.bz2 | deploy/sonic
	ansible sonic_live_dashboard -m file -a 'path=$$HOME/tmp state=directory mode=0770'
	ansible sonic_live_dashboard -m copy -a 'src=data/tiles/stats_tiles.tar.bz2 dest=$$HOME/tmp/stats_tiles.tar.bz2'
	ansible sonic_live_dashboard -m shell -a 'warn:false' -a ' \
		set -e; \
		set -o pipefail; \
		mkdir -p "$$HOME/public_html/tiles/stats"; \
		tar -cjf "$$HOME/tmp/stats_tiles_prev.tar.bz2" -C "$$HOME/public_html/tiles/stats" . ; \
		TMPDIR=$$(mktemp -d -p "$$HOME/tmp"); \
		function on_exit { rm -rf "$$TMPDIR"; }; \
		trap on_exit EXIT; \
		tar -xf "$$HOME/tmp/stats_tiles.tar.bz2" -C "$$TMPDIR"; \
		find "$$TMPDIR" -type d -exec chmod 0775 "{}" "+"; \
		find "$$TMPDIR" -type f -exec chmod 0664 "{}" "+"; \
		renameat2 -e "$$TMPDIR" "$$HOME/public_html/tiles/stats"; \
		rm -f "$$HOME/tmp/stats_tiles.tar.bz2"; \
	'
	touch $@

deploy/lima/stats_tiles: data/tiles/stats_tiles.tar.bz2 | deploy/lima
	ansible lima_live_dashboard -m file -a 'path=$$HOME/tmp state=directory mode=0770'
	ansible lima_live_dashboard -m copy -a 'src=data/tiles/stats_tiles.tar.bz2 dest=$$HOME/tmp/stats_tiles.tar.bz2'
	ansible lima_live_dashboard -m shell -a 'warn:false' -a ' \
		set -e; \
		set -o pipefail; \
		mkdir -p "$$HOME/public_html/tiles/stats"; \
		tar -cjf "$$HOME/tmp/stats_tiles_prev.tar.bz2" -C "$$HOME/public_html/tiles/stats" . ; \
		TMPDIR=$$(mktemp -d -p "$$HOME/tmp"); \
		function on_exit { rm -rf "$$TMPDIR"; }; \
		trap on_exit EXIT; \
		tar -xf "$$HOME/tmp/stats_tiles.tar.bz2" -C "$$TMPDIR"; \
		find "$$TMPDIR" -type d -exec chmod 0775 "{}" "+"; \
		find "$$TMPDIR" -type f -exec chmod 0664 "{}" "+"; \
		renameat2 -e "$$TMPDIR" "$$HOME/public_html/tiles/stats"; \
		rm -f "$$HOME/tmp/stats_tiles.tar.bz2"; \
	'
	touch $@

data/tiles/users_tiles.tar.bz2: db/table/osm_users_hex db/table/osm_meta db/function/calculate_h3_res | data/tiles
	bash ./scripts/generate_tiles.sh users | parallel --eta
	cd data/tiles/users/; tar cvf ../users_tiles.tar.bz2 --use-compress-prog=pbzip2 ./

deploy/geocint/users_tiles: data/tiles/users_tiles.tar.bz2 | deploy/geocint
	sudo mkdir -p /var/www/tiles; sudo chmod 777 /var/www/tiles
	rm -rf /var/www/tiles/users_new; mkdir -p /var/www/tiles/users_new
	cp -a data/tiles/users/. /var/www/tiles/users_new/
	rm -rf /var/www/tiles/users_old
	mv /var/www/tiles/users /var/www/tiles/users_old; mv /var/www/tiles/users_new /var/www/tiles/users
	touch $@

deploy/zigzag/users_tiles: data/tiles/users_tiles.tar.bz2 | deploy/zigzag
	ansible zigzag_live_dashboard -m file -a 'path=$$HOME/tmp state=directory mode=0770'
	ansible zigzag_live_dashboard -m copy -a 'src=data/tiles/users_tiles.tar.bz2 dest=$$HOME/tmp/users_tiles.tar.bz2'
	ansible zigzag_live_dashboard -m shell -a 'warn:false' -a ' \
		set -e; \
		set -o pipefail; \
		mkdir -p "$$HOME/public_html/tiles/users"; \
		tar -cjf "$$HOME/tmp/users_tiles_prev.tar.bz2" -C "$$HOME/public_html/tiles/users" . ; \
		TMPDIR=$$(mktemp -d -p "$$HOME/tmp"); \
		function on_exit { rm -rf "$$TMPDIR"; }; \
		trap on_exit EXIT; \
		tar -xf "$$HOME/tmp/users_tiles.tar.bz2" -C "$$TMPDIR"; \
		find "$$TMPDIR" -type d -exec chmod 0775 "{}" "+"; \
		find "$$TMPDIR" -type f -exec chmod 0664 "{}" "+"; \
		renameat2 -e "$$TMPDIR" "$$HOME/public_html/tiles/users"; \
		rm -f "$$HOME/tmp/users_tiles.tar.bz2"; \
	'
	touch $@

deploy/sonic/users_tiles: data/tiles/users_tiles.tar.bz2 | deploy/sonic
	ansible sonic_live_dashboard -m file -a 'path=$$HOME/tmp state=directory mode=0770'
	ansible sonic_live_dashboard -m copy -a 'src=data/tiles/users_tiles.tar.bz2 dest=$$HOME/tmp/users_tiles.tar.bz2'
	ansible sonic_live_dashboard -m shell -a 'warn:false' -a ' \
		set -e; \
		set -o pipefail; \
		mkdir -p "$$HOME/public_html/tiles/users"; \
		tar -cjf "$$HOME/tmp/users_tiles_prev.tar.bz2" -C "$$HOME/public_html/tiles/users" . ; \
		TMPDIR=$$(mktemp -d -p "$$HOME/tmp"); \
		function on_exit { rm -rf "$$TMPDIR"; }; \
		trap on_exit EXIT; \
		tar -xf "$$HOME/tmp/users_tiles.tar.bz2" -C "$$TMPDIR"; \
		find "$$TMPDIR" -type d -exec chmod 0775 "{}" "+"; \
		find "$$TMPDIR" -type f -exec chmod 0664 "{}" "+"; \
		renameat2 -e "$$TMPDIR" "$$HOME/public_html/tiles/users"; \
		rm -f "$$HOME/tmp/users_tiles.tar.bz2"; \
	'
	touch $@

deploy/lima/users_tiles: data/tiles/users_tiles.tar.bz2 | deploy/lima
	ansible lima_live_dashboard -m file -a 'path=$$HOME/tmp state=directory mode=0770'
	ansible lima_live_dashboard -m copy -a 'src=data/tiles/users_tiles.tar.bz2 dest=$$HOME/tmp/users_tiles.tar.bz2'
	ansible lima_live_dashboard -m shell -a 'warn:false' -a ' \
		set -e; \
		set -o pipefail; \
		mkdir -p "$$HOME/public_html/tiles/users"; \
		tar -cjf "$$HOME/tmp/users_tiles_prev.tar.bz2" -C "$$HOME/public_html/tiles/users" . ; \
		TMPDIR=$$(mktemp -d -p "$$HOME/tmp"); \
		function on_exit { rm -rf "$$TMPDIR"; }; \
		trap on_exit EXIT; \
		tar -xf "$$HOME/tmp/users_tiles.tar.bz2" -C "$$TMPDIR"; \
		find "$$TMPDIR" -type d -exec chmod 0775 "{}" "+"; \
		find "$$TMPDIR" -type f -exec chmod 0664 "{}" "+"; \
		renameat2 -e "$$TMPDIR" "$$HOME/public_html/tiles/users"; \
		rm -f "$$HOME/tmp/users_tiles.tar.bz2"; \
	'
	touch $@

data/population/population_api_tables.sqld.gz: db/table/stat_h3 db/table/bivariate_axis db/table/bivariate_overlays db/table/bivariate_indicators db/table/bivariate_colors | data/population
# crafting production friendly SQL dump
	bash -c "cat scripts/population_api_dump_header.sql <(pg_dump --no-owner -t stat_h3 | sed 's/ public.stat_h3 / public.stat_h3__new /; s/^CREATE INDEX stat_h3_geom_zoom_idx.*//;') <(pg_dump --clean --if-exists --no-owner -t bivariate_axis -t bivariate_axis_correlation -t bivariate_axis_stats -t bivariate_colors -t bivariate_indicators -t bivariate_overlays) scripts/population_api_dump_footer.sql | pigz" > $@__TMP
	mv $@__TMP $@
	touch $@

deploy/zigzag/population_api_tables: data/population/population_api_tables.sqld.gz | deploy/zigzag
	ansible zigzag_population_api -m file -a 'path=$$HOME/tmp state=directory mode=0770'
	ansible zigzag_population_api -m copy -a 'src=data/population/population_api_tables.sqld.gz dest=$$HOME/tmp/population_api_tables.sqld.gz'
	ansible zigzag_population_api -m postgresql_db -a 'name=population-api maintenance_db=population-api login_user=population-api login_host=localhost state=restore target=$$HOME/tmp/population_api_tables.sqld.gz'
	ansible zigzag_population_api -m file -a 'path=$$HOME/tmp/population_api_tables.sqld.gz state=absent'
	touch $@

deploy/sonic/population_api_tables: data/population/population_api_tables.sqld.gz | deploy/sonic
	ansible sonic_population_api -m file -a 'path=$$HOME/tmp state=directory mode=0770'
	ansible sonic_population_api -m copy -a 'src=data/population/population_api_tables.sqld.gz dest=$$HOME/tmp/population_api_tables.sqld.gz'
	ansible sonic_population_api -m postgresql_db -a 'name=population-api maintenance_db=population-api login_user=population-api login_host=localhost state=restore target=$$HOME/tmp/population_api_tables.sqld.gz'
	ansible sonic_population_api -m file -a 'path=$$HOME/tmp/population_api_tables.sqld.gz state=absent'
	touch $@

deploy/lima/population_api_tables: data/population/population_api_tables.sqld.gz | deploy/lima
	ansible lima_population_api -m file -a 'path=$$HOME/tmp state=directory mode=0770'
	ansible lima_population_api -m copy -a 'src=data/population/population_api_tables.sqld.gz dest=$$HOME/tmp/population_api_tables.sqld.gz'
	ansible lima_population_api -m postgresql_db -a 'name=population-api maintenance_db=population-api login_user=population-api login_host=localhost state=restore target=$$HOME/tmp/population_api_tables.sqld.gz'
	ansible lima_population_api -m file -a 'path=$$HOME/tmp/population_api_tables.sqld.gz state=absent'
	touch $@
