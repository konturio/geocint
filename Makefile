all: prod dev basemap_all ## [FINAL] Meta-target on top of all other targets.

dev:  deploy/geocint/belarus-latest.osm.pbf deploy/geocint/stats_tiles deploy/geocint/users_tiles deploy/zigzag/stats_tiles deploy/zigzag/users_tiles deploy/sonic/stats_tiles deploy/sonic/users_tiles deploy/geocint/isochrone_tables deploy/zigzag/population_api_tables deploy/sonic/population_api_tables deploy/s3/test/osm_addresses_minsk data/population/population_api_tables.sqld.gz data/out/kontur_population.gpkg.gz db/table/population_grid_h3_r8_osm_scaled data/out/morocco data/planet-check-refs db/table/worldpop_population_grid_h3_r8 db/table/worldpop_population_boundary db/table/kontur_boundaries reports/osm_gadm_comparison.html reports/osm_population_inconsitencies.html reports/population_check_osm.csv db/table/iso_codes reports/population_check_world data/out/abu_dhabi_export ## [FINAL] Builds all targets for development. Run on every branch.
	touch $@
	echo "Pipeline finished. Dev target has built!" | python3 scripts/slack_message.py geocint "Nightly build" cat

prod:  deploy/lima/stats_tiles deploy/lima/users_tiles deploy/lima/population_api_tables deploy/lima/osrm-backend-by-car deploy/geocint/global_fires_h3_r8_13months.csv.gz deploy/s3/osm_buildings_minsk deploy/s3/osm_addresses_minsk deploy/s3/osm_admin_boundaries ## [FINAL] Deploys artifacts to production. Runs only on master branch.
	touch $@
	echo "Pipeline finished. Prod target has built!" | python3 scripts/slack_message.py geocint "Nightly build" cat

basemap_all: basemap_dev basemap_prod ## [FINAL] All basemap related targets, temporarily removed from main build.
	touch $@

basemap_dev: deploy/geocint/basemap deploy/zigzag/basemap deploy/sonic/basemap ## Deploy basemap on development environment.
	touch $@

basemap_prod: deploy/lima/basemap ## Deploy basemap on production environment.
	touch $@

clean: ## [FINAL] Cleans the worktree for next nightly run. Does not clean non-repeating targets.
	if [ -f data/planet-is-broken ]; then rm -rf data/planet-latest.osm.pbf ; fi
	rm -rf deploy/ data/tiles/stats data/tiles/users data/tile_logs/index.html data/planet-is-broken
	profile_make_clean data/planet-latest-updated.osm.pbf data/covid19/_global_csv data/covid19/_us_csv data/tile_logs/_download data/global_fires/download_new_updates db/table/morocco_buildings_manual db/table/morocco_buildings_manual_roofprints data/covid19/vaccination/vaccine_acceptance_us_counties.csv
	psql -f scripts/clean.sql

data: ## Directory for storing temporary file based datasets.
	mkdir -p $@

db: ## Directory for storing database objects creation footprints.
	mkdir -p $@

reports: ## Directory for storing reports.
	mkdir -p $@

db/function: | db ## Directory for storing database functions footprints.
	mkdir -p $@

db/procedure: | db ## Directory for storing database procedures footprints.
	mkdir -p $@

db/table: | db ## Directory for storing database tables footprints.
	mkdir -p $@

db/index: | db ## Directory for storing database indexes footprints.
	mkdir -p $@

data/tiles: | data ## Directory for storing generated vector tiles.
	mkdir -p $@

data/in: | data
	mkdir -p $@

data/in/raster: | data/in
	mkdir -p $@

data/mid: | data
	mkdir -p $@

data/out: | data
	mkdir -p $@

data/out/morocco_buildings: | data/out
	mkdir -p $@

data/out/global_fires: | data/out
	mkdir -p $@

data/tiles/stat: | data/tiles
	mkdir -p $@

data/population: | data ## Directory for storing data_stat_h3 and bivariate datasets.
	mkdir -p $@

data/in/gadm: | data/in ## Directory for storing downloaded GADM (Database of Global Administrative Areas) datasets.
	mkdir -p $@

data/mid/gadm: | data/mid
	mkdir -p $@

data/in/wb/gdp: | data/in ## Directory for storing downloaded GDP (Gross domestic product) World Bank datasets.
	mkdir -p $@

data/mid/wb/gdp: | data/mid
	mkdir -p $@

data/in/raster/gebco_2020_geotiff: | data/in/raster ## Directory for GEBCO (General Bathymetric Chart of the Oceans) dataset.
	mkdir -p $@

data/mid/ndvi_2019_06_10: | data/mid ## Directory for NDVI rasters.
	mkdir -p $@

deploy:  ## Directory for deployment targets footprints.
	mkdir -p $@

deploy/lima: | deploy ## We use lima.kontur.io as a production server.
	mkdir -p $@

deploy/sonic: | deploy ## We use sonic.kontur.io as a staging server to test the software before setting it live at lima.kontur.io.
	mkdir -p $@

deploy/zigzag: | deploy
	mkdir -p $@

deploy/geocint: | deploy ## We use geocint as a GIS development server.
	mkdir -p $@

deploy/s3:
	mkdir -p $@/test

deploy/geocint/isochrone_tables: db/table/osm_road_segments db/table/osm_road_segments_new db/index/osm_road_segments_new_seg_id_node_from_node_to_seg_geom_idx db/index/osm_road_segments_new_seg_geom_idx
	touch $@

deploy/geocint/belarus-latest.osm.pbf: data/belarus-latest.osm.pbf | deploy/geocint ## Copy belarus-latest.osm.pbf to public_html folder to make it available online.
	cp data/belarus-latest.osm.pbf ~/public_html/belarus-latest.osm.pbf
	touch $@

deploy/lima/osrm-backend-by-car: deploy/geocint/belarus-latest.osm.pbf | deploy/lima
	aws sqs send-message --output json --region eu-central-1 --queue-url https://sqs.eu-central-1.amazonaws.com/001426858141/PuppetmasterInbound.fifo --message-body '{"jsonrpc":"2.0","method":"rebuildDockerImage","params":{"imageName":"kontur-osrm-backend-by-car","osmPbfUrl":"https://geocint.kontur.io/gis/belarus-latest.osm.pbf"},"id":"'`uuid`'"}' --message-group-id rebuildDockerImage--kontur-osrm-backend-by-car
	touch $@

data/planet-latest.osm.pbf: | data ## Download latest planet OSM pbf extraction through Bit torrent and rename it to planet-latest.osm.pbf.
	rm -f data/planet-*.osm.pbf data/planet-latest.seq data/planet-latest.osm.pbf.meta.json
	cd data; aria2c https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf.torrent --seed-time=0
	mv data/planet-*.osm.pbf $@
	rm -f data/planet-*.osm.pbf.torrent
	touch $@

data/planet-latest-updated.osm.pbf: data/planet-latest.osm.pbf | data ## Update planet-latest.osm.pbf OpenStreetMap extract with hourly diff.
	rm -f data/planet-diff.osc
	if [ -f data/planet-latest.seq ]; then pyosmium-get-changes -vv -s 50000 --server "https://planet.osm.org/replication/hour/" -f data/planet-latest.seq -o data/planet-diff.osc; else pyosmium-get-changes -vv -s 50000 --server "https://planet.osm.org/replication/hour/" -O data/planet-latest.osm.pbf -f data/planet-latest.seq -o data/planet-diff.osc; fi ||true
	rm -f data/planet-latest-updated.osm.pbf data/planet-latest-updated.osm.pbf.meta.json
	osmium apply-changes data/planet-latest.osm.pbf data/planet-diff.osc -f pbf,pbf_compression=false -o data/planet-latest-updated.osm.pbf
	# TODO: smoke check correctness of file
	cp -lf data/planet-latest-updated.osm.pbf data/planet-latest.osm.pbf
	touch $@

data/planet-check-refs: data/planet-latest-updated.osm.pbf | data ## Check if planet-latest.osm.pbf OSM extraction is referentially complete using Osmium tool (osmcode.org/osmium-tool/manual.html#checking-references).
	osmium check-refs -r --no-progress data/planet-latest.osm.pbf || touch data/planet-is-broken
	touch $@

data/belarus-latest.osm.pbf: data/planet-latest-updated.osm.pbf data/belarus_boundary.geojson | data ## Extract Belarus from planet-latest-updated.osm.pbf using Osmium tool.
	osmium extract -v -s smart -p data/belarus_boundary.geojson data/planet-latest-updated.osm.pbf -o data/belarus-latest.osm.pbf --overwrite
	touch $@

data/in/covid19: | data/in  ## Directory for storing original file based datasets on COVID-19
	mkdir -p $@

data/in/covid19/_global_csv: | data/in/covid19 ## Download global daily COVID-19 data by confirmed/deaths/recovered cases in csv from github Data Repository by the Center for Systems Science and Engineering (CSSE) at Johns Hopkins University.
	wget "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv" -O data/in/covid19/time_series_global_confirmed.csv
	wget "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv" -O data/in/covid19/time_series_global_deaths.csv
	wget "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_recovered_global.csv" -O data/in/covid19/time_series_global_recovered.csv
	touch $@

data/in/covid19/_us_csv: | data/in/covid19 ## Download US detailed daily COVID-19 data from github Data Repository by the Center for Systems Science and Engineering (CSSE) at Johns Hopkins University.
	wget "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv" -O data/in/covid19/time_series_us_confirmed.csv
	wget "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv" -O data/in/covid19/time_series_us_deaths.csv
	wget "https://coronavirus-dashboard.utah.gov/Utah_COVID19_data.zip" -O data/in/covid19/utah_covid19.zip
	touch $@

data/mid/covid19: | data/mid  ## Directory for storing temporary file based datasets on COVID-19
	mkdir -p $@

data/mid/covid19/covid19_utah.csv: data/in/covid19/_us_csv | data/mid/covid19
	unzip -p data/in/covid19/utah_covid19.zip 'Overview_COVID-19 Cases by Date of Symptom Onset or Diagnosis_'* > $@

data/mid/covid19/normalized_csv: data/in/covid19/_global_csv | data/mid/covid19
	rm -f data/mid/covid19/time_series_global_*_normalized.csv
	ls data/in/covid19/time_series_global* | parallel "python3 scripts/covid19_normalization.py {}"
	touch $@

db/table/covid19_in: data/mid/covid19/normalized_csv | db/table ## Normalized, merged, extracted latest data from CSSE COVID-19 global datasets.
	psql -c 'drop table if exists covid19_csv_in;'
	psql -c 'drop table if exists covid19_in;'
	psql -c 'create table covid19_csv_in (province text, country text, lat float, lon float, date timestamptz, value int, status text);'
	cat data/mid/covid19/time_series_global_confirmed_normalized.csv | tail -n +1 | psql -c "set time zone utc;copy covid19_csv_in (province, country, lat, lon, date, value) from stdin with csv header;"
	psql -c "update covid19_csv_in set status='confirmed' where status is null;"
	cat data/mid/covid19/time_series_global_deaths_normalized.csv | tail -n +1 | psql -c "set time zone utc;copy covid19_csv_in (province, country, lat, lon, date, value) from stdin with csv header;"
	psql -c "update covid19_csv_in set status='dead' where status is null;"
	cat data/mid/covid19/time_series_global_recovered_normalized.csv | tail -n +1 | psql -c "set time zone utc;copy covid19_csv_in (province, country, lat, lon, date, value) from stdin with csv header;"
	psql -c "update covid19_csv_in set status='recovered' where status is null;"
	psql -c "create table covid19_in as (select province, country, lat, lon, status, max(date) as date, max(value) as value from covid19_csv_in group by 1,2,3,4,5);"
	touch $@

data/mid/covid19/normalized_us_confirmed_csv: data/in/covid19/_us_csv | data/mid/covid19
	rm -f data/mid/covid19/time_series_us_confirmed_normalized.csv
	python3 scripts/covid19_us_confirmed_normalization.py data/in/covid19/time_series_us_confirmed.csv
	touch $@

db/table/covid19_us_confirmed_in: data/mid/covid19/normalized_us_confirmed_csv data/mid/covid19/covid19_utah.csv | db/table ## Normalized, merged data from CSSE COVID-19 US datasets (confirmed cases).
	psql -c 'drop table if exists covid19_us_confirmed_csv_in;'
	psql -c 'create table covid19_us_confirmed_csv_in (uid text, iso2 text, iso3 text, code3 text, fips text, admin2 text, province text, country text, lat float, lon float, combined_key text, date timestamptz, value int);'
	cat data/mid/covid19/time_series_us_confirmed_normalized.csv | tail -n +1 | psql -c "set time zone utc;copy covid19_us_confirmed_csv_in (uid, iso2, iso3, code3, fips, admin2, province, country, lat, lon, combined_key, date, value) from stdin with csv header;"
	psql -c 'drop table if exists covid19_utah_confirmed_csv_in;'
	psql -c 'create table covid19_utah_confirmed_csv_in (date timestamptz, confirmed_case_count int, cumulative_cases int, seven_day_average float);'
	cat data/mid/covid19/covid19_utah.csv | psql -c "copy covid19_utah_confirmed_csv_in (date , confirmed_case_count, cumulative_cases, seven_day_average) from stdin with csv header delimiter ',';"
	psql -f tables/covid19_us_confirmed_in.sql
	touch $@

data/mid/covid19/normalized_us_deaths_csv: data/in/covid19/_us_csv | data/mid/covid19
	rm -f data/mid/covid19/time_series_us_deaths_normalized.csv
	python3 scripts/covid19_us_deaths_normalization.py data/in/covid19/time_series_us_deaths.csv
	touch $@

db/table/covid19_us_deaths_in: data/mid/covid19/normalized_us_deaths_csv | db/table ## Normalized, merged data from CSSE COVID-19 US datasets (deaths).
	psql -c 'drop table if exists covid19_us_deaths_csv_in;'
	psql -c 'create table covid19_us_deaths_csv_in (uid text, iso2 text, iso3 text, code3 text, fips text, admin2 text, province text, country text, lat float, lon float, combined_key text, population int, date timestamptz, value int);'
	cat data/mid/covid19/time_series_us_deaths_normalized.csv | tail -n +1 | psql -c "set time zone utc;copy covid19_us_deaths_csv_in (uid, iso2, iso3, code3, fips, admin2, province, country, lat, lon, combined_key, population, date, value) from stdin with csv header;"
	psql -f tables/covid19_us_deaths_in.sql
	touch $@

db/table/covid19_admin_boundaries: db/table/covid19_in db/index/osm_tags_idx ## Admin boundaries for COVID-19 CSSE datasets extracted from OpenStreetMap (joined on coordinates and name matching).
	psql -f tables/covid19_admin_boundaries.sql
	touch $@

db/table/covid19_population_h3_r8: db/table/kontur_population_h3 db/table/covid19_us_counties db/table/covid19_admin_boundaries | db/table ## Genereate table of Covid19 cases (worldwide and USA) in h3 8 resolution from Kontur population dataset and used boundaries
	psql -f tables/covid19_population_h3_r8.sql
	touch $@

db/table/covid19_h3: db/table/covid19_population_h3_r8 db/table/covid19_us_counties db/table/covid19_admin_boundaries | db/table ## calculate cases rate, dither and generate overviews of covid19_population_h3_r8
	psql -f tables/covid19_h3.sql
	psql -c "call generate_overviews('covid19_h3', '{date, population, total_population, confirmed, recovered, dead}'::text[], '{max, sum, sum, sum, sum, sum}'::text[], 8);"
	touch $@

db/table/us_counties_boundary: data/mid/gadm/gadm36_shp_files | db/table ## USA counties boundaries extracted from GADM (Database of Global Administrative Areas) admin_level_2 dataset.
	psql -c 'drop table if exists gadm_us_counties_boundary;'
	ogr2ogr -f PostgreSQL PG:"dbname=gis" data/mid/gadm/gadm36_2.shp -sql "select name_1, name_2, gid_2, hasc_2 from gadm36_2 where gid_0 = 'USA'" -nln gadm_us_counties_boundary -nlt MULTIPOLYGON -lco GEOMETRY_NAME=geom
	ogr2ogr -append -f PostgreSQL PG:"dbname='gis'" data/mid/gadm/gadm36_1.shp -sql "select name_0 as name_1, name_1 as name_2, gid_1 as gid_2, hasc_1 as hasc_2 from gadm36_1 where gid_0 = 'PRI'" -nln gadm_us_counties_boundary -nlt MULTIPOLYGON -lco GEOMETRY_NAME=geom
	psql -c 'drop table if exists us_counties_fips_codes;'
	psql -c 'create table us_counties_fips_codes (state text, county text, hasc_code text, fips_code text);'
	cat data/counties_fips_hasc.csv | psql -c "copy us_counties_fips_codes (state, county, hasc_code, fips_code) from stdin with csv header delimiter ',';"
	psql -f tables/us_counties_boundary.sql
	touch $@

db/table/covid19_us_counties: db/table/covid19_us_confirmed_in db/table/covid19_us_deaths_in db/table/us_counties_boundary | db/table ## USA counties subdivided geometries
	psql -f tables/covid19_us_counties.sql
	touch $@

data/in/covid19/vaccination: | data/in/covid19
	mkdir -p $@

data/in/covid19/vaccination/vaccine_acceptance_us_counties.csv: | data/in/covid19/vaccination
	wget -q "https://api.covidcast.cmu.edu/epidata/covidcast/csv?signal=fb-survey:smoothed_covid_vaccinated&start_day=$(shell date -d '-30 days' +%Y-%m-%d)&end_day=$(shell date +%Y-%m-%d)&geo_type=county" -O $@

db/table/covid19_vaccine_accept_us_counties: data/in/covid19/vaccination/vaccine_acceptance_us_counties.csv db/table/us_counties_boundary
	psql -c 'drop table if exists covid19_vaccine_accept_us;'
	psql -c 'create table covid19_vaccine_accept_us (ogc_fid serial not null, geo_value text, signal text, time_value timestamptz, issue timestamptz, lag int, value float, stderr float, sample_size float, geo_type text, data_source text);'
	cat data/in/covid19/vaccination/vaccine_acceptance_us_counties.csv | psql -c 'copy covid19_vaccine_accept_us (ogc_fid, geo_value, signal, time_value, issue, lag, value, stderr, sample_size, geo_type, data_source) from stdin with csv header;'
	psql -f tables/covid19_vaccine_accept_us_counties.sql
	touch $@

db/table/covid19_vaccine_accept_us_counties_h3: db/table/covid19_vaccine_accept_us_counties
	psql -f tables/covid19_vaccine_accept_us_counties_h3.sql
	psql -c "call generate_overviews('covid19_vaccine_accept_us_counties_h3', '{vaccine_value}'::text[], '{sum}'::text[], 8);"
	touch $@

db/table/osm: data/planet-latest-updated.osm.pbf | db/table
	psql -c "drop table if exists osm;"
	OSMIUM_POOL_THREADS=8 OSMIUM_MAX_INPUT_QUEUE_SIZE=100 OSMIUM_MAX_OSMDATA_QUEUE_SIZE=100 OSMIUM_MAX_OUTPUT_QUEUE_SIZE=100 OSMIUM_MAX_WORK_QUEUE_SIZE=100 numactl --preferred=1 -N 1 osmium export -i dense_mmap_array -c osmium.config.json -f pg data/planet-latest.osm.pbf  -v --progress | psql -1 -c 'create table osm(geog geography, osm_type text, osm_id bigint, osm_user text, ts timestamptz, way_nodes bigint[], tags jsonb);alter table osm alter geog set storage external, alter osm_type set storage main, alter osm_user set storage main, alter way_nodes set storage external, alter tags set storage external, set (fillfactor=100); copy osm from stdin freeze;'
	psql -c "alter table osm set (parallel_workers = 32);"
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

db/function/parse_float: | db/function ## Converts text into a float or a NULL.
	psql -f functions/parse_float.sql
	touch $@

db/function/parse_integer: | db/function ## Converts text levels into a integer or a NULL.
	psql -f functions/parse_integer.sql
	touch $@

db/function/calculate_h3_res: db/function/h3
	psql -f functions/calculate_h3_res.sql
	touch $@

db/function/h3_raster_sum_to_h3: | db/function
	psql -f functions/h3_raster_sum_to_h3.sql
	touch $@

db/procedure/generate_overviews: | db/procedure
	psql -f procedures/generate_overviews.sql
	touch $@

db/table/osm_roads: db/table/osm db/index/osm_tags_idx ## Roads from OpenStreetMap.
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

data/in/raster/worldpop: | data/in/raster ## directory for World Pop tifs
	mkdir -p $@

data/in/raster/worldpop/download: | data/in/raster/worldpop ## Download World Pop tifs from worldpop.org.
	python3 scripts/parser_worldpop_tif_urls.py | parallel -j10 wget -nc -c -P data/in/raster/worldpop -i -
	touch $@

data/mid/worldpop: | data/mid ## Temporary worldpop dir for tiled tifs
	mkdir -p $@

data/mid/worldpop/tiled_rasters: data/in/raster/worldpop/download | data/mid/worldpop ## Tile raw stripped TIFs.
	rm -f data/mid/worldpop/tiled_*.tif
	find data/in/raster/worldpop/*.tif -type f | sort -r | parallel -j10 --eta 'gdal_translate -a_srs EPSG:4326 -co COMPRESS=LZW -co BIGTIFF=IF_SAFER -of COG {} data/mid/worldpop/tiled_{/}'
	touch $@

db/table/worldpop_population_raster: data/mid/worldpop/tiled_rasters | db/table ## Import raster data and create table with tiled data.
	psql -c "drop table if exists worldpop_population_raster"
	raster2pgsql -p -Y -s 4326 data/mid/worldpop/tiled_*.tif -t auto worldpop_population_raster | psql -q
	psql -c 'alter table worldpop_population_raster drop CONSTRAINT worldpop_population_raster_pkey;'
	ls -Sr data/mid/worldpop/tiled_*.tif | parallel --eta 'GDAL_CACHEMAX=10000 GDAL_NUM_THREADS=16 raster2pgsql -a -Y -s 4326 {} -t auto worldpop_population_raster | psql -q'
	psql -c "alter table worldpop_population_raster set (parallel_workers = 32);"
	psql -c "vacuum analyze worldpop_population_raster;"
	touch $@

db/table/worldpop_population_grid_h3_r8: db/table/worldpop_population_raster ## Count sum sum of World Pop raster values at h3 hexagons.
	psql -f tables/population_raster_grid_h3_r8.sql -v population_raster=worldpop_population_raster -v population_raster_grid_h3_r8=worldpop_population_raster_grid_h3_r8
	touch $@

db/table/worldpop_country_codes: data/worldpop/download | db/table ## Generate table with countries for WorldPop rasters.
	psql -c "drop table if exists worldpop_country_codes;"
	psql -c "create table worldpop_country_codes (code varchar(3) not null, primary key (code));"
	ls data/worldpop/*.tif | parallel --eta psql -c "\"insert into worldpop_country_codes(code) select upper(substr('{/.}', 1, 3)) where not exists (select code from worldpop_country_codes where code = upper(substr('{/.}', 1, 3)));\""
	touch $@

db/table/worldpop_population_boundary: db/table/worldpop_country_codes | db/table ## Generate table with boundaries for WorldPop data.
	psql -f tables/worldpop_population_boundary.sql
	touch $@

data/in/raster/hrsl_cogs: | data/in/raster ## Directory for HRSL raster data.
	mkdir -p $@

data/in/raster/hrsl_cogs/download: | data/in/raster/hrsl_cogs ## Download HRSL tifs from Data for Good at AWS S3.
	cd data/in/raster/hrsl_cogs; aws s3 sync s3://dataforgood-fb-data/hrsl-cogs/ ./ --no-sign-request
	touch $@

db/table/hrsl_population_raster: data/in/raster/hrsl_cogs/download | db/table ## Prepare table for raster data. Import HRSL raster tiles into database.
	psql -c "drop table if exists hrsl_population_raster;"
	raster2pgsql -p -Y -s 4326 data/in/raster/hrsl_cogs/hrsl_general/v1.5/*.tif -t auto hrsl_population_raster | psql -q
	psql -c 'alter table hrsl_population_raster drop CONSTRAINT hrsl_population_raster_pkey;'
	find data/in/raster/hrsl_cogs/hrsl_general -name "*.tif" -type f -printf "%f %p\n" | sed -E 's/.*-v(([[:digit:]]\.?)+)\.tif(.*)/\1 \0/;s/-v([[:digit:]]\.?)+\.tif//1' | sort -Vrk1,1 | sort -uk2,2 | cut -d ' ' -f3- | parallel --eta 'GDAL_CACHEMAX=10000 GDAL_NUM_THREADS=4 raster2pgsql -a -Y -s 4326 {} -t auto hrsl_population_raster | psql -q'
	psql -c "alter table hrsl_population_raster set (parallel_workers = 32);"
	psql -c "create index hrsl_population_raster_rast_idx on hrsl_population_raster using gist (ST_ConvexHull(rast));"
	psql -c "vacuum analyze hrsl_population_raster;"
	touch $@

db/table/hrsl_population_grid_h3_r8: db/table/hrsl_population_raster db/function/h3_raster_sum_to_h3 ## Sum of HRSL raster values into h3 hexagons equaled to 8 resolution.
	psql -f tables/population_raster_grid_h3_r8.sql -v population_raster=hrsl_population_raster -v population_raster_grid_h3_r8=hrsl_population_grid_h3_r8
	touch $@

db/table/hrsl_population_boundary: db/table/gadm_countries_boundary db/table/hrsl_population_raster | db/table ## Boundaries where HRSL data is available.
	psql -f tables/hrsl_population_boundary.sql
	touch $@

db/table/osm_unpopulated: db/index/osm_tags_idx | db/table ## Unpopulated areas from OpenStreetMap further used in kontur_population dataset.
	psql -f tables/osm_unpopulated.sql
	touch $@

db/table/ghs_globe_population_grid_h3_r8: db/table/ghs_globe_population_raster db/procedure/insert_projection_54009 db/function/h3_raster_sum_to_h3 | db/table ## Sum of GHS (Global Human Settlement) raster population values into h3 hexagons equaled to 8 resolution.
	psql -f tables/population_raster_grid_h3_r8.sql -v population_raster=ghs_globe_population_raster -v population_raster_grid_h3_r8=ghs_globe_population_grid_h3_r8
	psql -c "delete from ghs_globe_population_grid_h3_r8 where population = 0;"
	touch $@

data/in/raster/GHS_POP_E2015_GLOBE_R2019A_54009_250_V1_0.zip: | data/in/raster
	wget http://cidportal.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_MT_GLOBE_R2019A/GHS_POP_E2015_GLOBE_R2019A_54009_250/V1-0/GHS_POP_E2015_GLOBE_R2019A_54009_250_V1_0.zip -O $@

data/mid/GHS_POP_E2015_GLOBE_R2019A_54009_250_V1_0/GHS_POP_E2015_GLOBE_R2019A_54009_250_V1_0.tif: data/in/raster/GHS_POP_E2015_GLOBE_R2019A_54009_250_V1_0.zip | data/mid
	mkdir -p data/mid/GHS_POP_E2015_GLOBE_R2019A_54009_250_V1_0
	unzip -o data/in/raster/GHS_POP_E2015_GLOBE_R2019A_54009_250_V1_0.zip -d data/mid/GHS_POP_E2015_GLOBE_R2019A_54009_250_V1_0/

db/table/ghs_globe_population_raster: data/mid/GHS_POP_E2015_GLOBE_R2019A_54009_250_V1_0/GHS_POP_E2015_GLOBE_R2019A_54009_250_V1_0.tif | db/table
	psql -c "drop table if exists ghs_globe_population_raster"
	raster2pgsql -M -Y -s 54009 data/mid/GHS_POP_E2015_GLOBE_R2019A_54009_250_V1_0/GHS_POP_E2015_GLOBE_R2019A_54009_250_V1_0.tif -t auto ghs_globe_population_raster | psql -q
	psql -c "alter table ghs_globe_population_raster set (parallel_workers=32);"
	touch $@

data/in/raster/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.zip: | data/in/raster
	wget https://cidportal.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_SMOD_POP_GLOBE_R2016A/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k/V1-0/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.zip -O $@

data/mid/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.tif: data/in/raster/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.zip | data/mid
	unzip -o data/in/raster/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.zip -d data/mid/

db/table/ghs_globe_residential_raster: data/mid/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.tif | db/table
	psql -c "drop table if exists ghs_globe_residential_raster"
	raster2pgsql -M -Y -s 54009 data/mid/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.tif -t 256x256 ghs_globe_residential_raster | psql -q
	touch $@

db/table/ghs_globe_residential_vector: db/table/ghs_globe_residential_raster db/procedure/insert_projection_54009 db/function/h3_raster_sum_to_h3 | db/table
	psql -f tables/ghs_globe_residential_vector.sql
	touch $@

data/in/raster/copernicus_landcover: | data/in/raster ## Directory for Copernicus land cover data.
	mkdir -p $@

data/in/raster/copernicus_landcover/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.tif: | data/in/raster/copernicus_landcover ## Download Copernicus land cover raster.
	wget -c -nc https://zenodo.org/record/3939050/files/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.tif -O $@

db/table/copernicus_landcover_raster: data/in/raster/copernicus_landcover/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.tif | db/table ## Put land cover raster in table.
	psql -c "drop table if exists copernicus_landcover_raster;"
	raster2pgsql -M -Y -s 4326 data/in/raster/copernicus_landcover/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.tif -t auto copernicus_landcover_raster | psql -q
	psql -c "alter table copernicus_landcover_raster set (parallel_workers = 32);"
	touch $@

db/table/copernicus_builtup_h3: db/table/copernicus_landcover_raster | db/table ## Count of 'urban' pixels from land cover raster into h3 hexagons on 8 resolution.
	psql -f tables/copernicus_builtup_h3.sql
	touch $@

db/table/copernicus_forest_h3: db/table/copernicus_landcover_raster | db/table ## Forest area in km2 by types from land cover raster into h3 hexagons on 8 resolution.
	psql -f tables/copernicus_forest_h3.sql
	touch $@

db/table/osm_residential_landuse: db/index/osm_tags_idx ## Residential areas from osm.
	psql -f tables/osm_residential_landuse.sql
	touch $@

data/in/raster/gebco_2020_geotiff/gebco_2020_geotiff.zip: | data/in/raster/gebco_2020_geotiff ## Download GEBCO bathymetry zipped raster.
	wget "https://www.bodc.ac.uk/data/open_download/gebco/gebco_2020/geotiff/" -O $@

data/mid/gebco_2020_geotiff/gebco_2020_geotiffs_unzip: data/in/raster/gebco_2020_geotiff/gebco_2020_geotiff.zip | data/mid ## Unzip GEBCO raster.
	mkdir -p data/mid/gebco_2020_geotiff
	rm -f data/mid/gebco_2020_geotiff/*.tif
	unzip -o data/in/raster/gebco_2020_geotiff/gebco_2020_geotiff.zip -d data/mid/gebco_2020_geotiff/
	rm -f data/mid/gebco_2020_geotiff/*.pdf
	touch $@

data/mid/gebco_2020_geotiff/gebco_2020_merged.vrt: data/mid/gebco_2020_geotiff/gebco_2020_geotiffs_unzip
	rm -f data/mid/gebco_2020_geotiff/*.vrt
	gdalbuildvrt $@ data/mid/gebco_2020_geotiff/gebco_2020_n*.tif

data/mid/gebco_2020_geotiff/gebco_2020_merged.tif: data/mid/gebco_2020_geotiff/gebco_2020_merged.vrt
	rm -f $@
	GDAL_CACHEMAX=10000 GDAL_NUM_THREADS=16 gdalwarp -multi -t_srs epsg:4087 -r bilinear -of COG data/mid/gebco_2020_geotiff/gebco_2020_merged.vrt $@

data/mid/gebco_2020_geotiff/gebco_2020_merged_slope.tif: data/mid/gebco_2020_geotiff/gebco_2020_merged.tif
	rm -f $@
	GDAL_CACHEMAX=10000 GDAL_NUM_THREADS=16 gdaldem slope -of COG data/mid/gebco_2020_geotiff/gebco_2020_merged.tif $@

data/mid/gebco_2020_geotiff/gebco_2020_merged_4326_slope.tif: data/mid/gebco_2020_geotiff/gebco_2020_merged_slope.tif
	rm -f $@
	GDAL_CACHEMAX=10000 GDAL_NUM_THREADS=16 gdalwarp -t_srs EPSG:4326 -of COG -multi data/mid/gebco_2020_geotiff/gebco_2020_merged_slope.tif $@

db/table/gebco_2020_slopes: data/mid/gebco_2020_geotiff/gebco_2020_merged_4326_slope.tif | db/table ## Put GEBCO slope raster data into table.
	psql -c "drop table if exists gebco_2020_slopes;"
	raster2pgsql -M -Y -s 4326 data/mid/gebco_2020_geotiff/gebco_2020_merged_4326_slope.tif -t auto gebco_2020_slopes | psql -q
	touch $@

db/table/gebco_2020_slopes_h3: db/table/gebco_2020_slopes | db/table ## Generate h3 table with average slope values from 1 to 8 resolution.
	psql -f tables/gebco_values_into_h3.sql -v table_name=gebco_2020_slopes -v table_name_h3=gebco_2020_slopes_h3 -v item_name=avg_slope
	psql -c "call generate_overviews('gebco_2020_slopes_h3', '{avg_slope}'::text[], '{avg}'::text[], 8);"
	psql -c "create index on gebco_2020_slopes_h3 (h3, avg_slope);"
	touch $@

data/mid/gebco_2020_geotiff/gebco_2020_merged_4326.tif: data/mid/gebco_2020_geotiff/gebco_2020_merged.vrt
	rm -f $@
	GDAL_CACHEMAX=10000 GDAL_NUM_THREADS=16 gdal_translate -r bilinear -of COG -co "BIGTIFF=YES" data/mid/gebco_2020_geotiff/gebco_2020_merged.vrt $@

db/table/gebco_2020_elevation: data/mid/gebco_2020_geotiff/gebco_2020_merged_4326.tif | db/table ## Put GEBCO elevation raster data into table.
	psql -c "drop table if exists gebco_2020_elevation;"
	raster2pgsql -M -Y -s 4326 data/mid/gebco_2020_geotiff/gebco_2020_merged_4326.tif -t auto gebco_2020_elevation | psql -q
	touch $@

db/table/gebco_2020_elevation_h3: db/table/gebco_2020_elevation | db/table ## Generate h3 table with average elevation from 1 to 8 resolution.
	psql -f tables/gebco_values_into_h3.sql -v table_name=gebco_2020_elevation -v table_name_h3=gebco_2020_elevation_h3 -v item_name=avg_elevation
	psql -c "call generate_overviews('gebco_2020_elevation_h3', '{avg_elevation}'::text[], '{avg}'::text[], 8);"
	psql -c "create index on gebco_2020_elevation_h3 (h3, avg_elevation);"
	touch $@

data/mid/ndvi_2019_06_10/generate_ndvi_tifs: | data/mid/ndvi_2019_06_10 ## NDVI rasters generated from Sentinel 2 data.
	find /home/gis/sentinel-2-2019/2019/6/10/* -type d | parallel --eta 'cd {} && python3 /usr/bin/gdal_calc.py -A B04.tif -B B08.tif --calc="((1.0*B-1.0*A)/(1.0*B+1.0*A))" --type=Float32 --overwrite --outfile=ndvi.tif'
	touch $@

data/mid/ndvi_2019_06_10/warp_ndvi_tifs_4326: data/mid/ndvi_2019_06_10/generate_ndvi_tifs ## Reproject NDVI rasters to EPSG-4326.
	find /home/gis/sentinel-2-2019/2019/6/10/* -type d | parallel --eta 'cd {} && GDAL_CACHEMAX=10000 GDAL_NUM_THREADS=16 gdalwarp -multi -overwrite -t_srs EPSG:4326 -of COG ndvi.tif /home/gis/geocint/data/mid/ndvi_2019_06_10/ndvi_{#}_4326.tif'
	touch $@

db/table/ndvi_2019_06_10: data/mid/ndvi_2019_06_10/warp_ndvi_tifs_4326 | db/table ## Put NDVI rasters in table.
	psql -c "drop table if exists ndvi_2019_06_10;"
	raster2pgsql -p -Y -s 4326 data/mid/ndvi_2019_06_10/ndvi_1_4326.tif -t auto ndvi_2019_06_10 | psql -q
	psql -c 'alter table ndvi_2019_06_10 drop constraint if exists ndvi_2019_06_10_pkey;'
	ls data/mid/ndvi_2019_06_10/*.tif | parallel --eta 'raster2pgsql -a -Y -s 4326 {} -t auto ndvi_2019_06_10 | psql -q'
	psql -c "alter table ndvi_2019_06_10 set (parallel_workers = 32);"
	psql -c "vacuum analyze ndvi_2019_06_10;"
	touch $@

db/table/ndvi_2019_06_10_h3: db/table/ndvi_2019_06_10 | db/table ## Generate h3 table with average NDVI from 1 to 8 resolution.
	psql -f tables/ndvi_2019_06_10_h3.sql
	psql -c "call generate_overviews('ndvi_2019_06_10_h3', '{avg_ndvi}'::text[], '{avg}'::text[], 8);"
	psql -c "create index on ndvi_2019_06_10_h3 (h3, avg_ndvi);"
	touch $@

db/table/osm_building_count_grid_h3_r8: db/table/osm_buildings | db/table ## Count amount of OSM buildings at hexagons.
	psql -f tables/count_items_in_h3.sql -v table=osm_buildings -v table_h3=osm_building_count_grid_h3_r8 -v item_count=building_count
	touch $@

db/table/building_count_grid_h3: db/table/osm_building_count_grid_h3_r8 db/table/microsoft_buildings_h3 db/table/morocco_urban_pixel_mask_h3 db/table/morocco_buildings_h3 db/table/copernicus_builtup_h3 db/table/geoalert_urban_mapping_h3 db/table/new_zealand_buildings_h3 | db/table ## Count max amount of buildings at hexagons from all building datasets.
	psql -f tables/building_count_grid_h3.sql
	psql -c "call generate_overviews('building_count_grid_h3', '{building_count}'::text[], '{sum}'::text[], 8);"
	touch $@

data/in/gadm/gadm36_levels_shp.zip: | data/in/gadm ## Download GADM boundaries (Database of Global Administrative Areas) dataset.
	wget https://web.archive.org/web/20190829093806if_/https://data.biogeo.ucdavis.edu/data/gadm3.6/gadm36_levels_shp.zip -O $@

data/mid/gadm/gadm36_shp_files: data/in/gadm/gadm36_levels_shp.zip | data/mid/gadm ## Extract GADM boundaries (Database of Global Administrative Areas).
	unzip -o data/in/gadm/gadm36_levels_shp.zip -d data/mid/gadm/
	touch $@

db/table/gadm_boundaries: data/mid/gadm/gadm36_shp_files | db/table ## GADM boundaries (Database of Global Administrative Areas) dataset.
	ogr2ogr -append -overwrite -f PostgreSQL PG:"dbname=gis" -nln gadm_level_0 -nlt MULTIPOLYGON data/mid/gadm/gadm36_0.shp  --config PG_USE_COPY YES -lco FID=id -lco GEOMETRY_NAME=geom -progress
	ogr2ogr -append -overwrite -f PostgreSQL PG:"dbname=gis" -nln gadm_level_1 -nlt MULTIPOLYGON data/mid/gadm/gadm36_1.shp  --config PG_USE_COPY YES -lco FID=id -lco GEOMETRY_NAME=geom -progress
	ogr2ogr -append -overwrite -f PostgreSQL PG:"dbname=gis" -nln gadm_level_2 -nlt MULTIPOLYGON data/mid/gadm/gadm36_2.shp  --config PG_USE_COPY YES -lco FID=id -lco GEOMETRY_NAME=geom -progress
	ogr2ogr -append -overwrite -f PostgreSQL PG:"dbname=gis" -nln gadm_level_3 -nlt MULTIPOLYGON data/mid/gadm/gadm36_3.shp  --config PG_USE_COPY YES -lco FID=id -lco GEOMETRY_NAME=geom -progress
	psql -f tables/gadm_boundaries.sql
	touch $@

db/table/gadm_countries_boundary: db/table/gadm_boundaries ## Country boundaries from GADM (Database of Global Administrative Areas) dataset.
	psql -c "drop table if exists gadm_countries_boundary;"
	psql -c "create table gadm_countries_boundary as select row_number() over() gid, gid gid_0, \"name\" name_0, geom from gadm_boundaries where gadm_level = 0;"
	psql -c "alter table gadm_countries_boundary alter column geom type geometry(multipolygon, 3857) using ST_Transform(ST_ClipByBox2D(geom, ST_Transform(ST_TileEnvelope(0,0,0),4326)), 3857);"
	touch $@

db/table/kontur_boundaries: db/table/osm_admin_boundaries db/table/gadm_boundaries db/table/kontur_population_h3 | db/table ## We produce boundaries dataset based on OpenStreetMap admin boundaries with aggregated population from kontur_population_h3 and HASC (Hierarchichal Administrative Subdivision Codes) codes (www.statoids.com/ihasc.html) from GADM (Database of Global Administrative Areas).
	psql -f tables/kontur_boundaries.sql
	touch $@

reports/osm_gadm_comparison.html: db/table/kontur_boundaries db/table/gadm_boundaries | reports ## Validate OSM boundaries that OSM has no less polygons than GADM and generate html report for OpenStreetMap users.
	echo '<meta charset="utf-8">' > $@ | psql -HX -f tables/osm_gadm_comparison.sql | sed -e "s/\(<td align=\"left\">\)\([0-9]\{4,10\}\)\(<\/td>\)/\1<a href=\"https\:\/\/www.openstreetmap.org\/relation\/\2\">\2<\/a>\3/" >> $@

db/table/osm_population_inconsitencies: db/table/osm_admin_boundaries | db/table ## Validate OpenStreetMap population inconsistencies (one admin level can have a sum of population that is higher than the level above it, leading to negative population in admin regions).
	psql -f tables/osm_population_inconsitencies.sql
	touch $@

reports/osm_population_inconsitencies.html: db/table/osm_population_inconsitencies | reports ## Generate report for OpenStreetMap users about population inconsistencies (see also db/table/osm_population_inconsitencies target). Besides generating HTML table we also inject charset tag and clickable links into it using sed utility.
	echo $'<meta charset="utf-8">\n' "$(psql -HXP footer=off -P border -c 'select * from osm_population_inconsitencies;' | sed --z 's/\(<td align=\"left\">\)\([0-9]\{4,\}\)\(<\/td>\)\(\n\s\{4\}<td align=\"left\">\)\([^<>]\+\)\(<\/td>\n\s\{4\}<td align=\"right\">\)/\1<a href=\"https\:\/\/www.openstreetmap.org\/relation\/\2\">\2<\/a>\3\4<a href=\"http\:\/\/localhost\:8111\/load_object\?new_layer=true\&objects=r\2\&relation_members=true\">\5<\/a>\6/g')" > $@

db/table/population_check_osm: db/table/kontur_boundaries | db/table ## Check how OSM population and Kontur population corresponds with each other for kontur_boundaries dataset.
	psql -f tables/population_check_osm.sql
	touch $@

reports/population_check_osm.csv: db/table/population_check_osm | reports ## Export population_check_osm table to .csv and send Top 5 most inconsistent results to Kontur Slack (#gis channel).
	psql -q -X -c 'copy (select * from population_check_osm order by diff_pop desc) to stdout with csv header;' > $@
	cat $@ | tail -n +2 | head -5 | awk -F "\"*,\"*" '{print "<https://www.openstreetmap.org/relation/" $1 "|" $2">", $7}' | { echo "Top 5 boundaries with population different from OSM"; cat -; } | python3 scripts/slack_message.py geocint "Nightly build" cat

data/iso_codes.csv: | data ## Download ISO codes for countries from wikidata.
	wget 'https://query.wikidata.org/sparql?query=SELECT DISTINCT ?isoNumeric ?isoAlpha2 ?isoAlpha3 ?countryLabel WHERE {?country wdt:P31/wdt:P279* wd:Q56061; wdt:P299 ?isoNumeric; wdt:P297 ?isoAlpha2; wdt:P298 ?isoAlpha3. SERVICE wikibase:label { bd:serviceParam wikibase:language "en" }}' --retry-on-http-error=500 --header "Accept: text/csv" -O $@

db/table/iso_codes: data/iso_codes.csv | db/table ## Download ISO codes for countries from wikidata.
	psql -c 'drop table if exists iso_codes;'
	psql -c 'create table iso_codes(iso_num integer, iso2 char(2), iso3 char(3), name text);'
	cat data/iso_codes.csv | sed -e '/PM,PM,SPM/d' | psql -c "copy iso_codes from stdin with csv header;"
	touch $@

data/un_population.csv: | data ## Download United Nations population division dataset.
	wget 'https://population.un.org/wpp/Download/Files/1_Indicators%20(Standard)/CSV_FILES/WPP2019_TotalPopulationBySex.csv' -O $@

db/table/un_population: data/un_population.csv | db/table
	psql -c 'drop table if exists un_population_text;'
	psql -c 'create table un_population_text(iso text, name text, variant_id text, variant text, time text, mid_period text, pop_male text, pop_female text, pop_total text, pop_density text);'
	cat data/un_population.csv | psql -c "copy un_population_text from stdin with csv header delimiter ',';"
	psql -c 'drop table if exists un_population;'
	psql -c 'create table un_population as select iso::integer, name, variant_id::integer, variant, time::integer "year", parse_float(mid_period) "mid_period", parse_float(pop_male) * 1000 "pop_male", parse_float(pop_female) * 1000 "pop_female", parse_float(pop_total) * 1000 "pop_total", parse_float(pop_density) * 1000 "pop_density" from un_population_text;'
	psql -c 'drop table if exists un_population_text;'
	touch $@

#db/table/population_check_un: db/table/un_population db/table/iso_codes | db/table
#	psql -f tables/population_check_un.sql
#	touch $@

#reports/population_check_un.csv: db/table/population_check_un | reports
#	psql -c 'copy (select * from population_check_un order by diff_pop) to stdout with csv header;' > $@
#	cat $@ | tail -n +2 | head -10 | awk -F "\"*,\"*" '{print "<https://www.openstreetmap.org/relation/" $1 "|" $2">", $7}' | { echo "Top 10 countries with population different from UN"; cat -; } | python3 scripts/slack_message.py geocint "Nightly build" cat

reports/population_check_world: db/table/kontur_population_h3 db/table/un_population | reports
	psql -q -X -t -c "select abs(sum(population) - (select pop_total from un_population where variant_id = 2 and year = date_part('year', current_date) and name = 'World')) from kontur_population_h3 where resolution = 8;" > $@
	head -1 $@ | xargs echo "Planet population difference" | python3 scripts/slack_message.py geocint "Nightly build" cat

data/in/wb/gdp/wb_gdp.zip: | data/in/wb/gdp
	wget http://api.worldbank.org/v2/en/indicator/NY.GDP.MKTP.CD?downloadformat=xml -O $@

data/mid/wb/gdp/wb_gdp.xml: data/in/wb/gdp/wb_gdp.zip | data/mid/wb/gdp
	unzip -o data/in/wb/gdp/wb_gdp.zip -d data/mid/wb/gdp/
	cat data/mid/wb/gdp/API_NY*.xml | tr -d '\n\r\t' | sed 's/^.\{1\}//' > $@

db/table/wb_gdp: data/mid/wb/gdp/wb_gdp.xml | db/table
	psql -c "drop table if exists temp_xml;"
	psql -c "create table temp_xml ( value text );"
	cat data/mid/wb/gdp/wb_gdp.xml | psql -c "COPY temp_xml(value) FROM stdin DELIMITER E'\t' CSV QUOTE '''';"
	psql -f tables/wb_gdp.sql
	psql -c "drop table if exists temp_xml;"
	touch $@

db/table/wb_gadm_gdp_countries: db/table/wb_gdp db/table/gadm_countries_boundary
	psql -f tables/wb_gadm_gdp_countries.sql
	touch $@

db/table/gdp_h3: db/table/kontur_population_h3 db/table/wb_gadm_gdp_countries
	psql -f tables/gdp_h3.sql
	touch $@

data/in/water-polygons-split-3857.zip: | data/in ## Download OpenStreetMap water polygons (oceans and seas) archive.
	wget https://osmdata.openstreetmap.de/download/water-polygons-split-3857.zip -O $@

data/mid/water_polygons/water_polygons.shp: data/in/water-polygons-split-3857.zip | data/mid ## Unzip OpenStreetMap water polygons (oceans and seas) archive.
	mkdir -p data/mid/water_polygons
	unzip -jo data/in/water-polygons-split-3857.zip -d data/mid/water_polygons/

db/table/water_polygons_vector: data/mid/water_polygons/water_polygons.shp | db/table ## Import and subdivide OpenStreetMap water polygons (oceans and seas) as water_polygons_vector(EPSG-3857).
	psql -c "drop table if exists water_polygons_vector;"
	shp2pgsql -I -s 3857 data/mid/water_polygons/water_polygons.shp water_polygons_vector | psql -q
	psql -f tables/water_polygons_vector.sql
	touch $@

db/table/osm_water_lines: db/index/osm_tags_idx | db/table ## Water line geometries extracted from OpenStreetMap.
	psql -f tables/osm_water_lines.sql
	touch $@

db/table/osm_water_lines_buffers_subdivided: db/table/osm_water_lines | db/table
	psql -f tables/osm_water_lines_buffers_subdivided.sql
	touch $@

db/table/osm_water_polygons_in_subdivided: db/index/osm_tags_idx | db/table
	psql -f tables/osm_water_polygons_in_subdivided.sql
	touch $@

db/table/osm_water_polygons: db/table/osm_water_polygons_in_subdivided db/table/water_polygons_vector db/table/osm_water_lines_buffers_subdivided | db/table ## Merge water geometries into one table as polygons (linestring objects are buffered out with 1m in EPSG-3857).
	psql -f tables/osm_water_polygons.sql
	touch $@

db/procedure/insert_projection_54009: | db/procedure
	psql -f procedures/insert_projection_54009.sql || true
	touch $@

db/table/population_grid_h3_r8: db/table/hrsl_population_grid_h3_r8 db/table/hrsl_population_boundary db/table/ghs_globe_population_grid_h3_r8 | db/table ## General table for population data at hexagons.
	# IMPORTANT: removed WorldPop dependencies - db/table/worldpop_population_grid_h3_r8 db/table/worldpop_population_boundary
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

data/in/global_fires/download_new_updates: | data/in
	mkdir -p $@

data/in/global_fires/download_new_updates: | data/in/global_fires
	rm -f data/in/global_fires/new_updates/*.csv
	cd data/in/global_fires/new_updates; wget https://firms.modaps.eosdis.nasa.gov/data/active_fire/c6/csv/MODIS_C6_Global_48h.csv
	cd data/in/global_fires/new_updates; wget https://firms.modaps.eosdis.nasa.gov/data/active_fire/suomi-npp-viirs-c2/csv/SUOMI_VIIRS_C2_Global_48h.csv
	cd data/in/global_fires/new_updates; wget https://firms.modaps.eosdis.nasa.gov/data/active_fire/noaa-20-viirs-c2/csv/J1_VIIRS_C2_Global_48h.csv
	cp data/in/global_fires/new_updates/*.csv data/in/global_fires/
	touch $@

data/in/global_fires/copy_old_data: | data/in/global_fires/download_new_updates
	cp data/firms/old_tables/*.csv data/in/global_fires/
	touch $@

db/table/global_fires: data/in/global_fires/download_new_updates data/in/global_fires/copy_old_data | db/table
	psql -c "create table if not exists global_fires (id serial primary key, latitude float, longitude float, brightness float, bright_ti4 float, scan float, track float, satellite text, instrument text, confidence text, version text, bright_t31 float, bright_ti5 float, frp float, daynight text, acq_datetime timestamptz, hash text, h3_r8 h3index GENERATED ALWAYS AS (h3_geo_to_h3(ST_SetSrid(ST_Point(longitude, latitude), 4326), 8)) STORED);"
	rm -f data/in/global_fires/*_proc.csv
	ls data/in/global_fires/*.csv | parallel "python3 scripts/normalize_global_fires.py {}"
	ls data/in/global_fires/*_proc.csv | parallel "cat {} | psql -c \"set time zone utc; copy global_fires (latitude, longitude, brightness, bright_ti4, scan, track, satellite, confidence, version, bright_t31, bright_ti5, frp, daynight, acq_datetime, hash) from stdin with csv header;\" "
	psql -c "create index if not exists global_fires_hash_idx on global_fires (hash);"
	psql -c "create index if not exists global_fires_acq_datetime_idx on global_fires using brin (acq_datetime);"
	psql -c "delete from global_fires where id in(select id from(select id, row_number() over(partition by hash order by id) as row_num from global_fires) t where t.row_num > 1);"
	rm data/in/global_fires/*.csv
	touch $@

db/table/global_fires_stat_h3: db/table/global_fires
	psql -f tables/global_fires_stat_h3.sql
	touch $@

data/out/global_fires/global_fires_h3_r8_13months.csv.gz: db/table/global_fires | data/out/global_fires
	rm -rf $@
	psql -q -X -c "set timezone to utc; copy (select h3_r8, acq_datetime from global_fires where acq_datetime > (select max(acq_datetime) from global_fires) - interval '13 months' order by 1,2) to stdout with csv;" | pigz > $@

deploy/geocint/global_fires_h3_r8_13months.csv.gz: data/out/global_fires/global_fires_h3_r8_13months.csv.gz | deploy/geocint
	cp -vp data/out/global_fires/global_fires_h3_r8_13months.csv.gz ~/public_html/global_fires_h3_r8_13months.csv.gz
	touch $@

db/table/morocco_urban_pixel_mask: data/morocco_urban_pixel_mask.gpkg | db/table
	ogr2ogr -f PostgreSQL PG:"dbname=gis" data/morocco_urban_pixel_mask.gpkg
	touch $@

db/table/morocco_urban_pixel_mask_h3: db/table/morocco_urban_pixel_mask
	psql -f tables/morocco_urban_pixel_mask_h3.sql
	touch $@

db/table/morocco_buildings_h3: db/table/morocco_buildings | db/table  ## Count amount of Morocco buildings at hexagons.
	psql -f tables/count_items_h3.sql -v table=morocco_buildings -v table_h3=morocco_buildings_h3 -v item_count=building_count
	touch $@

data/in/microsoft_buildings: | data/in
	mkdir -p $@

data/in/microsoft_buildings/download: | data/in/microsoft_buildings
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/tanzania-uganda-buildings/Uganda_2019-09-16.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/tanzania-uganda-buildings/Tanzania_2019-09-16.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/Alberta.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/BritishColumbia.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/Manitoba.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/NewBrunswick.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/NewfoundlandAndLabrador.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/NorthwestTerritories.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/NovaScotia.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/Nunavut.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/Ontario.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/PrinceEdwardIsland.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/Quebec.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/Saskatchewan.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/canadian-buildings-v2/YukonTerritory.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Alabama.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Alaska.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Arizona.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Arkansas.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/California.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Colorado.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Connecticut.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Delaware.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/DistrictofColumbia.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Florida.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Georgia.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Hawaii.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Idaho.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Illinois.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Indiana.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Iowa.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Kansas.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Kentucky.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Louisiana.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Maine.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Maryland.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Massachusetts.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Michigan.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Minnesota.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Mississippi.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Missouri.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Montana.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Nebraska.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Nevada.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/NewHampshire.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/NewJersey.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/NewMexico.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/NewYork.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/NorthCarolina.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/NorthDakota.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Ohio.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Oklahoma.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Oregon.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Pennsylvania.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/RhodeIsland.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/SouthCarolina.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/SouthDakota.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Tennessee.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Texas.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Utah.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Vermont.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Virginia.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Washington.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/WestVirginia.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Wisconsin.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/usbuildings-v1-1/Wyoming.zip
	cd data/in/microsoft_buildings; wget -c -nc https://usbuildingdata.blob.core.windows.net/australia-buildings/Australia_2020-06-21.geojson.zip
	touch $@

data/mid/microsoft_buildings: | data/mid
	mkdir -p $@

data/mid/microsoft_buildings/unzip: data/in/microsoft_buildings/download | data/mid/microsoft_buildings
	ls data/in/microsoft_buildings/*.zip | parallel "unzip -o {} -d data/mid/microsoft_buildings/"
	touch $@

db/table/microsoft_buildings: data/mid/microsoft_buildings/unzip | db/table
	psql -c "drop table if exists microsoft_buildings;"
	psql -c "create table microsoft_buildings (ogc_fid serial not null, geom geometry(polygon,4326));"
	cd data/mid/microsoft_buildings; ls *.geojson | parallel 'ogr2ogr --config PG_USE_COPY YES -append -f PostgreSQL PG:"dbname=gis" {} -nln microsoft_buildings -lco GEOMETRY_NAME=geom -a_srs EPSG:4326'
	psql -c "create index on microsoft_buildings using gist(geom);"
	touch $@

db/table/microsoft_buildings_h3: db/table/microsoft_buildings | db/table ## Count amount of Microsoft Buildings at hexagons.
	psql -f tables/count_items_in_h3.sql -v table=microsoft_buildings -v table_h3=microsoft_buildings_h3 -v item_count=building_count
	touch $@

data/in/new_zealand_buildings: | data/in
	mkdir -p $@

data/in/new_zealand_buildings/download: | data/in/new_zealand_buildings ## Download New Zealand's buildings from AWS S3 bucket.
	cd data/in/new_zealand_buildings; aws s3 cp s3://geodata-us-east-1-kontur/public/geocint/in/data-land-information-new-zealand-govt-nz-building-outlines.gpkg ./
	touch $@

db/table/new_zealand_buildings: data/in/new_zealand_buildings/download | db/table ## Create table with New Zealand buildings.
	psql -c "drop table if exists new_zealand_buildings;"
	time ogr2ogr -f --config PG_USE_COPY YES PostgreSQL PG:"dbname=gis" data/in/new_zealand_buildings/data-land-information-new-zealand-govt-nz-building-outlines.gpkg -nln new_zealand_buildings -lco GEOMETRY_NAME=geom
	touch $@

db/table/new_zealand_buildings_h3: db/table/new_zealand_buildings ## Count amount of New Zealand buildings at hexagons.
	psql -f tables/count_items_in_h3.sql -v table=new_zealand_buildings -v table_h3=new_zealand_buildings_h3 -v item_count=building_count
	touch $@

data/in/geoalert_urban_mapping: | data/in
	mkdir -p $@

data/in/geoalert_urban_mapping/download: | data/in/geoalert_urban_mapping
	cd data/in/geoalert_urban_mapping; wget https://filebrowser.aeronetlab.space/s/TUVKmq2pwNwy4WH/download -O Open_UM_Geoalert-Russia-Chechnya.zip
	cd data/in/geoalert_urban_mapping; wget https://filebrowser.aeronetlab.space/s/znbuMiaZlsrh6NT/download -O Open_UM_Geoalert-Tyva.zip
	cd data/in/geoalert_urban_mapping; wget https://filebrowser.aeronetlab.space/s/q8vri4GTILLivv8/download -O Open-UM_Geoalert-Mos_region.zip
	touch $@

data/mid/geoalert_urban_mapping: | data/mid
	mkdir -p $@

data/mid/geoalert_urban_mapping/unzip: data/in/geoalert_urban_mapping/download | data/mid/geoalert_urban_mapping
	ls data/in/geoalert_urban_mapping/*.zip | parallel "unzip -o {} -d data/mid/geoalert_urban_mapping/"
	touch $@

db/table/geoalert_urban_mapping: data/mid/geoalert_urban_mapping/unzip | db/table
	psql -c "drop table if exists geoalert_urban_mapping;"
	psql -c "create table geoalert_urban_mapping (fid serial not null, class_id integer, processing_date timestamptz, is_osm boolean, geom geometry);"
	cd data/mid/geoalert_urban_mapping; ls *.gpkg | parallel 'ogr2ogr --config PG_USE_COPY YES -append -f PostgreSQL PG:"dbname=gis" {} -nln geoalert_urban_mapping -lco GEOMETRY_NAME=geom'
	touch $@

db/table/geoalert_urban_mapping_h3: db/table/geoalert_urban_mapping | db/table ## Count amount of Geoalert buildings at hexagons.
	psql -f tables/count_items_in_h3.sql -v table=geoalert_urban_mapping -v table_h3=geoalert_urban_mapping_h3 -v item_count=building_count
	touch $@

db/table/kontur_population_h3: db/table/osm_residential_landuse db/table/population_grid_h3_r8 db/table/building_count_grid_h3 db/table/osm_unpopulated db/table/osm_water_polygons db/function/h3 db/table/morocco_urban_pixel_mask_h3 db/index/osm_tags_idx | db/table
	psql -f tables/kontur_population_h3.sql
	touch $@

data/out/kontur_population.gpkg.gz: db/table/kontur_population_h3 | data/out
	rm -f $@
	rm -f data/out/kontur_population.gpkg
	ogr2ogr -f GPKG data/out/kontur_population.gpkg PG:'dbname=gis' -sql "select geom, population from kontur_population_h3 where population>0 and resolution=8 order by h3" -lco "SPATIAL_INDEX=NO" -nln kontur_population
	cd data/out/; pigz kontur_population.gpkg

data/in/kontur_population_v2: | data/in ## Directory for Kontur Population v2.
	mkdir -p $@

data/in/kontur_population_v2/kontur_population_20200928.gpkg.gz: | data/in/kontur_population_v2 ## Download Kontur Population v2 gzip to geocint.
	rm -rf $@
	wget https://adhoc.kontur.io/data/kontur_population_20200928.gpkg.gz -O $@

data/mid/kontur_population_v2: | data/mid ## Create folder for Kontur Population v2 gpkg.
	mkdir -p $@

data/mid/kontur_population_v2/kontur_population_20200928.gpkg: data/in/kontur_population_v2/kontur_population_20200928.gpkg.gz | data/mid/kontur_population_v2 ## Unzip Kontur Population v2 geopackage archive.
	gzip -dck data/in/kontur_population_v2/kontur_population_20200928.gpkg.gz > $@

db/table/kontur_population_v2: data/mid/kontur_population_v2/kontur_population_20200928.gpkg ## Import population v2 into database.
	psql -c "drop table if exists kontur_population_v2;"
	ogr2ogr --config PG_USE_COPY YES -f PostgreSQL PG:'dbname=gis' data/mid/kontur_population_v2/kontur_population_20200928.gpkg -t_srs EPSG:4326 -nln kontur_population_v2 -lco GEOMETRY_NAME=geom
	touch $@

db/table/kontur_population_v2_h3: db/table/kontur_population_v2 ## Generate h3 hexagon for population v2.
	psql -f tables/kontur_population_v2_h3.sql
	psql -c "call generate_overviews('kontur_population_v2_h3', '{population}'::text[], '{sum}'::text[], 8);"
	touch $@

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
	ogr2ogr --config PG_USE_COPY YES -f PostgreSQL PG:"dbname=gis" data/morocco_buildings/geoalert_morocco_stage_3.gpkg "buildings_3" -nln morocco_buildings
	psql -f tables/morocco_buildings.sql
	touch $@

data/out/morocco_buildings/morocco_buildings_footprints_phase3.geojson.gz: db/table/morocco_buildings | data/out/morocco_buildings
	rm -f $@ data/out/morocco_buildings/morocco_buildings_footprints_phase3.geojson
	ogr2ogr -f GeoJSON data/out/morocco_buildings/morocco_buildings_footprints_phase3.geojson PG:"dbname=gis" -sql "select ST_Transform(geom, 4326) as footprint, building_height, height_confidence, is_residential, imagery_vintage, height_is_valid from morocco_buildings_date" -nln morocco_buildings_footprints_phase3
	cd data/out/morocco_buildings; pigz morocco_buildings_footprints_phase3.geojson

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

data/out/morocco_buildings/morocco_buildings_manual_phase2.geojson.gz: db/table/morocco_buildings_iou db/table/morocco_buildings_manual | data/out/morocco_buildings
	rm -f $@
	ogr2ogr -f GeoJSON data/out/morocco_buildings/morocco_buildings_manual_phase2.geojson PG:'dbname=gis' -sql 'select ST_Transform(footprint, 4326), building_height, city, is_confident from morocco_buildings_manual_extent' -nln morocco_buildings_manual_phase2
	cd data/out/morocco_buildings; pigz morocco_buildings_manual_phase2.geojson

data/out/morocco_buildings/morocco_buildings_manual_roofprints_phase2.geojson.gz: db/table/morocco_buildings_iou db/table/morocco_buildings_manual_roofprints | data/out/morocco_buildings
	rm -f $@
	ogr2ogr -f GeoJSON data/out/morocco_buildings/morocco_buildings_manual_roofprints_phase2.geojson PG:'dbname=gis' -sql 'select ST_Transform(geom, 4326), building_height, city, is_confident from morocco_buildings_manual_roofprints_extent' -nln morocco_buildings_manual_roofprints_phase2
	cd data/out/morocco_buildings; pigz morocco_buildings_manual_roofprints_phase2.geojson

data/out/morocco_buildings/morocco_buildings_benchmark_phase2.geojson.gz: db/table/morocco_buildings_benchmark | data/out/morocco_buildings
	rm -f $@
	ogr2ogr -f GeoJSON data/out/morocco_buildings/morocco_buildings_benchmark_phase2.geojson PG:'dbname=gis' -sql 'select ST_Transform(geom, 4326), building_height, city, height_confidence, is_residential from morocco_buildings_benchmark' -nln morocco_buildings_benchmark
	cd data/out/morocco_buildings; pigz morocco_buildings_benchmark_phase2.geojson

data/out/morocco_buildings/morocco_buildings_benchmark_roofprints_phase2.geojson.gz: db/table/morocco_buildings_benchmark_roofprints | data/out/morocco_buildings
	rm -f $@
	ogr2ogr -f GeoJSON data/out/morocco_buildings/morocco_buildings_benchmark_roofprints_phase2.geojson PG:'dbname=gis' -sql 'select ST_Transform(geom, 4326), building_height, city, height_confidence, is_residential from morocco_buildings_benchmark_roofprints' -nln morocco_buildings_benchmark_roofprints
	cd data/out/morocco_buildings; pigz morocco_buildings_benchmark_roofprints_phase2.geojson

data/out/morocco: data/out/morocco_buildings/morocco_buildings_footprints_phase3.geojson.gz data/out/morocco_buildings/morocco_buildings_benchmark_roofprints_phase2.geojson.gz data/out/morocco_buildings/morocco_buildings_benchmark_phase2.geojson.gz data/out/morocco_buildings/morocco_buildings_manual_roofprints_phase2.geojson.gz data/out/morocco_buildings/morocco_buildings_manual_phase2.geojson.gz | data/out
	touch $@

db/table/abu_dhabi_admin_boundaries: | db/table
	psql -f tables/abu_dhabi_admin_boundaries.sql
	touch $@

db/table/abu_dhabi_eatery: db/table/osm db/index/osm_tags_idx db/table/abu_dhabi_admin_boundaries | db/table
	psql -f tables/abu_dhabi_eatery.sql
	touch $@

db/table/abu_dhabi_food_shops: db/table/osm db/index/osm_tags_idx db/table/abu_dhabi_admin_boundaries | db/table
	psql -f tables/abu_dhabi_food_shops.sql
	touch $@

db/table/abu_dhabi_bivariate_pop_food_shops: db/table/abu_dhabi_eatery db/table/abu_dhabi_food_shops db/table/kontur_population_h3 | db/table
	psql -f tables/abu_dhabi_bivariate_pop_food_shops.sql
	touch $@

data/out/abu_dhabi: | data/out
	mkdir -p $@

data/out/abu_dhabi/abu_dhabi_admin_boundaries.geojson: db/table/abu_dhabi_admin_boundaries | data/out/abu_dhabi
	ogr2ogr -f GeoJSON $@ PG:'dbname=gis' -sql 'select gid, name, gadm_level, geom from abu_dhabi_admin_boundaries' -nln abu_dhabi_admin_boundaries

data/out/abu_dhabi/abu_dhabi_eatery.csv: db/table/abu_dhabi_eatery | data/out/abu_dhabi
	psql -q -X -c 'copy (select osm_id, type, ST_Y(geom) "lat", ST_X(geom) "lon" from abu_dhabi_eatery) to stdout with csv header;' > $@

data/out/abu_dhabi/abu_dhabi_food_shops.csv: db/table/abu_dhabi_food_shops | data/out/abu_dhabi
	psql -q -X -c 'copy (select osm_id, type, ST_Y(geom) "lat", ST_X(geom) "lon" from abu_dhabi_food_shops) to stdout with csv header;' > $@

data/out/abu_dhabi/abu_dhabi_bivariate_pop_food_shops.csv: db/table/abu_dhabi_bivariate_pop_food_shops | data/out/abu_dhabi
	psql -q -X -c 'copy (select h3, population, places, bivariate_cell_label from abu_dhabi_bivariate_pop_food_shops) to stdout with csv header;' > $@

data/out/abu_dhabi_export: data/out/abu_dhabi/abu_dhabi_admin_boundaries.geojson data/out/abu_dhabi/abu_dhabi_eatery.csv data/out/abu_dhabi/abu_dhabi_food_shops.csv data/out/abu_dhabi/abu_dhabi_bivariate_pop_food_shops.csv
	touch $@

db/table/osm_population_raw_idx: db/table/osm_population_raw
	psql -c "create index on osm_population_raw using gist(geom)"
	touch $@

db/table/population_grid_h3_r8_osm_scaled: db/table/population_grid_h3_r8 db/procedure/decimate_admin_level_in_osm_population_raw db/table/osm_population_raw_idx
	psql -f tables/population_grid_h3_r8_osm_scaled.sql
	touch $@

db/table/osm_landuse: db/table/osm db/index/osm_tags_idx | db/table
	psql -f tables/osm_landuse.sql
	touch $@

db/table/osm_landuse_industrial: db/table/osm db/index/osm_tags_idx | db/table
	psql -f tables/osm_landuse_industrial.sql
	touch $@

db/table/osm_landuse_industrial_h3: db/table/osm_landuse_industrial | db/table
	psql -f tables/osm_landuse_industrial_h3.sql
	psql -c "call generate_overviews('osm_landuse_industrial_h3', '{industrial_area}'::text[], '{sum}'::text[], 8);"
	touch $@

db/table/osm_volcanos_h3: db/index/osm_tags_idx db/procedure/generate_overviews | db/table
	psql -f tables/osm_volcanos.sql
	psql -f tables/count_points_inside_h3.sql -v table=osm_volcanos -v table_h3=osm_volcanos_h3 -v item_count=volcanos_count
	psql -c "call generate_overviews('osm_volcanos_h3', '{volcanos_count}'::text[], '{sum}'::text[], 8);"
	touch $@

db/table/osm_buildings_minsk: db/table/osm_buildings_use | db/table
	psql -c "drop table if exists osm_buildings_minsk;"
	psql -c "create table osm_buildings_minsk as (select building, street, hno, levels, height, use, \"name\", geom from osm_buildings b where ST_DWithin (b.geom, (select geog::geometry from osm where tags @> '{\"name\":\"Минск\", \"boundary\":\"administrative\"}' and osm_id = 59195 and osm_type = 'relation'), 0));"
	touch $@

data/out/osm_buildings_minsk.geojson.gz: db/table/osm_buildings_minsk | data/out
	rm -f $@
	rm -f data/out/osm_buildings_minsk.geojson*
	ogr2ogr -f GeoJSON data/out/osm_buildings_minsk.geojson PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_minsk' -nln osm_buildings_minsk
	cd data/out/; pigz osm_buildings_minsk.geojson

deploy/s3/osm_buildings_minsk: data/out/osm_buildings_minsk.geojson.gz | deploy/s3
	aws s3api put-object --bucket geodata-us-east-1-kontur --key public/geocint/osm_buildings_minsk.geojson.gz --body data/out/osm_buildings_minsk.geojson.gz --content-type "application/json" --content-encoding "gzip" --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers
	touch $@

data/in/census_gov: | data/in
	mkdir $@

data/in/census_gov/cb_2019_us_tract_500k.zip: | data/in/census_gov ## Download census tract data from AWS S3 bucket.
	cd data/in/census_gov; aws s3 cp s3://geodata-us-east-1-kontur/public/geocint/in/cb_2019_us_tract_500k.zip ./

data/mid/census_gov: | data/mid
	mkdir $@

data/mid/census_gov/cb_2019_us_tract_500k.shp: data/in/census_gov/cb_2019_us_tract_500k.zip | data/mid/census_gov
	unzip -o data/in/census_gov/cb_2019_us_tract_500k.zip -d data/mid/census_gov/
	touch $@

db/table/us_census_tract_boundaries: data/mid/census_gov/cb_2019_us_tract_500k.shp | db/table ## Import all US census tract boundaries into database
	ogr2ogr --config PG_USE_COPY YES -overwrite -s_srs EPSG:4269 -t_srs EPSG:4326 -f PostgreSQL PG:"dbname=gis" data/mid/census_gov/cb_2019_us_tract_500k.shp -nlt GEOMETRY -lco GEOMETRY_NAME=geom -nln us_census_tract_boundaries
	touch $@

data/in/census_gov/data_census_download: | data/in/census_gov ## Download thematic census tracts Zealand's buildings from AWS S3 bucket.
	cd data/in/census_gov; aws s3 cp s3://geodata-us-east-1-kontur/public/geocint/in/ ./ --recursive --exclude "*" --include "*us_census_tracts_*"
	touch $@

data/mid/census_gov/us_census_tracts_stats.csv: data/in/census_gov/data_census_download | data/mid/census_gov
	python3 scripts/normalize_census_data.py -c data/census_data_config.json -o $@

db/table/us_census_tract_stats: db/table/us_census_tract_boundaries data/mid/census_gov/us_census_tracts_stats.csv | db/table
	psql -c 'drop table if exists us_census_tracts_stats_in;'
	psql -c 'create table us_census_tracts_stats_in (id_tract text, tract_name text, pop_under_5_total float, pop_over_65_total float, families_total float, families_poverty_percent float, poverty_families_total float generated always as (families_total * families_poverty_percent / 100) stored, pop_disability_total float, pop_not_well_eng_speak float, pop_working_total float, pop_with_cars_percent float, pop_without_car float generated always as (pop_working_total - (pop_working_total * pop_with_cars_percent) / 100) stored);'
	cat data/mid/census_gov/us_census_tracts_stats.csv | psql -c "copy us_census_tracts_stats_in (id_tract, tract_name, pop_under_5_total, pop_over_65_total, families_total, families_poverty_percent, pop_disability_total, pop_not_well_eng_speak, pop_working_total, pop_with_cars_percent) from stdin with csv header delimiter ';';"
	psql -f tables/us_census_tracts_stats.sql
	touch $@

db/table/us_census_tracts_stats_h3: db/table/us_census_tract_stats db/procedure/generate_overviews | db/table ## Generate h3 with stats data in California census tracts from 1 to 8 resolution
	psql -f tables/us_census_tracts_stats_h3.sql
	psql -c "call generate_overviews('us_census_tracts_stats_h3', '{pop_under_5_total, pop_over_65_total, poverty_families_total, pop_disability_total, pop_not_well_eng_speak, pop_without_car}'::text[], '{sum, sum, sum, sum, sum, sum}'::text[], 8);"
	touch $@

db/table/pf_days_maxtemp_in: | db/table
	psql -c 'drop table if exists pf_days_maxtemp_in;'
	ogr2ogr -f PostgreSQL PG:"dbname=gis" data/in/probable_futures/20104.gremo.geojson -nln pf_days_maxtemp_in -lco GEOMETRY_NAME=geom
	touch $@

db/table/pf_night_maxtemp_in: | db/table
	psql -c 'drop table if exists pf_nights_maxtemp_in;'
	ogr2ogr -f PostgreSQL PG:"dbname=gis" data/in/probable_futures/20204.gremo.geojson -nln pf_nights_maxtemp_in -lco GEOMETRY_NAME=geom
	touch $@

db/table/pf_days_wet_bulb_in: | db/table
	psql -c 'drop table if exists pf_days_wet_bulb_in;'
	ogr2ogr -f PostgreSQL PG:"dbname=gis" data/in/probable_futures/20304.gremo.geojson -nln pf_days_wet_bulb_in -lco GEOMETRY_NAME=geom
	touch $@

db/table/pf_maxtemp_idw_h3: db/table/pf_night_maxtemp_in db/table/pf_days_maxtemp_in db/table/pf_days_wet_bulb_in | db/table
	psql -f tables/pf_maxtemp_idw_h3.sql
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

data/out/osm_addresses_minsk.geojson.gz: db/table/osm_addresses_minsk | data/out
	rm -vf data/out/osm_addresses_minsk.geojson*
	ogr2ogr -f GeoJSON data/out/osm_addresses_minsk.geojson PG:'dbname=gis' -sql "select * from osm_addresses_minsk" -nln osm_addresses_minsk
	pigz data/out/osm_addresses_minsk.geojson

deploy/s3/test/osm_addresses_minsk: data/out/osm_addresses_minsk.geojson.gz | deploy/s3
	aws s3api copy-object --copy-source geodata-us-east-1-kontur/public/geocint/test/osm_addresses_minsk.geojson.gz --bucket geodata-us-east-1-kontur --key public/geocint/test/osm_addresses_minsk.geojson.gz.bak --content-type "application/json" --content-encoding "gzip" --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers
	aws s3api put-object --bucket geodata-us-east-1-kontur --key public/geocint/test/osm_addresses_minsk.geojson.gz --body data/out/osm_addresses_minsk.geojson.gz --content-type "application/json" --content-encoding "gzip" --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers
	touch $@

deploy/s3/osm_addresses_minsk: data/out/osm_addresses_minsk.geojson.gz | deploy/s3
	aws s3api copy-object --copy-source geodata-us-east-1-kontur/public/geocint/osm_addresses_minsk.geojson.gz --bucket geodata-us-east-1-kontur --key public/geocint/osm_addresses_minsk.geojson.gz.bak --content-type "application/json" --content-encoding "gzip" --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers
	aws s3api put-object --bucket geodata-us-east-1-kontur --key public/geocint/osm_addresses_minsk.geojson.gz --body data/out/osm_addresses_minsk.geojson.gz --content-type "application/json" --content-encoding "gzip" --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers
	touch $@

db/table/osm_admin_boundaries: db/table/osm db/index/osm_tags_idx | db/table
	psql -f tables/osm_admin_boundaries.sql
	touch $@

data/osm_admin_boundaries.geojson.gz: db/table/osm_admin_boundaries
	rm -vf data/osm_admin_boundaries.geojson*
	ogr2ogr -f GeoJSON data/osm_admin_boundaries.geojson PG:'dbname=gis' -sql "select * from osm_admin_boundaries" -nln osm_admin_boundaries
	pigz data/osm_admin_boundaries.geojson
	touch $@

deploy/s3/osm_admin_boundaries: data/osm_admin_boundaries.geojson.gz | deploy/s3
	aws s3api put-object --bucket geodata-us-east-1-kontur --key public/geocint/osm_admin_boundaries.geojson.gz --body data/osm_admin_boundaries.geojson.gz --content-type "application/json" --content-encoding "gzip" --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers
	touch $@

db/table/osm_buildings: db/index/osm_tags_idx db/function/parse_float db/function/parse_integer | db/table ## Table with all the buildings, but not all the properties yet.
	psql -f tables/osm_buildings.sql
	touch $@

db/table/osm_buildings_use: db/table/osm_buildings db/table/osm_landuse ## Set use in buildings table from landuse table.
	psql -f tables/osm_buildings_use.sql
	touch $@

db/table/residential_pop_h3: db/table/kontur_population_h3 db/table/ghs_globe_residential_vector | db/table
	psql -f tables/residential_pop_h3.sql
	touch $@

db/table/stat_h3: db/table/osm_object_count_grid_h3 db/table/residential_pop_h3 db/table/gdp_h3 db/table/user_hours_h3 db/table/tile_logs db/table/global_fires_stat_h3 db/table/building_count_grid_h3 db/table/covid19_vaccine_accept_us_counties_h3 db/table/copernicus_forest_h3 db/table/gebco_2020_slopes_h3 db/table/ndvi_2019_06_10_h3 db/table/covid19_h3 db/table/kontur_population_v2_h3 db/table/osm_landuse_industrial_h3 db/table/osm_volcanos_h3 db/table/us_census_tracts_stats_h3 db/table/gebco_2020_elevation_h3 db/table/pf_maxtemp_idw_h3 | db/table
	psql -f tables/stat_h3.sql
	touch $@

db/table/bivariate_axis: db/table/bivariate_indicators db/table/stat_h3 | data/tiles/stat
	psql -f tables/bivariate_axis.sql
	touch $@

db/table/bivariate_axis_correlation: db/table/bivariate_axis db/table/stat_h3 | data/tiles/stat
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
	psql -c "call generate_overviews('tile_logs_h3', '{view_count}'::text[], '{sum}'::text[], 8);"
	touch $@

data/tiles/stats_tiles.tar.bz2: tile_generator/tile_generator db/table/bivariate_axis db/table/bivariate_overlays db/table/bivariate_indicators db/table/bivariate_colors db/table/stat_h3 db/table/osm_meta | data/tiles
	tile_generator/tile_generator -j 32 --min-zoom 0 --max-zoom 8 --sql-query-filepath 'scripts/stats.sql' --db-config 'dbname=gis user=gis' --output-path data/tiles/stats
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

data/tiles/users_tiles.tar.bz2: tile_generator/tile_generator db/table/osm_users_hex db/table/osm_meta db/function/calculate_h3_res | data/tiles
	tile_generator/tile_generator -j 32 --min-zoom 0 --max-zoom 8 --sql-query-filepath 'scripts/users.sql' --db-config 'dbname=gis user=gis' --output-path data/tiles/users
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

data/population/population_api_tables.sqld.gz: db/table/stat_h3 db/table/bivariate_axis db/table/bivariate_axis_correlation  db/table/bivariate_overlays db/table/bivariate_indicators db/table/bivariate_colors | data/population ## Crafting production friendly SQL dump
	bash -c "cat scripts/population_api_dump_header.sql <(pg_dump --no-owner -t stat_h3 | sed 's/ public.stat_h3 / public.stat_h3__new /; s/^CREATE INDEX stat_h3.*//;') <(pg_dump --clean --if-exists --no-owner -t bivariate_axis -t bivariate_axis_correlation -t bivariate_axis_stats -t bivariate_colors -t bivariate_indicators -t bivariate_overlays) scripts/population_api_dump_footer.sql | pigz" > $@__TMP
	mv $@__TMP $@
	touch $@

deploy/s3/test/population_api_tables: data/population/population_api_tables.sqld.gz | deploy/s3
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/test/population_api_tables.sqld.gz s3://geodata-eu-central-1-kontur/private/geocint/test/population_api_tables.sqld.gz.bak --profile geocint_pipeline_sender
	aws s3 cp data/population/population_api_tables.sqld.gz s3://geodata-eu-central-1-kontur/private/geocint/test/population_api_tables.sqld.gz --profile geocint_pipeline_sender
	touch $@

deploy/zigzag/population_api_tables: deploy/s3/test/population_api_tables | deploy/zigzag
	ansible zigzag_population_api -m file -a 'path=$$HOME/tmp state=directory mode=0770'
	ansible zigzag_population_api -m amazon.aws.aws_s3 -a 'bucket=geodata-eu-central-1-kontur object=/private/geocint/test/population_api_tables.sqld.gz dest=$$HOME/tmp/population_api_tables.sqld.gz mode=get'
	ansible zigzag_population_api -m postgresql_db -a 'name=population-api maintenance_db=population-api login_user=population-api login_host=localhost state=restore target=$$HOME/tmp/population_api_tables.sqld.gz'
	ansible zigzag_population_api -m file -a 'path=$$HOME/tmp/population_api_tables.sqld.gz state=absent'
	touch $@

deploy/sonic/population_api_tables: deploy/s3/test/population_api_tables | deploy/sonic
	ansible sonic_population_api -m file -a 'path=$$HOME/tmp state=directory mode=0770'
	ansible sonic_population_api -m amazon.aws.aws_s3 -a 'bucket=geodata-eu-central-1-kontur object=/private/geocint/test/population_api_tables.sqld.gz dest=$$HOME/tmp/population_api_tables.sqld.gz mode=get'
	ansible sonic_population_api -m postgresql_db -a 'name=population-api maintenance_db=population-api login_user=population-api login_host=localhost state=restore target=$$HOME/tmp/population_api_tables.sqld.gz'
	ansible sonic_population_api -m file -a 'path=$$HOME/tmp/population_api_tables.sqld.gz state=absent'
	touch $@

deploy/lima/population_api_tables: data/population/population_api_tables.sqld.gz | deploy/lima
	ansible lima_population_api -m file -a 'path=$$HOME/tmp state=directory mode=0770'
	ansible lima_population_api -m copy -a 'src=data/population/population_api_tables.sqld.gz dest=$$HOME/tmp/population_api_tables.sqld.gz'
	ansible lima_population_api -m postgresql_db -a 'name=population-api maintenance_db=population-api login_user=population-api login_host=localhost state=restore target=$$HOME/tmp/population_api_tables.sqld.gz'
	ansible lima_population_api -m file -a 'path=$$HOME/tmp/population_api_tables.sqld.gz state=absent'
	touch $@

db/table/osm2pgsql: data/planet-latest-updated.osm.pbf | db/table
	osm2pgsql --style basemap/osm2pgsql_styles/default.style --number-processes 32 --hstore-all --flat-nodes data/planet-latest-updated-flat-nodes --slim --drop --create data/planet-latest-updated.osm.pbf
	touch $@

db/table/osm2pgsql_mix_in_coastlines: db/table/osm2pgsql db/table/water_polygons_vector | db/table
	psql -c "insert into planet_osm_polygon (osm_id, \"natural\", way, way_area) select 0 as osm_id, 'coastline' as \"natural\", geom as way, ST_Area(geom) as way_area from water_polygons_vector;"
	touch $@

kothic:
	git clone -b master --single-branch https://github.com/kothic/kothic.git

tile_generator/tile_generator: tile_generator/main.go tile_generator/go.mod
	cd tile_generator; go get; go build -o tile_generator

db/function/basemap_mapsme: | kothic db/function
	python2 kothic/src/komap.py \
		--renderer=mvt-sql \
		--stylesheet basemap/styles/ninja.mapcss \
		--osm2pgsql-style basemap/osm2pgsql_styles/default.style \
		| psql
	touch $@

data/tiles/basemap_all: tile_generator/tile_generator db/function/basemap_mapsme db/table/osm2pgsql_mix_in_coastlines | data/tiles
	tile_generator/tile_generator -j 32 --min-zoom 0 --max-zoom 8 --sql-query-filepath 'scripts/basemap.sql' --db-config 'dbname=gis user=gis' --output-path data/tiles/basemap
	touch $@

data/basemap: | data
	mkdir -p $@

data/basemap/glyphs: | data/basemap
	mkdir -p $@

data/basemap/sprite: | data/basemap
	mkdir -p $@

data/basemap/metadata: | data/basemap
	mkdir -p $@

data/basemap/metadata/zigzag: | data/basemap/metadata
	mkdir -p $@

data/basemap/metadata/sonic: | data/basemap/metadata
	mkdir -p $@

data/basemap/metadata/lima: | data/basemap/metadata
	mkdir -p $@

data/basemap/metadata/geocint: | data/basemap/metadata
	mkdir -p $@

data/basemap/glyphs_all: | data/basemap/glyphs
	rm -rf basemap/omt_fonts
	git clone https://github.com/openmaptiles/fonts.git basemap/omt_fonts
	cd basemap/omt_fonts; npm i
	cd basemap/omt_fonts; node generate.js
	cp -r basemap/omt_fonts/_output/. data/basemap/glyphs
	touch $@

data/basemap/sprite_all: | data/basemap/sprite
	wget -O data/basemap/sprite/sprite@2x.png https://api.mapbox.com/styles/v1/akiyamka/cjushbakm094j1fryd5dn0x4q/0a2mkag2uzqs8kk8pfue80nq2/sprite@2x.png?access_token=pk.eyJ1IjoiYWtpeWFta2EiLCJhIjoiY2p3NjNwdmkyMGp4NTN5cGI0cHFzNW5wZiJ9.WXaCSY3ZLzwB9AIJaOovLw
	wget -O data/basemap/sprite/sprite@2x.json https://api.mapbox.com/styles/v1/akiyamka/cjushbakm094j1fryd5dn0x4q/0a2mkag2uzqs8kk8pfue80nq2/sprite@2x.json?access_token=pk.eyJ1IjoiYWtpeWFta2EiLCJhIjoiY2p3NjNwdmkyMGp4NTN5cGI0cHFzNW5wZiJ9.WXaCSY3ZLzwB9AIJaOovLw
	wget -O data/basemap/sprite/sprite.png https://api.mapbox.com/styles/v1/akiyamka/cjushbakm094j1fryd5dn0x4q/0a2mkag2uzqs8kk8pfue80nq2/sprite.png?access_token=pk.eyJ1IjoiYWtpeWFta2EiLCJhIjoiY2p3NjNwdmkyMGp4NTN5cGI0cHFzNW5wZiJ9.WXaCSY3ZLzwB9AIJaOovLw
	wget -O data/basemap/sprite/sprite.json https://api.mapbox.com/styles/v1/akiyamka/cjushbakm094j1fryd5dn0x4q/0a2mkag2uzqs8kk8pfue80nq2/sprite.json?access_token=pk.eyJ1IjoiYWtpeWFta2EiLCJhIjoiY2p3NjNwdmkyMGp4NTN5cGI0cHFzNW5wZiJ9.WXaCSY3ZLzwB9AIJaOovLw
	touch $@

data/basemap/metadata/zigzag/style_ninja.json: | kothic data/basemap/metadata/zigzag
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet basemap/styles/ninja.mapcss \
		--tiles-max-zoom 9 \
		--tiles-url https://zigzag.kontur.io/tiles/basemap/{z}/{x}/{y}.mvt \
		--glyphs-url https://zigzag.kontur.io/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		--sprite-url https://zigzag.kontur.io/tiles/basemap/sprite \
		> $@
	cat $@ | python basemap/scripts/patch_style_display_osm_from_z9.py | sponge $@

data/basemap/metadata/zigzag/style_day.json: | kothic data/basemap/metadata/zigzag
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet basemap/styles/mapsme_mod/style-clear/style.mapcss \
		--tiles-max-zoom 9 \
		--tiles-url https://zigzag.kontur.io/tiles/basemap/{z}/{x}/{y}.mvt \
		--glyphs-url https://zigzag.kontur.io/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		> $@

data/basemap/metadata/zigzag/style_night.json: | kothic data/basemap/metadata/zigzag
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet basemap/styles/mapsme_mod/style-night/style.mapcss \
		--tiles-max-zoom 9 \
		--tiles-url https://zigzag.kontur.io/tiles/basemap/{z}/{x}/{y}.mvt \
		--glyphs-url https://zigzag.kontur.io/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		> $@

data/basemap/metadata/sonic/style_ninja.json: | kothic data/basemap/metadata/sonic
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet basemap/styles/ninja.mapcss \
		--tiles-max-zoom 9 \
		--tiles-url https://sonic.kontur.io/tiles/basemap/{z}/{x}/{y}.mvt \
		--glyphs-url https://sonic.kontur.io/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		--sprite-url https://sonic.kontur.io/tiles/basemap/sprite \
		> $@
	cat $@ | python basemap/scripts/patch_style_display_osm_from_z9.py | sponge $@

data/basemap/metadata/sonic/style_day.json: | kothic data/basemap/metadata/sonic
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet basemap/styles/mapsme_mod/style-clear/style.mapcss \
		--tiles-max-zoom 9 \
		--tiles-url https://sonic.kontur.io/tiles/basemap/{z}/{x}/{y}.mvt \
		--glyphs-url https://sonic.kontur.io/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		> $@

data/basemap/metadata/sonic/style_night.json: | kothic data/basemap/metadata/sonic
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet basemap/styles/mapsme_mod/style-night/style.mapcss \
		--tiles-max-zoom 9 \
		--tiles-url https://sonic.kontur.io/tiles/basemap/{z}/{x}/{y}.mvt \
		--glyphs-url https://sonic.kontur.io/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		> $@

data/basemap/metadata/lima/style_ninja.json: | kothic data/basemap/metadata/lima
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet basemap/styles/ninja.mapcss \
		--tiles-max-zoom 9 \
		--tiles-url https://disaster.ninja/tiles/basemap/{z}/{x}/{y}.mvt \
		--glyphs-url https://disaster.ninja/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		--sprite-url https://disaster.ninja/tiles/basemap/sprite \
		> $@
	cat $@ | python basemap/scripts/patch_style_display_osm_from_z9.py | sponge $@

data/basemap/metadata/lima/style_day.json: | kothic data/basemap/metadata/lima
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet basemap/styles/mapsme_mod/style-clear/style.mapcss \
		--tiles-max-zoom 9 \
		--tiles-url https://disaster.ninja/tiles/basemap/{z}/{x}/{y}.mvt \
		--glyphs-url https://disaster.ninja/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		> $@

data/basemap/metadata/lima/style_night.json: | kothic data/basemap/metadata/lima
	python2 kothic/src/libkomb.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet basemap/styles/mapsme_mod/style-night/style.mapcss \
		--tiles-max-zoom 9 \
		--tiles-url https://disaster.ninja/tiles/basemap/{z}/{x}/{y}.mvt \
		--glyphs-url https://disaster.ninja/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		> $@

data/basemap/metadata/geocint/style_ninja.json: basemap/styles/ninja.mapcss | kothic data/basemap/metadata/geocint
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet basemap/styles/ninja.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://geocint.kontur.io/pgtileserv/public.basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://geocint.kontur.io/basemap/glyphs/{fontstack}/{range}.pbf \
		--sprite-url https://geocint.kontur.io/basemap/sprite \
		> $@
	cat $@ | python basemap/scripts/patch_style_display_osm_from_z9.py | sponge $@

data/basemap/metadata/geocint/style_day.json: | kothic data/basemap/metadata/geocint
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet basemap/styles/mapsme_mod/style-clear/style.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://geocint.kontur.io/pgtileserv/public.basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://geocint.kontur.io/basemap/glyphs/{fontstack}/{range}.pbf \
		> $@

data/basemap/metadata/geocint/style_night.json: | kothic data/basemap/metadata/geocint
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet basemap/styles/mapsme_mod/style-night/style.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://geocint.kontur.io/pgtileserv/public.basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://geocint.kontur.io/basemap/glyphs/{fontstack}/{range}.pbf \
		> $@

deploy/geocint/basemap_mapcss: data/basemap/metadata/geocint/style_ninja.json data/basemap/metadata/geocint/style_day.json data/basemap/metadata/geocint/style_night.json
	cp data/basemap/metadata/geocint/style_ninja.json /var/www/html/basemap/style_ninja.json
	cp data/basemap/metadata/geocint/style_day.json /var/www/html/basemap/style_mwm.json
	cp data/basemap/metadata/geocint/style_night.json /var/www/html/basemap/style_mwm_night.json
	touch $@

deploy/geocint/basemap: deploy/geocint/basemap_mapcss data/tiles/basemap_all data/basemap/glyphs_all | deploy/geocint
	cp -r data/basemap/glyphs/. /var/www/html/basemap/glyphs
	cp -r data/tiles/basemap/. /var/www/tiles/basemap
	touch $@

data/basemap/zigzag.tar.bz2: data/tiles/basemap_all data/basemap/metadata/zigzag/style_ninja.json data/basemap/metadata/zigzag/style_day.json data/basemap/metadata/zigzag/style_night.json data/basemap/glyphs_all data/basemap/sprite_all
	tar cvf $@ --use-compress-prog=pbzip2 -C data/tiles/basemap . -C ../../basemap glyphs -C sprite . -C ../metadata/zigzag .

data/basemap/sonic.tar.bz2: data/tiles/basemap_all data/basemap/metadata/sonic/style_ninja.json data/basemap/metadata/sonic/style_day.json data/basemap/metadata/sonic/style_night.json data/basemap/glyphs_all data/basemap/sprite_all
	tar cvf $@ --use-compress-prog=pbzip2 -C data/tiles/basemap . -C ../../basemap glyphs -C sprite . -C ../metadata/sonic .

data/basemap/lima.tar.bz2: data/tiles/basemap_all data/basemap/metadata/lima/style_ninja.json data/basemap/metadata/lima/style_day.json data/basemap/metadata/lima/style_night.json data/basemap/glyphs_all data/basemap/sprite_all
	tar cvf $@ --use-compress-prog=pbzip2 -C data/tiles/basemap . -C ../../basemap glyphs -C sprite . -C ../metadata/lima .

deploy/zigzag/basemap: data/basemap/zigzag.tar.bz2 | deploy/zigzag
	ansible zigzag_live_dashboard -m file -a 'path=$$HOME/tmp state=directory mode=0770'
	ansible zigzag_live_dashboard -m copy -a 'src=data/basemap/zigzag.tar.bz2 dest=$$HOME/tmp/basemap.tar.bz2'
	ansible zigzag_live_dashboard -m shell -a 'warn:false' -a ' \
		set -e; \
		set -o pipefail; \
		mkdir -p "$$HOME/public_html/tiles/basemap"; \
		tar -cjf "$$HOME/tmp/basemap_prev.tar.bz2" -C "$$HOME/public_html/tiles/basemap" . ; \
		TMPDIR=$$(mktemp -d -p "$$HOME/tmp"); \
		function on_exit { rm -rf "$$TMPDIR"; }; \
		trap on_exit EXIT; \
		tar -xf "$$HOME/tmp/basemap.tar.bz2" -C "$$TMPDIR"; \
		find "$$TMPDIR" -type d -exec chmod 0775 "{}" "+"; \
		find "$$TMPDIR" -type f -exec chmod 0664 "{}" "+"; \
		renameat2 -e "$$TMPDIR" "$$HOME/public_html/tiles/basemap"; \
		rm -f "$$HOME/tmp/basemap.tar.bz2"; \
	'
	touch $@

deploy/sonic/basemap: data/basemap/sonic.tar.bz2 | deploy/sonic
	ansible sonic_live_dashboard -m file -a 'path=$$HOME/tmp state=directory mode=0770'
	ansible sonic_live_dashboard -m copy -a 'src=data/basemap/sonic.tar.bz2 dest=$$HOME/tmp/basemap.tar.bz2'
	ansible sonic_live_dashboard -m shell -a 'warn:false' -a ' \
		set -e; \
		set -o pipefail; \
		mkdir -p "$$HOME/public_html/tiles/basemap"; \
		tar -cjf "$$HOME/tmp/basemap_prev.tar.bz2" -C "$$HOME/public_html/tiles/basemap" . ; \
		TMPDIR=$$(mktemp -d -p "$$HOME/tmp"); \
		function on_exit { rm -rf "$$TMPDIR"; }; \
		trap on_exit EXIT; \
		tar -xf "$$HOME/tmp/basemap.tar.bz2" -C "$$TMPDIR"; \
		find "$$TMPDIR" -type d -exec chmod 0775 "{}" "+"; \
		find "$$TMPDIR" -type f -exec chmod 0664 "{}" "+"; \
		renameat2 -e "$$TMPDIR" "$$HOME/public_html/tiles/basemap"; \
		rm -f "$$HOME/tmp/basemap.tar.bz2"; \
	'
	touch $@

deploy/lima/basemap: data/basemap/lima.tar.bz2 | deploy/lima
	ansible lima_live_dashboard -m file -a 'path=$$HOME/tmp state=directory mode=0770'
	ansible lima_live_dashboard -m copy -a 'src=data/basemap/lima.tar.bz2 dest=$$HOME/tmp/basemap.tar.bz2'
	ansible lima_live_dashboard -m shell -a 'warn:false' -a ' \
		set -e; \
		set -o pipefail; \
		mkdir -p "$$HOME/public_html/tiles/basemap"; \
		tar -cjf "$$HOME/tmp/basemap_prev.tar.bz2" -C "$$HOME/public_html/tiles/basemap" . ; \
		TMPDIR=$$(mktemp -d -p "$$HOME/tmp"); \
		function on_exit { rm -rf "$$TMPDIR"; }; \
		trap on_exit EXIT; \
		tar -xf "$$HOME/tmp/basemap.tar.bz2" -C "$$TMPDIR"; \
		find "$$TMPDIR" -type d -exec chmod 0775 "{}" "+"; \
		find "$$TMPDIR" -type f -exec chmod 0664 "{}" "+"; \
		renameat2 -e "$$TMPDIR" "$$HOME/public_html/tiles/basemap"; \
		rm -f "$$HOME/tmp/basemap.tar.bz2"; \
	'
	touch $@