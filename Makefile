## -------------- EXPORT BLOCK ------------------------

# configuration file
file := ${GEOCINT_WORK_DIRECTORY}/config.inc.sh
# Add here export for every varible from configuration file that you are going to use in targets
export PGDATABASE = $(shell sed -n -e '/^PGDATABASE/p' ${file} | cut -d "=" -f 2)
export SLACK_CHANNEL = $(shell sed -n -e '/^SLACK_CHANNEL/p' ${file} | cut -d "=" -f 2)
export SLACK_BOT_NAME = $(shell sed -n -e '/^SLACK_BOT_NAME/p' ${file} | cut -d "=" -f 2)
export SLACK_BOT_EMOJI = $(shell sed -n -e '/^SLACK_BOT_EMOJI/p' ${file} | cut -d "=" -f 2)
export SLACK_KEY = $(shell sed -n -e '/^SLACK_KEY/p' ${file} | cut -d "=" -f 2)
export HDX_API_TOKEN = $(shell sed -n -e '/^HDX_API_TOKEN/p' ${file} | cut -d "=" -f 2)

current_date:=$(shell date '+%Y%m%d')

# these makefiles stored in geocint-runner and geocint-openstreetmap repositories
# runner_make contains basic set of targets for creation project folder structure
# osm_make contains contain set of targets for osm data processing
include runner_make osm_make

## ------------- CONTROL BLOCK -------------------------

all: prod dev data/out/abu_dhabi_export data/out/isochrone_destinations_export db/table/covid19_vaccine_accept_us_counties_h3 data/out/morocco deploy/geocint/users_tiles db/table/iso_codes db/table/un_population deploy/geocint/docker_osrm_backend data/out/kontur_boundaries_per_country/export db/function/build_isochrone deploy/dev/users_tiles db/table/ghsl_h3 data/out/ghsl_output/export_gpkg data/out/kontur_topology_boundaries_per_country/export data/out/hdxloader/hdxloader_update_customviz deploy/kontur_boundaries_new_release_on_hdx db/table/foursquare_places_h3 db/table/foursquare_visits_h3 db/table/ndpba_rva_h3 db/table/global_rva_h3 data/out/csv/foursquare_places_count.csv data/out/csv/foursquare_visits_count.csv ## [FINAL] Meta-target on top of all other targets, or targets on parking.

dev: deploy/geocint/belarus-latest.osm.pbf deploy/s3/test/osm_users_hex_dump deploy/test/users_tiles deploy/geocint/isochrone_tables deploy/dev/cleanup_cache deploy/test/cleanup_cache deploy/s3/test/osm_addresses_minsk data/out/kontur_population.gpkg.gz data/out/kontur_population_r6.gpkg.gz data/out/kontur_population_r4.gpkg.gz data/planet-check-refs deploy/s3/test/reports/test_reports_public deploy/s3/dev/reports/dev_reports_public data/out/kontur_population_per_country/export db/table/ndpba_rva_h3 deploy/s3/test/kontur_events_updated db/table/prescale_to_osm_check_changes data/out/kontur_population_v5_r4.gpkg.gz data/out/kontur_population_v5_r6.gpkg.gz data/out/kontur_population_v5_r4.csv data/out/kontur_population_v5_r6.csv data/out/kontur_population_v5.csv data/out/missed_hascs_check deploy_indicators/test/custom_axis/all_custom_axis deploy_indicators/dev/custom_axis/all_custom_axis deploy_indicators/test/presets/all_presets deploy_indicators/dev/presets/all_presets deploy/s3/test/reports/reports.tar.gz deploy/s3/dev/reports/reports.tar.gz ## [FINAL] Builds all targets for development. Run on every branch.	
	touch $@
	echo "Dev target has built!" | python3 scripts/slack_message.py $$SLACK_CHANNEL ${SLACK_BOT_NAME} $$SLACK_BOT_EMOJI

prod_new_deploy: deploy/prod/users_tiles deploy/s3/prod/osm_users_hex_dump deploy/prod/cleanup_cache deploy/prod/osrm-backend-by-car deploy/s3/osm_buildings_minsk deploy/s3/osm_addresses_minsk deploy/s3/kontur_boundaries deploy/s3/kontur_boundaries_for_boundary_selector.geojson.gz data/out/reports/population_check deploy/s3/prod/reports/prod_reports_public data/planet-check-refs deploy/s3/topology_boundaries data/mid/mapswipe/mapswipe_s3_data_update deploy/s3/prod/kontur_events_updated data/out/missed_hascs_check data/out/kontur_boundaries/kontur_boundaries.gpkg.gz deploy/s3/kontur_default_languages.gpkg.gz data/out/reports/kontur_boundaries_compare_with_latest_on_hdx deploy_indicators/prod/custom_axis/all_custom_axis deploy_indicators/prod/presets/all_presets deploy/s3/prod/reports/reports.tar.gz ## [FINAL] Deploys artifacts to production. Runs only on master branch.
	touch $@
	echo "Prod target has built!" | python3 scripts/slack_message.py $$SLACK_CHANNEL ${SLACK_BOT_NAME} $$SLACK_BOT_EMOJI

prod: deploy/prod/users_tiles deploy/s3/prod/osm_users_hex_dump deploy/prod/cleanup_cache_old deploy/prod/osrm-backend-by-car deploy/s3/osm_buildings_minsk deploy/s3/osm_addresses_minsk deploy/s3/kontur_boundaries deploy/s3/kontur_boundaries_for_boundary_selector.geojson.gz data/out/reports/population_check deploy/s3/prod/reports/prod_reports_public data/planet-check-refs deploy/s3/topology_boundaries data/mid/mapswipe/mapswipe_s3_data_update deploy/s3/prod/kontur_events_updated data/out/missed_hascs_check data/out/kontur_boundaries/kontur_boundaries.gpkg.gz deploy/s3/kontur_default_languages.gpkg.gz data/out/reports/kontur_boundaries_compare_with_latest_on_hdx deploy/s3/prod/reports/reports.tar.gz ## [FINAL] Deploys artifacts to production. Runs only on master branch.
	touch $@
	echo "Prod target has built!" | python3 scripts/slack_message.py $$SLACK_CHANNEL ${SLACK_BOT_NAME} $$SLACK_BOT_EMOJI

clean: ## [FINAL] Cleans the worktree for next nightly run. Does not clean non-repeating targets.
	if [ -f data/planet-is-broken ]; then rm -rf data/planet-latest.osm.pbf ; fi
	rm -rf deploy/ data/tiles/stats data/tiles/users data/tile_logs/index.html data/planet-is-broken
	profile_make_clean data/planet-latest-updated.osm.pbf data/in/covid19/_global_csv data/in/covid19/_us_csv data/tile_logs/_download data/in/global_fires/new_updates/download_new_updates data/in/covid19/vaccination/vaccine_acceptance_us_counties.csv db/table/osm_reports_list data/in/wikidata_hasc_codes.csv data/in/kontur_events/download data/in/event_api_data/kontur_public_feed data/in/wikidata_population_csv/download data/in/prescale_to_osm.csv data/in/mapswipe/projects_new.csv data/in/mapswipe/projects_old.csv data/in/mapswipe/mapswipe.zip data/in/users_deleted.txt db/table/kontur_boundaries_hasc_codes_check data/in/hot_projects/hot_projects data/in/live_sensor_data_h3.csv db/table/insights_api_indicators_list_test db/table/insights_api_indicators_list_dev db/table/insights_api_indicators_list_prod
	psql -f scripts/clean.sql
	# Clean old OSRM docker images
	docker image prune --force --filter label=stage=osrm-builder
	docker image prune --force --filter label=stage=osrm-backend

data/tiles: | data ## Directory for storing generated vector tiles.
	mkdir -p $@

data/out/morocco_buildings: | data/out ## Data generated within project Morocco Buildings for Swiss Re.
	mkdir -p $@

data/in/global_fires: | data/in ## Data downloaded within project Global Fires.
	mkdir -p $@

data/mid/global_fires: | data/mid ## Data processed within project Global Fires.
	mkdir -p $@

data/out/global_fires: | data/out ## Data generated within project Global Fires.
	mkdir -p $@

data/out/docker: | data/out ## Docker images.
	mkdir -p $@

data/out/population: | data/out ## Directory for storing data_stat_h3 and bivariate datasets dump.
	mkdir -p $@

data/out/kontur_boundaries: | data/out ## Directory for Kontur Boundaries final dataset.
	mkdir -p $@

data/out/reports: | data/out ## Directory for OpenStreetMap quality reports.
	mkdir -p $@

data/out/csv: | data/out ## Directory for csv dumps of data tables
	mkdir -p $@

data/in/gadm: | data/in ## Directory for storing downloaded GADM (Database of Global Administrative Areas) datasets.
	mkdir -p $@

data/mid/gadm: | data/mid ## Unzipped GADM (Database of Global Administrative Areas) shapefiles.
	mkdir -p $@

data/in/wb/gdp: | data/in ## Directory for storing downloaded GDP (Gross domestic product) World Bank datasets.
	mkdir -p $@

data/in/mapswipe: | data/in ## Directory for storing downloaded mapswipe data.
	mkdir -p $@

data/mid/mapswipe: | data/in ## Directory for storing temporary mapswipe data.
	mkdir -p $@

data/mid/mapswipe/ym_files: | data/mid/mapswipe ## Directory for storing yes-maybe mapswipe files.
	mkdir -p $@

data/in/foursquare: | data/in ## Directory for storing foursquare places and visits data.
	mkdir -p $@

data/mid/foursquare: | data/mid ## Directory for storing unzipped foursquare data
	mkdir -p $@

data/mid/wb/gdp: | data/mid ## Intermediate GDP (Gross domestic product) World Bank data.
	mkdir -p $@

data/in/raster/VNL_v21_npp_2021_global: | data/in/raster ## Directory for Night Lights data (Harmonized_DN_NTL_2021_simVIIRS).
	mkdir -p $@

data/mid/VNL_v21_npp_2021_global/VNL_v21_npp_2021_global_vcmslcfg_c202205302300.median_masked: | data/mid ## Directory for storing unzipped Night Lights data.
	mkdir -p $@

data/in/raster/gebco_2022_geotiff: | data/in/raster ## Directory for GEBCO 2022 (General Bathymetric Chart of the Oceans) dataset.
	mkdir -p $@

data/in/raster/meta_forest_canopy_height: | data/in/raster ## Directory for High Resolution Forest Canopy Layer dataset.
	mkdir -p $@

data/mid/ndvi_2019_06_10: | data/mid ## Directory for NDVI rasters. Taken from https://medium.com/sentinel-hub/digital-twin-sandbox-sentinel-2-collection-available-to-everyone-20f3b5de846e
	mkdir -p $@

deploy/prod: | deploy ## folder for prod deployment footprints.
	mkdir -p $@

deploy/test: | deploy ## folder for test deployment footprints.
	mkdir -p $@

deploy/dev: | deploy ## folder for dev deployment footprints.
	mkdir -p $@

deploy_indicators: ## initial folder for Insights API footprints
	mkdir -p $@

deploy_indicators/dev: | deploy_indicators ## folder for Insights API footprints for DEV instance
	mkdir -p $@

deploy_indicators/test: | deploy_indicators ## folder for Insights API footprints for TEST instance
	mkdir -p $@

deploy_indicators/prod: | deploy_indicators ## folder for Insights API footprints for PROD instance
	mkdir -p $@

deploy_indicators/dev/uploads: | deploy_indicators/dev ## folder for layer uploading to dev Insights API footprints
	mkdir -p $@

deploy_indicators/test/uploads: | deploy_indicators/test ## folder for layer uploading to test Insights API footprints
	mkdir -p $@

deploy_indicators/prod/uploads: | deploy_indicators/prod ## folder for layer uploading to prod Insights API footprints
	mkdir -p $@

deploy_indicators/dev/custom_axis: | deploy_indicators/dev ## Folder to store custom axis deployment fingerprints for dev instance.
	mkdir -p $@

deploy_indicators/test/custom_axis: | deploy_indicators/test ## Folder to store custom axis deployment fingerprints for test instance.
	mkdir -p $@

deploy_indicators/prod/custom_axis: | deploy_indicators/prod ## Folder to store custom axis deployment fingerprints for prod instance.
	mkdir -p $@

deploy_indicators/dev/presets: | deploy_indicators/dev ## Folder to store presets deployment fingerprints for dev instance.
	mkdir -p $@

deploy_indicators/test/presets: | deploy_indicators/test ## Folder to store presets deployment fingerprints for test instance.
	mkdir -p $@

deploy_indicators/prod/presets: | deploy_indicators/prod ## Folder to store presets deployment fingerprints for prod instance.
	mkdir -p $@

deploy/geocint: | deploy ## We use geocint as a GIS development server.
	mkdir -p $@

deploy/s3/test: | deploy/s3 ## Target-created directory for deployments on S3 test division.
	mkdir -p $@

deploy/s3/dev: | deploy/s3 ## Target-created directory for deployments on S3 dev division.
	mkdir -p $@

deploy/s3/prod: | deploy/s3 ## Target-created directory for deployments on S3 prod division.
	mkdir -p $@

deploy/s3/test/reports: | deploy/s3/test ## Target-created directory for OpenStreetMap quality reports test deployments on S3.
	mkdir -p $@

deploy/s3/dev/reports: | deploy/s3/dev ## Target-created directory for OpenStreetMap quality reports dev deployments on S3.
	mkdir -p $@

deploy/s3/prod/reports: | deploy/s3/prod ## Target-created directory for OpenStreetMap quality reports production deployments on S3.
	mkdir -p $@

deploy/geocint/isochrone_tables: db/table/osm_road_segments db/table/osm_road_segments_new db/index/osm_road_segments_new_seg_id_node_from_node_to_seg_geom_idx db/index/osm_road_segments_new_seg_geom_idx ## Make sure OpenStreetMap road graph for City Split Tool is ready.
	touch $@

deploy/geocint/belarus-latest.osm.pbf: data/belarus-latest.osm.pbf | deploy/geocint ## Copy belarus-latest.osm.pbf to public_html folder to make it available online.
	cp data/belarus-latest.osm.pbf ~/public_html/belarus-latest.osm.pbf
	touch $@

deploy/geocint/reports: | deploy/geocint ## Directory for storing deploy ready OpenStreetMap quality report files.
	mkdir -p $@

deploy/geocint/reports/test: | deploy/geocint ## Directory for storing deploy ready OpenStreetMap quality report files (testing).
	mkdir -p $@

deploy/geocint/reports/dev: | deploy/geocint ## Directory for storing deploy ready OpenStreetMap quality report files (developing).
	mkdir -p $@

deploy/geocint/reports/prod: | deploy/geocint ## Directory for storing deploy ready OpenStreetMap quality report files (production).
	mkdir -p $@

deploy/prod/osrm-backend-by-car: deploy/geocint/belarus-latest.osm.pbf | deploy/prod ## Send message through Amazon Simple Queue Service to trigger rebuild Belarus road graph in OSRM in Docker on remote server.
	aws sqs send-message --output json --region eu-central-1 --queue-url https://sqs.eu-central-1.amazonaws.com/001426858141/PuppetmasterInbound.fifo --message-body '{"jsonrpc":"2.0","method":"rebuildDockerImage","params":{"imageName":"kontur-osrm-backend-by-car","osmPbfUrl":"https://geocint.kontur.io/gis/belarus-latest.osm.pbf"},"id":"'`uuid`'"}' --message-group-id rebuildDockerImage--kontur-osrm-backend-by-car
	touch $@

data/belarus-latest.osm.pbf: data/planet-latest-updated.osm.pbf data/belarus_boundary.geojson | data ## Extract Belarus from planet-latest-updated.osm.pbf using Osmium tool.
	osmium extract -v -s smart -p data/belarus_boundary.geojson data/planet-latest-updated.osm.pbf -o data/belarus-latest.osm.pbf --overwrite
	touch $@

data/in/covid19: | data/in  ## Directory for storing original file based datasets on COVID-19
	mkdir -p $@

data/in/covid19/_global_csv: | data/in/covid19 ## Download global daily COVID-19 data by confirmed/deaths/recovered cases in csv from github Data Repository by the CSSE (Center for Systems Science and Engineering) at Johns Hopkins University.
	wget "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv" -O data/in/covid19/time_series_global_confirmed.csv
	wget "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv" -O data/in/covid19/time_series_global_deaths.csv
	wget "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_recovered_global.csv" -O data/in/covid19/time_series_global_recovered.csv
	touch $@

data/in/covid19/_us_csv: | data/in/covid19 ## Download US detailed daily COVID-19 data from github Data Repository by the CSSE (Center for Systems Science and Engineering) at Johns Hopkins University.
	wget "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv" -O data/in/covid19/time_series_us_confirmed.csv
	wget "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv" -O data/in/covid19/time_series_us_deaths.csv
	touch $@

data/mid/covid19: | data/mid  ## Directory for storing temporary file based datasets on COVID-19
	mkdir -p $@

data/mid/covid19/normalized_csv: data/in/covid19/_global_csv | data/mid/covid19  ## Normalize detailed daily global COVID-19 data from the CSSE (Center for Systems Science and Engineering) at Johns Hopkins University.
	rm -f data/mid/covid19/time_series_global_*_normalized.csv
	ls data/in/covid19/time_series_global* | parallel "python3 scripts/covid19_normalization.py {}"
	touch $@

db/table/covid19_in: data/mid/covid19/normalized_csv | db/table ## Normalized, merged, extracted latest data from CSSE (Center for Systems Science and Engineering) at Johns Hopkins University COVID-19 global datasets.
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

data/mid/covid19/normalized_us_confirmed_csv: data/in/covid19/_us_csv | data/mid/covid19 ## Normalize US COVID-19 data from the CSSE (Center for Systems Science and Engineering) at Johns Hopkins University (confirmed cases).
	rm -f data/mid/covid19/time_series_us_confirmed_normalized.csv
	python3 scripts/covid19_us_confirmed_normalization.py data/in/covid19/time_series_us_confirmed.csv
	touch $@

db/table/covid19_us_confirmed_in: data/mid/covid19/normalized_us_confirmed_csv | db/table ## Normalized, merged data from CSSE (Center for Systems Science and Engineering) at Johns Hopkins University COVID-19 US datasets (confirmed cases).
	psql -c 'drop table if exists covid19_us_confirmed_csv_in;'
	psql -c 'create table covid19_us_confirmed_csv_in (uid text, iso2 text, iso3 text, code3 text, fips text, admin2 text, province text, country text, lat float, lon float, combined_key text, date timestamptz, value int);'
	cat data/mid/covid19/time_series_us_confirmed_normalized.csv | tail -n +1 | psql -c "set time zone utc;copy covid19_us_confirmed_csv_in (uid, iso2, iso3, code3, fips, admin2, province, country, lat, lon, combined_key, date, value) from stdin with csv header;"
	psql -f tables/covid19_us_confirmed_in.sql
	touch $@

data/mid/covid19/normalized_us_deaths_csv: data/in/covid19/_us_csv | data/mid/covid19  ## Normalize US COVID-19 data from the CSSE (Center for Systems Science and Engineering) at Johns Hopkins University (deaths).
	rm -f data/mid/covid19/time_series_us_deaths_normalized.csv
	python3 scripts/covid19_us_deaths_normalization.py data/in/covid19/time_series_us_deaths.csv
	touch $@

db/table/covid19_us_deaths_in: data/mid/covid19/normalized_us_deaths_csv | db/table ## Normalized, merged data from CSSE (Center for Systems Science and Engineering) COVID-19 US datasets (deaths).
	psql -c 'drop table if exists covid19_us_deaths_csv_in;'
	psql -c 'create table covid19_us_deaths_csv_in (uid text, iso2 text, iso3 text, code3 text, fips text, admin2 text, province text, country text, lat float, lon float, combined_key text, population int, date timestamptz, value int);'
	cat data/mid/covid19/time_series_us_deaths_normalized.csv | tail -n +1 | psql -c "set time zone utc;copy covid19_us_deaths_csv_in (uid, iso2, iso3, code3, fips, admin2, province, country, lat, lon, combined_key, population, date, value) from stdin with csv header;"
	psql -f tables/covid19_us_deaths_in.sql
	touch $@

db/table/covid19_admin_boundaries: db/table/covid19_in db/index/osm_tags_idx ## Admin boundaries for COVID-19 CSSE (Center for Systems Science and Engineering) datasets extracted from OpenStreetMap (joined on coordinates and name matching).
	psql -f tables/covid19_admin_boundaries.sql
	touch $@

db/table/covid19_population_h3_r8: db/table/kontur_population_h3 db/table/covid19_us_counties db/table/covid19_admin_boundaries | db/table ## Genereate table of Covid19 cases (worldwide and USA) in h3 8 resolution from Kontur population dataset and used boundaries
	psql -f tables/covid19_population_h3_r8.sql
	touch $@

db/table/covid19_h3: db/table/covid19_population_h3_r8 db/table/covid19_us_counties db/table/covid19_admin_boundaries db/procedure/generate_overviews | db/table ## calculate cases rate, dither and generate overviews of covid19_population_h3_r8
	psql -f tables/covid19_h3.sql
	psql -c "call generate_overviews('covid19_h3', '{date, population, total_population, confirmed, recovered, dead}'::text[], '{max, sum, sum, sum, sum, sum}'::text[], 8);"
	touch $@

db/table/us_counties_boundary: db/table/gadm_boundaries | db/table ## USA counties boundaries extracted from GADM (Database of Global Administrative Areas) admin_level_2 dataset.
	psql -f tables/gadm_us_counties_boundary.sql
	psql -c 'drop table if exists us_counties_fips_codes;'
	psql -c 'create table us_counties_fips_codes (state text, county text, hasc_code text, fips_code text);'
	cat static_data/counties_fips_hasc.csv | psql -c "copy us_counties_fips_codes (state, county, hasc_code, fips_code) from stdin with csv header delimiter ',';"
	psql -f tables/us_counties_boundary.sql
	touch $@

db/table/covid19_us_counties: db/table/covid19_us_confirmed_in db/table/covid19_us_deaths_in db/table/us_counties_boundary | db/table ## USA counties subdivided geometries
	psql -f tables/covid19_us_counties.sql
	touch $@

data/in/covid19/vaccination: | data/in/covid19 ## Data on COVID-19 vaccination.
	mkdir -p $@

data/in/covid19/vaccination/vaccine_acceptance_us_counties.csv: | data/in/covid19/vaccination ## Download data on COVID-19 vaccine acceptance in US from Carnegie Mellon University.
	wget -q "https://api.covidcast.cmu.edu/epidata/covidcast/csv?signal=fb-survey:smoothed_covid_vaccinated&start_day=$(shell date -d '-30 days' +%Y-%m-%d)&end_day=$(shell date +%Y-%m-%d)&geo_type=county" -O $@

db/table/covid19_vaccine_accept_us_counties: data/in/covid19/vaccination/vaccine_acceptance_us_counties.csv db/table/us_counties_boundary ## Aggregated data on COVID-19 vaccine acceptance in US based on Carnegie Mellon University dataset.
	psql -c 'drop table if exists covid19_vaccine_accept_us;'
	psql -c 'create table covid19_vaccine_accept_us (ogc_fid serial not null, geo_value text, signal text, time_value timestamptz, issue timestamptz, lag int, value float, stderr float, sample_size float, geo_type text, data_source text);'
	cat data/in/covid19/vaccination/vaccine_acceptance_us_counties.csv | psql -c 'copy covid19_vaccine_accept_us (ogc_fid, geo_value, signal, time_value, issue, lag, value, stderr, sample_size, geo_type, data_source) from stdin with csv header;'
	psql -f tables/covid19_vaccine_accept_us_counties.sql
	touch $@

db/table/covid19_vaccine_accept_us_counties_h3: db/table/covid19_vaccine_accept_us_counties db/procedure/generate_overviews | db/table  ## Aggregated data on COVID-19 vaccine acceptance in US based on Carnegie Mellon University dataset distributed on H3 hexagon grid.
	psql -f tables/covid19_vaccine_accept_us_counties_h3.sql
	psql -c "call generate_overviews('covid19_vaccine_accept_us_counties_h3', '{vaccine_value}'::text[], '{sum}'::text[], 8);"
	touch $@

data/belarus_boundary.geojson: db/table/osm db/index/osm_tags_idx ## Belarus boundary extracted from OpenStreetMap daily import.
	psql -q -X -c "\copy (select ST_AsGeoJSON(belarus) from (select geog::geometry as polygon from osm where osm_type = 'relation' and osm_id = 59065 and tags @> '{\"boundary\":\"administrative\"}') belarus) to stdout" | jq -c . > data/belarus_boundary.geojson
	touch $@

db/function/osm_way_nodes_to_segments: | db/function ## Function to segmentize prepared input linestring (used when segmentizing road graph for City Split Tool).
	psql -f functions/osm_way_nodes_to_segments.sql
	touch $@

db/function/h3: | db/function ## Custom SQL functions to work with H3 hexagons grid (ST_H3Bucket) used in target SQL queries more than ones.
	psql -f functions/st_h3bucket.sql
	touch $@

db/function/parse_float: | db/function ## Converts text into a float or a NULL.
	psql -f functions/parse_float.sql
	touch $@

db/function/parse_integer: | db/function ## Converts text levels into a integer or a NULL.
	psql -f functions/parse_integer.sql
	touch $@

db/function/tile_zoom_level_to_h3_resolution: | db/function ## Function to get H3 resolution that will fit given tile zoom level
	psql -f functions/tile_zoom_level_to_h3_resolution.sql
	touch $@

data/out/tile_zoom_level_to_h3_resolution_test: db/function/tile_zoom_level_to_h3_resolution | data/out ## Test if current version of function returns same h3 resolutions as previous one
	cat scripts/tile_zoom_level_to_h3_resolution_test.sql | psql -AXt |  xargs -I {} bash scripts/check_items_count.sh {} 1
	touch $@

db/function/h3_raster_sum_to_h3: | db/function ## Aggregate sum raster values on H3 hexagon grid.
	psql -f functions/h3_raster_sum_to_h3.sql
	touch $@

db/procedure/generate_overviews: | db/procedure ## Generate overviews for H3 resolution < 8 using different aggregations.
	psql -f procedures/generate_overviews.sql
	touch $@

db/procedure/dither_area_to_not_bigger_than_100pc_of_hex_area: | db/procedure ## Dither areas to not be bigger than 100% of hexagon's area for every resolution.
	psql -f procedures/dither_area_to_not_bigger_than_100pc_of_hex_area.sql
	touch $@

data/in/facebook: | data/in  ## Directory for Facebook data
	mkdir -p $@

data/in/facebook/medium_voltage_distribution: | data/in/facebook  ## Directory for Facebook Medium Voltage Distribution csvs
	mkdir -p $@

data/in/facebook/medium_voltage_distribution/downloaded: | data/in/facebook/medium_voltage_distribution  ## Download Facebook Medium Voltage Distribution csvs.
	cat static_data/facebook/medium-voltage-distribution-sources.txt | xargs -P 8 -I {} wget -nv -nc {} --directory-prefix=data/in/facebook/medium_voltage_distribution
	wget -nc -nv --input-file=static_data/facebook/medium-voltage-distribution-sources.txt --directory-prefix=data/in/facebook/medium_voltage_distribution
	touch $@

db/table/facebook_medium_voltage_distribution_in: data/in/facebook/medium_voltage_distribution/downloaded | db/table  ## Load CSVs
	psql -c "drop table if exists facebook_medium_voltage_distribution_in;"
	psql -c "create table facebook_medium_voltage_distribution_in (lat float, lon float, value int);"
	ls data/in/facebook/medium_voltage_distribution/*.csv | \
		parallel \
			"psql -c \"\copy facebook_medium_voltage_distribution_in (lat, lon, value) from '{}' with csv header delimiter ',';\""
	touch $@

db/table/facebook_medium_voltage_distribution_h3: db/table/facebook_medium_voltage_distribution_in db/procedure/generate_overviews | db/table  ## Put Facebook Medium Voltage Distribution on H3
	psql -f tables/facebook_medium_voltage_distribution_h3.sql
	psql -c "call generate_overviews('facebook_medium_voltage_distribution_h3', '{powerlines}'::text[], '{sum}'::text[], 8);"
	touch $@

data/in/facebook_roads: | data/in ## Directory for Facebook roads downloaded data.
	mkdir -p $@

data/mid/facebook_roads: | data/mid ## Directory for Facebook roads extracted data.
	mkdir -p $@

data/in/facebook_roads/downloaded: | data/in/facebook_roads ## Download Facebook roads.
	wget -nc --input-file=static_data/facebookroads/downloadlist.txt --directory-prefix=data/in/facebook_roads
	touch $@

data/in/facebook_roads/validity_controlled: data/in/facebook_roads/downloaded | data/in/facebook_roads ## Check Facebook roads downloaded archives validity
	ls -1 data/in/facebook_roads/*.tar.gz | parallel --halt now,fail=1 gunzip -t {}
	touch $@

data/mid/facebook_roads/extracted: data/in/facebook_roads/validity_controlled | data/mid/facebook_roads ## Extract Facebook roads.
	rm -f data/mid/facebook_roads/*.gpkg
	ls data/in/facebook_roads/*.tar.gz | parallel 'tar -C data/mid/facebook_roads -xf {}'
	touch $@

db/table/facebook_roads_in: data/mid/facebook_roads/extracted | db/table ## Loading Facebook roads into db.
	psql -c "drop table if exists facebook_roads_in;"
	psql -c "create table facebook_roads_in (way_fbid text, highway_tag text, geom geometry(geometry, 4326));"
	ls data/mid/facebook_roads/*.gpkg | parallel 'ogr2ogr --config PG_USE_COPY YES -append -f PostgreSQL PG:"dbname=gis" {} -nln facebook_roads_in'
	psql -c "vacuum analyse facebook_roads_in;"
	touch $@

db/table/facebook_roads_in_h3_r8: db/table/facebook_roads_in | db/table ## Build h3 overviews for prefiltered Facebook roads at all levels.
	psql -f tables/facebook_roads_in_h3_r8.sql
	touch $@

db/table/facebook_roads_last_filtered: db/table/facebook_roads_in | db/table ## Save first timestamp for Facebook road filter.
	psql -c "create table if not exists facebook_roads_last_filtered as (select '2006-01-01'::date::timestamp as ts);"
	touch $@

db/table/hexagons_for_regression: db/table/kontur_boundaries db/table/land_polygons_h3_r8 ## Create table with hexes only from countries where facebook data were not published
	psql -f tables/hexagons_for_regression.sql
	touch $@

db/table/facebook_roads: db/table/facebook_roads_in db/table/facebook_roads_last_filtered db/table/osm_roads | db/table ## Filter Facebook roads.
	psql -f tables/facebook_roads.sql
	psql -1 -c "alter table facebook_roads rename to facebook_roads_old; alter table facebook_roads_new rename to facebook_roads;"
	psql -c "update facebook_roads_last_filtered set ts = coalesce((select ts from osm_roads_increment limit 1), ts);"
	psql -c "drop table facebook_roads_old; drop table osm_roads_increment;"
	touch $@

db/table/facebook_roads_h3: db/table/facebook_roads db/procedure/generate_overviews | db/table ## Build h3 overviews for Facebook roads at all levels.
	psql -f tables/facebook_roads_h3.sql
	psql -c "call generate_overviews('facebook_roads_h3', '{fb_roads_length}'::text[], '{sum}'::text[], 8);"
	touch $@

db/table/osm_roads: db/table/osm | db/table ## Roads from OpenStreetMap.
	psql -f tables/osm_roads.sql
	touch $@

db/table/osm_road_segments_new: db/function/osm_way_nodes_to_segments db/table/osm_roads | db/table  ## Segmentized road graph with calculated walk and drive times from daily OpenStreetMap roads extract to use for routing within City Split Tool.
	psql -f tables/osm_road_segments.sql
	touch $@

db/index/osm_road_segments_new_seg_id_node_from_node_to_seg_geom_idx: db/table/osm_road_segments_new | db/index ## Composite index on osm_road_segments_new table.
	psql -c "drop index if exists osm_road_segments_new_seg_id_node_from_node_to_seg_geom_idx;"
	psql -c "create index osm_road_segments_new_seg_id_node_from_node_to_seg_geom_idx on osm_road_segments_new (seg_id, node_from, node_to, seg_geom);"
	touch $@

db/index/osm_road_segments_new_seg_geom_idx: db/table/osm_road_segments_new | db/index ## Composite BRIN index on osm_road_segments_new table.
	psql -c "drop index if exists osm_road_segments_new_seg_geom_walk_time_idx;"
	psql -c "create index osm_road_segments_new_seg_geom_walk_time_idx on osm_road_segments_new using brin (seg_geom, walk_time);"
	touch $@

db/table/osm_road_segments: db/table/osm_road_segments_new db/index/osm_road_segments_new_seg_geom_idx db/index/osm_road_segments_new_seg_id_node_from_node_to_seg_geom_idx | db/table ## Replace previous osm_road_segments road graph table (used for routing within City Split Tool) with newly calculated one.
	psql -1 -c "drop table if exists osm_road_segments; alter table osm_road_segments_new rename to osm_road_segments;"
	psql -c "alter index if exists osm_road_segments_new_seg_geom_walk_time_idx rename to osm_road_segments_seg_geom_walk_time_idx;"
	psql -c "alter index if exists osm_road_segments_new_seg_id_node_from_node_to_seg_geom_idx rename to osm_road_segments_seg_id_node_from_node_to_seg_geom_idx;"
	touch $@

db/table/osm_road_segments_h3: db/table/osm_road_segments db/procedure/generate_overviews | db/table ## osm road segments aggregated to h3
	psql -f tables/osm_road_segments_h3.sql
	psql -c "call generate_overviews('osm_road_segments_h3', '{highway_length}'::text[], '{sum}'::text[], 8);"
	touch $@

db/table/osm_road_segments_6_months: db/table/osm_roads db/table/osm_meta | db/table ## osm road segments for 6 months
	psql -f tables/osm_road_segments_6_months.sql
	touch $@

db/table/osm_road_segments_6_months_h3: db/table/osm_road_segments_6_months db/procedure/generate_overviews | db/table ## osm road segments aggregated to h3
	psql -f tables/osm_road_segments_6_months_h3.sql
	psql -c "call generate_overviews('osm_road_segments_6_months_h3', '{highway_length_6_months}'::text[], '{sum}'::text[], 8);"
	touch $@

data/in/users_deleted.txt: | data/in ## get list of deleted osm users
	wget -q "https://planet.openstreetmap.org/users_deleted/users_deleted.txt" -O $@

db/table/users_deleted: data/in/users_deleted.txt | db/table ## load list of deleted osm users to db
	psql -c "drop table if exists users_deleted; create table users_deleted (osm_user text);"
	cat data/in/users_deleted.txt | sed 's/ //g' | sed 's/^/user_/' | psql -c 'copy users_deleted (osm_user) from stdin with csv header;'
	touch $@

db/table/osm_user_count_grid_h3: db/table/osm db/function/h3 db/table/osm_meta db/table/users_deleted | db/table ## Statistics on OpenStreetMap users activity for last 2 years aggregated on H3 hexagon grid.
	psql -f tables/osm_user_count_grid_h3.sql
	touch $@

db/table/osm_users_hex: db/table/osm_user_count_grid_h3 db/table/osm_local_active_users | db/table ## Select most active user per H3 hexagon cell.
	psql -f tables/osm_users_hex.sql
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

data/in/raster/GHS_POP_E2020_GLOBE_R2023A_54009_100_V1_0.zip: | data/in/raster ## Download GHS (Global Human Settlement) population grid dataset archive.
	wget https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A/GHS_POP_E2020_GLOBE_R2023A_54009_100/V1-0/GHS_POP_E2020_GLOBE_R2023A_54009_100_V1_0.zip -O $@
	touch $@

data/mid/GHS_POP_E2020_GLOBE_R2023A_54009_100_V1_0/GHS_POP_E2020_GLOBE_R2023A_54009_100_V1_0.tif: data/in/raster/GHS_POP_E2020_GLOBE_R2023A_54009_100_V1_0.zip | data/mid  ## GHS (Global Human Settlement) population grid dataset extracted.
	mkdir -p data/mid/GHS_POP_E2020_GLOBE_R2023A_54009_100_V1_0
	unzip -o data/in/raster/GHS_POP_E2020_GLOBE_R2023A_54009_100_V1_0.zip -d data/mid/GHS_POP_E2020_GLOBE_R2023A_54009_100_V1_0/
	touch $@

db/table/ghs_globe_population_raster: data/mid/GHS_POP_E2020_GLOBE_R2023A_54009_100_V1_0/GHS_POP_E2020_GLOBE_R2023A_54009_100_V1_0.tif | db/table  ## GHS (Global Human Settlement) population grid dataset imported into database (technical details - ghsl.jrc.ec.europa.eu/ghs_pop2023.php).
	psql -c "drop table if exists ghs_globe_population_raster"
	raster2pgsql -M -Y -s 54009 data/mid/GHS_POP_E2020_GLOBE_R2023A_54009_100_V1_0/GHS_POP_E2020_GLOBE_R2023A_54009_100_V1_0.tif -t auto ghs_globe_population_raster | psql -q
	touch $@

db/table/ghs_globe_population_grid_h3_r8: db/table/ghs_globe_population_raster db/procedure/insert_projection_54009 db/function/h3_raster_sum_to_h3 | db/table ## Sum of GHS (Global Human Settlement) raster population values into h3 hexagons equaled to 8 resolution.
	psql -f tables/population_raster_grid_h3_r8.sql -v population_raster=ghs_globe_population_raster -v population_raster_grid_h3_r8=ghs_globe_population_grid_h3_r8
	psql -c "delete from ghs_globe_population_grid_h3_r8 where population = 0;"
	touch $@

data/in/raster/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.zip: | data/in/raster  ## Download GHS-SMOD (Global Human Settlement Model) grid dataset archive.
	wget https://cidportal.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_SMOD_POP_GLOBE_R2016A/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k/V1-0/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.zip -O $@
	touch $@

data/mid/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.tif: data/in/raster/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.zip | data/mid ## GHS-SMOD (Global Human Settlement Model) grid dataset unzipped.
	unzip -o data/in/raster/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.zip -d data/mid/
	touch $@

db/table/ghs_globe_residential_raster: data/mid/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.tif | db/table  ## GHS-SMOD (Global Human Settlement Model) grid dataset imported into database (technical details - ghsl.jrc.ec.europa.eu/ghs_smod2019.php).
	psql -c "drop table if exists ghs_globe_residential_raster"
	raster2pgsql -M -Y -s 54009 data/mid/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0/GHS_SMOD_POP2015_GLOBE_R2016A_54009_1k_v1_0.tif -t 256x256 ghs_globe_residential_raster | psql -q
	touch $@

db/table/ghs_globe_residential_vector: db/table/ghs_globe_residential_raster db/procedure/insert_projection_54009 db/function/h3_raster_sum_to_h3 | db/table ## GHS-SMOD (Global Human Settlement Model) raster polygonized and reprojected with extracted centtroids (EPSG-3857).
	psql -f tables/ghs_globe_residential_vector.sql
	touch $@

data/in/raster/copernicus_landcover: | data/in/raster ## Directory for Copernicus land cover data.
	mkdir -p $@

data/in/raster/copernicus_landcover/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.tif: | data/in/raster/copernicus_landcover ## Download Copernicus land cover raster.
	wget -c -nc https://zenodo.org/record/3939050/files/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.tif -O $@

db/table/copernicus_landcover_raster: data/in/raster/copernicus_landcover/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.tif | db/table ## Put land cover raster in table.
	psql -c "drop table if exists copernicus_landcover_raster;"
	raster2pgsql -M -Y -s 4326 data/in/raster/copernicus_landcover/PROBAV_LC100_global_v3.0.1_2019-nrt_Discrete-Classification-map_EPSG-4326.tif -t auto copernicus_landcover_raster | psql -q
	touch $@

db/table/copernicus_builtup_h3: db/table/copernicus_landcover_raster | db/table ## Count of 'urban' pixels from land cover raster into h3 hexagons on 8 resolution.
	psql -f tables/copernicus_builtup_h3.sql
	touch $@

db/table/copernicus_landcover_h3: db/table/copernicus_landcover_raster db/procedure/dither_area_to_not_bigger_than_100pc_of_hex_area | db/table ## Forest area in km2 by types from land cover raster into h3 hexagons on 8 resolution.
	psql -f tables/copernicus_landcover_h3.sql
	psql -c "call dither_area_to_not_bigger_than_100pc_of_hex_area('copernicus_landcover_h3_in', 'copernicus_landcover_h3', '{forest_area, evergreen_needle_leaved_forest, shrubs, herbage, unknown_forest, cropland, wetland, moss_lichen, bare_vegetation, builtup, snow_ice, permanent_water}'::text[], 8);"
	psql -c "drop table if exists copernicus_landcover_h3_in;"
	touch $@

db/table/osm_residential_landuse: db/index/osm_tags_idx ## Residential areas from osm.
	psql -f tables/osm_residential_landuse.sql
	touch $@

data/in/mapswipe/mapswipe.zip: | data/in/mapswipe ## Download zip with files
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/data/in/mapswipe/mapswipe.zip $@ --profile geocint_pipeline_sender
	touch $@

data/mid/mapswipe/ym_files/unzip: data/in/mapswipe/mapswipe.zip | data/mid/mapswipe/ym_files ## unzip mapswipe yes-maybe data
	rm -f data/mid/mapswipe/ym_files/*.geojson
	unzip -qq data/in/mapswipe/mapswipe.zip -d data/mid/mapswipe/ym_files/
	touch $@

data/in/mapswipe/projects_new.csv: | data/in/mapswipe ## Dowload actual overview of mapswipe projects.
	rm -f data/in/mapswipe/projects_new.csv
	wget https://apps.mapswipe.org/api/projects/projects.csv --no-check-certificate -O $@

data/in/mapswipe/projects_old.csv: | data/in/mapswipe ## Dowload previous overview of mapswipe projects.
	rm -f data/in/mapswipe/projects_old.csv
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/data/in/mapswipe/projects_old.csv $@ --profile geocint_pipeline_sender
	touch $@

data/in/mapswipe/projects_old_update: data/in/mapswipe/projects_new.csv data/in/mapswipe/projects_old.csv | data/in/mapswipe ## update previous mapswipe projects overview on s3.
	aws s3 cp data/in/mapswipe/projects_old.csv s3://geodata-eu-central-1-kontur/private/geocint/data/in/mapswipe/projects_old.csv --profile geocint_pipeline_sender
	touch $@

db/table/mapswipe_projects_new: data/in/mapswipe/projects_new.csv | db/table ## Loading new mapswipe overview data to database.
	psql -c "drop table if exists mapswipe_projects_new;"
	psql -c "create table mapswipe_projects_new (idx smallint, project_id text, name text, project_details text, look_for text, project_type text, image_url text, created timestamp, custom_options text, tile_server_names text, status text, area_sqkm float, geom text, centroid text, progress float, number_of_users float, number_of_results float, number_of_results_progress float, day timestamp);"
	cat data/in/mapswipe/projects_new.csv | psql -c "copy mapswipe_projects_new from stdin with csv header;"
	touch $@

db/table/mapswipe_projects_old: data/in/mapswipe/projects_old.csv | db/table ## Loading new mapswipe overview data to database.
	psql -c "drop table if exists mapswipe_projects_old;"
	psql -c "create table mapswipe_projects_old (idx smallint, project_id text, name text, project_details text, look_for text, project_type text, tile_server_names text, status text, area_sqkm float, geom text, centroid text, progress float, number_of_users float, number_of_results float, number_of_results_progress float, day timestamp);"
	cat data/in/mapswipe/projects_old.csv | psql -c "copy mapswipe_projects_old from stdin with csv header;"
	touch $@

data/mid/mapswipe/mapswipe_delta.csv: db/table/mapswipe_projects_new db/table/mapswipe_projects_old | data/mid/mapswipe ## Check mapswipe data to find differences.
	psql -f tables/mapswipe_delta.sql
	psql -qXc "copy (select * from mapswipe_delta) to stdout with (format csv, header false, delimiter ';');" > $@

data/mid/mapswipe/ym_files/update: data/mid/mapswipe/ym_files/unzip data/mid/mapswipe/mapswipe_delta.csv | data/mid/mapswipe/ym_files ## update mapswipe data with fresh files
	cat data/mid/mapswipe/mapswipe_delta.csv | xargs -I {} rm -f data/mid/mapswipe/ym_files/yes_maybe_{}.geojson
	## we need for || true to avoid crushing this target through of 404 not found error
	cat data/mid/mapswipe/mapswipe_delta.csv | xargs -I {} echo 'https://apps.mapswipe.org/api/yes_maybe/yes_maybe_{}.geojson'| parallel -j5 'wget -O -q -P data/mid/mapswipe/ym_files/ {1}' || true
	touch $@

data/mid/mapswipe/mapswipe_s3_data_update: data/in/mapswipe/projects_old_update data/mid/mapswipe/ym_files/update | data/mid/mapswipe ## Zip updated geojsonl and load to s3
	rm -f data/mid/mapswipe/ym_files/mapswipe.zip
	cd data/mid/mapswipe/ym_files/ ; zip mapswipe.zip *.geojson
	aws s3 cp data/mid/mapswipe/ym_files/mapswipe.zip s3://geodata-eu-central-1-kontur/private/geocint/data/in/mapswipe/mapswipe.zip --profile geocint_pipeline_sender
	touch $@

db/table/mapswipe_hot_tasking_data: data/mid/mapswipe/ym_files/update | db/table ## Loading mapswipe hot tasking geojsons to database
	psql -c "drop table if exists mapswipe_hot_tasking_data;"
	psql -c "create table mapswipe_hot_tasking_data (id integer, geom geometry(POLYGON,4326));"
	ls -S data/mid/mapswipe/ym_files/*.geojson | parallel 'ogr2ogr -append -f PostgreSQL PG:"dbname=gis" {} -nln mapswipe_hot_tasking_data -nlt POLYGON --config PG_USE_COPY YES'
	touch $@

db/table/mapswipe_hot_tasking_data_h3: db/table/mapswipe_hot_tasking_data db/table/land_polygons_h3_r8 db/procedure/generate_overviews db/procedure/dither_area_to_not_bigger_than_100pc_of_hex_area | db/table ## Create h3 table with mapswipe data
	psql -f tables/mapswipe_hot_tasking_data_h3.sql
	psql -c "call dither_area_to_not_bigger_than_100pc_of_hex_area('mapswipe_hot_tasking_data_h3_in', 'mapswipe_hot_tasking_data_h3', '{mapswipe_area}'::text[], 8);"
	psql -c "drop table if exists mapswipe_hot_tasking_data_h3_in;"
	touch $@

data/in/raster/VNL_v21_npp_2021_global/VNL_v21_npp_2021_global_vcmslcfg_c202205302300.median_masked.dat.tif.gz: | data/in/raster/VNL_v21_npp_2021_global  ## download, tile, pack and upload nightlights rasters
	## this archive was downloaded manually from eogdata.mines.edu
	## link is stored in static-data/viirs/nightlights.txt but you might want to download a newer one.
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/data/in/raster/VNL_v21_npp_2021_global/VNL_v21_npp_2021_global_vcmslcfg_c202205302300.median_masked.dat.tif.gz $@ --profile geocint_pipeline_sender
	touch $@

data/mid/VNL_v21_npp_2021_global/VNL_v21_npp_2021_global_vcmslcfg_c202205302300.median_masked_cut_into_tiles: data/in/raster/VNL_v21_npp_2021_global/VNL_v21_npp_2021_global_vcmslcfg_c202205302300.median_masked.dat.tif.gz | data/mid/VNL_v21_npp_2021_global/VNL_v21_npp_2021_global_vcmslcfg_c202205302300.median_masked ## Unzip and cut to tiles
	rm -f data/mid/VNL_v21_npp_2021_global/VNL_v21_npp_2021_global_vcmslcfg_c202205302300.median_masked/*
	gzip -dfk data/in/raster/VNL_v21_npp_2021_global/VNL_v21_npp_2021_global_vcmslcfg_c202205302300.median_masked.dat.tif.gz
	gdal_retile.py -ps 1024 1024 -targetDir data/mid/VNL_v21_npp_2021_global/VNL_v21_npp_2021_global_vcmslcfg_c202205302300.median_masked data/in/raster/VNL_v21_npp_2021_global/VNL_v21_npp_2021_global_vcmslcfg_c202205302300.median_masked.dat.tif
	gdalbuildvrt data/mid/VNL_v21_npp_2021_global/VNL_v21_npp_2021_global_vcmslcfg_c202205302300.median_masked/VNL_v21_npp_2021_global_vcmslcfg_c202205302300.median_masked.vrt data/mid/VNL_v21_npp_2021_global/VNL_v21_npp_2021_global_vcmslcfg_c202205302300.median_masked/*.tif
	touch $@

db/table/night_lights_raster: data/mid/VNL_v21_npp_2021_global/VNL_v21_npp_2021_global_vcmslcfg_c202205302300.median_masked_cut_into_tiles | db/table ## Loading night lights raster to dartabase
	psql -c "drop table if exists night_lights_raster"
	raster2pgsql -p -Y -s data/mid/VNL_v21_npp_2021_global/VNL_v21_npp_2021_global_vcmslcfg_c202205302300.median_masked/*.tif -t auto night_lights_raster | psql -q
	ls data/mid/VNL_v21_npp_2021_global/VNL_v21_npp_2021_global_vcmslcfg_c202205302300.median_masked/*.tif | parallel --eta 'GDAL_CACHEMAX=10000 GDAL_NUM_THREADS=4 raster2pgsql -a -Y -s 4326 {} -t auto night_lights_raster | psql -q'
	touch $@

db/table/night_lights_h3: db/table/night_lights_raster | db/table ## Count intensity of night lights into h3 hexagons and generate overviews.
	psql -f tables/night_lights_h3.sql
	psql -c "call generate_overviews('night_lights_h3', '{intensity}'::text[], '{avg}'::text[], 8);"
	touch $@

data/in/raster/gebco_2022_geotiff/gebco_2022_geotiff.zip: | data/in/raster/gebco_2022_geotiff ## Download GEBCO 2022 (General Bathymetric Chart of the Oceans) bathymetry zipped raster dataset.
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/in/gebco_2022_geotiff/gebco_2022_geotiff.zip $@ --profile geocint_pipeline_sender
	touch $@

data/mid/gebco_2022_geotiff: | data/mid ## Create folder for unzipping GEBCO 2022 rasters
	mkdir -p $@

data/mid/gebco_2022_geotiff/gebco_2022_geotiffs_unzip: data/in/raster/gebco_2022_geotiff/gebco_2022_geotiff.zip | data/mid/gebco_2022_geotiff ## Unzip GEBCO 2022 (General Bathymetric Chart of the Oceans) rasters.
	rm -f data/mid/gebco_2022_geotiff/*.tif
	unzip -o data/in/raster/gebco_2022_geotiff/gebco_2022_geotiff.zip -d data/mid/gebco_2022_geotiff/
	rm -f data/mid/gebco_2022_geotiff/*.pdf
	touch $@

data/mid/gebco_2022_geotiff/gebco_2022_merged.vrt: data/mid/gebco_2022_geotiff/gebco_2022_geotiffs_unzip | data/mid/gebco_2022_geotiff ## Virtual raster from GEBCO 2022 (General Bathymetric Chart of the Oceans) bathymetry dataset.
	rm -f data/mid/gebco_2022_geotiff/*.vrt
	gdalbuildvrt $@ data/mid/gebco_2022_geotiff/gebco_2022_n*.tif

data/mid/gebco_2022_geotiff/gebco_2022_merged.tif: data/mid/gebco_2022_geotiff/gebco_2022_merged.vrt | data/mid/gebco_2022_geotiff ## GEBCO 2022 (General Bathymetric Chart of the Oceans) bathymetry raster (2022) converted from virtual raster (EPSG-4087).
	rm -f $@
	GDAL_CACHEMAX=10000 GDAL_NUM_THREADS=16 gdalwarp -multi -t_srs epsg:4087 -co "BIGTIFF=YES" -r bilinear -of COG data/mid/gebco_2022_geotiff/gebco_2022_merged.vrt $@

data/mid/gebco_2022_geotiff/gebco_2022_merged_slope.tif: data/mid/gebco_2022_geotiff/gebco_2022_merged.tif | data/mid/gebco_2022_geotiff ## Slope raster calculated from GEBCO 2022 (General Bathymetric Chart of the Oceans) bathymetry dataset (EPSG-4087).
	rm -f $@
	GDAL_CACHEMAX=10000 GDAL_NUM_THREADS=16 gdaldem slope -of COG -co "BIGTIFF=YES" data/mid/gebco_2022_geotiff/gebco_2022_merged.tif $@

data/mid/gebco_2022_geotiff/gebco_2022_merged_4326_slope.tif: data/mid/gebco_2022_geotiff/gebco_2022_merged_slope.tif | data/mid/gebco_2022_geotiff ## Slope raster calculated from GEBCO 2022 (General Bathymetric Chart of the Oceans) bathymetry dataset (EPSG-4326).
	rm -f $@
	GDAL_CACHEMAX=10000 GDAL_NUM_THREADS=16 gdalwarp -t_srs EPSG:4326 -of COG -co "BIGTIFF=YES" -multi data/mid/gebco_2022_geotiff/gebco_2022_merged_slope.tif $@

db/table/gebco_2022_slopes: data/mid/gebco_2022_geotiff/gebco_2022_merged_4326_slope.tif | db/table ## GEBCO 2022 (General Bathymetric Chart of the Oceans) slope raster data imported into database.
	psql -c "drop table if exists gebco_2022_slopes;"
	raster2pgsql -M -Y -s 4326 data/mid/gebco_2022_geotiff/gebco_2022_merged_4326_slope.tif -t auto gebco_2022_slopes | psql -q
	touch $@

db/table/gebco_2022_slopes_h3: db/table/gebco_2022_slopes | db/table ## GEBCO 2022 (General Bathymetric Chart of the Oceans) slope data in h3.
	psql -f scripts/raster_values_into_h3.sql -v table_name=gebco_2022_slopes -v table_name_h3=gebco_2022_slopes_h3 -v aggr_func=avg -v item_name=avg_slope_gebco_2022
	psql -c "create index on gebco_2022_slopes_h3 (h3);"
	touch $@

data/mid/gebco_2022_geotiff/gebco_2022_merged_4326.tif: data/mid/gebco_2022_geotiff/gebco_2022_merged.vrt | data/mid/gebco_2022_geotiff ## GEBCO 2022 (General Bathymetric Chart of the Oceans) bathymetry raster converted from virtual raster (EPSG-4326).
	rm -f $@
	GDAL_CACHEMAX=10000 GDAL_NUM_THREADS=16 gdal_translate -r bilinear -of COG -co "BIGTIFF=YES" data/mid/gebco_2022_geotiff/gebco_2022_merged.vrt $@

db/table/gebco_2022_elevation: data/mid/gebco_2022_geotiff/gebco_2022_merged_4326.tif | db/table ## GEBCO 2022 (General Bathymetric Chart of the Oceans) elevation raster data imported into database.
	psql -c "drop table if exists gebco_2022_elevation;"
	raster2pgsql -M -Y -s 4326 data/mid/gebco_2022_geotiff/gebco_2022_merged_4326.tif -t auto gebco_2022_elevation | psql -q
	touch $@

db/table/gebco_2022_elevation_h3: db/table/gebco_2022_elevation | db/table ## GEBCO 2022 (General Bathymetric Chart of the Oceans) elevation data in h3.
	psql -f scripts/raster_values_into_h3.sql -v table_name=gebco_2022_elevation -v table_name_h3=gebco_2022_elevation_h3 -v aggr_func=avg -v item_name=avg_elevation_gebco_2022
	touch $@

db/table/gebco_2022_h3: db/table/gebco_2022_slopes_h3 db/table/gebco_2022_elevation_h3 db/table/land_polygons_h3_r8 db/procedure/generate_overviews | db/table ## GEBCO 2022 - H3 hexagons table with average slope and elevation values from 1 to 8 resolution
	psql -f tables/gebco_2022_h3.sql
	psql -c "call generate_overviews('gebco_2022_h3', '{avg_slope_gebco_2022, avg_elevation_gebco_2022}'::text[], '{avg, avg}'::text[], 8);"
	psql -c "create index on gebco_2022_h3 (h3);"
	touch $@

data/mid/ndvi_2019_06_10/generate_ndvi_tifs: | data/mid/ndvi_2019_06_10 ## NDVI rasters generated from Sentinel 2 data.
	find /home/gis/sentinel-2-2019/2019/6/10/* -type d | parallel --eta 'cd {} && gdal_calc.py -A B04.tif -B B08.tif --calc="((1.0*B-1.0*A)/(1.0*B+1.0*A))" --type=Float32 --overwrite --outfile=ndvi.tif'
	touch $@

data/mid/ndvi_2019_06_10/warp_ndvi_tifs_4326: data/mid/ndvi_2019_06_10/generate_ndvi_tifs ## Reproject NDVI rasters to EPSG-4326.
	find /home/gis/sentinel-2-2019/2019/6/10/* -type d | parallel --eta 'cd {} && gdalwarp -multi -overwrite -t_srs EPSG:4326 -of COG -co OVERVIEWS=NONE ndvi.tif /home/gis/geocint/data/mid/ndvi_2019_06_10/ndvi_{#}_4326.tif'
	touch $@

db/table/ndvi_2019_06_10: data/mid/ndvi_2019_06_10/warp_ndvi_tifs_4326 | db/table ## Put NDVI rasters in table.
	psql -c "drop table if exists ndvi_2019_06_10;"
	raster2pgsql -p -Y -s 4326 data/mid/ndvi_2019_06_10/ndvi_1_4326.tif -t auto ndvi_2019_06_10 | psql -q
	psql -c 'alter table ndvi_2019_06_10 drop constraint if exists ndvi_2019_06_10_pkey;'
	ls data/mid/ndvi_2019_06_10/*.tif | parallel --eta 'raster2pgsql -a -Y -s 4326 {} -t auto ndvi_2019_06_10 | psql -q'
	psql -c "vacuum analyze ndvi_2019_06_10;"
	touch $@

db/table/ndvi_2019_06_10_h3: db/table/ndvi_2019_06_10 db/procedure/generate_overviews | db/table ## Generate h3 table with average NDVI from 1 to 8 resolution.
	psql -f tables/ndvi_2019_06_10_h3.sql
	psql -c "call generate_overviews('ndvi_2019_06_10_h3', '{avg_ndvi}'::text[], '{avg}'::text[], 8);"
	psql -c "create index on ndvi_2019_06_10_h3 (h3, avg_ndvi);"
	touch $@

db/table/osm_building_count_grid_h3_r8: db/table/osm_buildings | db/table ## Count amount of OSM buildings at hexagons.
	psql -f tables/count_items_in_h3.sql -v table=osm_buildings -v table_h3=osm_building_count_grid_h3_r8 -v item_count=building_count
	touch $@

db/table/building_count_grid_h3: db/table/osm_building_count_grid_h3_r8 db/table/microsoft_buildings_h3 db/table/morocco_urban_pixel_mask_h3 db/table/morocco_buildings_h3 db/table/copernicus_builtup_h3 db/table/geoalert_urban_mapping_h3 db/table/new_zealand_buildings_h3 db/table/abu_dhabi_buildings_h3 db/procedure/generate_overviews | db/table ## Count max amount of buildings at hexagons from all building datasets.
	psql -f tables/building_count_grid_h3.sql
	psql -c "call generate_overviews('building_count_grid_h3', '{building_count}'::text[], '{sum}'::text[], 8);"
	touch $@

### GADM 4.10 export block -- Database of Global Administrative Areas ###

data/in/gadm/gadm_410-levels.zip: | data/in/gadm ## Download GADM (Database of Global Administrative Areas) boundaries dataset.
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/in/gadm_410-levels.zip $@ --profile geocint_pipeline_sender

data/mid/gadm/gadm_410-levels.gpkg: data/in/gadm/gadm_410-levels.zip | data/mid/gadm ## Extract GADM (Database of Global Administrative Areas) boundaries.
	unzip -o data/in/gadm/gadm_410-levels.zip -d data/mid/gadm/
	touch $@

db/table/gadm_boundaries: data/mid/gadm/gadm_410-levels.gpkg | db/table ## Load GADM boundaries for 0-3 administrative levels.
	seq 0 3 | parallel --eta --progress 'ogr2ogr -append -overwrite -f PostgreSQL PG:"dbname=$$PGDATABASE" data/mid/gadm/gadm_410-levels.gpkg  -sql "select * from ADM_{}" -nln gadm_level_{} -nlt MULTIPOLYGON --config PG_USE_COPY YES -lco FID=id -lco GEOMETRY_NAME=geom'
	psql -f tables/gadm_boundaries.sql
	touch $@

db/table/gadm_countries_boundary: db/table/gadm_boundaries ## Country boundaries from GADM (Database of Global Administrative Areas) dataset.
	psql -c "drop table if exists gadm_countries_boundary;"
	psql -c "create table gadm_countries_boundary as select row_number() over() gid, gid_0, \"name\" name_0, geom from gadm_boundaries where gadm_level = 0;"
	psql -c "alter table gadm_countries_boundary alter column geom type geometry(multipolygon, 3857) using ST_Transform(ST_ClipByBox2D(geom, ST_Transform(ST_TileEnvelope(0,0,0),4326)), 3857);"
	touch $@

### End GADM 4.10 export block ###

### Kontur Boundaries block ###

db/table/default_languages_2_level: db/table/osm | db/table ## import data with default languages from csv file
	psql -c "drop table if exists default_languages_2_level;"
	psql -c "create table default_languages_2_level(a2 text, code text, hasc text, name text, wikicode text, osm_id integer, lang text, lang2 text, geom geometry);"
	cat static_data/kontur_boundaries/default_language_2_level.csv | psql -c "copy default_languages_2_level(a2, code, hasc, name, wikicode, osm_id, lang, lang2) from stdin with csv header delimiter ',';"
	psql -c "update default_languages_2_level p set geom = ST_Normalize(k.geog::geometry) from osm k where p.osm_id = k.osm_id;"
	touch $@

db/table/default_language_boundaries: db/table/default_languages_2_level db/index/osm_tags_idx | db/table ## select relations with existed default language
	psql -f tables/default_language_boundaries.sql
	touch $@

data/in/default_languages_2_level_if_relations_exist_check: db/table/default_languages_2_level db/table/osm_admin_boundaries ## check if relations still be actual
	echo 'List of osm relations from static_data/kontur_boundaries/default_language_2_level.csv, that were missed in osm_admin_boundaries table. Check relations and update osm or csv.' > $@__LOSTED_RELATIONS_MESSAGE
	echo '```' >> $@__LOSTED_RELATIONS_MESSAGE
	psql --set null=¤ --set linestyle=unicode --set border=2 -qXc "select osm_id, name, wikicode from default_languages_2_level where osm_id not in (select osm_id from osm_admin_boundaries) order by 1;" >> $@__LOSTED_RELATIONS_MESSAGE
	echo '```' >> $@__LOSTED_RELATIONS_MESSAGE
	psql -qXtc 'select count(*) from default_languages_2_level where osm_id not in (select osm_id from osm_admin_boundaries);' > $@__LOSTED_RELATIONS
	if [ 0 -lt $$(cat $@__LOSTED_RELATIONS) ]; then cat $@__LOSTED_RELATIONS_MESSAGE | python3 scripts/slack_message.py $$SLACK_CHANNEL ${SLACK_BOT_NAME} $$SLACK_BOT_EMOJI; fi
	rm -f $@__LOSTED_RELATIONS_MESSAGE $@__LOSTED_RELATIONS
	touch $@

data/out/required_relations_check: db/table/osm_admin_boundaries | data/out ## Check if West Sahara, US Minor Islands, Swalbard and Jan Mayen, State of Palestine relations exists in osm_admin_boundaries and send bug reports to Kontur Slack (#geocint channel).
	psql -c "drop table if exists required_relations;"
	psql -c "create table required_relations as (select unnest(array[1703814, 2559126, 2185386, 3245620, 3791785, 7391020, 60189, 1059500]) osm_id);"	
	echo 'Pipeine was interrupted because followed relations from list of osm relations that we access directly by osm_id in kontur_boundaries production were not found in osm_admin_boundaries table.' > $@__REQUIRED_RELATIONS_MESSAGE
	echo '```' >> $@__REQUIRED_RELATIONS_MESSAGE
	psql --set null=¤ --set linestyle=unicode --set border=2 -qXc "select osm_id from required_relations where osm_id not in (select osm_id from osm_admin_boundaries);" >> $@__REQUIRED_RELATIONS_MESSAGE
	echo '```' >> $@__REQUIRED_RELATIONS_MESSAGE
	psql -qXtc "select count(*) from required_relations where osm_id not in (select osm_id from osm_admin_boundaries);" > $@__NUMBER_MISSED_REQUIRED_RELATIONS
	if [ 0 -lt $$(cat $@__NUMBER_MISSED_REQUIRED_RELATIONS) ]; then cat $@__REQUIRED_RELATIONS_MESSAGE | python3 scripts/slack_message.py $$SLACK_CHANNEL ${SLACK_BOT_NAME} $$SLACK_BOT_EMOJI && exit 1; fi
	rm -f $@__REQUIRED_RELATIONS_MESSAGE $@__NUMBER_MISSED_REQUIRED_RELATIONS
	touch $@

db/table/kontur_boundaries: data/out/required_relations_check db/table/osm_admin_boundaries db/table/gadm_boundaries db/table/kontur_population_h3 db/table/wikidata_hasc_codes db/table/wikidata_population db/table/osm data/in/default_languages_2_level_if_relations_exist_check db/table/default_language_boundaries | db/table ## We produce boundaries dataset based on OpenStreetMap admin boundaries with aggregated population from kontur_population_h3 and HASC (Hierarchichal Administrative Subdivision Codes) codes (www.statoids.com/ihasc.html) from GADM (Database of Global Administrative Areas).
	psql -f tables/kontur_boundaries.sql
	touch $@

data/out/reports/kontur_boundaries_compare_with_latest_on_hdx: db/table/kontur_boundaries_v4 db/table/kontur_boundaries | data/out/reports ## Compare most recent geocint kontur boundaries to latest released and send bug reports to Kontur Slack (#geocint channel).
	psql -qXtc "select count(*) from kontur_boundaries_v4;" > $@__KONTUR_BOUNDARIES_DEPLOYED
	psql -qXtc "select count(*) from kontur_boundaries;" > $@__KONTUR_BOUNDARIES_CURRENT
	if [ $$(cat $@__KONTUR_BOUNDARIES_CURRENT) -lt $$(cat $@__KONTUR_BOUNDARIES_DEPLOYED) ]; then echo "Current Kontur boundaries has less rows than the previously released" | python3 scripts/slack_message.py $$SLACK_CHANNEL ${SLACK_BOT_NAME} $$SLACK_BOT_EMOJI; fi
	rm -f $@__KONTUR_BOUNDARIES_CURRENT $@__KONTUR_BOUNDARIES_DEPLOYED
	touch $@

data/out/kontur_boundaries/kontur_boundaries.gpkg.gz: data/out/reports/kontur_boundaries_compare_with_latest_on_hdx | data/out/kontur_boundaries ## Kontur Boundaries (most recent) geopackage archive
	rm -f $@
	ogr2ogr -f GPKG data/out/kontur_boundaries/kontur_boundaries.gpkg PG:'dbname=gis' -sql "select admin_level, name, name_en, population, hasc, geom from kontur_boundaries order by name" -lco "SPATIAL_INDEX=NO" -nln kontur_boundaries
	cd data/out/kontur_boundaries; pigz -k kontur_boundaries.gpkg
	touch $@

db/table/kontur_default_languages: db/table/kontur_boundaries db/table/default_language_boundaries db/table/default_languages_2_level | db/table ## create kontur_default_languages dataset (administartive boundaries with default language (initial + extrapolated) + non-administrative like a language province)
	psql -f tables/kontur_default_languages.sql
	touch $@

data/out/kontur_default_languages.gpkg.gz: db/table/kontur_default_languages db/table/kontur_boundaries | data/out ## Extract kontur_default_languages table to gpkg file and zip 	
	rm -f $@	
	ogr2ogr -f GPKG data/out/kontur_default_languages.gpkg PG:'dbname=gis' -sql "select * from kontur_default_languages order by osm_id" -lco "SPATIAL_INDEX=NO" -nln kontur_default_languages
	cd data/out/; pigz kontur_default_languages.gpkg
	touch $@

deploy/s3/kontur_default_languages.gpkg.gz: data/out/kontur_default_languages.gpkg.gz ## deploy kontur default languages dataset to s3
	aws s3 cp data/out/kontur_default_languages.gpkg.gz s3://geodata-eu-central-1-kontur-public/kontur_datasets/kontur_default_languages.gpkg.gz --profile geocint_pipeline_sender --acl public-read
	touch $@

db/table/topology_boundaries: db/table/kontur_boundaries db/table/water_polygons_vector ## Create topology build of kontur boundaries
	psql -f tables/topology_boundaries.sql
	touch $@

data/out/topology_boundaries.geojson.gz: db/table/topology_boundaries | data/out ## Outputs compressed geojson with Kontor Boundaries topology build
	rm -vf data/out/topology_boundaries.geojson.gz*
	ogr2ogr -f GeoJSON data/out/topology_boundaries.geojson PG:'dbname=gis' -sql "select * from topology_boundary" -nln kontur_topology_boundary
	pigz data/out/topology_boundaries.geojson

deploy/s3/topology_boundaries: data/out/topology_boundaries.geojson.gz | deploy/s3 ## Uploads compressed geojson with topology build of Kontur Boundaries in public directory in geodata-us-east-1-kontur s3 bucket
	aws s3 cp data/out/topology_boundaries.geojson.gz s3://geodata-eu-central-1-kontur-public/kontur_datasets/topology_boundaries.geojson.gz --profile geocint_pipeline_sender --acl public-read
	touch $@

db/table/hdx_locations_with_wikicodes: db/table/wikidata_hasc_codes | db/table ## Create table with HDX locations with hasc codes
	psql -c "drop table if exists hdx_locations;"
	psql -c "create table hdx_locations (href text, code text, hasc text, name text);"
	psql -c "\copy hdx_locations (href, code, hasc, name) from 'static_data/kontur_boundaries/hdx_locations.csv' with csv header delimiter ';';"
	psql -f tables/hdx_locations_with_wikicodes.sql
	psql -c "drop table if exists hdx_locations;"
	touch $@

db/table/hdx_boundaries: db/table/hdx_locations_with_wikicodes db/table/kontur_boundaries | db/table ## Create table with HDX locations with hasc codes
	psql -f tables/hdx_boundaries.sql
	touch $@

## Kontur Boundaries for boundaries selector block

data/out/kontur_boundaries.geojson.gz: db/table/kontur_boundaries | data/out ## Export to geojson and archive administrative boundaries polygons from Kontur Boundaries dataset to be used in kcapi for Event-api enrichment - geocoding, DN boundary selector.
	cp -vf $@ data/out/kontur_boundaries.geojson.gz_bak || true
	rm -vf data/out/kontur_boundaries.geojson data/out/kontur_boundaries.geojson.gz
	ogr2ogr -f GeoJSON data/out/kontur_boundaries.geojson PG:'dbname=gis' -sql "select osm_id, osm_type, boundary, admin_level, name, tags, geom from kontur_boundaries" -nln osm_admin_boundaries
	pigz data/out/kontur_boundaries.geojson
	touch $@

deploy/s3/kontur_boundaries: data/out/kontur_boundaries.geojson.gz | deploy/s3 ## Deploy Kontur admin boundaries dataset to Amazon S3 - we use this extraction in kcapi/boundary_selector.
	aws s3api put-object --bucket geodata-us-east-1-kontur --key public/geocint/osm_admin_boundaries.geojson.gz --body data/out/kontur_boundaries.geojson.gz --content-type "application/json" --content-encoding "gzip" --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers
	touch $@

data/out/kontur_boundaries_for_boundary_selector.geojson.gz: db/table/kontur_boundaries | data/out ## Export to geojson and archive administrative boundaries polygons from Kontur Boundaries dataset to be used in LayersDB for Event-api enrichment - geocoding, DN boundary selector.
	cp -vf $@ data/out/kontur_boundaries_for_boundary_selector.geojson.gz_bak || true
	rm -vf data/out/kontur_boundaries_for_boundary_selector.geojson data/out/kontur_boundaries_for_boundary_selector.geojson.gz
	ogr2ogr -f GeoJSON data/out/kontur_boundaries_for_boundary_selector.geojson PG:'dbname=gis' -sql "select to_json((select d from (select k.osm_id, k.osm_type, h.code as iso3countrycode, k.boundary, k.admin_level, k.name, k.tags) d)) as properties, (json_extract_path_text(o.meta::json, 'data', 'timestamp', 'last'))::timestamp with time zone as last_updated, geom from kontur_boundaries k join osm_meta o on true left join hdx_locations_with_wikicodes h on k.hasc_wiki = h.hasc" -nln osm_admin_boundaries
	pigz data/out/kontur_boundaries_for_boundary_selector.geojson
	touch $@

deploy/s3/kontur_boundaries_for_boundary_selector.geojson.gz: data/out/kontur_boundaries_for_boundary_selector.geojson.gz | deploy/s3 ## Deploy Kontur admin boundaries for boundary selector dataset to Amazon S3 - we use this extraction in LayersDB/boundary_selector.
	aws s3 cp data/out/kontur_boundaries_for_boundary_selector.geojson.gz s3://geodata-eu-central-1-kontur-public/kontur_datasets/kontur_boundaries_for_boundary_selector.geojson.gz --profile geocint_pipeline_sender --acl public-read
	touch $@

## Kontur Boundaries new version release block 

data/out/kontur_boundaries_per_country: | data/out ## Directory for per country extraction from kontur_boundaries
	mkdir -p $@

data/out/kontur_boundaries_per_country/gpkg_export_commands.txt: | data/out/kontur_boundaries_per_country ## Create file with per country extraction commands
	cat static_data/kontur_boundaries/hdx_locations.csv | \
		parallel --colsep ';' \
			'echo "ogr2ogr -f GPKG data/out/kontur_boundaries_per_country/kontur_boundaries_"{3}"_$(current_date).gpkg PG:*dbname=gis* -sql *select admin_level, osm_admin_level, name, name_en, population, hasc, geom from kontur_boundaries_export where location = %"{3}"% order by admin_level;* -nln boundaries -lco *SPATIAL_INDEX=NO*"' | sed -r 's/[\*]+/\"/g' | sed -r "s/[\%]+/\'/g" > $@

	sed -i '1d' $@

data/out/kontur_boundaries_per_country/export: db/table/hdx_boundaries data/out/kontur_boundaries_per_country/gpkg_export_commands.txt db/table/kontur_boundaries | data/out/kontur_boundaries_per_country ## Extraction boundaries data per country
	psql -f tables/kontur_boundaries_export.sql
	rm -f data/out/kontur_boundaries_per_country/*.gpkg*
	cat data/out/kontur_boundaries_per_country/gpkg_export_commands.txt | parallel '{}'
	touch $@

data/out/kontur_topology_boundaries_per_country: | data/out ## Directory for per country extraction from kontur_topolgy_boundaries
	mkdir -p $@
	
data/out/kontur_topology_boundaries_per_country/export: db/table/water_polygons_vector db/table/hdx_boundaries db/table/kontur_boundaries | data/out/kontur_topology_boundaries_per_country ## Topology per country export
	psql -X -q -t -F , -A -c "SELECT hasc FROM hdx_boundaries GROUP by 1" > $@__HASCS_LIST
	cat $@__HASCS_LIST | parallel "psql -c 'drop table if exists topology_tmp_{};'"
	cat $@__HASCS_LIST | parallel "psql -c 'drop table if exists topology_boundaries_{};'"
	cat $@__HASCS_LIST | parallel "psql -v tab_temp=topology_tmp_{} -v tab_result=topology_boundaries_{} -v cnt_code={} -f scripts/topology_boundaries_per_country_export.sql"
	cat $@__HASCS_LIST | parallel "echo $$(date '+%Y%m%d') {}" | parallel --colsep ' ' "ogr2ogr -overwrite -f GPKG data/out/kontur_topology_boundaries_per_country/kontur_topology_boundaries_{2}_{1}.gpkg PG:'dbname=gis' topology_boundaries_{2} -nln kontur_topology_boundaries_{2}_{1} -lco OVERWRITE=yes"
	cat $@__HASCS_LIST | parallel "psql -c 'drop table if exists topology_boundaries_{};'"
	rm -f $@__HASCS_LIST
	touch $@

data/out/kontur_boundaries/hdx_world_extraction_export: db/table/kontur_boundaries | data/out/kontur_boundaries ## Extract new kontur boundaries world release
	ogr2ogr -f GPKG data/out/kontur_boundaries/kontur_boundaries_$(current_date).gpkg PG:"dbname=gis" -sql "select kontur_admin_level as admin_level, admin_level as osm_admin_level, name, name_en, population, hasc_wiki as hasc, geom from kontur_boundaries order by admin_level;" -nln boundaries -lco "SPATIAL_INDEX=NO"
	touch $@
	
deploy/kontur_boundaries_per_country_on_hdx: data/out/kontur_boundaries_per_country/export ## Deploy new kontur boundaries per country release on hdx
	cd scripts/; python3 -m hdxloader load -t country-boundaries -s prod -k $$HDX_API_TOKEN -d /data/out/kontur_boundaries_per_country/ --no-dry-run
	touch $@

deploy/kontur_topology_boundaries_per_country_on_hdx: data/out/kontur_topology_boundaries_per_country/export ## Deploy new kontur topology boundaries per country release on hdx
	cd scripts/; python3 -m hdxloader load -t country-boundaries -s prod -k $$HDX_API_TOKEN -d /data/out/kontur_topology_boundaries_per_country/ --no-dry-run
	touch $@

deploy/kontur_boundaries_new_release_on_hdx: data/out/kontur_boundaries/hdx_world_extraction_export deploy/kontur_boundaries_per_country_on_hdx deploy/kontur_topology_boundaries_per_country_on_hdx ## Kontur Boundaries new hdx release final target
	touch $@

## End Kontur Boundaries new version release block 

data/in/kontur_boundaries_previous_release: | data/in ## Kontur Boundaries previous release input.
	mkdir -p $@

data/mid/kontur_boundaries_previous_release: | data/mid ## Kontur Boundaries previous release mid data.
	mkdir -p $@

data/in/kontur_boundaries_previous_release/kontur_boundaries_v4.gpkg.gz: | data/in/kontur_boundaries_previous_release ## Download Kontur Boundaries previous release gzip to geocint.
	rm -rf $@
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/kontur_boundaries_v4.gpkg.gz $@ --profile geocint_pipeline_sender

data/mid/kontur_boundaries_previous_release/kontur_boundaries_v4.gpkg: data/in/kontur_boundaries_previous_release/kontur_boundaries_v4.gpkg.gz | data/mid/kontur_boundaries_previous_release ## Unzip Kontur Boundaries previous release geopackage archive.
	gzip -dck data/in/kontur_boundaries_previous_release/kontur_boundaries_v4.gpkg.gz > $@

db/table/kontur_boundaries_v4: data/mid/kontur_boundaries_previous_release/kontur_boundaries_v4.gpkg ## Import Kontur Boundaries previous release into database.
	psql -c "drop table if exists kontur_boundaries_v4;"
	ogr2ogr --config PG_USE_COPY YES -f PostgreSQL PG:'dbname=gis' data/mid/kontur_boundaries_previous_release/kontur_boundaries_v4.gpkg -t_srs EPSG:4326 -nln kontur_boundaries_v4 -lco GEOMETRY_NAME=geom
	touch $@

### END Kontur Boundaries block ###

### Disaster Ninja Reports block ###

db/table/osm_reports_list: db/table/osm_meta db/table/population_check_osm db/table/osm_population_inconsistencies db/table/osm_gadm_comparison db/table/osm_unmapped_places_report db/table/osm_missing_roads db/table/osm_missing_boundaries_report | db/table ## Reports table for further generation of JSON file that will be used to generate a HTML page on Disaster Ninja
	psql -f tables/osm_reports_list.sql
	touch $@

db/table/boundaries_statistics_report: db/table/stat_h3 data/out/kontur_boundaries_per_country/export db/table/hot_projects | db/table ## MVP boundaries statistics report
	psql -f tables/boundaries_statistics_report.sql
	touch $@

db/table/population_check_osm: db/table/kontur_boundaries db/table/hdx_boundaries | db/table ## Check how OSM population and Kontur population corresponds with each other for kontur_boundaries dataset.
	psql -f tables/population_check_osm.sql
	touch $@

db/table/osm_population_inconsistencies: db/table/osm_admin_boundaries | db/table ## Validate OpenStreetMap population inconsistencies (one admin level can have a sum of population that is higher than the level above it, leading to negative population in admin regions).
	psql -f tables/osm_population_inconsistencies.sql
	touch $@

db/table/osm_gadm_comparison: db/table/kontur_boundaries db/table/gadm_boundaries | db/table ## Validate OSM boundaries that OSM has no less polygons than GADM.
	psql -f tables/osm_gadm_comparison.sql
	touch $@

db/table/osm_unmapped_places_report: db/table/stat_h3 db/table/hdx_boundaries | db/table ## Report with a list of vieved but unmapped populated places
	psql -f tables/osm_unmapped_places_report.sql
	touch $@

db/table/osm_missing_roads: db/table/stat_h3 db/table/osm_admin_boundaries | db/table ## Report with a list places where Facebook has more roads than OpenStreetMap
	psql -f tables/osm_missing_roads.sql
	touch $@

db/table/osm_missing_boundaries_report: db/table/osm_admin_boundaries db/table/kontur_boundaries_v4 | db/table ## Report with a list boundaries potentially broken in OpenStreetMap
	psql -f tables/osm_missing_boundaries_report.sql
	touch $@

data/out/reports/boundaries_statistics_report.csv: db/table/boundaries_statistics_report | data/out/reports ## Export MVP boundaries statistics report
	psql -qXc "copy (select \"Name\", \"Admin level\", \"Population\", \"People with no OSM buildings\", \"People with no OSM roads\", \"People with no OSM objects\",\"Populated area km2\",\"Populated area with no OSM objects %\",\"Populated area with no OSM buildings %\",\"Populated area with no OSM roads %\",\"Hazardous days count\",\"HOT Projects\" from boundaries_statistics_report order by location, admin_level) to stdout with (format csv, header true, delimiter ';');" | sed 's/\"\"/\@\@\@/g' | sed 's/\"//' | sed 's/\"//' | sed 's/\@\@\@/\"/g' > $@

data/out/reports/osm_gadm_comparison.csv: db/table/osm_gadm_comparison db/table/osm_meta | data/out/reports ## Export OSM-GADM comparison report to CSV with semicolon delimiter.
	psql -qXc "copy (select \"OSM id\", \"Admin level\", \"OSM name\", \"GADM name\" from osm_gadm_comparison order by id limit 10000) to stdout with (format csv, header true, delimiter ';');" | sed 's/\"\"/\@\@\@/g' | sed 's/\"//' | sed 's/\"//' | sed 's/\@\@\@/\"/g'  > $@

data/out/reports/osm_population_inconsistencies.csv: db/table/osm_population_inconsistencies | data/out/reports ## Export population inconsistencies report (see also db/table/osm_population_inconsistencies target) to CSV with semicolon delimiter.
	psql -qXc "copy (select \"OSM id\", \"Name\", \"Admin level\", \"Population\", \"Population date\", \"Population source\", \"SUM subregions population\", \"Population difference value\", \"Population difference %\" from osm_population_inconsistencies order by id) to stdout with (format csv, header true, delimiter ';');" | sed 's/\"\"/\@\@\@/g' | sed 's/\"//' | sed 's/\"//' | sed 's/\@\@\@/\"/g' > $@

data/out/reports/population_check_osm.csv: db/table/population_check_osm db/table/osm_meta | data/out/reports ## Export population_check_osm report to CSV with semicolon delimiter and send Top 5 most inconsistent results (scaled and not scaled) to Kontur Slack (#geocint channel).
	psql -qXc "copy (select \"OSM id\", \"Country\", \"Name\", \"OSM population date\", \"OSM population\", \"Kontur population\", \"Wikidata population\", \"OSM-Kontur Population difference\", \"Wikidata-Kontur Population difference\" from population_check_osm order by abs(\"OSM-Kontur Population difference\") desc limit 1000) to stdout with (format csv, header true, delimiter ';');" | sed 's/\"\"/\@\@\@/g' | sed 's/\"//' | sed 's/\"//' | sed 's/\@\@\@/\"/g' > $@
	psql -qXtf scripts/population_check_osm_message_scaled.sql | python3 scripts/slack_message.py $$SLACK_CHANNEL ${SLACK_BOT_NAME} $$SLACK_BOT_EMOJI
	psql -qXtf scripts/population_check_osm_message_not_scaled.sql | python3 scripts/slack_message.py $$SLACK_CHANNEL ${SLACK_BOT_NAME} $$SLACK_BOT_EMOJI

data/out/reports/osm_unmapped_places.csv: db/table/osm_unmapped_places_report | data/out/reports ## Export report to CSV
	psql -qXc "copy (select h3 as \"H3 index\", \"Country\", population as \"Kontur population\", view_count as \"osm.org view count\", \"Place bounding box\" from osm_unmapped_places_report order by id) to stdout with (format csv, header true, delimiter ';');" > $@

data/out/reports/osm_missing_roads.csv: db/table/osm_missing_roads | data/out/reports ## Export report to CSV
	psql -qXc "copy (select row_number() over() as id, h3 as \"H3 index\", \"Country\", \"OSM roads length, km\", \"Facebook roads length, km\", \"Place bounding box\" from osm_missing_roads order by diff desc limit 14000) to stdout with (format csv, header true, delimiter ';');" > $@

data/out/reports/osm_missing_boundaries_report.csv: db/table/osm_missing_boundaries_report | data/out/reports ## Export OSM missing boundaries report to CSV with semicolon delimiter.
	psql -qXc 'copy (select "OSM id", "Admin level", "Name", "Country" from osm_missing_boundaries_report order by id) to stdout with (format csv, header true, delimiter ";");' | sed 's/\"\"/\@\@\@/g' | sed 's/\"//' | sed 's/\"//' | sed 's/\@\@\@/\"/g' > $@

data/out/reports/osm_reports_list_test.json: db/table/osm_reports_list | data/out/reports ## Export OpenStreetMap quality reports table to JSON file that will be used to generate a HTML page on Disaster Ninja (development version)
	psql -qXc 'copy (select jsonb_agg(row) from osm_reports_list row) to stdout;' | sed 's/\@\@\@\@\@/\/test/g' | sed 's=\\=@@=g' | sed 's/\@\@\@\@/\\/g' > $@
	touch $@

data/out/reports/osm_reports_list_dev.json: db/table/osm_reports_list | data/out/reports ## Export OpenStreetMap quality reports table to JSON file that will be used to generate a HTML page on Disaster Ninja (development version)
	psql -qXc 'copy (select jsonb_agg(row) from osm_reports_list row) to stdout;' | sed 's/\@\@\@\@\@/\/dev/g' | sed 's=\\=@@=g' | sed 's/\@\@\@\@/\\/g' > $@
	touch $@

data/out/reports/osm_reports_list_prod.json: db/table/osm_reports_list | data/out/reports ## Export OpenStreetMap quality reports table to JSON file that will be used to generate a HTML page on Disaster Ninja (production version)
	psql -qXc 'copy (select jsonb_agg(row) from (select * from osm_reports_list) row where public_access is true) to stdout;' | sed 's/\@\@\@\@\@//g' | sed 's=\\=@@=g' | sed 's/\@\@\@\@/\\/g'> $@
	touch $@

deploy/geocint/reports/boundaries_statistics_report.csv: data/out/reports/boundaries_statistics_report.csv | deploy/geocint/reports ## Copy MVP boundaries statistics report to public_html folder to make it available online.
	mkdir -p ~/public_html/reports && cp data/out/reports/boundaries_statistics_report.csv ~/public_html/reports/boundaries_statistics_report.csv
	touch $@

deploy/geocint/reports/osm_gadm_comparison.csv: data/out/reports/osm_gadm_comparison.csv | deploy/geocint/reports ## Copy OSM-GADM comparison report to public_html folder to make it available online.
	mkdir -p ~/public_html/reports && cp data/out/reports/osm_gadm_comparison.csv ~/public_html/reports/osm_gadm_comparison.csv
	touch $@

deploy/geocint/reports/osm_population_inconsistencies.csv: data/out/reports/osm_population_inconsistencies.csv | deploy/geocint/reports ## Copy osm population inconsistencies report to public_html folder to make it available online.
	mkdir -p ~/public_html/reports && cp data/out/reports/osm_population_inconsistencies.csv ~/public_html/reports/osm_population_inconsistencies.csv
	touch $@

deploy/geocint/reports/population_check_osm.csv: data/out/reports/population_check_osm.csv | deploy/geocint/reports  ## Copy osm population check report to public_html folder to make it available online.
	mkdir -p ~/public_html/reports && cp data/out/reports/population_check_osm.csv ~/public_html/reports/population_check_osm.csv
	touch $@

deploy/geocint/reports/osm_unmapped_places.csv: data/out/reports/osm_unmapped_places.csv | deploy/geocint/reports ## Copy report file to public_html
	mkdir -p ~/public_html/reports && cp data/out/reports/osm_unmapped_places.csv ~/public_html/reports/osm_unmapped_places.csv
	touch $@

deploy/geocint/reports/osm_missing_roads.csv: data/out/reports/osm_missing_roads.csv | deploy/geocint/reports ## Copy report file to public_html
	mkdir -p ~/public_html/reports && cp data/out/reports/osm_missing_roads.csv ~/public_html/reports/osm_missing_roads.csv
	touch $@

deploy/geocint/reports/osm_missing_boundaries_report.csv: data/out/reports/osm_missing_boundaries_report.csv | deploy/geocint/reports ## Copy report file to public_html
	mkdir -p ~/public_html/reports && cp data/out/reports/osm_missing_boundaries_report.csv ~/public_html/reports/osm_missing_boundaries_report.csv
	touch $@

deploy/geocint/reports/osm_reports_list_test.json: data/out/reports/osm_reports_list_test.json | deploy/geocint/reports ## Copy reports JSON file to public_html folder to make it available online.
	mkdir -p ~/public_html/reports && cp data/out/reports/osm_reports_list_test.json ~/public_html/reports/osm_reports_list_test.json
	touch $@

deploy/geocint/reports/osm_reports_list_dev.json: data/out/reports/osm_reports_list_dev.json | deploy/geocint/reports ## Copy reports JSON file to public_html folder to make it available online.
	mkdir -p ~/public_html/reports && cp data/out/reports/osm_reports_list_dev.json ~/public_html/reports/osm_reports_list_dev.json
	touch $@

deploy/geocint/reports/osm_reports_list_prod.json: data/out/reports/osm_reports_list_prod.json | deploy/geocint/reports ## Copy reports JSON file to public_html folder to make it available online.
	mkdir -p ~/public_html/reports && cp data/out/reports/osm_reports_list_prod.json ~/public_html/reports/osm_reports_list_prod.json
	touch $@

deploy/geocint/reports/test/reports.tar.gz: deploy/geocint/reports/osm_unmapped_places.csv deploy/geocint/reports/osm_missing_roads.csv deploy/geocint/reports/osm_gadm_comparison.csv deploy/geocint/reports/osm_population_inconsistencies.csv deploy/geocint/reports/population_check_osm.csv deploy/geocint/reports/osm_missing_boundaries_report.csv deploy/geocint/reports/boundaries_statistics_report.csv deploy/geocint/reports/osm_reports_list_test.json | deploy/geocint/reports/test  ## OSM quality reports (most recent) testing archive.
	rm -f ~/public_html/test/reports.tar.gz
	cd ~/public_html/reports; tar --transform='flags=r;s|list_test|list|' -cf test_reports.tar.gz -I pigz osm_reports_list_test.json population_check_osm.csv osm_gadm_comparison.csv  osm_population_inconsistencies.csv osm_unmapped_places.csv osm_missing_roads.csv osm_missing_boundaries_report.csv boundaries_statistics_report.csv
	touch $@

deploy/geocint/reports/dev/reports.tar.gz: deploy/geocint/reports/osm_unmapped_places.csv deploy/geocint/reports/osm_missing_roads.csv deploy/geocint/reports/osm_gadm_comparison.csv deploy/geocint/reports/osm_population_inconsistencies.csv deploy/geocint/reports/population_check_osm.csv deploy/geocint/reports/osm_missing_boundaries_report.csv deploy/geocint/reports/boundaries_statistics_report.csv deploy/geocint/reports/osm_reports_list_dev.json | deploy/geocint/reports/dev  ## OSM quality reports (most recent) dev archive.
	rm -f ~/public_html/dev/reports.tar.gz
	cd ~/public_html/reports; tar --transform='flags=r;s|list_dev|list|' -cf dev_reports.tar.gz -I pigz osm_reports_list_dev.json population_check_osm.csv osm_gadm_comparison.csv  osm_population_inconsistencies.csv osm_unmapped_places.csv osm_missing_roads.csv osm_missing_boundaries_report.csv boundaries_statistics_report.csv
	touch $@

deploy/geocint/reports/prod/reports.tar.gz: deploy/geocint/reports/osm_unmapped_places.csv deploy/geocint/reports/osm_missing_roads.csv deploy/geocint/reports/osm_gadm_comparison.csv deploy/geocint/reports/osm_population_inconsistencies.csv deploy/geocint/reports/population_check_osm.csv deploy/geocint/reports/osm_missing_boundaries_report.csv deploy/geocint/reports/boundaries_statistics_report.csv deploy/geocint/reports/osm_reports_list_prod.json | deploy/geocint/reports/prod  ## OSM quality reports (most recent) production archive.
	rm -f ~/public_html/prod/reports.tar.gz
	cd ~/public_html/reports; tar --transform='flags=r;s|list_prod|list|' -cf prod_reports.tar.gz -I pigz osm_reports_list_prod.json population_check_osm.csv osm_gadm_comparison.csv osm_population_inconsistencies.csv  osm_unmapped_places.csv osm_missing_roads.csv osm_missing_boundaries_report.csv boundaries_statistics_report.csv
	touch $@

deploy/s3/test/reports/reports.tar.gz: deploy/geocint/reports/test/reports.tar.gz | deploy/s3/test/reports ## Putting reports archive to AWS test reports folder in private bucket. Before it we backup the previous reports archive.
	# (|| true) is needed to avoid failing when there is nothing to be backed up. that is the case on a first run or when bucket got changed.
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/test/reports/reports.tar.gz s3://geodata-eu-central-1-kontur/private/geocint/test/reports/reports.tar.gz.bak --profile geocint_pipeline_sender || true
	aws s3 cp ~/public_html/reports/test_reports.tar.gz s3://geodata-eu-central-1-kontur/private/geocint/test/reports/reports.tar.gz --profile geocint_pipeline_sender
	touch $@

deploy/s3/dev/reports/reports.tar.gz: deploy/geocint/reports/dev/reports.tar.gz | deploy/s3/dev/reports ## Putting reports archive to AWS dev reports folder in private bucket. Before it we backup the previous reports archive.
	# (|| true) is needed to avoid failing when there is nothing to be backed up. that is the case on a first run or when bucket got changed.
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/dev/reports/reports.tar.gz s3://geodata-eu-central-1-kontur/private/geocint/dev/reports/reports.tar.gz.bak --profile geocint_pipeline_sender || true
	aws s3 cp ~/public_html/reports/dev_reports.tar.gz s3://geodata-eu-central-1-kontur/private/geocint/dev/reports/reports.tar.gz --profile geocint_pipeline_sender
	touch $@

deploy/s3/prod/reports/reports.tar.gz: deploy/geocint/reports/prod/reports.tar.gz | deploy/s3/prod/reports ## Putting reports archive to AWS production reports folder in private bucket. Before it we backup the previous reports archive.
	# (|| true) is needed to avoid failing when there is nothing to be backed up. that is the case on a first run or when bucket got changed.
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/prod/reports/reports.tar.gz s3://geodata-eu-central-1-kontur/private/geocint/prod/reports/reports.tar.gz.bak --profile geocint_pipeline_sender || true
	aws s3 cp ~/public_html/reports/prod_reports.tar.gz s3://geodata-eu-central-1-kontur/private/geocint/prod/reports/reports.tar.gz --profile geocint_pipeline_sender
	touch $@

deploy/s3/test/reports/test_reports_public: deploy/geocint/reports/test/reports.tar.gz | deploy/s3/test/reports ## Putting reports to AWS test reports folder in public bucket (TEST).
	rm -rf ~/public_html/reports/test_reports_public/
	mkdir -p ~/public_html/reports/test_reports_public/
	tar -xzf ~/public_html/reports/test_reports.tar.gz -C ~/public_html/reports/test_reports_public/
	aws s3 sync ~/public_html/reports/test_reports_public/ s3://geodata-eu-central-1-kontur-public/kontur_reports/test/ --profile geocint_pipeline_sender --acl public-read
	touch $@

deploy/s3/dev/reports/dev_reports_public: deploy/geocint/reports/dev/reports.tar.gz | deploy/s3/dev/reports ## Putting reports to AWS test reports folder in public bucket (DEV).
	rm -rf ~/public_html/reports/dev_reports_public/
	mkdir -p ~/public_html/reports/dev_reports_public/
	tar -xzf ~/public_html/reports/dev_reports.tar.gz -C ~/public_html/reports/dev_reports_public/
	aws s3 sync ~/public_html/reports/dev_reports_public/ s3://geodata-eu-central-1-kontur-public/kontur_reports/dev/ --profile geocint_pipeline_sender --acl public-read
	touch $@

deploy/s3/prod/reports/prod_reports_public: deploy/geocint/reports/prod/reports.tar.gz | deploy/s3/prod/reports ## Putting reports to AWS prod reports folder in public bucket (PROD).
	rm -rf ~/public_html/reports/prod_reports_public/
	mkdir -p ~/public_html/reports/prod_reports_public/
	tar -xzf ~/public_html/reports/prod_reports.tar.gz -C ~/public_html/reports/prod_reports_public/
	aws s3 sync ~/public_html/reports/prod_reports_public/ s3://geodata-eu-central-1-kontur-public/kontur_reports/ --exclude 'osm_missing_boundaries_report.csv' --profile geocint_pipeline_sender --acl public-read
	aws s3 sync ~/public_html/reports/prod_reports_public/ s3://geodata-eu-central-1-kontur-public/kontur_reports/ --exclude='*' --include='osm_missing_boundaries_report.csv' --profile geocint_pipeline_sender
	touch $@

### End Disaster Ninja Reports block ###

### Wikidata code block
db/table/wikidata_naturalization_gap: | db/table ## Global collection of years of years_to_naturalisation and multiple_citizenship (0 - not allowed, 1 - with restrictions, 2 - allowed) per country
	psql -c "drop table if exists wikidata_naturalization_gap;"
	psql -c "create table wikidata_naturalization_gap (name text, hasc text, code text, years_to_naturalisation float,multiple_citizenship integer);"
	cat static_data/wikidata_naturalization/naturalization_gap.csv | psql -c "copy wikidata_naturalization_gap from stdin with csv header;"
	psql -c "create index on wikidata_naturalization_gap using btree(hasc);"
	touch $@

db/table/wikidata_naturalization_gap_h3: db/table/kontur_boundaries db/table/wikidata_naturalization_gap db/procedure/generate_overviews db/procedure/transform_hasc_to_h3 | db/table ## Generation overviws of wikidata years_to_naturalisation and multiple_citizenship
	psql -c "call transform_hasc_to_h3('wikidata_naturalization_gap', 'wikidata_naturalization_gap_h3', 'hasc', '{years_to_naturalisation,multiple_citizenship}'::text[], 8);"
	psql -c "call generate_overviews('wikidata_naturalization_gap_h3', '{years_to_naturalisation,multiple_citizenship}'::text[], '{max,min}'::text[], 8);"
	touch $@

data/in/iso_codes.csv: | data/in ## Download ISO codes for countries from wikidata.
	wget 'https://query.wikidata.org/sparql?query=SELECT DISTINCT ?isoNumeric ?isoAlpha2 ?isoAlpha3 ?countryLabel WHERE {?country wdt:P31/wdt:P279* wd:Q56061; wdt:P299 ?isoNumeric; wdt:P297 ?isoAlpha2; wdt:P298 ?isoAlpha3. SERVICE wikibase:label { bd:serviceParam wikibase:language "en" }}' --retry-on-http-error=500 --header "Accept: text/csv" -O $@

db/table/iso_codes: data/in/iso_codes.csv | db/table ## Download ISO codes for countries from wikidata.
	psql -c 'drop table if exists iso_codes;'
	psql -c 'create table iso_codes(iso_num integer, iso2 char(2), iso3 char(3), name text);'
	cat data/in/iso_codes.csv | sed -e '/PM,PM,SPM/d' | psql -c "copy iso_codes from stdin with csv header;"
	touch $@

data/in/wikidata_hasc_codes.csv: | data/in ## Download HASC codes for admin boundaries from wikidata.
	wget 'https://query.wikidata.org/sparql?query=SELECT DISTINCT (?item AS ?wikidata_object) ?itemLabel ?hasc WHERE { SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE]". } { SELECT DISTINCT ?item ?itemLabel ?hasc WHERE {{ ?item wdt:P8119 ?object; wdt:P8119 ?hasc; } UNION { ?item wdt:P297 ?object; wdt:P297 ?hasc; } SERVICE wikibase:label { bd:serviceParam wikibase:language "en" . }}order by DESC(?hasc) }}' --retry-on-http-error=500 --header "Accept: text/csv" -O $@

db/table/wikidata_hasc_codes: data/in/wikidata_hasc_codes.csv| db/table ## Import wikidata HASC codes into database.
	psql -c 'drop table if exists wikidata_hasc_codes_in;'
	psql -c 'create table wikidata_hasc_codes_in (wikidata_item text, name text, hasc text);'
	cat data/in/wikidata_hasc_codes.csv | sed -e '/PM,PM,SPM/d' | psql -c "copy wikidata_hasc_codes_in from stdin with csv header;"
	psql -c 'drop table if exists wikidata_hasc_codes;'
	psql -c 'create table wikidata_hasc_codes as select distinct on (wikidata_item) * from wikidata_hasc_codes_in order by wikidata_item, hasc desc;'
	psql -c 'drop table if exists wikidata_hasc_codes_in;'
	touch $@

data/in/wikidata_population_csv: | data/in ## Wikidata population csv (input).
	mkdir -p $@

data/in/wikidata_population_csv/download: data/in/wikidata_hasc_codes.csv | data/in/wikidata_population_csv ## Download Wikidata population.
	rm -f data/in/wikidata_population_csv/*_wiki_pop.csv

	# NB! Notice `seq 2` here. First, wget triggers query execution which might take some time.
	# In 99 of 100 everything goes well but in case of thousands of rows we might catch timout during downloading
	# So we run wget twice because for the second time it uses cached query.

	cat static_data/wikidata_population/wikidata_population_ranges.txt \
		| parallel -j1 --colsep " " \
			'seq 2 | xargs -I JUSTAPLACEHOLDER wget \
				-nv \
				"https://query.wikidata.org/sparql?query=SELECT \
					?country \
					?countryLabel \
					?population \
					?census_date \
					WHERE { \
						?country p:P1082 ?population_statement . \
						?population_statement ps:P1082 ?population . \
						OPTIONAL { ?population_statement pq:P585 ?census_date . } \
						FILTER ({1} <= ?population %26%26 ?population < {2}) . \
						SERVICE wikibase:label { bd:serviceParam wikibase:language \"en\" . } }" \
				--retry-on-http-error=500 \
				--header "Accept: text/csv" \
				-O data/in/wikidata_population_csv/{1}_{2}_wiki_pop.csv; \
			sleep 1'
	touch $@

db/table/wikidata_population: data/in/wikidata_population_csv/download | db/table ## Check wikidata population data is valid and complete and import into database if true.
	grep --include=\*_wiki_pop.csv -rnw 'data/in/wikidata_population_csv/' -e "java.util.concurrent.TimeoutException" | wc -l > $@__WIKIDATA_POP_CSV_WITH_TIMEOUTEXCEPTION
	if [ $$(cat $@__WIKIDATA_POP_CSV_WITH_TIMEOUTEXCEPTION) -lt 1 ]; then \
		psql -c 'drop table if exists wikidata_population_in;'; \
		psql -c 'create table wikidata_population_in(wikidata_item text, wikidata_name text, population numeric, census_date text);'; \
		ls data/in/wikidata_population_csv/*_wiki_pop.csv \
			| parallel 'cat {} | psql -c "copy wikidata_population_in from stdin with csv header;"'; \
		psql -f tables/wikidata_population.sql; \
		psql -c 'drop table if exists wikidata_population_in;'; \
	fi

	if [ 0 -lt $$(cat $@__WIKIDATA_POP_CSV_WITH_TIMEOUTEXCEPTION) ]; then \
		echo "Latest wikidata population loading was failed with wikidata TimeoutException, using previous one." \
			| python3 scripts/slack_message.py $$SLACK_CHANNEL ${SLACK_BOT_NAME} $$SLACK_BOT_EMOJI; \
	fi
	rm -f $@__WIKIDATA_POP_CSV_WITH_TIMEOUTEXCEPTION
	touch $@

data/in/un_population.csv: | data/in ## Download United Nations population division dataset.
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/in/un_population.csv $@ --profile geocint_pipeline_sender

db/table/un_population: data/in/un_population.csv | db/table ## UN (United Nations) population division dataset imported into database.
	psql -c 'drop table if exists un_population_text;'
	psql -c 'create table un_population_text(iso text, name text, variant_id text, variant text, time text, mid_period text, pop_male text, pop_female text, pop_total text, pop_density text);'
	# Import raw UN population dataset into database
	cat data/in/un_population.csv | psql -c "copy un_population_text from stdin with csv header delimiter ',';"
	psql -c 'drop table if exists un_population;'
	# Transform raw UN population dataset into database table.
	psql -c 'create table un_population as select iso::integer, name, variant_id::integer, variant, time::integer "year", parse_float(mid_period) "mid_period", parse_float(pop_male) * 1000 "pop_male", parse_float(pop_female) * 1000 "pop_female", parse_float(pop_total) * 1000 "pop_total", parse_float(pop_density) * 1000 "pop_density" from un_population_text;'
	psql -c 'drop table if exists un_population_text;'
	touch $@

#db/table/population_check_un: db/table/un_population db/table/iso_codes | db/table
#	psql -f tables/population_check_un.sql
#	touch $@

#data/out/reports/population_check_un.csv: db/table/population_check_un | data/out/reports
#	psql -c 'copy (select * from population_check_un order by diff_pop) to stdout with csv header;' > $@
#	cat $@ | tail -n +2 | head -10 | awk -F "\"*,\"*" '{print "<https://www.openstreetmap.org/relation/" $1 "|" $2">", $7}' | { echo "Top 10 countries with population different from UN"; cat -; } | python3 scripts/slack_message.py $$SLACK_CHANNEL ${SLACK_BOT_NAME} $$SLACK_BOT_EMOJI

data/in/prescale_to_osm.csv: | data/in ## Download master table with right population values from osm
	wget -c -nc "https://docs.google.com/spreadsheets/d/1-XuFA8c3sweMhCi52tdfhepGXavimUWA7vPc3BoQb1c/export?format=csv&gid=0" -O $@

db/table/prescale_to_osm: data/in/prescale_to_osm.csv | db/table ## Load prescale_to_osm data to the table
	psql -c 'drop table if exists prescale_to_osm;'
	psql -c 'create table prescale_to_osm (osm_type text, osm_id bigint, country text, name text, url text, right_population bigint, actual_osm_pop bigint, change_date date, geom geometry);'
	cat data/in/prescale_to_osm.csv | psql -c "copy prescale_to_osm(osm_type, osm_id, country, name, url, right_population, change_date) from stdin with csv header delimiter ',';"
	touch $@

db/table/prescale_to_osm_boundaries: db/table/prescale_to_osm db/table/osm_admin_boundaries db/table/water_polygons_vector | db/table ## Check changes in osm population tags and create table with polygons|population|admin_level from prescale_to_osm and all polygons, which included in them
	psql -f tables/prescale_to_osm_boundaries.sql
	psql -q -X -t -c 'select count(*) from prescale_to_osm_boundaries where osm_id = 3311547;' > $@__IS_CHERNOBYL_AREA_EXIST
	if [ $$(cat $@__IS_CHERNOBYL_AREA_EXIST) -lt 1 ]; then echo "Chornobyl Nuclear Power Plant Zone of Alienation (osm_id 3311547) was missed. Population in 30km zome may be inaccurate. Stop pipeline." | python3 scripts/slack_message.py $$SLACK_CHANNEL ${SLACK_BOT_NAME} $$SLACK_BOT_EMOJI && exit 1; fi
	rm -f $@__IS_CHERNOBYL_AREA_EXIST
	touch $@

db/table/prescale_to_osm_check_changes: db/table/prescale_to_osm_boundaries | db/table ## Check the number of object with nonactual osm population
	psql -q -X -t -c 'select count(*) from changed_population where geom is null;' > $@__WRONG_GEOM
	psql -q -X -t -c 'select count(*) from changed_population where right_population <> actual_osm_pop;' > $@__CHANG_POP
	if [ $$(cat $@__CHANG_POP) -lt 1 ] && [ $$(cat $@__WRONG_GEOM) -lt 1 ]; then psql -c 'drop table if exists changed_population;';echo "Prescale_to_OSM_master table contains actual values" | python3 scripts/slack_message.py $$SLACK_CHANNEL ${SLACK_BOT_NAME} $$SLACK_BOT_EMOJI; fi
	if [ 0 -lt $$(cat $@__CHANG_POP) ]; then echo "Some population values in OSM was changed. Please check changed_population table." | python3 scripts/slack_message.py $$SLACK_CHANNEL ${SLACK_BOT_NAME} $$SLACK_BOT_EMOJI; fi
	if [ 0 -lt $$(cat $@__WRONG_GEOM) ]; then echo "Some geometry values is null. Please check changed_population table." | python3 scripts/slack_message.py $$SLACK_CHANNEL ${SLACK_BOT_NAME} $$SLACK_BOT_EMOJI; fi
	rm $@__CHANG_POP $@__WRONG_GEOM
	touch $@

db/procedure/decimate_admin_level_in_prescale_to_osm_boundaries: db/table/prescale_to_osm_boundaries | db/procedure ## Transform admin boundaries with raw population values into solid continuous coverage with calculated population for every feature.
	seq 2 1 26 | xargs -I {} psql -f procedures/decimate_admin_level_in_prescale_to_osm_boundaries.sql -v current_level={}
	touch $@

db/table/kontur_population_h3: db/table/osm_residential_landuse db/table/population_grid_h3_r8 db/table/building_count_grid_h3 db/table/osm_unpopulated db/table/osm_water_polygons db/function/h3 db/table/morocco_urban_pixel_mask_h3 db/index/osm_tags_idx db/procedure/decimate_admin_level_in_prescale_to_osm_boundaries | db/table  ## Kontur Population (most recent).
	psql -f tables/kontur_population_h3.sql
	touch $@

data/out/reports/population_check_world: db/table/kontur_population_h3 db/table/kontur_population_v5_h3 db/table/kontur_boundaries | data/out/reports ## Compare total population from final Kontur population dataset to previously released and send bug reports to Kontur Slack (#geocint channel).
	psql -q -X -t -c 'select sum(population) from kontur_population_v5_h3 where resolution = 0' > $@__KONTUR_POP_V5
	psql -q -X -t -c 'select sum(population) from kontur_population_h3 where resolution = 0;' > $@__KONTUR_POP_V5_1
	if [ $$(cat $@__KONTUR_POP_V5_1) -lt 8000000000 ]; then echo "*Kontur population is broken*\nless than 8 billion people" | python3 scripts/slack_message.py $$SLACK_CHANNEL ${SLACK_BOT_NAME} $$SLACK_BOT_EMOJI && exit 1; fi
	if [ $$(cat $@__KONTUR_POP_V5_1) -lt $$(cat $@__KONTUR_POP_V5) ]; then echo "Kontur population is less than the previously released" | python3 scripts/slack_message.py $$SLACK_CHANNEL ${SLACK_BOT_NAME} $$SLACK_BOT_EMOJI; fi
	echo "Actual Kontur Population total is $$(cat $@__KONTUR_POP_V5_1)" | python3 scripts/slack_message.py $$SLACK_CHANNEL ${SLACK_BOT_NAME} $$SLACK_BOT_EMOJI
	rm -f $@__KONTUR_POP_V5 $@__KONTUR_POP_V5_1
	touch $@

data/out/reports/population_check: data/out/reports/population_check_osm.csv data/out/reports/population_check_world | data/out/reports ## Common target of population checks.
	touch $@

data/in/wb/gdp/wb_gdp.zip: | data/in/wb/gdp ## Download GDP (Gross domestic product) dataset from World Bank.
	wget http://api.worldbank.org/v2/en/indicator/NY.GDP.MKTP.CD?downloadformat=xml -O $@

data/mid/wb/gdp/wb_gdp.xml: data/in/wb/gdp/wb_gdp.zip | data/mid/wb/gdp ## Unzip GDP (Gross domestic product) dataset from World Bank. Translate and rename XML file.
	unzip -o data/in/wb/gdp/wb_gdp.zip -d data/mid/wb/gdp/
	cat data/mid/wb/gdp/API_NY*.xml | tr -d '\n\r\t' | sed 's/^.\{1\}//' > $@

db/table/wb_gdp: data/mid/wb/gdp/wb_gdp.xml | db/table ## GDP (Gross domestic product) dataset from World Bank.
	# Import input XML into database
	psql -c "drop table if exists temp_xml;"
	psql -c "create table temp_xml ( value text );"
	cat data/mid/wb/gdp/wb_gdp.xml | psql -c "COPY temp_xml(value) FROM stdin DELIMITER E'\t' CSV QUOTE '''';"
	# Translate raw XML into database table
	psql -f tables/wb_gdp.sql
	psql -c "drop table if exists temp_xml;"
	touch $@

db/table/wb_gadm_gdp_countries: db/table/wb_gdp db/table/gadm_countries_boundary ## Subdivided countries boundaries with joined GDP (Gross domestic product) for the last known year data from World Bank.
	psql -f tables/wb_gadm_gdp_countries.sql
	touch $@

db/table/gdp_h3: db/table/kontur_population_h3 db/table/wb_gadm_gdp_countries ## GDP (Gross domestic product) for the last known year from World Bank distributed on H3 hexagons grid.
	psql -f tables/gdp_h3.sql
	touch $@

## Woldbank Tax Rate
db/table/worldbank_tax_rate: | db/table ## Global Worldbank Tax Rate (source https://data.worldbank.org/indicator/IC.TAX.TOTL.CP.ZS 2005-2019)
	psql -c "drop table if exists worldbank_tax_rate;"
	psql -c "create table worldbank_tax_rate (name text, hasc text, code text, indicator_name text, indicator_code text, t2005 float, t2006 float, t2007 float, t2008 float, t2009 float, t2010 float, t2011 float, t2012 float, t2013 float, t2014 float, t2015 float, t2016 float, t2017 float, t2018 float, t2019 float);"
	cat static_data/worldbank/world_bank_tax_rate_2005-2019.csv | psql -c "copy worldbank_tax_rate from stdin with csv header;"
	psql -c "create index on worldbank_tax_rate using btree(hasc);"
	touch $@

db/table/worldbank_tax_rate_h3: db/table/kontur_boundaries db/table/worldbank_tax_rate db/procedure/generate_overviews db/procedure/transform_hasc_to_h3 | db/table ## Generation overviws of worldbank_tax_rate
	psql -c "call transform_hasc_to_h3('worldbank_tax_rate', 'worldbank_tax_rate_h3', 'hasc', '{t2019}'::text[], 8);"
	psql -c "call generate_overviews('worldbank_tax_rate_h3', '{t2019}'::text[], '{max}'::text[], 8);"
	touch $@

## End Worldbank Tax Rate

data/in/water-polygons-split-3857.zip: | data/in ## Download OpenStreetMap water polygons (oceans and seas) archive.
	wget https://osmdata.openstreetmap.de/download/water-polygons-split-3857.zip -O $@
	touch $@

data/mid/water_polygons/water_polygons_shapefile: data/in/water-polygons-split-3857.zip | data/mid ## Unzip OpenStreetMap water polygons (oceans and seas) archive.
	mkdir -p data/mid/water_polygons
	unzip -jo data/in/water-polygons-split-3857.zip -d data/mid/water_polygons/
	touch $@

db/table/water_polygons_vector: data/mid/water_polygons/water_polygons_shapefile | db/table ## Subdivided OpenStreetMap water polygons (oceans and seas)(EPSG-3857).
	psql -c "drop table if exists water_polygons_vector;"
	# Import water polygons Shapefile into database
	shp2pgsql -I -s 3857 data/mid/water_polygons/water_polygons.shp water_polygons_vector | psql -q
	# Subdivide complex water polygons (ST_NPoints(geom) > 100)
	psql -f tables/water_polygons_vector.sql
	touch $@

db/table/osm_water_lines: db/index/osm_tags_idx | db/table ## Water line geometries extracted from OpenStreetMap (EPSG-3857).
	psql -f tables/osm_water_lines.sql
	touch $@

db/table/osm_water_lines_buffers_subdivided: db/table/osm_water_lines | db/table ## Buffer polygons (1m. in EPSG-3857) from Water line geometries extracted from OpenStreetMap (EPSG-3857).
	psql -f tables/osm_water_lines_buffers_subdivided.sql
	touch $@

db/table/osm_water_polygons_in_subdivided: db/index/osm_tags_idx | db/table ## Subdivided water polygons geometries extracted from OpenStreetMap (EPSG-3857).
	psql -f tables/osm_water_polygons_in_subdivided.sql
	touch $@

db/table/osm_water_polygons: db/table/osm_water_polygons_in_subdivided db/table/water_polygons_vector db/table/osm_water_lines_buffers_subdivided | db/table ## Subdivided OpenStreetMap water polygons combined from 3 datasets (linestring objects buffered out with 1m in EPSG-3857, seas and oceans subdivided and other polygonal water objects subdivided)(EPSG-3857).
	psql -f tables/osm_water_polygons.sql
	touch $@

data/in/daylight_coastlines.tgz: | data/in ## daylightmap.org/coastlines.html
	wget https://daylight-map-distribution.s3.us-west-1.amazonaws.com/release/v1.6/coastlines-v1.6.tgz -O $@

data/mid/daylight_coastlines: | data/mid ## Directory for unpacked Daylight Coastlines shapefiles
	mkdir -p $@

data/mid/daylight_coastlines/land_polygons.shp: data/in/daylight_coastlines.tgz | data/mid/daylight_coastlines ## Unpack Daylight Coastlines
	tar zxvf data/in/daylight_coastlines.tgz -C data/mid/daylight_coastlines
	touch $@

db/table/land_polygons_vector: data/mid/daylight_coastlines/land_polygons.shp | db/table ## Import land vector polygons from Daylight Coastlines in database
	psql -c "drop table if exists land_polygons_vector;"
	ogr2ogr --config PG_USE_COPY YES -overwrite -f PostgreSQL PG:"dbname=gis" -a_srs EPSG:4326 data/mid/daylight_coastlines/land_polygons.shp -nlt GEOMETRY -lco GEOMETRY_NAME=geom -nln land_polygons_vector
	touch $@

db/table/land_polygons_h3_r8: db/table/land_polygons_vector | db/table ## land h3
	psql -f tables/land_polygons_h3_r8.sql
	touch $@

db/procedure/insert_projection_54009: | db/procedure ## Add ESRI-54009 projection into spatial_ref_sys for further use.
	psql -f procedures/insert_projection_54009.sql || true
	touch $@

db/table/population_grid_h3_r8: db/table/hrsl_population_grid_h3_r8 db/table/hrsl_population_boundary db/table/ghs_globe_population_grid_h3_r8 | db/table ## General table for population data at hexagons.
	psql -f tables/population_grid_h3_r8.sql
	touch $@

db/table/osm_local_active_users: db/function/h3 db/table/osm_user_count_grid_h3 | db/table ## OpenStreetMap local active users (heuristics based on user activity).
	psql -f tables/osm_local_active_users.sql
	touch $@

db/table/user_hours_h3: db/function/h3 db/table/osm_user_count_grid_h3 db/table/osm_local_active_users | db/table ## Statistics on mapping hours (total hours and from local users only) of OpenStreetMap editors aggregated on H3 hexagon grid.
	psql -f tables/user_hours_h3.sql
	touch $@

db/table/osm_object_count_grid_h3: db/table/osm db/function/h3 db/table/osm_meta | db/table ## Object/building/line counts for OpenStreetMap that only mark the changes in last 6 months.
	psql -f tables/osm_object_count_grid_h3.sql
	touch $@

data/in/global_fires/download_firms_archive: | data/in/global_fires ## Download active fire products (FIRMS - Fire Information for Resource Management System) for last 14 months from AWS.
	# Cleanup failed downloads
	rm -f data/in/global_fires/firms_archive_*.gz.*
	# Download files for the last 13 month
	seq -s " " $$(date -u -d "13 month ago" +"%Y") $$(date -u +"%Y") | sed 's/[^ ]*/--include="firms_archive_&.csv.gz"/g' | xargs -I {} sh -c 'aws s3 sync --size-only --exclude="*" {} s3://geodata-eu-central-1-kontur/private/geocint/in/global_fires/ data/in/global_fires/ --profile geocint_pipeline_sender'
	touch $@

data/mid/global_fires/extract_firms_archive: data/in/global_fires/download_firms_archive | data/mid/global_fires ## Extract aggregated 20 years active fire products (FIRMS - Fire Information for Resource Management System).
	rm -f data/in/global_fires/firms_archive_*.csv
	pigz -dk data/in/global_fires/firms_archive_*.csv.gz
	mv data/in/global_fires/firms_archive_*.csv data/mid/global_fires/
	touch $@

### Global Fires block ###

data/in/global_fires/new_updates: | data/in ## Last updates for active fire products from FIRMS (Fire Information for Resource Management System).
	mkdir -p $@

data/in/global_fires/new_updates/download_new_updates: | data/in/global_fires/new_updates data/mid/global_fires ## Download active fire products from the MODIS (Moderate Resolution Imaging Spectroradiometer ) and VIIRS (Visible Infrared Imaging Radiometer Suite) for the last 7 days.
	wget -O - https://firms.modaps.eosdis.nasa.gov/data/active_fire/modis-c6.1/csv/MODIS_C6_1_Global_7d.csv | sed '1s/$$/,\instrument/; 2,$$s/$$/,MODIS/' > data/in/global_fires/new_updates/MODIS_C6_Global_7d.csv
	wget -O - https://firms.modaps.eosdis.nasa.gov/data/active_fire/suomi-npp-viirs-c2/csv/SUOMI_VIIRS_C2_Global_7d.csv | sed '1s/$$/,\instrument/; 2,$$s/$$/,VIIRS/' > data/in/global_fires/new_updates/SUOMI_VIIRS_C2_Global_7d.csv
	wget -O - https://firms.modaps.eosdis.nasa.gov/data/active_fire/noaa-20-viirs-c2/csv/J1_VIIRS_C2_Global_7d.csv | sed '1s/$$/,\instrument/; 2,$$s/$$/,VIIRS/' > data/in/global_fires/new_updates/J1_VIIRS_C2_Global_7d.csv
	find -L data/in/global_fires/new_updates -name "*.csv" -type f -printf "%f\n" | parallel "python3 scripts/normalize_global_fires.py data/in/global_fires/new_updates/{} > data/mid/global_fires/{}"
	rm -f data/in/global_fires/new_updates/*.csv
	touch $@

db/table/global_fires_in: data/in/global_fires/new_updates/download_new_updates data/mid/global_fires/extract_firms_archive | db/table ## Fire products from FIRMS (Fire Information for Resource Management System) aggregated, normalized and imported into database.
	psql -c "drop table if exists global_fires_in;"
	psql -c "create table global_fires_in(latitude float, longitude float, brightness float, bright_ti4 float, scan float, track float, satellite text, instrument text, confidence text, version text, bright_t31 float, bright_ti5 float, frp float, daynight text, acq_datetime timestamptz, hash text);"
	ls -S data/mid/global_fires/*.csv | parallel "cat {} | psql -c 'set time zone utc; copy global_fires_in (latitude, longitude, brightness, bright_ti4, scan, track, satellite, instrument, confidence, version, bright_t31, bright_ti5, frp, daynight, acq_datetime, hash) from stdin with csv header;'"
	psql -c "vacuum analyze global_fires_in;"
	touch $@

db/table/global_fires: db/table/global_fires_in | db/table ## Active fire products from FIRMS (Fire Information for Resource Management System) aggregated, normalized and imported into database.
	psql -f tables/global_fires.sql
	psql -1 -c "alter table global_fires rename to global_fires_old; alter table global_fires_new rename to global_fires; drop table global_fires_old;"
	psql -c "create index on global_fires using brin (acq_datetime, hash);"
	rm -f data/mid/global_fires/*.csv
	touch $@

data/out/global_fires/update: db/table/global_fires | data/out/global_fires ## Last update for active fire products.
	rm -f data/out/global_fires/firms_archive_*.csv.gz
	aws s3 ls s3://geodata-eu-central-1-kontur/private/geocint/in/global_fires/ --profile geocint_pipeline_sender | tail -1 | cut -d ' ' -f 1,2 | date +"%s" -f - > $@__LAST_DEPLOY_TS
	if [ $$(cat $@__LAST_DEPLOY_TS) -lt $$(date -d "1 week ago" +"%s") ]; then echo '*Global Fires* broken. Latest data for *'$$(cat $@__LAST_DEPLOY_TS | xargs -I {} date -d @{} -u +"%Y-%m-%d")'*. See section <https://gitlab.com/kontur-private/platform/geocint/#manual-update-of-global-fires|"Manual update of Global Fires"> in README.md' | python3 scripts/slack_message.py $$SLACK_CHANNEL ${SLACK_BOT_NAME} $$SLACK_BOT_EMOJI; fi
	seq $$(cat $@__LAST_DEPLOY_TS | xargs -I {}  date -u -d @{} +"%Y") $$(date -u +"%Y") | parallel --eta "psql -qXc 'set time zone utc; copy (select * from global_fires where acq_datetime >= '\''{}-01-01'\'' and acq_datetime < '\''{}-01-01'\''::date + interval '\''1 year'\'' order by acq_datetime, hash) to stdout with csv header;' | pigz -9 > data/out/global_fires/firms_archive_{}.csv.gz"
	rm -f $@__LAST_DEPLOY_TS
	touch $@

deploy/s3/global_fires: data/out/global_fires/update | deploy/s3 ## Deploy update for active fire products to S3.
	aws s3 sync --size-only --exclude="*" --include "firms_archive_*.csv.gz" data/out/global_fires/ s3://geodata-eu-central-1-kontur/private/geocint/in/global_fires/ --profile geocint_pipeline_sender
	touch $@

db/table/global_fires_stat_h3: deploy/s3/global_fires ## Aggregate active fire data from FIRMS (Fire Information for Resource Management System) on H3 hexagon grid.
	psql -f tables/global_fires_stat_h3.sql
	touch $@

### END Global Fires block ###

data/in/microsoft_buildings: | data/in ## Microsoft Building Footprints dataset (input).
	mkdir -p $@

data/in/microsoft_buildings/download: | data/in/microsoft_buildings ## Download Microsoft Building Footprints dataset.
	grep -h -v '^#' static_data/microsoft_buildings/*.txt | parallel --eta 'wget -q -c -nc -P data/in/microsoft_buildings {}'
	touch $@

data/in/microsoft_buildings/validity_controlled: data/in/microsoft_buildings/download | data/in/microsoft_buildings ## Check downloaded Microsoft Building Footprints archives.
	ls -1 data/in/microsoft_buildings/*.zip | parallel --halt now,fail=1 unzip -t {}
	touch $@

db/table/microsoft_buildings: data/in/microsoft_buildings/validity_controlled | db/table  ## Microsoft Building Footprints dataset imported into database.
	psql -c "drop table if exists microsoft_buildings;"
	psql -c "create table microsoft_buildings(filename text, geom geometry(Geometry,4326));"
	find data/in/microsoft_buildings/* -type f -name "*.zip" -printf '%s\t%p\n' | sort -r -n | cut -f2- | sed -r 's/(.*\/(.*)\.(.*)$$)/ogr2ogr -append -f PostgreSQL --config PG_USE_COPY YES PG:"dbname=gis" "\/vsizip\/\1" -sql "select '\''\2'\'' as filename, * from \\"\2\\"" -nln microsoft_buildings -a_srs EPSG:4326/' | parallel --eta '{}'
	psql -c "vacuum analyze microsoft_buildings;"
	touch $@

db/table/microsoft_buildings_h3: db/table/microsoft_buildings | db/table ## Count amount of Microsoft Buildings at hexagons.
	psql -f tables/count_items_in_h3.sql -v table=microsoft_buildings -v table_h3=microsoft_buildings_h3 -v item_count=building_count
	touch $@

data/in/new_zealand_buildings: | data/in ## New Zealand's buildings dataset from LINZ (Land Information New Zealand).
	mkdir -p $@

data/in/new_zealand_buildings/data-land-information-new-zealand-govt-nz-building-outlines-120923.gpkg: | data/in/new_zealand_buildings ## Download New Zealand's buildings from AWS S3 bucket.
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/in/data-land-information-new-zealand-govt-nz-building-outlines-120923.gpkg.gz data/in/new_zealand_buildings/data-land-information-new-zealand-govt-nz-building-outlines-120923.gpkg.gz --profile geocint_pipeline_sender
	pigz -d data/in/new_zealand_buildings/data-land-information-new-zealand-govt-nz-building-outlines-120923.gpkg.gz

db/table/new_zealand_buildings: data/in/new_zealand_buildings/data-land-information-new-zealand-govt-nz-building-outlines-120923.gpkg | db/table ## Create table with New Zealand buildings.
	psql -c "drop table if exists new_zealand_buildings;"
	time ogr2ogr -f --config PG_USE_COPY YES PostgreSQL PG:"dbname=gis" data/in/new_zealand_buildings/data-land-information-new-zealand-govt-nz-building-outlines-120923.gpkg -nln new_zealand_buildings -lco GEOMETRY_NAME=geom
	touch $@

db/table/new_zealand_buildings_h3: db/table/new_zealand_buildings ## Count amount of New Zealand buildings at hexagons.
	psql -f tables/count_items_in_h3.sql -v table=new_zealand_buildings -v table_h3=new_zealand_buildings_h3 -v item_count=building_count
	touch $@

data/in/geoalert_urban_mapping: | data/in ## Geoalert Urban mapping datasets.
	mkdir -p $@

data/in/geoalert_urban_mapping/download: | data/in/geoalert_urban_mapping  ## Download Geoalert Urban mapping datasets.
	cat geoalert_buildings/url_filename.txt | parallel --colsep ' ' "wget -q {1} -O data/in/geoalert_urban_mapping/{2}"
	touch $@

data/mid/geoalert_urban_mapping: | data/mid  ## Geoalert Urban mapping datasets processed.
	mkdir -p $@

data/mid/geoalert_urban_mapping/unzip: data/in/geoalert_urban_mapping/download | data/mid/geoalert_urban_mapping  ## Unzip Geoalert Urban mapping datasets.
	ls data/in/geoalert_urban_mapping/*.zip | parallel "unzip -o {} -d data/mid/geoalert_urban_mapping/"
	touch $@

db/table/geoalert_urban_mapping: data/mid/geoalert_urban_mapping/unzip | db/table  ## Geoalert Urban mapping datasets imported into database.
	psql -c "drop table if exists geoalert_urban_mapping;"
	psql -c "create table geoalert_urban_mapping (fid serial not null, class_id integer, processing_date timestamptz, is_osm boolean, geom geometry);"
	cd data/mid/geoalert_urban_mapping; ls *.gpkg | parallel 'ogr2ogr --config PG_USE_COPY YES -append -f PostgreSQL PG:"dbname=gis" {} -nln geoalert_urban_mapping -lco GEOMETRY_NAME=geom'
	touch $@

db/table/geoalert_urban_mapping_h3: db/table/geoalert_urban_mapping | db/table ## Amount of Geoalert buildings at H3 hexagons.
	psql -f tables/count_items_in_h3.sql -v table=geoalert_urban_mapping -v table_h3=geoalert_urban_mapping_h3 -v item_count=building_count
	touch $@

data/out/kontur_population.gpkg.gz: db/table/kontur_population_h3 | data/out  ## Kontur Population (most recent) geopackage archive.
	rm -f $@
	rm -f data/out/kontur_population.gpkg
	ogr2ogr \
		-f GPKG \
		-sql "select h3, population, geom from kontur_population_h3 where population > 0 and resolution = 8 order by h3" \
		-lco "SPATIAL_INDEX=NO" \
		-nln population \
		-gt 65536 \
		data/out/kontur_population.gpkg \
		PG:'dbname=gis'
	pigz data/out/kontur_population.gpkg

data/out/kontur_population_r6.gpkg.gz: db/table/kontur_population_h3 | data/out  ## Kontur Population (most recent) geopackage archive at 6th resolution.
	rm -f $@
	rm -f data/out/kontur_population_r6.gpkg
	ogr2ogr \
		-f GPKG \
		-sql "select h3, population, geom from kontur_population_h3 where population > 0 and resolution = 6 order by h3" \
		-lco "SPATIAL_INDEX=YES" \
		-nln population \
		-gt 65536 \
		data/out/kontur_population_r6.gpkg \
		PG:'dbname=gis'
	pigz data/out/kontur_population_r6.gpkg

data/out/kontur_population_r4.gpkg.gz: db/table/kontur_population_h3 | data/out  ## Kontur Population (most recent) geopackage archive at 4th resolution.
	rm -f $@
	rm -f data/out/kontur_population_r4.gpkg
	ogr2ogr \
		-f GPKG \
		-sql "select h3, population, geom from kontur_population_h3 where population > 0 and resolution = 4 order by h3" \
		-lco "SPATIAL_INDEX=YES" \
		-nln population \
		-gt 65536 \
		data/out/kontur_population_r4.gpkg \
		PG:'dbname=gis'
	pigz data/out/kontur_population_r4.gpkg

data/out/kontur_population_per_country: | data/out ## Directory for per country extraction from kontur_boundaries
	mkdir -p $@

data/out/kontur_population_per_country/gpkg_export_commands.txt: | data/out/kontur_population_per_country ## Create file with per country extraction commands
	cat static_data/kontur_boundaries/hdx_locations.csv | \
		parallel --colsep ';' \
			'echo "\
				ogr2ogr \
					-f GPKG \
					-overwrite \
					-sql *select h3, population, geom from kontur_population_export where location = %"{3}"%;* \
					-lco *SPATIAL_INDEX=NO* \
					-nln population \
					-gt 65536 \
					data/out/kontur_population_per_country/kontur_population_"{3}"_$(current_date).gpkg \
					PG:*dbname=gis*"' \
				| sed -r 's/[\*]+/\"/g' | sed -r "s/[\%]+/\'/g" > $@
	sed -i '1d' $@

data/out/kontur_population_per_country/export: data/out/kontur_population_per_country/gpkg_export_commands.txt db/table/hdx_boundaries db/table/kontur_population_h3 | data/out/kontur_population_per_country ## Per country H3 r8 extraction with population
	psql -f tables/kontur_population_export.sql
	rm -f data/out/kontur_population_per_country/*.gpkg*
	cat data/out/kontur_population_per_country/gpkg_export_commands.txt | parallel '{}'
	psql -c "drop table if exists kontur_population_export;"
	touch $@

data/in/kontur_population_v5: | data/in ## Kontur Population v5 (input).
	mkdir -p $@

data/in/kontur_population_v5/kontur_population_20231101.gpkg.gz: | data/in/kontur_population_v5 ## Download Kontur Population v5 gzip to geocint.
	rm -rf $@
	wget -c -nc https://geodata-eu-central-1-kontur-public.s3.eu-central-1.amazonaws.com/kontur_datasets/kontur_population_20231101.gpkg.gz -O $@

data/mid/kontur_population_v5: | data/mid ## Kontur Population v5 dataset.
	mkdir -p $@

data/mid/kontur_population_v5/kontur_population_20231101.gpkg: data/in/kontur_population_v5/kontur_population_20231101.gpkg.gz | data/mid/kontur_population_v5 ## Unzip Kontur Population v5 geopackage archive.
	gzip -dck data/in/kontur_population_v5/kontur_population_20231101.gpkg.gz > $@

db/table/kontur_population_v5: data/mid/kontur_population_v5/kontur_population_20231101.gpkg | db/table ## Import population v5 into database.
	psql -c "drop table if exists kontur_population_v5;"
	ogr2ogr --config PG_USE_COPY YES -f PostgreSQL PG:'dbname=gis' data/mid/kontur_population_v5/kontur_population_20231101.gpkg -t_srs EPSG:4326 -nln kontur_population_v5 -lco GEOMETRY_NAME=geom
	touch $@

db/table/kontur_population_v5_h3: db/table/kontur_population_v5 db/procedure/generate_overviews | db/table ## Generate h3 hexagon for population v5.
	psql -f tables/kontur_population_v5_h3.sql
	psql -c "call generate_overviews('kontur_population_v5_h3', '{population}'::text[], '{sum}'::text[], 8);"
	touch $@

data/out/kontur_population_v5_r6.gpkg.gz: db/table/kontur_population_v5_h3 | data/out  ## Kontur Population v5 geopackage archive at 6th resolution.
	rm -f $@
	rm -f data/out/kontur_population_v5_r6.gpkg
	ogr2ogr \
		-f GPKG \
		-sql "select h3, population, st_transform(h3_cell_to_boundary_geometry(h3), 3857) from kontur_population_v5_h3 where population > 0 and resolution = 6 order by h3" \
		-lco "SPATIAL_INDEX=YES" \
		-nln population \
		-gt 65536 \
		data/out/kontur_population_v5_r6.gpkg \
		PG:'dbname=gis'
	pigz data/out/kontur_population_v5_r6.gpkg

data/out/kontur_population_v5_r4.gpkg.gz: db/table/kontur_population_v5_h3 | data/out  ## Kontur Population v5 geopackage archive at 4th resolution.
	rm -f $@
	rm -f data/out/kontur_population_v5_r4.gpkg
	ogr2ogr \
		-f GPKG \
		-sql "select h3, population, st_transform(h3_cell_to_boundary_geometry(h3), 3857) from kontur_population_v5_h3 where population > 0 and resolution = 4 order by h3" \
		-lco "SPATIAL_INDEX=YES" \
		-nln population \
		-gt 65536 \
		data/out/kontur_population_v5_r4.gpkg \
		PG:'dbname=gis'
	pigz data/out/kontur_population_v5_r4.gpkg

data/out/kontur_population_v5.csv: db/table/kontur_population_v5_h3 | data/out  ## Kontur Population v5 csv at 8th resolution.
	rm -f $@
	psql -qXc 'copy (select "h3", "population" from kontur_population_v5_h3 where resolution=8 order by h3) to stdout with (format csv, header true, delimiter ",");' > $@
	touch $@

data/out/kontur_population_v5_r6.csv: db/table/kontur_population_v5_h3 | data/out  ## Kontur Population v5 csv at 6th resolution.
	rm -f $@
	psql -qXc 'copy (select "h3", "population" from kontur_population_v5_h3 where resolution=6 order by h3) to stdout with (format csv, header true, delimiter ",");' > $@
	touch $@

data/out/kontur_population_v5_r4.csv: db/table/kontur_population_v5_h3 | data/out  ## Kontur Population v5 csv at 4th resolution.
	rm -f $@
	psql -qXc 'copy (select "h3", "population" from kontur_population_v5_h3 where resolution=4 order by h3) to stdout with (format csv, header true, delimiter ",");' > $@
	touch $@

### Morocco data block ###

data/in/morocco_buildings: | data/in ## morocco_buildings input data.
	mkdir -p $@

data/in/morocco_buildings/morocco_urban_pixel_mask.gpkg: | data/in/morocco_buildings ## morocco_urban_pixel_mask downloaded.
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/in/morocco_buildings/morocco_urban_pixel_mask.gpkg $@ --profile geocint_pipeline_sender
	touch $@

db/table/morocco_urban_pixel_mask: data/in/morocco_buildings/morocco_urban_pixel_mask.gpkg | db/table ## Morocco rough urban territories vector layer from Geoalert.
	ogr2ogr -f PostgreSQL PG:"dbname=gis" data/in/morocco_buildings/morocco_urban_pixel_mask.gpkg
	touch $@

db/table/morocco_urban_pixel_mask_h3: db/table/morocco_urban_pixel_mask ## Morocco urban pixel mask aggregated count on H3 hexagons grid.
	psql -f tables/morocco_urban_pixel_mask_h3.sql
	touch $@

data/in/morocco_buildings/morocco_all_tables.sql.gz: | data/in/morocco_buildings ## morocco tables dump download.
	rm -f $@
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/in/morocco_buildings/morocco_all_tables.sql.gz $@ --profile geocint_pipeline_sender	

data/in/morocco_buildings/morocco_all_tables.sql: data/in/morocco_buildings/morocco_all_tables.sql.gz ## morocco all table dump download.
	rm -f $@
	gzip -dck data/in/morocco_buildings/morocco_all_tables.sql.gz > $@

db/table/morocco_all_tables: data/in/morocco_buildings/morocco_all_tables.sql | db/table ## restore all morocco tables from dump
	psql < data/in/morocco_buildings/morocco_all_tables.sql
	touch $@

db/table/morocco_buildings_manual_roofprints: static_data/morocco_buildings/morocco_buildings_manual_roof_20201030.geojson ## Morocco manually split roofprints of buildings for verification of automatically traced Geoalert building datasets (EPSG-3857).
	psql -c "drop table if exists morocco_buildings_manual_roofprints;"
	ogr2ogr -f PostgreSQL PG:"dbname=gis" static_data/morocco_buildings/morocco_buildings_manual_roof_20201030.geojson -nln morocco_buildings_manual_roofprints
	psql -c "alter table morocco_buildings_manual_roofprints rename column wkb_geometry to geom;"
	psql -c "alter table morocco_buildings_manual_roofprints alter column geom type geometry;"
	psql -c "update morocco_buildings_manual_roofprints set geom = ST_Transform(geom, 3857);"
	touch $@

db/table/morocco_buildings_manual: static_data/morocco_buildings/morocco_buildings_manual_20201030.geojson  ## Morocco manually split footprints of buildings for verification of automatically traced Geoalert building datasets (EPSG-3857).
	psql -c "drop table if exists morocco_buildings_manual;"
	ogr2ogr -f PostgreSQL PG:"dbname=gis" static_data/morocco_buildings/morocco_buildings_manual_20201030.geojson -nln morocco_buildings_manual
	psql -c "alter table morocco_buildings_manual rename column wkb_geometry to geom;"
	psql -c "alter table morocco_buildings_manual alter column geom type geometry;"
	psql -c "update morocco_buildings_manual set geom = ST_CollectionExtract(ST_MakeValid(ST_Transform(geom, 3857)), 3) where ST_SRID(geom) != 3857 or not ST_IsValid(geom);"
	touch $@

data/in/morocco_buildings/geoalert_morocco_stage_3.gpkg: | data/in/morocco_buildings ## Geoalert building dataset for Morocco (Phase 3) downloaded.
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/in/morocco_buildings/geoalert_morocco_stage_3.gpkg $@ --profile geocint_pipeline_sender
	touch $@

db/table/morocco_buildings: data/in/morocco_buildings/geoalert_morocco_stage_3.gpkg db/table/morocco_all_tables | db/table  ## Automatically traced Geoalert building dataset for Morocco (Phase 3) imported into database.
	psql -c "drop table if exists morocco_buildings;"
	ogr2ogr --config PG_USE_COPY YES -f PostgreSQL PG:"dbname=gis" data/in/morocco_buildings/geoalert_morocco_stage_3.gpkg "buildings_3" -nln morocco_buildings
	psql -f tables/morocco_buildings.sql
	touch $@

db/table/morocco_buildings_h3: db/table/morocco_buildings | db/table  ## Count amount of Morocco buildings at hexagons.
	psql -f tables/count_items_in_h3.sql -v table=morocco_buildings -v table_h3=morocco_buildings_h3 -v item_count=building_count
	touch $@

data/out/morocco_buildings/morocco_buildings_footprints_phase3.geojson.gz: db/table/morocco_buildings | data/out/morocco_buildings ## Export to GEOJSON and archive Geoalert building dataset for Morocco (Phase 3).
	rm -f $@ data/out/morocco_buildings/morocco_buildings_footprints_phase3.geojson
	ogr2ogr -f GeoJSON data/out/morocco_buildings/morocco_buildings_footprints_phase3.geojson PG:"dbname=gis" -sql "select ST_Transform(geom, 4326) as footprint, building_height, height_confidence, is_residential, imagery_vintage, height_is_valid from morocco_buildings_date" -nln morocco_buildings_footprints_phase3
	cd data/out/morocco_buildings; pigz morocco_buildings_footprints_phase3.geojson

db/table/morocco_buildings_benchmark: static_data/morocco_buildings/phase_3/footprints/agadir_footprints_benchmark_ph3.geojson static_data/morocco_buildings/phase_3/footprints/casablanca_footprints_benchmark_ph3.geojson static_data/morocco_buildings/phase_3/footprints/chefchaouen_footprints_benchmark_ph3.geojson static_data/morocco_buildings/phase_3/footprints/fes_footprints_benchmark_ph3.geojson static_data/morocco_buildings/phase_3/footprints/meknes_footprints_benchmark_ph3.geojson | db/table ## Detected benchmark from old satellite imagery (EPSG-3857).
	psql -c "drop table if exists morocco_buildings_benchmark;"
	ogr2ogr -f PostgreSQL PG:"dbname=gis" static_data/morocco_buildings/phase_3/footprints/agadir_footprints_benchmark_ph3.geojson -nln morocco_buildings_benchmark
	psql -c "alter table morocco_buildings_benchmark add column city text;"
	psql -c "alter table morocco_buildings_benchmark alter column wkb_geometry type geometry;"
	psql -c "update morocco_buildings_benchmark set city = 'Agadir' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" static_data/morocco_buildings/phase_3/footprints/casablanca_footprints_benchmark_ph3.geojson -nln morocco_buildings_benchmark
	psql -c "update morocco_buildings_benchmark set city = 'Casablanca' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" static_data/morocco_buildings/phase_3/footprints/chefchaouen_footprints_benchmark_ph3.geojson -nln morocco_buildings_benchmark
	psql -c "update morocco_buildings_benchmark set city = 'Chefchaouen' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" static_data/morocco_buildings/phase_3/footprints/fes_footprints_benchmark_ph3.geojson -nln morocco_buildings_benchmark
	psql -c "update morocco_buildings_benchmark set city = 'Fes' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" static_data/morocco_buildings/phase_3/footprints/meknes_footprints_benchmark_ph3.geojson -nln morocco_buildings_benchmark
	psql -c "update morocco_buildings_benchmark set city = 'Meknes' where city is null;"
	psql -f tables/morocco_buildings_benchmark.sql -v morocco_buildings=morocco_buildings_benchmark
	touch $@

db/table/morocco_buildings_benchmark_roofprints: static_data/morocco_buildings/phase_3/roofprints/agadir_roofptints_benchmark_ph3.geojson static_data/morocco_buildings/phase_3/roofprints/casablanca_roofptints_benchmark_ph3.geojson static_data/morocco_buildings/phase_3/roofprints/chefchaouen_roofptints_benchmark_ph3.geojson static_data/morocco_buildings/phase_3/roofprints/fes_roofptints_benchmark_ph3.geojson static_data/morocco_buildings/phase_3/roofprints/meknes_roofptints_benchmark_ph3.geojson | db/table ## Separate datasets of Morocco cities buildings roofrints combined together and imported into database (for further benchmarking automatically segmentized buildings) (EPSG-3857).
	psql -c "drop table if exists morocco_buildings_benchmark_roofprints;"
	ogr2ogr -f PostgreSQL PG:"dbname=gis" static_data/morocco_buildings/phase_3/roofprints/agadir_roofptints_benchmark_ph3.geojson -nln morocco_buildings_benchmark_roofprints
	psql -c "alter table morocco_buildings_benchmark_roofprints add column city text;"
	psql -c "alter table morocco_buildings_benchmark_roofprints alter column wkb_geometry type geometry;"
	psql -c "update morocco_buildings_benchmark_roofprints set city = 'Agadir' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" static_data/morocco_buildings/phase_3/roofprints/casablanca_roofptints_benchmark_ph3.geojson -nln morocco_buildings_benchmark_roofprints
	psql -c "update morocco_buildings_benchmark_roofprints set city = 'Casablanca' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" static_data/morocco_buildings/phase_3/roofprints/chefchaouen_roofptints_benchmark_ph3.geojson -nln morocco_buildings_benchmark_roofprints
	psql -c "update morocco_buildings_benchmark_roofprints set city = 'Chefchaouen' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" static_data/morocco_buildings/phase_3/roofprints/fes_roofptints_benchmark_ph3.geojson -nln morocco_buildings_benchmark_roofprints
	psql -c "update morocco_buildings_benchmark_roofprints set city = 'Fes' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" static_data/morocco_buildings/phase_3/roofprints/meknes_roofptints_benchmark_ph3.geojson -nln morocco_buildings_benchmark_roofprints
	psql -c "update morocco_buildings_benchmark_roofprints set city = 'Meknes' where city is null;"
	psql -f tables/morocco_buildings_benchmark.sql -v morocco_buildings=morocco_buildings_benchmark_roofprints
	touch $@

db/table/morocco_buildings_extents: static_data/morocco_buildings/extents/agadir_extents.geojson static_data/morocco_buildings/extents/casablanca_extents.geojson static_data/morocco_buildings/extents/chefchaouen_extents.geojson static_data/morocco_buildings/extents/fes_extents.geojson static_data/morocco_buildings/extents/meknes_extents.geojson | db/table ## Combined (for all cities) area of interest as extent mask area from Geoalert's repository (EPSG-3857).
	psql -c "drop table if exists morocco_buildings_extents;"
	ogr2ogr -f PostgreSQL PG:"dbname=gis" static_data/morocco_buildings/extents/agadir_extents.geojson -a_srs EPSG:3857 -nln morocco_buildings_extents
	psql -c "alter table morocco_buildings_extents add column city text;"
	psql -c "alter table morocco_buildings_extents alter column wkb_geometry type geometry;"
	psql -c "update morocco_buildings_extents set city = 'Agadir' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" static_data/morocco_buildings/extents/casablanca_extents.geojson -a_srs EPSG:3857 -nln morocco_buildings_extents
	psql -c "update morocco_buildings_extents set city = 'Casablanca' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" static_data/morocco_buildings/extents/chefchaouen_extents.geojson -a_srs EPSG:3857 -nln morocco_buildings_extents
	psql -c "update morocco_buildings_extents set city = 'Chefchaouen' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" static_data/morocco_buildings/extents/fes_extents.geojson -a_srs EPSG:3857 -nln morocco_buildings_extents
	psql -c "update morocco_buildings_extents set city = 'Fes' where city is null;"
	ogr2ogr -append -f PostgreSQL PG:"dbname=gis" static_data/morocco_buildings/extents/meknes_extents.geojson -a_srs EPSG:3857 -nln morocco_buildings_extents
	psql -c "update morocco_buildings_extents set city = 'Meknes' where city is null;"
	psql -c "alter table morocco_buildings_extents rename column wkb_geometry to geom; update morocco_buildings_extents set geom = ST_Transform(geom, 3857);"
	touch $@

db/table/morocco_buildings_footprints_phase3_clipped: db/table/morocco_buildings db/table/morocco_buildings_extents ## Buildings footprints from Geoalert sampled from Morocco buildings dataset for further benchmarking (EPSG-3857).
	psql -c "drop table if exists morocco_buildings_footprints_phase3_clipped;"
	psql -c "create table morocco_buildings_footprints_phase3_clipped as (select a.* from morocco_buildings a join morocco_buildings_extents b on ST_Intersects(a.geom, ST_Transform(b.geom, 4326)));"
	psql -c "update morocco_buildings_footprints_phase3_clipped set geom = ST_CollectionExtract(ST_MakeValid(ST_Transform(geom, 3857)), 3) where ST_SRID(geom) != 3857 or not ST_IsValid(geom);"
	touch $@

db/table/morocco_buildings_manual_roofprints_phase3: static_data/morocco_buildings/phase_3/fes_meknes_height_patch.geojson db/table/morocco_buildings_manual_roofprints | db/table ## Buildings roofprints from Geoalert sampled from Morocco buildings dataset for further benchmarking (EPSG-3857).
	psql -c "drop table if exists morocco_buildings_manual_roofprints_phase3;"
	psql -c "create table morocco_buildings_manual_roofprints_phase3 as (select * from morocco_buildings_manual_roofprints);"
	psql -c "drop table if exists fes_meknes_height_patch;"
	ogr2ogr -f PostgreSQL PG:"dbname=gis" static_data/morocco_buildings/phase_3/fes_meknes_height_patch.geojson -nln fes_meknes_height_patch
	psql -c "alter table fes_meknes_height_patch alter column wkb_geometry type geometry;"
	psql -c "update fes_meknes_height_patch set wkb_geometry = ST_Transform(wkb_geometry, 3857);"
	psql -c "update morocco_buildings_manual_roofprints_phase3 a set building_height = machine_height, is_confident = true from fes_meknes_height_patch b where ST_Intersects(ST_PointOnSurface(a.geom), wkb_geometry) and better = 'robo';"
	psql -c "update morocco_buildings_manual_roofprints_phase3 a set is_confident = false from fes_meknes_height_patch b where ST_Intersects(ST_PointOnSurface(a.geom), wkb_geometry) and better = 'wtf';"
	psql -c "update morocco_buildings_manual_roofprints_phase3 a set is_confident = true from fes_meknes_height_patch b where ST_Intersects(ST_PointOnSurface(a.geom), wkb_geometry) and better = 'man';"
	psql -c "update morocco_buildings_manual_roofprints_phase3 set geom = ST_CollectionExtract(ST_MakeValid(ST_Transform(geom, 3857)), 3) where ST_SRID(geom) != 3857 or not ST_IsValid(geom);"
	touch $@

db/table/morocco_buildings_iou: db/table/morocco_buildings_benchmark_roofprints db/table/morocco_buildings_benchmark db/table/morocco_buildings_manual_roofprints db/table/morocco_buildings_manual db/table/morocco_buildings_extents db/table/morocco_buildings_footprints_phase3_clipped db/table/morocco_buildings_manual_roofprints_phase3 | data/out/morocco_buildings ## Calculation IoU metrics for all buildings from Morocco dateset test benchmark
	rm -f data/out/morocco_buildings/metric_storage.csv
	psql -f tables/morocco_buildings_iou.sql -v reference_buildings_table=morocco_buildings_manual_roofprints_phase3 -v examinee_buildings_table=morocco_buildings_benchmark_roofprints -v benchmark_clip_table=morocco_buildings_extents -v type=roof
	echo "morocco_buildings_manual_roofprints_phase3 & morocco_buildings_benchmark_roofprints tables, type=roof" > data/out/morocco_buildings/metric_storage.csv
	psql -q -c '\crosstabview' -A -F "," -c "select city, metric, value from metrics_storage order by 1;" | head -6 >> data/out/morocco_buildings/metric_storage.csv
	psql -f tables/morocco_buildings_iou.sql -v reference_buildings_table=morocco_buildings_manual -v examinee_buildings_table=morocco_buildings_benchmark -v benchmark_clip_table=morocco_buildings_extents -v type=foot
	echo "morocco_buildings_manual & morocco_buildings_benchmark tables, type=foot" >> data/out/morocco_buildings/metric_storage.csv
	psql -q -c '\crosstabview' -A -F "," -c "select city, metric, value from metrics_storage order by 1;" | head -6 >> data/out/morocco_buildings/metric_storage.csv
	echo "morocco_buildings_manual & morocco_buildings_footprints_phase3_clipped tables, type=foot" >> data/out/morocco_buildings/metric_storage.csv
	psql -f tables/morocco_buildings_iou.sql -v reference_buildings_table=morocco_buildings_manual -v examinee_buildings_table=morocco_buildings_footprints_phase3_clipped -v benchmark_clip_table=morocco_buildings_extents -v type=foot
	psql -q -c '\crosstabview' -A -F "," -c "select city, metric, value from metrics_storage order by 1;" | head -6 >> data/out/morocco_buildings/metric_storage.csv
	touch $@

data/out/morocco_buildings/morocco_buildings_manual_phase2.geojson.gz: db/table/morocco_buildings_iou db/table/morocco_buildings_manual | data/out/morocco_buildings  ## Morocco Buildings footprints from Geoalert imported into database for further benchmarking(phase 2)(EPSG-3857).
	rm -f $@
	ogr2ogr -f GeoJSON data/out/morocco_buildings/morocco_buildings_manual_phase2.geojson PG:'dbname=gis' -sql 'select ST_Transform(footprint, 4326), building_height, city, is_confident from morocco_buildings_manual_extent' -nln morocco_buildings_manual_phase2
	cd data/out/morocco_buildings; pigz morocco_buildings_manual_phase2.geojson

data/out/morocco_buildings/morocco_buildings_manual_roofprints_phase2.geojson.gz: db/table/morocco_buildings_iou db/table/morocco_buildings_manual_roofprints | data/out/morocco_buildings  ## Morocco Buildings roofprints from Geoalert imported into database for further benchmarking (phase 2)(EPSG-3857).
	rm -f $@
	ogr2ogr -f GeoJSON data/out/morocco_buildings/morocco_buildings_manual_roofprints_phase2.geojson PG:'dbname=gis' -sql 'select ST_Transform(geom, 4326), building_height, city, is_confident from morocco_buildings_manual_roofprints_extent' -nln morocco_buildings_manual_roofprints_phase2
	cd data/out/morocco_buildings; pigz morocco_buildings_manual_roofprints_phase2.geojson

data/out/morocco_buildings/morocco_buildings_benchmark_phase2.geojson.gz: db/table/morocco_buildings_benchmark | data/out/morocco_buildings ## Benchmarks on Morocco Buildings footprints from Geoalert (phase 2)(EPSG-3857).
	rm -f $@
	ogr2ogr -f GeoJSON data/out/morocco_buildings/morocco_buildings_benchmark_phase2.geojson PG:'dbname=gis' -sql 'select ST_Transform(geom, 4326), building_height, city, height_confidence, is_residential from morocco_buildings_benchmark' -nln morocco_buildings_benchmark
	cd data/out/morocco_buildings; pigz morocco_buildings_benchmark_phase2.geojson

data/out/morocco_buildings/morocco_buildings_benchmark_roofprints_phase2.geojson.gz: db/table/morocco_buildings_benchmark_roofprints | data/out/morocco_buildings ## Benchmarks on Morocco Buildings roofprints from Geoalert (phase 2)(EPSG-3857).
	rm -f $@
	ogr2ogr -f GeoJSON data/out/morocco_buildings/morocco_buildings_benchmark_roofprints_phase2.geojson PG:'dbname=gis' -sql 'select ST_Transform(geom, 4326), building_height, city, height_confidence, is_residential from morocco_buildings_benchmark_roofprints' -nln morocco_buildings_benchmark_roofprints
	cd data/out/morocco_buildings; pigz morocco_buildings_benchmark_roofprints_phase2.geojson

data/out/morocco: data/out/morocco_buildings/morocco_buildings_footprints_phase3.geojson.gz data/out/morocco_buildings/morocco_buildings_benchmark_roofprints_phase2.geojson.gz data/out/morocco_buildings/morocco_buildings_benchmark_phase2.geojson.gz data/out/morocco_buildings/morocco_buildings_manual_roofprints_phase2.geojson.gz data/out/morocco_buildings/morocco_buildings_manual_phase2.geojson.gz | data/out ## Flag all Morocco buildings output datasets are exported.
	touch $@

### END Morocco Data block ###

## start Abu Dhabi block

db/table/abu_dhabi_admin_boundaries: db/table/osm db/index/osm_tags_idx db/table/gadm_countries_boundary | db/table ## Abu Dhabi admin boundaries extracted from GADM (Database of Global Administrative Areas).
	psql -f tables/abu_dhabi_admin_boundaries.sql
	touch $@

db/table/abu_dhabi_eatery: db/table/osm db/index/osm_tags_idx db/table/abu_dhabi_admin_boundaries | db/table ## Abu Dhabi eatery extracted from OpenStreetMap.
	psql -f tables/abu_dhabi_eatery.sql
	touch $@

db/table/abu_dhabi_food_shops: db/table/osm db/index/osm_tags_idx db/table/abu_dhabi_admin_boundaries | db/table ## Abu Dhabi food shops extracted from OpenStreetMap.
	psql -f tables/abu_dhabi_food_shops.sql
	touch $@

db/table/abu_dhabi_bivariate_pop_food_shops: db/table/abu_dhabi_eatery db/table/abu_dhabi_food_shops db/table/kontur_population_h3 | db/table ## H3 bivariate layer with population vs food shops for Abu Dhabi.
	psql -f tables/abu_dhabi_bivariate_pop_food_shops.sql
	touch $@

data/in/abu_dhabi_geoalert_v4.geojson: | data/in ## Download buildings dataset from Geoalert for Abu Dhabi.
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/in/abu_dhabi_geoalert_v4.geojson $@ --profile geocint_pipeline_sender

db/table/abu_dhabi_buildings: data/in/abu_dhabi_geoalert_v4.geojson | db/table ## Buildings dataset from Geoalert for Abu Dhabi imported into database.
	ogr2ogr --config PG_USE_COPY YES -overwrite -f PostgreSQL PG:"dbname=gis" data/in/abu_dhabi_geoalert_v4.geojson -nln abu_dhabi_buildings -lco GEOMETRY_NAME=geom
	touch $@

db/table/abu_dhabi_buildings_h3: db/table/abu_dhabi_buildings | db/table ## Amount of buildings dataset from Geoalert for Abu Dhabi at H3 hexagons.
	psql -f tables/count_items_in_h3.sql -v table=abu_dhabi_buildings -v table_h3=abu_dhabi_buildings_h3 -v item_count=building_count
	touch $@

data/out/abu_dhabi: | data/out ## Directory for Abu Dhabi datasets output.
	mkdir -p $@

data/out/abu_dhabi/abu_dhabi_admin_boundaries.geojson: db/table/abu_dhabi_admin_boundaries | data/out/abu_dhabi  ## Abu Dhabi admin boundaries from GADM (Database of Global Administrative Areas) exported to geojson.
	ogr2ogr -f GeoJSON $@ PG:'dbname=gis' -sql 'select id as gid, name, gadm_level, geom from abu_dhabi_admin_boundaries' -nln abu_dhabi_admin_boundaries

data/out/abu_dhabi/abu_dhabi_eatery.csv: db/table/abu_dhabi_eatery | data/out/abu_dhabi ## Abu Dhabi eatery from OpenStreetMap exported to csv.
	psql -q -X -c 'copy (select osm_id, type, ST_Y(geom) "lat", ST_X(geom) "lon" from abu_dhabi_eatery) to stdout with csv header;' > $@

data/out/abu_dhabi/abu_dhabi_food_shops.csv: db/table/abu_dhabi_food_shops | data/out/abu_dhabi ## Abu Dhabi food shops from OpenStreetMap exported to csv.
	psql -q -X -c 'copy (select osm_id, type, ST_Y(geom) "lat", ST_X(geom) "lon" from abu_dhabi_food_shops) to stdout with csv header;' > $@

data/out/abu_dhabi/abu_dhabi_bivariate_pop_food_shops.csv: db/table/abu_dhabi_bivariate_pop_food_shops | data/out/abu_dhabi ## H3 bivariate layer with population vs food shops for Abu Dhabi exported to csv.
	psql -q -X -c 'copy (select h3, population, places, bivariate_cell_label from abu_dhabi_bivariate_pop_food_shops) to stdout with csv header;' > $@

db/table/abu_dhabi_buildings_population: db/table/abu_dhabi_buildings | db/table ## Distribute Kontur population by buildings in Abu Dhabi.
	psql -f tables/abu_dhabi_buildings_population.sql
	touch $@

db/table/abu_dhabi_pds_bicycle_10min: db/table/abu_dhabi_buildings_population deploy/geocint/docker_osrm_backend | db/table ## Buildings with Population Density Score within 10 minutes accessibility by bicycle profile in Abu Dhabi.
	psql -c 'drop table if exists abu_dhabi_pds_bicycle_10min;'
	psql -c 'create table abu_dhabi_pds_bicycle_10min(id integer, height float, pds integer, geom geometry);'
	psql -X -c 'copy (select id from abu_dhabi_buildings_population) to stdout;' | parallel --eta 'psql -X -f tables/abu_dhabi_pds_bicycle_10min.sql -v id={};'
	psql -c 'vacuum full abu_dhabi_pds_bicycle_10min;'
	touch $@

data/out/abu_dhabi/abu_dhabi_pds_bicycle_10min.geojson: db/table/abu_dhabi_pds_bicycle_10min | data/out/abu_dhabi ## Export to GeoJson buildings with Population Density Score within 10 minutes accessibility by bicycle profile in Abu Dhabi.
	ogr2ogr -f GeoJSON $@ PG:'dbname=gis' -sql 'select * from abu_dhabi_pds_bicycle_10min' -nln abu_dhabi_pds_bicycle_10min

data/out/abu_dhabi_export: data/out/abu_dhabi/abu_dhabi_admin_boundaries.geojson data/out/abu_dhabi/abu_dhabi_eatery.csv data/out/abu_dhabi/abu_dhabi_food_shops.csv data/out/abu_dhabi/abu_dhabi_bivariate_pop_food_shops.csv data/out/abu_dhabi/abu_dhabi_pds_bicycle_10min.geojson ## Make sure all Abu Dhabi datasets have been exported.
	touch $@

## end Abu Dhabi block

data/out/aoi_boundary.geojson: db/table/kontur_boundaries | data/out ## Get boundaries of Belarus, UAE, Kosovo, USA.
	psql -q -X -c "\copy (select ST_AsGeoJSON(aoi) from (select ST_Union(geom) as polygon from kontur_boundaries where tags ->> 'name:en' in ('Belarus', 'Kosovo', 'United Arab Emirates', 'United States') and gadm_level = 0) aoi) to stdout" | jq -c . > $@

data/out/aoi-latest.osm.pbf: data/planet-latest-updated.osm.pbf data/out/aoi_boundary.geojson | data/out ## Extract from planet-latest-updated.osm.pbf by aoi_boundary.geojson using Osmium tool.
	osmium extract -v -s smart -p data/out/aoi_boundary.geojson data/planet-latest-updated.osm.pbf -o $@ --overwrite

data/out/docker/osrm_context.tar: data/out/aoi-latest.osm.pbf | data/out/docker ## Create tar-file with context for OSRM docker build.
	tar cvf $@ data/out/aoi-latest.osm.pbf supplemental/OSRM/profiles scripts/dockerfile-osrm-backend

data/out/docker/osrm_backend_foot: data/out/docker/osrm_context.tar | data/out/docker ## Build docker image with OSRM router by foot profile.
	docker build --build-arg PORT=5000 --build-arg OSRM_PROFILE=foot --build-arg OSM_FILE=data/out/aoi-latest.osm.pbf --file scripts/dockerfile-osrm-backend --tag osrm-backend-foot --no-cache - < data/out/docker/osrm_context.tar
	touch $@

data/out/docker/osrm_backend_bicycle: data/out/docker/osrm_context.tar | data/out/docker ## Build docker image with OSRM router by bicycle profile.
	docker build --build-arg PORT=5001 --build-arg OSRM_PROFILE=bicycle --build-arg OSM_FILE=data/out/aoi-latest.osm.pbf --file scripts/dockerfile-osrm-backend --tag osrm-backend-bicycle --no-cache - < data/out/docker/osrm_context.tar
	touch $@

data/out/docker/osrm_backend_car: data/out/docker/osrm_context.tar | data/out/docker ## Build docker image with OSRM router by car profile.
	docker build --build-arg PORT=5002 --build-arg OSRM_PROFILE=car-shortest --build-arg OSM_FILE=data/out/aoi-latest.osm.pbf --file scripts/dockerfile-osrm-backend --tag osrm-backend-car --no-cache - < data/out/docker/osrm_context.tar
	touch $@

data/out/docker/osrm_backend_car_emergency: data/out/docker/osrm_context.tar | data/out/docker ## Build docker image with OSRM router by car-emergency profile.
	docker build --build-arg PORT=5003 --build-arg OSRM_PROFILE=car-emergency --build-arg OSM_FILE=data/out/aoi-latest.osm.pbf --file scripts/dockerfile-osrm-backend --tag osrm-backend-car-emergency --no-cache - < data/out/docker/osrm_context.tar
	touch $@

data/out/docker/osrm_backend_motorbike: data/out/docker/osrm_context.tar | data/out/docker ## Build docker image with OSRM router by motorbike profile.
	docker build --build-arg PORT=5004 --build-arg OSRM_PROFILE=motorbike --build-arg OSM_FILE=data/out/aoi-latest.osm.pbf --file scripts/dockerfile-osrm-backend --tag osrm-backend-motorbike --no-cache - < data/out/docker/osrm_context.tar
	touch $@

deploy/geocint/docker_osrm_backend_foot: data/out/docker/osrm_backend_foot | deploy/geocint ## Restart docker container with OSRM router by foot profile.
	sh scripts/restart_docker_osrm_backend.sh osrm-backend-foot 5000
	touch $@

deploy/geocint/docker_osrm_backend_bicycle: data/out/docker/osrm_backend_bicycle | deploy/geocint ## Restart docker container with OSRM router by bicycle profile.
	sh scripts/restart_docker_osrm_backend.sh osrm-backend-bicycle 5001
	touch $@

deploy/geocint/docker_osrm_backend_car: data/out/docker/osrm_backend_car | deploy/geocint ## Restart docker container with OSRM router by car profile.
	sh scripts/restart_docker_osrm_backend.sh osrm-backend-car 5002
	touch $@

deploy/geocint/docker_osrm_backend_car_emergency: data/out/docker/osrm_backend_car_emergency | deploy/geocint ## Restart docker container with OSRM router by car emergency profile.
	sh scripts/restart_docker_osrm_backend.sh osrm-backend-car-emergency 5003
	touch $@

deploy/geocint/docker_osrm_backend_motorbike: data/out/docker/osrm_backend_motorbike | deploy/geocint ## Restart docker container with OSRM router by motorbike profile.
	sh scripts/restart_docker_osrm_backend.sh osrm-backend-motorbike 5004
	touch $@

deploy/geocint/docker_osrm_backend: deploy/geocint/docker_osrm_backend_foot deploy/geocint/docker_osrm_backend_bicycle deploy/geocint/docker_osrm_backend_car deploy/geocint/docker_osrm_backend_car_emergency deploy/geocint/docker_osrm_backend_motorbike | deploy/geocint  ## Deploy all OSRM Docker builds after their runs started.
	touch $@

db/function/calculate_osrm_eta: deploy/geocint/docker_osrm_backend | db/function ## ETA calculation function using OSRM router.
	psql -f functions/calculate_osrm_eta.sql
	touch $@

db/function/build_isochrone: db/function/calculate_osrm_eta db/table/osm_road_segments | db/function ## Isochrone construction function.
	psql -f functions/build_isochrone.sql
	touch $@

db/table/osm_landuse: db/table/osm db/index/osm_tags_idx | db/table ## Landuse polygons extracted from OpenStreetMap.
	psql -f tables/osm_landuse.sql
	touch $@

db/table/osm_landuse_industrial: db/table/osm db/index/osm_tags_idx | db/table ## Industrial landuse polygons extracted from OpenStreetMap.
	psql -f tables/osm_landuse_industrial.sql
	touch $@

db/table/osm_landuse_industrial_h3: db/table/osm_landuse_industrial db/procedure/generate_overviews | db/table ## Aggregate industrial landuse area on H3 hexagons grid.
	psql -f tables/osm_landuse_industrial_h3.sql
	psql -c "call generate_overviews('osm_landuse_industrial_h3', '{industrial_area}'::text[], '{sum}'::text[], 8);"
	touch $@

db/table/osm_volcanos_h3: db/index/osm_tags_idx db/procedure/generate_overviews | db/table ## H3 hexagons grid with aggregated count volcanoes from OpenStreetMap dataset.
	# Extract volcanoes points from OpenStreetMap dataset.
	psql -f tables/osm_volcanos.sql
	# Count volcanoes within H3 grid hexagons of resolution = 8.
	psql -f tables/count_points_inside_h3.sql -v table=osm_volcanos -v table_h3=osm_volcanos_h3 -v item_count=volcanos_count
	# Generate overviews for resolution < 8 hexagons.
	psql -c "call generate_overviews('osm_volcanos_h3', '{volcanos_count}'::text[], '{sum}'::text[], 8);"
	touch $@

db/table/osm_places_eatery: db/index/osm_tags_idx | db/table ## Eatery extraction from OpenStreetMap.
	psql -f tables/osm_places_eatery.sql
	touch $@

db/table/osm_places_eatery_h3: db/table/osm_places_eatery db/procedure/generate_overviews | db/table ## Eatery count h3 layer from OpenStreetMap.
	# Count eatery places within H3 grid hexagons of resolution = 8.
	psql -f tables/count_points_inside_h3.sql -v table=osm_places_eatery -v table_h3=osm_places_eatery_h3 -v item_count=eatery_count
	# Generate overviews for resolution < 8 hexagons.
	psql -c "call generate_overviews('osm_places_eatery_h3', '{eatery_count}'::text[], '{sum}'::text[], 8);"
	touch $@

db/table/osm_places_food_shops: db/index/osm_tags_idx | db/table ## Extract food_shops points from OpenStreetMap dataset.	
	psql -f tables/osm_places_food_shops.sql
	touch $@

db/table/osm_places_food_shops_h3: db/table/osm_places_food_shops db/procedure/generate_overviews | db/table ## Food shops count h3 layer from OpenStreetMap.
	# Count eatery places within H3 grid hexagons of resolution = 8.
	psql -f tables/count_points_inside_h3.sql -v table=osm_places_food_shops -v table_h3=osm_places_food_shops_h3 -v item_count=food_shops_count
	# Generate overviews for resolution < 8 hexagons.
	psql -c "call generate_overviews('osm_places_food_shops_h3', '{food_shops_count}'::text[], '{sum}'::text[], 8);"
	touch $@

db/table/osm_buildings_minsk: db/table/osm_buildings_use | db/table ## Minsk buildings extracted from OpenStreetMap dataset.
	psql -c "drop table if exists osm_buildings_minsk;"
	psql -c "create table osm_buildings_minsk as (select building, street, hno, levels, height, use, \"name\", geom from osm_buildings b where ST_DWithin (b.geom, (select geog::geometry from osm where tags @> '{\"name:be\":\"Мінск\", \"boundary\":\"administrative\"}' and osm_id = 59195 and osm_type = 'relation'), 0));"
	touch $@

data/out/osm_buildings_minsk.geojson.gz: db/table/osm_buildings_minsk | data/out  ## Export to geojson and archive Minsk buildings extracted from OpenStreetMap dataset.
	rm -f $@
	rm -f data/out/osm_buildings_minsk.geojson*
	ogr2ogr -f GeoJSON data/out/osm_buildings_minsk.geojson PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_minsk' -nln osm_buildings_minsk
	cd data/out/; pigz osm_buildings_minsk.geojson
	touch $@

deploy/s3/osm_buildings_minsk: data/out/osm_buildings_minsk.geojson.gz | deploy/s3 ## Deploy Minsk buildings dataset to Amazon S3.
	aws s3api put-object --bucket geodata-us-east-1-kontur --key public/geocint/osm_buildings_minsk.geojson.gz --body data/out/osm_buildings_minsk.geojson.gz --content-type "application/json" --content-encoding "gzip" --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers
	touch $@

data/in/census_gov: | data/in ## Directory for input census tract data.
	mkdir $@

data/in/census_gov/cb_2019_us_tract_500k.zip: | data/in/census_gov ## Download census tract data from AWS S3 bucket.
	cd data/in/census_gov; aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/in/cb_2019_us_tract_500k.zip ./ --profile geocint_pipeline_sender
	touch $@

data/mid/census_gov: | data/mid ## Directory for intermediate census tract data.
	mkdir $@

data/mid/census_gov/cb_2019_us_tract_500k.shp: data/in/census_gov/cb_2019_us_tract_500k.zip | data/mid/census_gov ## Unzip census tract dataset.
	unzip -o data/in/census_gov/cb_2019_us_tract_500k.zip -d data/mid/census_gov/
	touch $@

db/table/us_census_tract_boundaries_subdivide: data/mid/census_gov/cb_2019_us_tract_500k.shp | db/table ## Import all US census tract boundaries into database and create table with subdivided geometry
	ogr2ogr --config PG_USE_COPY YES -overwrite -s_srs EPSG:4269 -t_srs EPSG:4326 -f PostgreSQL PG:"dbname=gis" data/mid/census_gov/cb_2019_us_tract_500k.shp -nlt GEOMETRY -lco GEOMETRY_NAME=geom -nln us_census_tract_boundaries
	psql -f tables/us_census_tract_boundaries_subdivide.sql
	touch $@

db/table/us_census_tracts_population_h3_r8: db/table/us_census_tract_boundaries_subdivide db/table/kontur_population_h3 | db/table ## Extract hex with population on 8 resolution for US from kontur_population_h3
	psql -f tables/us_census_tracts_population_h3_r8.sql
	touch $@

data/in/census_gov/data_census_download: | data/in/census_gov ## Download thematic census tracts Zealand's buildings from AWS S3 bucket.
	cd data/in/census_gov; aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/us_census/ ./ --recursive --exclude "*" --include "*us_census_tracts_*" --profile geocint_pipeline_sender
	touch $@

data/mid/census_gov/us_census_tracts_stats.csv: data/in/census_gov/data_census_download | data/mid/census_gov ## Normalize US census tracts dataset.
	python3 scripts/normalize_census_data.py -c static_data/census_data_config.json -o $@

db/table/us_census_tract_stats: db/table/us_census_tracts_population_h3_r8 db/table/us_census_tract_boundaries_subdivide data/mid/census_gov/us_census_tracts_stats.csv | db/table ## US census tracts statistics imported into database.
	psql -c 'drop table if exists us_census_tracts_stats_in;'
	psql -c 'create table us_census_tracts_stats_in (id_tract text, tract_name text, pop_under_5_total float, pop_over_65_total float, families_total float, families_poverty_percent float, poverty_families_total float generated always as (families_total * families_poverty_percent / 100) stored, pop_disability_total float, pop_not_well_eng_speak float, pop_working_total float, pop_with_cars_percent float, pop_without_car float generated always as (pop_working_total - (pop_working_total * pop_with_cars_percent) / 100) stored);'
	cat data/mid/census_gov/us_census_tracts_stats.csv | psql -c "copy us_census_tracts_stats_in (id_tract, tract_name, pop_under_5_total, pop_over_65_total, families_total, families_poverty_percent, pop_disability_total, pop_not_well_eng_speak, pop_working_total, pop_with_cars_percent) from stdin with csv header delimiter ';';"
	psql -f tables/us_census_tracts_stats.sql
	touch $@

db/table/us_census_tracts_stats_h3: db/table/us_census_tract_stats db/procedure/generate_overviews db/table/us_census_tracts_population_h3_r8 | db/table ## Generate h3 with stats data in California census tracts from 1 to 8 resolution
	psql -f tables/us_census_tracts_stats_h3.sql
	psql -c "call generate_overviews('us_census_tracts_stats_h3', '{pop_under_5_total, pop_over_65_total, poverty_families_total, pop_disability_total, pop_not_well_eng_speak, pop_without_car}'::text[], '{sum, sum, sum, sum, sum, sum}'::text[], 8);"
	touch $@

data/in/probable_futures: | data/in ## Create folder for Probable Futures dataset.
	mkdir $@

data/in/probable_futures/data_sync: | data/in/probable_futures ## Sync PF GeoJSONs from AWS S3 bucket with local dir.
	aws s3 sync s3://geodata-eu-central-1-kontur/private/geocint/in/probable_futures data/in/probable_futures/ --profile geocint_pipeline_sender
	touch $@

db/table/pf_days_maxtemp_in: data/in/probable_futures/data_sync | db/table ## Count (in days) above 32C (90F).
	psql -c 'drop table if exists pf_days_maxtemp_in;'
	ogr2ogr -f PostgreSQL PG:"dbname=gis" data/in/probable_futures/20104.gremo.geojson -nln pf_days_maxtemp_in -lco GEOMETRY_NAME=geom
	touch $@

db/table/pf_night_maxtemp_in: data/in/probable_futures/data_sync | db/table ## Count nights above 25C (68F).
	psql -c 'drop table if exists pf_nights_maxtemp_in;'
	ogr2ogr -f PostgreSQL PG:"dbname=gis" data/in/probable_futures/20204.gremo.geojson -nln pf_nights_maxtemp_in -lco GEOMETRY_NAME=geom
	touch $@

db/table/pf_days_wet_bulb_in: data/in/probable_futures/data_sync | db/table ## Count (in days) above 32C (wet-bulb).
	psql -c 'drop table if exists pf_days_wet_bulb_in;'
	ogr2ogr -f PostgreSQL PG:"dbname=gis" data/in/probable_futures/20304.gremo.geojson -nln pf_days_wet_bulb_in -lco GEOMETRY_NAME=geom
	touch $@

db/table/pf_maxtemp_idw_h3: db/table/pf_night_maxtemp_in db/table/pf_days_maxtemp_in db/table/pf_days_wet_bulb_in | db/table ## Collect PF tables into one, IDW interpolation on level 8
	psql -f tables/pf_maxtemp_idw_h3.sql
	touch $@

db/table/pf_maxtemp_h3: db/table/pf_maxtemp_idw_h3 db/table/kontur_population_h3 | db/table ## add man-days above 32C to PF data
	psql -f tables/pf_maxtemp_h3.sql
	touch $@

db/table/osm_addresses: db/table/osm db/index/osm_tags_idx | db/table ## Geometry with address key extracted from OpenStreetMap dataset.
	psql -f tables/osm_addresses.sql
	touch $@

db/index/osm_addresses_geom_idx: db/table/osm_addresses | db/index ## Index on geometry addresses table.
	psql -c "drop index if exists osm_addresses_geom_idx;"
	psql -c "create index osm_addresses_geom_idx on osm_addresses using brin (geom);"
	touch $@

db/table/osm_addresses_minsk: db/index/osm_addresses_geom_idx db/table/osm_addresses | db/table ## Minsk address geometry extracted from OpenStreetMap dataset.
	psql -f tables/osm_addresses_minsk.sql
	touch $@

data/out/osm_addresses_minsk.geojson.gz: db/table/osm_addresses_minsk | data/out ## Export to geojson and archive Minsk address geometry extracted from OpenStreetMap dataset.
	rm -vf data/out/osm_addresses_minsk.geojson*
	ogr2ogr -f GeoJSON data/out/osm_addresses_minsk.geojson PG:'dbname=gis' -sql "select * from osm_addresses_minsk" -nln osm_addresses_minsk
	cd data/out/; pigz osm_addresses_minsk.geojson
	touch $@

deploy/s3/test/osm_addresses_minsk: data/out/osm_addresses_minsk.geojson.gz | deploy/s3/test ## OpenStreetMap addresses dataset used in advanced Minsk geocoder (kontur.fibery.io/Tasks/User_Story/Postgres-Geocoder-for-Minsk-22).
	aws s3api copy-object --copy-source geodata-us-east-1-kontur/public/geocint/test/osm_addresses_minsk.geojson.gz --bucket geodata-us-east-1-kontur --key public/geocint/test/osm_addresses_minsk.geojson.gz.bak --content-type "application/json" --content-encoding "gzip" --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers
	aws s3api put-object --bucket geodata-us-east-1-kontur --key public/geocint/test/osm_addresses_minsk.geojson.gz --body data/out/osm_addresses_minsk.geojson.gz --content-type "application/json" --content-encoding "gzip" --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers
	touch $@

deploy/s3/osm_addresses_minsk: data/out/osm_addresses_minsk.geojson.gz | deploy/s3 ## Deploy Minsk address geometry geojson to Amazon S3.
	aws s3api copy-object --copy-source geodata-us-east-1-kontur/public/geocint/osm_addresses_minsk.geojson.gz --bucket geodata-us-east-1-kontur --key public/geocint/osm_addresses_minsk.geojson.gz.bak --content-type "application/json" --content-encoding "gzip" --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers
	aws s3api put-object --bucket geodata-us-east-1-kontur --key public/geocint/osm_addresses_minsk.geojson.gz --body data/out/osm_addresses_minsk.geojson.gz --content-type "application/json" --content-encoding "gzip" --grant-read uri=http://acs.amazonaws.com/groups/global/AllUsers
	touch $@

db/table/osm_admin_boundaries: db/table/osm db/index/osm_tags_idx | db/table ## Administrative boundaries polygons extracted from OpenStreetMap dataset.
	psql -f tables/osm_admin_boundaries.sql
	touch $@

# db/table/hexagonify_boundaries: db/table/kontur_boundaries db/table/facebook_roads | db/table ## H3 hexagons from Kontur boundaries polygons for country level.
# 	psql -f tables/hexagonify_boundaries.sql
# 	touch $@

db/table/osm_buildings: db/table/osm db/function/parse_float db/function/parse_integer | db/table ## All the buildings (but not all the properties yet) extracted from OpenStreetMap dataset.
	psql -f tables/osm_buildings.sql
	touch $@

db/table/osm_buildings_use: db/index/osm_tags_idx db/table/osm_buildings db/table/osm_landuse ## Set use in buildings table from landuse table.
	psql -f tables/osm_buildings_use.sql
	touch $@

db/table/residential_pop_h3: db/table/kontur_population_h3 db/table/ghs_globe_residential_vector | db/table ## GHS (Global Human Settlement) residential areas aggregated on H3 hexagons grid.
	psql -f tables/residential_pop_h3.sql
	touch $@

## Isochrones calculation block

db/table/isochrone_destinations: | db/table ## Initialize isochrone_destinations table.
	psql -c 'drop table if exists isochrone_destinations;'
	psql -c 'create table isochrone_destinations (osm_id bigint, type text, tags jsonb, geom geometry);'
	touch $@

db/table/isochrone_destinations_new: db/table/isochrone_destinations db/index/osm_tags_idx | db/table ## Get new isochrone destinations from osm.
	psql -f tables/isochrone_destinations_new.sql
	touch $@

db/table/isochrone_destinations_h3_r8: | db/table ## Initialize isochrone_destinations_h3_r8 table.
	psql -c 'drop table if exists isochrone_destinations_h3_r8;'
	psql -c 'create table isochrone_destinations_h3_r8 (osm_id bigint, h3 h3index, type text, distance float, geom geometry);'
	touch $@

db/function/calculate_isodist_h3: db/table/osm_road_segments | db/function ## H3 isodist construction function.
	psql -f functions/calculate_isodist_h3.sql
	touch $@

db/table/update_isochrone_destinations_h3_r8: db/table/isochrone_destinations_new db/table/isochrone_destinations_h3_r8 db/function/calculate_isodist_h3 | db/table ## Aggregate 30 km isodists to H3 hexagons with resolution 8 for new isochrone destinations.
	psql -c 'delete from isochrone_destinations_h3_r8 where osm_id in (select osm_id from isochrone_destinations except all select osm_id from isochrone_destinations_new);'
	psql -c 'vacuum isochrone_destinations_h3_r8;'
	psql -X -c 'copy (select osm_id from isochrone_destinations_new except all select osm_id from isochrone_destinations) to stdout;' | parallel --eta 'psql -c "insert into isochrone_destinations_h3_r8(osm_id, h3, type, distance, geom) select d.osm_id, i.h3, d.type, i.distance, st_setsrid(i.geom, 4326) from isochrone_destinations_new d, calculate_isodist_h3(geom, 30000, 8) i where d.osm_id = {};"'
	touch $@

db/table/update_isochrone_destinations: db/table/update_isochrone_destinations_h3_r8 | db/table ## Update update_isochrone_destinations table.
	psql -1 -c "drop table if exists isochrone_destinations; alter table isochrone_destinations_new rename to isochrone_destinations;"
	touch $@

db/table/isodist_fire_stations_h3: db/table/update_isochrone_destinations db/table/kontur_population_h3 | db/table ## H3 hexagons from fire stations.
	psql -f tables/isodist_fire_stations_h3.sql
	seq 8 -1 1 | xargs -I {} psql -f tables/isodist_h3_overview.sql -v table_name=isodist_fire_stations_h3 -v seq_res={}
	psql -c "drop table isodist_fire_stations_h3_distinct;"
	touch $@

db/table/isodist_hospitals_h3: db/table/update_isochrone_destinations db/table/kontur_population_h3 | db/table ## H3 hexagons from hospitals.
	psql -f tables/isodist_hospitals_h3.sql
	seq 8 -1 1 | xargs -I {} psql -f tables/isodist_hospitals_h3_overview.sql -v seq_res={}
	psql -c "drop table isodist_hospitals_h3_distinct;"
	touch $@

db/table/isodist_charging_stations_h3: db/table/update_isochrone_destinations db/table/kontur_population_h3 | db/table ## H3 hexagons from charging stations.
	psql -f tables/isodist_charging_stations_h3.sql
	seq 8 -1 1 | xargs -I {} psql -f tables/isodist_h3_overview.sql -v table_name=isodist_charging_stations_h3 -v seq_res={}
	psql -c "drop table isodist_charging_stations_h3_distinct;"
	touch $@

db/table/isodist_bomb_shelters_h3: db/table/update_isochrone_destinations db/table/kontur_population_h3 | db/table ## H3 hexagons from bomb shelters.
	psql -f tables/isodist_bomb_shelters_h3.sql
	seq 8 -1 1 | xargs -I {} psql -f tables/isodist_h3_overview.sql -v table_name=isodist_bomb_shelters_h3 -v seq_res={}
	psql -c "drop table isodist_bomb_shelters_h3_distinct;"
	touch $@
## Isochrones calculation block end

db/table/global_rva_indexes: | db/table ## Global RVA indexes to Bivariate Manager
	psql -c "drop table if exists global_rva_indexes;"
	psql -c "create table global_rva_indexes (country_name text,iso_code text,hasc text,raw_mhe_pop_scaled numeric,raw_mhe_cap_scaled numeric,raw_mhe_index numeric,relative_mhe_pop_scaled numeric,relative_mhe_cap_scaled numeric,relative_mhe_index numeric,mhe_index numeric,life_expectancy_scale numeric,infant_mortality_scale numeric,maternal_mortality_scale numeric,prevalence_undernourished_scale numeric,vulnerable_health_status_index numeric,pop_wout_improved_sanitation_scale numeric,pop_wout_improved_water_scale numeric,clean_water_access_vulnerability_index numeric,adult_illiteracy_scale numeric,gross_enrollment_scale numeric,years_of_schooling_scale numeric,pop_wout_internet_scale numeric,info_access_vulnerability_index numeric,export_minus_import_percent_scale numeric,average_inflation_scale numeric,economic_dependency_scale numeric,economic_constraints_index numeric,female_govt_seats_scale numeric,female_male_secondary_enrollment_scale numeric,female_male_labor_ratio_scale numeric,gender_inequality_index numeric,max_political_discrimination_scale numeric,max_economic_discrimination_scale numeric,ethnic_discrimination_index numeric,marginalization_index numeric,population_change_scale numeric,urban_population_change_scale numeric,population_pressures_index numeric,freshwater_withdrawals_scale numeric,forest_area_change_scale numeric,ruminant_density_scale numeric,environmental_stress_index numeric,recent_disaster_losses_scale numeric,recent_disaster_deaths_scale numeric,recent_disaster_impacts_index numeric,recent_conflict_deaths_scale numeric,displaced_populations_scale numeric,conflict_impacts_index numeric,vulnerability_index numeric,voice_and_accountability_scale numeric,rule_of_law_scale numeric,political_stability_scale numeric,govt_effectiveness_scale numeric,control_of_corruption_scale numeric,governance_index numeric,gni_per_capita_scale numeric,reserves_per_capita_scale numeric,economic_capacity_index numeric,fixed_phone_access_scale numeric,mobile_phone_access_scale numeric,internet_server_access_scale numeric,communications_capacity_index numeric,port_rnwy_density_scale numeric,road_rr_density_scale numeric,transportation_index numeric,hospital_bed_density_scale numeric,nurses_midwives_scale numeric,physicians_scale numeric,health_care_capacity_index numeric,infrastructure_capacity_index numeric,biome_protection_scale numeric,marine_protected_area_scale numeric,environmental_capacity_index numeric,coping_capacity_index numeric,resilience_index numeric,mhr_index numeric);"
	cat static_data/pdc_bivariate_manager/global_rva_hasc.csv | psql -c "copy global_rva_indexes from stdin with csv header;"
	psql -c "create index on global_rva_indexes using btree(hasc);"
	touch $@

db/table/global_rva_h3: db/table/kontur_boundaries db/table/global_rva_indexes db/procedure/generate_overviews db/procedure/transform_hasc_to_h3 | db/table ## Generation overviws of global rva indexes
	psql -c "call transform_hasc_to_h3('global_rva_indexes', 'global_rva_h3', 'hasc', '{raw_mhe_pop_scaled, raw_mhe_cap_scaled, raw_mhe_index, relative_mhe_pop_scaled, relative_mhe_cap_scaled, relative_mhe_index, mhe_index, life_expectancy_scale, infant_mortality_scale, maternal_mortality_scale, prevalence_undernourished_scale, vulnerable_health_status_index, pop_wout_improved_sanitation_scale, pop_wout_improved_water_scale, clean_water_access_vulnerability_index, adult_illiteracy_scale, gross_enrollment_scale, years_of_schooling_scale, pop_wout_internet_scale, info_access_vulnerability_index, export_minus_import_percent_scale, average_inflation_scale, economic_dependency_scale, economic_constraints_index, female_govt_seats_scale, female_male_secondary_enrollment_scale, female_male_labor_ratio_scale, gender_inequality_index, max_political_discrimination_scale, max_economic_discrimination_scale, ethnic_discrimination_index, marginalization_index, population_change_scale, urban_population_change_scale, population_pressures_index, freshwater_withdrawals_scale, forest_area_change_scale, ruminant_density_scale, environmental_stress_index, recent_disaster_losses_scale, recent_disaster_deaths_scale, recent_disaster_impacts_index, recent_conflict_deaths_scale, displaced_populations_scale, conflict_impacts_index, vulnerability_index, voice_and_accountability_scale, rule_of_law_scale, political_stability_scale, govt_effectiveness_scale, control_of_corruption_scale, governance_index, gni_per_capita_scale, reserves_per_capita_scale, economic_capacity_index, fixed_phone_access_scale, mobile_phone_access_scale, internet_server_access_scale, communications_capacity_index, port_rnwy_density_scale, road_rr_density_scale, transportation_index, hospital_bed_density_scale, nurses_midwives_scale, physicians_scale, health_care_capacity_index, infrastructure_capacity_index, biome_protection_scale, marine_protected_area_scale, environmental_capacity_index, coping_capacity_index, resilience_index, mhr_index}'::text[], 8);"
	psql -c "call generate_overviews('global_rva_h3', '{raw_mhe_pop_scaled, raw_mhe_cap_scaled, raw_mhe_index, relative_mhe_pop_scaled, relative_mhe_cap_scaled, relative_mhe_index, mhe_index, life_expectancy_scale, infant_mortality_scale, maternal_mortality_scale, prevalence_undernourished_scale, vulnerable_health_status_index, pop_wout_improved_sanitation_scale, pop_wout_improved_water_scale, clean_water_access_vulnerability_index, adult_illiteracy_scale, gross_enrollment_scale, years_of_schooling_scale, pop_wout_internet_scale, info_access_vulnerability_index, export_minus_import_percent_scale, average_inflation_scale, economic_dependency_scale, economic_constraints_index, female_govt_seats_scale, female_male_secondary_enrollment_scale, female_male_labor_ratio_scale, gender_inequality_index, max_political_discrimination_scale, max_economic_discrimination_scale, ethnic_discrimination_index, marginalization_index, population_change_scale, urban_population_change_scale, population_pressures_index, freshwater_withdrawals_scale, forest_area_change_scale, ruminant_density_scale, environmental_stress_index, recent_disaster_losses_scale, recent_disaster_deaths_scale, recent_disaster_impacts_index, recent_conflict_deaths_scale, displaced_populations_scale, conflict_impacts_index, vulnerability_index, voice_and_accountability_scale, rule_of_law_scale, political_stability_scale, govt_effectiveness_scale, control_of_corruption_scale, governance_index, gni_per_capita_scale, reserves_per_capita_scale, economic_capacity_index, fixed_phone_access_scale, mobile_phone_access_scale, internet_server_access_scale, communications_capacity_index, port_rnwy_density_scale, road_rr_density_scale, transportation_index, hospital_bed_density_scale, nurses_midwives_scale, physicians_scale, health_care_capacity_index, infrastructure_capacity_index, biome_protection_scale, marine_protected_area_scale, environmental_capacity_index, coping_capacity_index, resilience_index, mhr_index}'::text[], '{avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg}'::text[], 8);"
	touch $@

db/table/ndpba_rva_indexes: | db/table ## NDPBA RVA indexes
	psql -c "drop table if exists ndpba_rva_indexes;"
	psql -c 'create table ndpba_rva_indexes("country" text, "hasc" text, "region_indicator" text, "raw_population_exposure_index" numeric, "raw_economic_exposure" numeric, "relative_population_exposure_index" numeric, "relative_economic_exposure" numeric, "poverty" numeric, "economic_dependency" numeric, "maternal_mortality" numeric, "infant_mortality" numeric, "malnutrition" numeric, "population_change" numeric, "urban_pop_change" numeric, "school_enrollment" numeric, "years_of_schooling" numeric, "fem_to_male_labor" numeric, "proportion_of_female_seats_in_government" numeric, "life_expectancy" numeric, "protected_area" numeric, "physicians_per_10000_persons" numeric, "nurse_midwife_per_10k" numeric, "distance_to_hospital" numeric, "hbeds_per_10000_persons" numeric, "distance_to_port" numeric, "road_density" numeric, "households_with_fixed_phone" numeric, "households_with_cell_phone" numeric, "voter_participation" numeric);'
	cat static_data/pdc_bivariate_manager/ndpba_rva.csv | psql -c "copy ndpba_rva_indexes from stdin with csv header;"
	touch $@

db/table/ndpba_rva_h3: db/table/kontur_boundaries db/table/ndpba_rva_indexes db/procedure/generate_overviews db/procedure/transform_hasc_to_h3 | db/table ## Generation overviews of ndpba rva indexes
	psql -c "call transform_hasc_to_h3('ndpba_rva_indexes', 'ndpba_rva_h3', 'hasc', '{raw_population_exposure_index,raw_economic_exposure,relative_population_exposure_index,relative_economic_exposure,poverty,economic_dependency,maternal_mortality,infant_mortality,malnutrition,population_change,urban_pop_change,school_enrollment,years_of_schooling,fem_to_male_labor,proportion_of_female_seats_in_government,life_expectancy,protected_area,physicians_per_10000_persons,nurse_midwife_per_10k,distance_to_hospital,hbeds_per_10000_persons,distance_to_port,road_density,households_with_fixed_phone,households_with_cell_phone,voter_participation}'::text[], 8);"
	psql -c "call generate_overviews('ndpba_rva_h3', '{raw_population_exposure_index,raw_economic_exposure,relative_population_exposure_index,relative_economic_exposure,poverty,economic_dependency,maternal_mortality,infant_mortality,malnutrition,population_change,urban_pop_change,school_enrollment,years_of_schooling,fem_to_male_labor,proportion_of_female_seats_in_government,life_expectancy,protected_area,physicians_per_10000_persons,nurse_midwife_per_10k,distance_to_hospital,hbeds_per_10000_persons,distance_to_port,road_density,households_with_fixed_phone,households_with_cell_phone,voter_participation}'::text[], '{avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg,avg}'::text[], 8);"
	touch $@

data/in/foursquare/downloaded: | data/in/foursquare ## download and rename 4sq archives
	cd data/in/foursquare; aws s3 sync s3://geodata-eu-central-1-kontur/private/geocint/in/foursquare/ ./ --profile geocint_pipeline_sender
	touch $@

data/mid/foursquare/kontour_places.csv: data/in/foursquare/downloaded | data/mid/foursquare ## extract archive and filter csv
	rm -f $@
	zcat data/in/foursquare/kontour_places.csv.gz | sed ':a;s/^\(\([^"]*,\?\|"[^",]*",\?\)*"[^",]*\),/\1 /;ta' | cut -d, -f1,4,5 | egrep -v "\[ | evaluation_sample | roof" | grep -vP "\w*[A-Z]+\w*" | sed '/,/!d' > $@

data/mid/foursquare/kontour_visits_csv: data/in/foursquare/downloaded | data/mid/foursquare ## extract archives and filter csv
	rm -f data/mid/foursquare/kontour_visits*.csv
	zcat data/in/foursquare/part-00132-tid-3339978440558258505-6a4e8282-87e3-454b-a65f-d919022a27fd-4195596-1.c000.csv.gz | cut -d, -f2,6,7 > data/mid/foursquare/kontour_visits_2021_08.csv
	zcat data/in/foursquare/part-00191-tid-3339978440558258505-6a4e8282-87e3-454b-a65f-d919022a27fd-4195595-1.c000.csv.gz | cut -d, -f2,6,7 > data/mid/foursquare/kontour_visits_2021_09.csv
	zcat data/in/foursquare/part-00075-tid-3339978440558258505-6a4e8282-87e3-454b-a65f-d919022a27fd-4195592-1.c000.csv.gz | cut -d, -f2,6,7 > data/mid/foursquare/kontour_visits_2021_10.csv
	zcat data/in/foursquare/part-00055-tid-3339978440558258505-6a4e8282-87e3-454b-a65f-d919022a27fd-4195594-1.c000.csv.gz | cut -d, -f2,6,7 > data/mid/foursquare/kontour_visits_2021_11.csv
	zcat data/in/foursquare/part-00075-tid-3339978440558258505-6a4e8282-87e3-454b-a65f-d919022a27fd-4195592-2.c000.csv.gz | cut -d, -f2,6,7 > data/mid/foursquare/kontour_visits_2021_12.csv
	zcat data/in/foursquare/part-00194-tid-3339978440558258505-6a4e8282-87e3-454b-a65f-d919022a27fd-4195593-1.c000.csv.gz | cut -d, -f2,6,7 > data/mid/foursquare/kontour_visits_2022_01.csv
	touch $@

db/table/foursquare_places: data/mid/foursquare/kontour_places.csv | db/table ## Import 4sq places into database.
	psql -c 'drop table if exists foursquare_places;'
	psql -c 'create table foursquare_places(fsq_id text, latitude float, longitude float, h3_r8 h3index GENERATED ALWAYS AS (h3_lat_lng_to_cell(ST_SetSrid(ST_Point(longitude, latitude), 4326)::point, 8)) STORED);'
	cat data/mid/foursquare/kontour_places.csv | psql -c "copy foursquare_places (fsq_id, latitude, longitude) from stdin with csv header delimiter ','"
	touch $@

db/table/foursquare_visits: data/mid/foursquare/kontour_visits_csv | db/table ## Import 4sq visits into database.
	psql -c 'drop table if exists foursquare_visits;'
	psql -c 'create table foursquare_visits (protectedts text, latitude float, longitude float, h3_r8 h3index GENERATED ALWAYS AS (h3_lat_lng_to_cell(ST_SetSrid(ST_Point(longitude, latitude), 4326)::point, 8)) STORED);'
	ls data/mid/foursquare/kontour_visits*.csv | parallel 'cat {} | psql -c "copy foursquare_visits (protectedts, latitude, longitude) from stdin with csv header; "'
	touch $@

db/table/foursquare_places_h3: db/table/foursquare_places db/procedure/generate_overviews | db/table ## Aggregate 4sq places count  on H3 hexagon grid.
	psql -f tables/foursquare_places_h3.sql
	psql -c "call generate_overviews('foursquare_places_h3', '{foursquare_places_count}'::text[], '{sum}'::text[], 8);"
	touch $@

db/table/foursquare_visits_h3: db/table/foursquare_visits db/procedure/generate_overviews | db/table ## Aggregate 4sq visits count on H3 hexagon grid.
	psql -f tables/foursquare_visits_h3.sql
	psql -c "call generate_overviews('foursquare_visits_h3', '{foursquare_visits_count}'::text[], '{sum}'::text[], 8);"
	touch $@

db/table/stat_h3: db/table/osm_object_count_grid_h3 db/table/residential_pop_h3 db/table/gdp_h3 db/table/user_hours_h3 db/table/tile_logs db/table/global_fires_stat_h3 db/table/building_count_grid_h3 db/table/copernicus_landcover_h3 db/table/gebco_2022_h3 db/table/ndvi_2019_06_10_h3 db/table/covid19_h3 db/table/kontur_population_v5_h3 db/table/osm_landuse_industrial_h3 db/table/osm_volcanos_h3 db/table/us_census_tracts_stats_h3 db/table/pf_maxtemp_h3 db/table/isodist_fire_stations_h3 db/table/isodist_hospitals_h3 db/table/facebook_roads_h3 db/table/tile_logs_bf2402 db/table/osm_road_segments_h3 db/table/osm_road_segments_6_months_h3 db/table/disaster_event_episodes_h3 db/table/facebook_medium_voltage_distribution_h3 db/table/night_lights_h3 db/table/osm_places_food_shops_h3 db/table/osm_places_eatery_h3 db/table/mapswipe_hot_tasking_data_h3 db/table/total_road_length_h3 db/table/global_solar_atlas_h3 db/table/worldclim_temperatures_h3 db/table/isodist_bomb_shelters_h3 db/table/isodist_charging_stations_h3 db/table/waste_containers_h3 db/table/proximities_h3 db/table/solar_farms_placement_suitability_synthetic_h3 db/table/existing_solar_power_panels_h3 db/table/safety_index_h3 db/table/live_sensor_data_h3 db/table/meta_forest_canopy_height_h3 db/table/worldbank_tax_rate_h3 db/table/wikidata_naturalization_gap_h3 | db/table ## Main table with summarized statistics aggregated on H3 hexagons grid used within Bivariate manager.
	psql -f tables/stat_h3.sql
	touch $@

db/table/stat_h3_data_quality_check: db/table/stat_h3 | db/table ## check if all h3 values in stat_h3 are unique and not null and control that there is no indicators in stat_h3 where all values on 8th resolution are zeros.
	psql -qXc "copy (select column_name::text FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'stat_h3' and column_name not in ('h3', 'geom', 'zoom', 'resolution')) to stdout with csv;" | parallel "bash scripts/psql_query_number_of_records_at_stat_h3.sh {}" | xargs -I {} bash scripts/check_value_is_not_zero_with_description.sh {}
	rm -f $@__STAT_H3_NULLS
	psql -q -X -t -c 'select count(*) from stat_h3 where h3 is null;' > $@__STAT_H3_NULLS	
	if [ 0 -lt $$(cat $@__STAT_H3_NULLS) ]; then echo "Table stat_h3 contains null h3 indexes. Execution was interrupted." | python3 scripts/slack_message.py $$SLACK_CHANNEL ${SLACK_BOT_NAME} $$SLACK_BOT_EMOJI && exit 1; fi
	rm -f $@__STAT_H3_NULLS $@__STAT_H3_DUPLICATES
	psql -q -X -t -c 'select count(h3) - count(distinct h3) as diff from stat_h3;' > $@__STAT_H3_DUPLICATES
	if [ 0 -lt $$(cat $@__STAT_H3_DUPLICATES) ]; then echo "Table stat_h3 contains duplicated h3 indexes. Execution was interrupted." | python3 scripts/slack_message.py $$SLACK_CHANNEL ${SLACK_BOT_NAME} $$SLACK_BOT_EMOJI && exit 1; fi
	rm -f $@__STAT_H3_DUPLICATES
	touch $@

db/table/stat_h3_quality: db/table/stat_h3 db/table/stat_h3_data_quality_check | db/table ## summarized statistics aggregated on H3 hexagons between resolutions.
	psql -f tables/stat_h3_quality.sql
	touch $@

db/table/bivariate_axis_overrides: | db/table ## Overrides for bivariate axis.
	psql -f tables/bivariate_axis_overrides.sql
	touch $@

db/table/bivariate_axis: db/table/bivariate_indicators db/table/bivariate_axis_overrides db/table/bivariate_overlays db/table/stat_h3 db/table/stat_h3_quality | db/table ## Precalculated axis parameters (min, max, percentiles, quality, etc.) for bivariate layers.
	psql -f tables/bivariate_axis.sql
	psql -qXc "copy (select numerator, denominator from bivariate_axis) to stdout with csv;" | parallel --colsep ',' 'psql -f tables/bivariate_axis_stops.sql -v numerator={1} -v denominator={2}'
	psql -qXc "copy (select numerator, denominator from bivariate_axis) to stdout with csv;" | tee /dev/tty | parallel --colsep ',' 'psql -f tables/bivariate_axis_quality_estimate.sql -v numerator={1} -v denominator={2}'
	psql -f tables/bivariate_axis_updates.sql
	psql -qXc "copy (select numerator, denominator from bivariate_axis) to stdout with csv;" | parallel --colsep ',' "psql -f tables/bivariate_axis_analytics.sql -v numerator={1} -v denominator={2}"
	psql -c "vacuum analyze bivariate_axis;"
	touch $@

db/table/bivariate_axis_correlation: db/table/bivariate_axis db/table/stat_h3_quality db/table/bivariate_indicators | db/table ## Precalculated correlations for bivariate layers
	psql -f tables/bivariate_axis_correlation.sql
	touch $@

db/table/bivariate_overlays: db/table/osm_meta db/table/tile_logs | db/table ## Several default indicator presets for Bivariate manager.
	psql -f tables/bivariate_overlays.sql
	touch $@

db/table/bivariate_unit: db/table/stat_h3 | db/table ## Bivariate units description
	psql -f tables/bivariate_unit.sql
	touch $@

db/table/bivariate_unit_localization: db/table/bivariate_unit | db/table ## Bivariate unit localization
	psql -f tables/bivariate_unit_localization.sql
	touch $@

db/table/bivariate_indicators: db/table/bivariate_unit_localization | db/table ## Bivariate indicators properties, and attribution used in Bivariate manager.
	psql -f tables/bivariate_indicators.sql
	touch $@

db/table/bivariate_colors: db/table/stat_h3 | db/table ## Color pallets used for styling layers in Bivariate manager.
	psql -f tables/bivariate_colors.sql
	touch $@

data/tile_logs: | data ## Directory for OpenStreetMap tiles usage statistics dataset.
	mkdir -p $@

data/tile_logs/_download: | data/tile_logs data ## Download OpenStreetMap tiles usage logs.
	cd data/tile_logs/ && wget -A xz -r -l 1 -nd -np -nc https://planet.openstreetmap.org/tile_logs/
	touch $@

db/table/tile_logs: data/tile_logs/_download db/procedure/generate_overviews | db/table ## OpenStreetMap tiles usage logs imported into database.
	psql -c "drop table if exists tile_logs;"
	psql -c "create table tile_logs (tile_date timestamptz, z int, x int, y int, view_count int, geom geometry generated always as (ST_Transform(ST_TileEnvelope(z, x, y), 4326)) stored);"
	find data/tile_logs/ -type f -size +10M | sort -r | head -30 | parallel "xzcat {} | python3 scripts/import_osm_tile_logs.py {} | psql -c 'copy tile_logs from stdin with csv'"
	psql -f tables/tile_stats.sql
	psql -f tables/tile_logs_h3.sql
	psql -c "call generate_overviews('tile_logs_h3', '{view_count}'::text[], '{sum}'::text[], 8);"
	touch $@

data/tile_logs/tiles-2022-02-23.txt.xz: | data/tile_logs/_download ## use txt.xz file as footprint not to run next target every run.
	touch $@

db/table/tile_logs_bf2402: db/procedure/generate_overviews | data/tile_logs/tiles-2022-02-23.txt.xz db/table ## OpenStreetMap tiles logs 30 days before 24.02.2022.
	psql -c "drop table if exists tile_logs_bf2402;"
	psql -c "create table tile_logs_bf2402 (tile_date timestamptz, z int, x int, y int, view_count int);"
	cat static_data/tile_list/tile_logs_list.txt | parallel "xzcat {} | python3 scripts/import_osm_tile_logs.py {} | psql -c 'copy tile_logs_bf2402 from stdin with csv'"
	psql -f tables/tile_stats_bf2402.sql
	psql -f tables/tile_logs_bf2402_h3.sql
	psql -c "call generate_overviews('tile_logs_bf2402_h3', '{view_count_bf2402}'::text[], '{sum}'::text[], 8);"
	touch $@

data/out/osm_users_hex.sql.gz: db/table/osm_users_hex | data/out  ## Select most active user per H3 hexagon cell dump.
	rm -f data/out/osm_users_hex.sql.gz data/out/osm_users_hex.sql data/out/osm_users_hex_update_time
	pg_dump --no-tablespaces --data-only --no-owner -t osm_users_hex -f data/out/osm_users_hex.sql
	pigz --best data/out/osm_users_hex.sql
	echo $$(date '+%Y-%m-%d %H:%M:%S') > data/out/osm_users_hex_update_time
	touch $@

data/out/osm_users_hex_dump_min_file_size: data/out/osm_users_hex.sql.gz| data/out ## Checking minimum file size.
	bash scripts/check_min_file_size.sh data/out/osm_users_hex.sql.gz 750
	touch $@

deploy/s3/test/osm_users_hex_dump: data/out/osm_users_hex.sql.gz | deploy/s3/test ## Putting active user dump from local folder to AWS dev folder in private bucket.
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/test/osm_users_hex.sql.gz s3://geodata-eu-central-1-kontur/private/geocint/test/osm_users_hex.sql.gz.bak --profile geocint_pipeline_sender || true
	aws s3 cp data/out/osm_users_hex.sql.gz      s3://geodata-eu-central-1-kontur/private/geocint/test/osm_users_hex.sql.gz      --profile geocint_pipeline_sender
	aws s3 cp data/out/osm_users_hex_update_time s3://geodata-eu-central-1-kontur/private/geocint/test/osm_users_hex_update_time --profile geocint_pipeline_sender
	touch $@

deploy/s3/prod/osm_users_hex_dump: deploy/s3/test/osm_users_hex_dump data/out/osm_users_hex_dump_min_file_size | deploy/s3/prod ## Putting active user dump from test folder to prod one in private bucket.
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/prod/osm_users_hex.sql.gz      s3://geodata-eu-central-1-kontur/private/geocint/prod/osm_users_hex.sql.gz.bak  --profile geocint_pipeline_sender || true
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/test/osm_users_hex.sql.gz      s3://geodata-eu-central-1-kontur/private/geocint/prod/osm_users_hex.sql.gz      --profile geocint_pipeline_sender
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/test/osm_users_hex_update_time s3://geodata-eu-central-1-kontur/private/geocint/prod/osm_users_hex_update_time --profile geocint_pipeline_sender
	touch $@

tile_generator/tile_generator: tile_generator/main.go tile_generator/go.mod  ## Compile tile_generator with GO
	cd tile_generator; go get; go build -o tile_generator

data/tiles/users_tiles.tar.bz2: tile_generator/tile_generator db/table/osm_users_hex db/table/osm_meta db/function/tile_zoom_level_to_h3_resolution data/out/tile_zoom_level_to_h3_resolution_test | data/tiles ## Generate vector tiles from osm_users_hex table (most active user per H3 hexagon cell) and archive it for further deploy to QA and production servers.
	tile_generator/tile_generator -j 32 --min-zoom 0 --max-zoom 8 --sql-query-filepath 'scripts/users.sql' --db-config 'dbname=gis user=gis' --output-path data/tiles/users
	cd data/tiles/users/; tar cvf ../users_tiles.tar.bz2 --use-compress-prog=pbzip2 ./

deploy/geocint/users_tiles: data/tiles/users_tiles.tar.bz2 | deploy/geocint ## Copy vector tiles from osm_users_hex table to public_html folder to make them available online.
	sudo mkdir -p /var/www/tiles; sudo chmod 777 /var/www/tiles
	rm -rf /var/www/tiles/users_new; mkdir -p /var/www/tiles/users_new
	cp -a data/tiles/users/. /var/www/tiles/users_new/
	rm -rf /var/www/tiles/users_old
	mv /var/www/tiles/users /var/www/tiles/users_old; mv /var/www/tiles/users_new /var/www/tiles/users
	touch $@

deploy/dev/users_tiles: data/tiles/users_tiles.tar.bz2 | deploy/dev ## Deploy vector tiles from osm_users_hex table to TEST DVLP server.
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

deploy/test/users_tiles: data/tiles/users_tiles.tar.bz2 | deploy/test ## Deploy vector tiles from osm_users_hex table to TEST QA server.
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

deploy/prod/users_tiles: data/tiles/users_tiles.tar.bz2 | deploy/prod ## Deploy vector tiles from osm_users_hex table to PROD server.
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

data/out/population/stat_h3.sqld.gz: db/table/stat_h3 | data/out/population ## Crafting production friendly SQL dump for stat_h3 table
	bash -c "cat scripts/population_api_dump_header.sql <(pg_dump --no-owner --no-tablespaces -t stat_h3 | sed 's/ public.stat_h3 / public.stat_h3__new /; s/^CREATE INDEX stat_h3.*//;') scripts/population_api_dump_footer.sql | pigz" > $@__TMP
	mv $@__TMP $@
	touch $@

data/out/population/bivariate_tables_checks: db/table/bivariate_axis db/table/bivariate_axis_correlation db/table/bivariate_overlays db/table/bivariate_indicators db/table/bivariate_colors | data/out/population ## series of bivariate tables quality checks
	psql -AXt -c "select count(*) from bivariate_axis where quality = 'NaN' or quality is NULL;" |  xargs -I {} bash scripts/check_items_count.sh {} 0
	psql -AXt -c "select count(*) from bivariate_axis_correlation where quality = 'NaN' or correlation = 'NaN' or quality is NULL or correlation is NULL;" |  xargs -I {} bash scripts/check_items_count.sh {} 0
	touch $@

data/out/population/bivariate_tables.sqld.gz: data/out/population/bivariate_tables_checks | data/out/population ## Crafting bivariate tables SQL dump
	bash -c "pg_dump --clean --if-exists --no-owner --no-tablespaces -t bivariate_axis -t bivariate_axis_correlation -t bivariate_axis_stats -t bivariate_colors -t bivariate_indicators -t bivariate_overlays -t bivariate_unit -t bivariate_unit_localization | pigz" > $@__TMP
	mv $@__TMP $@
	touch $@

deploy/s3/prod/stat_h3_dump: data/out/population/stat_h3.sqld.gz | deploy/s3/prod ## Copying stat_h3 table dump from server to AWS-prod one.
	# (|| true) is needed to avoid failing when there is nothing to be backed up. that is the case on a first run or when bucket got changed.
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/prod/stat_h3.sqld.gz s3://geodata-eu-central-1-kontur/private/geocint/prod/stat_h3.sqld.gz.bak --profile geocint_pipeline_sender || true
	aws s3 cp data/out/population/stat_h3.sqld.gz s3://geodata-eu-central-1-kontur/private/geocint/prod/stat_h3.sqld.gz --profile geocint_pipeline_sender
	touch $@

deploy/s3/prod/bivariate_tables_dump: data/out/population/bivariate_tables.sqld.gz | deploy/s3/prod ## Сopying bivariate tables dump from server to AWS-prod one.
	# (|| true) is needed to avoid failing when there is nothing to be backed up. that is the case on a first run or when bucket got changed.
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/prod/bivariate_tables.sqld.gz s3://geodata-eu-central-1-kontur/private/geocint/prod/bivariate_tables.sqld.gz.bak --profile geocint_pipeline_sender || true
	aws s3 cp data/out/population/bivariate_tables.sqld.gz s3://geodata-eu-central-1-kontur/private/geocint/prod/bivariate_tables.sqld.gz --profile geocint_pipeline_sender
	touch $@

deploy/s3/prod/population_api_tables_check_mdate: deploy/s3/prod/stat_h3_dump deploy/s3/prod/bivariate_tables_dump data/out/population/stat_h3.sqld.gz data/out/population/bivariate_tables.sqld.gz | deploy/s3/prod ## Checking if dumps on AWS is not older than local file.
	bash scripts/check_population_api_tables_dump_dates.sh
	touch $@

deploy/prod/population_api_tables: deploy/s3/prod/population_api_tables_check_mdate | deploy/prod ## Getting population_api_tables dump from AWS private prod folder and restoring it.
	ansible lima_insights_api -m file -a 'path=$$HOME/tmp state=directory mode=0770'
	ansible lima_insights_api -m amazon.aws.aws_s3 -a 'bucket=geodata-eu-central-1-kontur object=/private/geocint/prod/stat_h3.sqld.gz dest=$$HOME/tmp/stat_h3.sqld.gz mode=get'
	ansible lima_insights_api -m amazon.aws.aws_s3 -a 'bucket=geodata-eu-central-1-kontur object=/private/geocint/prod/bivariate_tables.sqld.gz dest=$$HOME/tmp/bivariate_tables.sqld.gz mode=get'
	ansible lima_insights_api -m community.postgresql.postgresql_db -a 'name=insights-api maintenance_db=insights-api login_user=insights-api login_host=paris.kontur.io state=restore target=$$HOME/tmp/stat_h3.sqld.gz target_opts="-v ON_ERROR_STOP=1"'
	ansible lima_insights_api -m community.postgresql.postgresql_db -a 'name=insights-api maintenance_db=insights-api login_user=insights-api login_host=paris.kontur.io state=restore target=$$HOME/tmp/bivariate_tables.sqld.gz target_opts="-v ON_ERROR_STOP=1"'
	ansible lima_insights_api -m file -a 'path=$$HOME/tmp/bivariate_tables.sqld.gz state=absent'
	ansible lima_insights_api -m file -a 'path=$$HOME/tmp/stat_h3.sqld.gz state=absent'
	touch $@

deploy/prod/cleanup_cache_old: deploy/prod/population_api_tables | deploy/prod ## Clear insights-api cache on Prod.
	bash scripts/check_http_response_code.sh GET https://apps.kontur.io/insights-api/cache/cleanUp 200
	touch $@


data/in/kontur_events: | data/in ## Download dir for kontur_events files.
	mkdir -p $@

data/out/kontur_events: | data/out ## Output dir for kontur_events updated files
	mkdir -p $@

data/in/kontur_events/download: | data/in/kontur_events ## Download kontur-events.geojsons for every tier.
	rm -f data/in/kontur_events/*.geojson
	aws s3 cp "s3://event-api-locker01/kontur_events/EXP/kontur-events.geojson"      data/in/kontur_events/kontur-events-exp.geojson  --profile kontur-events
	aws s3 cp "s3://event-api-locker01/kontur_events/TEST DEV/kontur-events.geojson" data/in/kontur_events/kontur-events-dev.geojson  --profile kontur-events
	aws s3 cp "s3://event-api-locker01/kontur_events/TEST QA/kontur-events.geojson"  data/in/kontur_events/kontur-events-test.geojson --profile kontur-events
	aws s3 cp "s3://event-api-locker01/kontur_events/PROD/kontur-events.geojson"     data/in/kontur_events/kontur-events-prod.geojson --profile kontur-events
	touch $@

data/out/kontur_events/updated:  data/in/kontur_events/download | data/out/kontur_events ## update.
	rm -f data/out/kontur_events/*.geojson
	cat data/in/kontur_events/kontur-events-exp.geojson  | jq | sed "/updated_at/c\ \"updated_at\" : \"${shell date '+%d-%m-%YT%H:%M:%SZ'}\"" | jq -c . > data/out/kontur_events/kontur-events-exp.geojson
	cat data/in/kontur_events/kontur-events-dev.geojson  | jq | sed "/updated_at/c\ \"updated_at\" : \"${shell date '+%d-%m-%YT%H:%M:%SZ'}\"" | jq -c . > data/out/kontur_events/kontur-events-dev.geojson
	cat data/in/kontur_events/kontur-events-test.geojson | jq | sed "/updated_at/c\ \"updated_at\" : \"${shell date '+%d-%m-%YT%H:%M:%SZ'}\"" | jq -c . > data/out/kontur_events/kontur-events-test.geojson
	cat data/in/kontur_events/kontur-events-prod.geojson | jq | sed "/updated_at/c\ \"updated_at\" : \"${shell date '+%d-%m-%YT%H:%M:%SZ'}\"" | jq -c . > data/out/kontur_events/kontur-events-prod.geojson
	touch $@

deploy/s3/test/kontur_events_updated: data/out/kontur_events/updated | deploy/s3/test ## create backups and load updated files.
	aws s3 cp "s3://event-api-locker01/kontur_events/EXP/kontur-events.geojson" "s3://event-api-locker01/kontur_events/EXP/kontur-events.geojson.bak" --profile kontur-events
	aws s3 cp data/out/kontur_events/kontur-events-exp.geojson "s3://event-api-locker01/kontur_events/EXP/kontur-events.geojson" --profile kontur-events
	aws s3 cp "s3://event-api-locker01/kontur_events/TEST DEV/kontur-events.geojson" "s3://event-api-locker01/kontur_events/TEST DEV/kontur-events.geojson.bak" --profile kontur-events
	aws s3 cp data/out/kontur_events/kontur-events-dev.geojson "s3://event-api-locker01/kontur_events/TEST DEV/kontur-events.geojson" --profile kontur-events
	aws s3 cp "s3://event-api-locker01/kontur_events/TEST QA/kontur-events.geojson" "s3://event-api-locker01/kontur_events/TEST QA/kontur-events.geojson.bak" --profile kontur-events
	aws s3 cp data/out/kontur_events/kontur-events-test.geojson "s3://event-api-locker01/kontur_events/TEST QA/kontur-events.geojson" --profile kontur-events
	touch $@

deploy/s3/prod/kontur_events_updated: data/out/kontur_events/updated | deploy/s3/prod ## create backups and load updated files.
	aws s3 cp "s3://event-api-locker01/kontur_events/PROD/kontur-events.geojson" "s3://event-api-locker01/kontur_events/PROD/kontur-events.geojson.bak" --profile kontur-events
	aws s3 cp data/out/kontur_events/kontur-events-prod.geojson "s3://event-api-locker01/kontur_events/PROD/kontur-events.geojson" --profile kontur-events
	touch $@

data/in/event_api_data: | data/in ## download directory for events-api data
	mkdir -p $@

data/in/event_api_data/kontur_public_feed: | data/in/event_api_data ## download event-api data (only kontur-public feed at the moment)
	python3 ./scripts/event_api_parser.py \
		-e \
		--work-dir ./data/in/event_api_data \
		--stage prod \
		--feed kontur-public
	touch $@

db/table/disaster_event_episodes: data/in/event_api_data/kontur_public_feed | db/table  ## import kontur-public feed event episodes in database
	psql -c 'drop table if exists disaster_event_episodes;'
	psql -c 'create table if not exists disaster_event_episodes (fid serial primary key, eventid uuid, episode_type text, episode_severity text, episode_name text, episode_startedat timestamptz, episode_endedat timestamptz, geom geometry(geometry, 4326));'
	find data/in/event_api_data/kontur-public/ -name "*.geojson*" -type f | parallel 'ogr2ogr --config PG_USE_COPY YES -append -f PostgreSQL PG:"dbname=gis" {} -nln disaster_event_episodes -a_srs EPSG:4326'
	psql -c 'create index disaster_event_episodes_episode_type_episode_endedat_idx on disaster_event_episodes (episode_type, episode_endedat)'
	touch $@

db/table/disaster_event_episodes_h3: db/table/disaster_event_episodes db/table/land_polygons_h3_r8 db/table/osm | db/table  ## hexagonify kontur-public event geometries
	psql -f tables/disaster_event_episodes_h3.sql
	touch $@

db/table/total_road_length_h3: db/table/facebook_roads_h3 db/table/hexagons_for_regression db/table/facebook_roads_in_h3_r8 db/table/osm_road_segments_h3 db/table/kontur_population_h3 db/procedure/generate_overviews | db/table ## adjust total road length with linear regression from population
	psql -f tables/total_road_length_h3.sql
	psql -c "call generate_overviews('total_road_length_h3', '{total_road_length}'::text[], '{sum}'::text[], 8);"
	touch $@

### Global solar atlas ###
## Global solar atlas - create dirs
data/in/raster/global_solar_atlas: | data/in/raster ## Directory for Global Solar Atlas datasets.
	mkdir -p $@

data/mid/global_solar_atlas: | data/mid ## Create folder for global solar atlas datasets
	mkdir -p $@

data/mid/global_solar_atlas/GHI: | data/mid/global_solar_atlas ## Create folder for GHI  (global solar atlas dataset)
	mkdir -p $@

## Global solar atlas - dowload zip files

data/in/raster/global_solar_atlas/World_GHI_GISdata_LTAy_AvgDailyTotals_GlobalSolarAtlas-v2_GEOTIFF.zip: | data/in/raster/global_solar_atlas ## Download Global Solar Atlas GHI dataset from S3
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/in/global_solar_atlas/World_GHI_GISdata_LTAy_AvgDailyTotals_GlobalSolarAtlas-v2_GEOTIFF.zip $@ --profile geocint_pipeline_sender
	touch $@

## Global solar atlas - unzip

data/mid/global_solar_atlas/GHI/unzip: data/in/raster/global_solar_atlas/World_GHI_GISdata_LTAy_AvgDailyTotals_GlobalSolarAtlas-v2_GEOTIFF.zip | data/mid/global_solar_atlas/GHI ## Unzip Global Solar Atlas GHI dataset
	rm -f data/mid/global_solar_atlas/GHI/*.tif
	unzip -j -o data/in/raster/global_solar_atlas/World_GHI_GISdata_LTAy_AvgDailyTotals_GlobalSolarAtlas-v2_GEOTIFF.zip -d data/mid/global_solar_atlas/GHI/
	rm -f data/mid/global_solar_atlas/GTI/*.pdf
	touch $@

## Global solar atlas - download rasters to database

db/table/global_solar_atlas_ghi: data/mid/global_solar_atlas/GHI/unzip | db/table ## Load global solar atlas GHI dataset to database
	psql -c "drop table if exists global_solar_atlas_ghi;"
	raster2pgsql -M -Y -s 4326 data/mid/global_solar_atlas/GHI/GHI.tif -t auto global_solar_atlas_ghi | psql -q
	touch $@

## Global solar atlas - convert raster tables to h3 and create common table

db/table/global_solar_atlas_h3: db/table/global_solar_atlas_ghi db/procedure/generate_overviews | db/table ## Global solar atlas - H3 hexagons table with average GTI, GHI, PVOUT values from 1 to 8 resolution
	psql -f tables/global_solar_atlas_h3.sql
	psql -c "call generate_overviews('global_solar_atlas_h3', '{gsa_ghi}'::text[], '{avg}'::text[], 8);"
	psql -c "create index on global_solar_atlas_h3 (h3);"
	touch $@

### END Global solar atlas ###


### WorldClim temperatures ###
## Worldclim temperatures - create dirs

data/in/raster/worldclim: | data/in/raster ## Directory for Worldclim datasets.
	mkdir -p $@

data/mid/worldclim: | data/mid ## Create mid folder for worldclim datasets
	mkdir -p $@

data/mid/worldclim/avg_temp: | data/mid/worldclim ## Create mid folder average temperatures (Worldclim)
	mkdir -p $@

data/mid/worldclim/min_temp: | data/mid/worldclim ## Create mid folder min temperatures (Worldclim)
	mkdir -p $@

data/mid/worldclim/max_temp: | data/mid/worldclim ## Create mid folder max temperatures (Worldclim)
	mkdir -p $@

## WorldClim temperatures - dowload zip files

data/in/raster/worldclim/wc2.1_30s_tavg.zip: | data/in/raster/worldclim ## Download Worldclim avg temperatures from S3
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/in/worldclim/wc2.1_30s_tavg.zip $@ --profile geocint_pipeline_sender
	touch $@

data/in/raster/worldclim/wc2.1_30s_tmin.zip: | data/in/raster/worldclim ## Download Worldclim min temperatures from S3
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/in/worldclim/wc2.1_30s_tmin.zip $@ --profile geocint_pipeline_sender
	touch $@

data/in/raster/worldclim/wc2.1_30s_tmax.zip: | data/in/raster/worldclim ## Download Worldclim max temperatures from S3
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/in/worldclim/wc2.1_30s_tmax.zip $@ --profile geocint_pipeline_sender
	touch $@

## Worldclim temperatures - unzip

data/mid/worldclim/avg_temp/unzip: data/in/raster/worldclim/wc2.1_30s_tavg.zip | data/mid/worldclim/avg_temp ## Unzip Worldclim average temperatures
	rm -f data/mid/worldclim/avg_temp/*.tif
	unzip -j -o data/in/raster/worldclim/wc2.1_30s_tavg.zip -d data/mid/worldclim/avg_temp/
	touch $@

data/mid/worldclim/min_temp/unzip: data/in/raster/worldclim/wc2.1_30s_tmin.zip | data/mid/worldclim/avg_temp ## Unzip Worldclim min temperatures
	rm -f data/mid/worldclim/min_temp/*.tif
	unzip -j -o data/in/raster/worldclim/wc2.1_30s_tmin.zip -d data/mid/worldclim/min_temp/
	touch $@

data/mid/worldclim/max_temp/unzip: data/in/raster/worldclim/wc2.1_30s_tmax.zip | data/mid/worldclim/max_temp ## Unzip Worldclim max temperatures
	rm -f data/mid/worldclim/max_temp/*.tif
	unzip -j -o data/in/raster/worldclim/wc2.1_30s_tmax.zip -d data/mid/worldclim/max_temp/
	touch $@

## Worldclim temperatures - prepare datasets
## Worldclim temperatures - Calculate mean from averages
data/mid/worldclim/avg_temp/average_temperatures_in.tif: data/mid/worldclim/avg_temp/unzip | data/mid/worldclim/avg_temp ## Calculate average yearly temperature from Worldclim montly means
	rm -f $@
	gdal_calc.py -A data/mid/worldclim/avg_temp/wc2.1_30s_tavg_01.tif -B data/mid/worldclim/avg_temp/wc2.1_30s_tavg_02.tif -C data/mid/worldclim/avg_temp/wc2.1_30s_tavg_03.tif -D data/mid/worldclim/avg_temp/wc2.1_30s_tavg_04.tif -E data/mid/worldclim/avg_temp/wc2.1_30s_tavg_05.tif -F data/mid/worldclim/avg_temp/wc2.1_30s_tavg_06.tif -G data/mid/worldclim/avg_temp/wc2.1_30s_tavg_07.tif -H data/mid/worldclim/avg_temp/wc2.1_30s_tavg_08.tif -I data/mid/worldclim/avg_temp/wc2.1_30s_tavg_09.tif -J data/mid/worldclim/avg_temp/wc2.1_30s_tavg_10.tif -K data/mid/worldclim/avg_temp/wc2.1_30s_tavg_11.tif -L data/mid/worldclim/avg_temp/wc2.1_30s_tavg_12.tif --outfile=$@ --calc="numpy.mean((A,B,C,D,E,F,G,H,I,J,K,L),axis=0)"
	touch $@

data/mid/worldclim/avg_temp/average_temperatures.tif: data/mid/worldclim/avg_temp/average_temperatures_in.tif | data/mid/worldclim/avg_temp ## Change resolution of average yearly temperature from Worldclim montly means
	rm -f $@
	gdalwarp data/mid/worldclim/avg_temp/average_temperatures_in.tif -co compress=deflate -tr 0.005 0.005 $@
	touch $@

## Worldclim temperatures - Calculate min of mins

data/mid/worldclim/min_temp/minimal_temperatures_in.tif: data/mid/worldclim/min_temp/unzip | data/mid/worldclim/min_temp ## Calculate minimal yearly temperature from Worldclim montly minimals
	rm -f $@
	gdal_calc.py -A data/mid/worldclim/min_temp/wc2.1_30s_tmin_01.tif -B data/mid/worldclim/min_temp/wc2.1_30s_tmin_02.tif -C data/mid/worldclim/min_temp/wc2.1_30s_tmin_03.tif -D data/mid/worldclim/min_temp/wc2.1_30s_tmin_04.tif -E data/mid/worldclim/min_temp/wc2.1_30s_tmin_05.tif -F data/mid/worldclim/min_temp/wc2.1_30s_tmin_06.tif -G data/mid/worldclim/min_temp/wc2.1_30s_tmin_07.tif -H data/mid/worldclim/min_temp/wc2.1_30s_tmin_08.tif -I data/mid/worldclim/min_temp/wc2.1_30s_tmin_09.tif -J data/mid/worldclim/min_temp/wc2.1_30s_tmin_10.tif -K data/mid/worldclim/min_temp/wc2.1_30s_tmin_11.tif -L data/mid/worldclim/min_temp/wc2.1_30s_tmin_12.tif --outfile=$@ --calc="numpy.min((A,B,C,D,E,F,G,H,I,J,K,L),axis=0)"
	touch $@

data/mid/worldclim/min_temp/minimal_temperatures.tif: data/mid/worldclim/min_temp/minimal_temperatures_in.tif | data/mid/worldclim/min_temp ## Change resolution for minimal yearly temperature from Worldclim montly minimals
	rm -f $@
	gdalwarp data/mid/worldclim/min_temp/minimal_temperatures_in.tif -co compress=deflate -tr 0.005 0.005 $@
	touch $@

## Worldclim temperatures - Calculate max of maxs

data/mid/worldclim/max_temp/maximal_temperatures_in.tif: data/mid/worldclim/max_temp/unzip | data/mid/worldclim/max_temp ## Calculate maximal yearly temperature from Worldclim montly maximals
	rm -f $@
	gdal_calc.py -A data/mid/worldclim/max_temp/wc2.1_30s_tmax_01.tif -B data/mid/worldclim/max_temp/wc2.1_30s_tmax_02.tif -C data/mid/worldclim/max_temp/wc2.1_30s_tmax_03.tif -D data/mid/worldclim/max_temp/wc2.1_30s_tmax_04.tif -E data/mid/worldclim/max_temp/wc2.1_30s_tmax_05.tif -F data/mid/worldclim/max_temp/wc2.1_30s_tmax_06.tif -G data/mid/worldclim/max_temp/wc2.1_30s_tmax_07.tif -H data/mid/worldclim/max_temp/wc2.1_30s_tmax_08.tif -I data/mid/worldclim/max_temp/wc2.1_30s_tmax_09.tif -J data/mid/worldclim/max_temp/wc2.1_30s_tmax_10.tif -K data/mid/worldclim/max_temp/wc2.1_30s_tmax_11.tif -L data/mid/worldclim/max_temp/wc2.1_30s_tmax_12.tif --outfile=$@ --calc="numpy.max((A,B,C,D,E,F,G,H,I,J,K,L),axis=0)"
	touch $@

data/mid/worldclim/max_temp/maximal_temperatures.tif: data/mid/worldclim/max_temp/maximal_temperatures_in.tif | data/mid/worldclim/max_temp ## Change resolution of maximal yearly temperature from Worldclim montly maximals
	rm -f $@
	gdalwarp data/mid/worldclim/max_temp/maximal_temperatures_in.tif -co compress=deflate -tr 0.005 0.005 $@
	touch $@

## Worldclim temperatures - download rasters to database

db/table/worldclim_avg_temp: data/mid/worldclim/avg_temp/average_temperatures.tif | db/table ## Load worldclim average temperatures raster
	psql -c "drop table if exists worldclim_avg_temp;"
	raster2pgsql -M -Y -s 4326 data/mid/worldclim/avg_temp/average_temperatures.tif -t auto worldclim_avg_temp | psql -q
	touch $@

db/table/worldclim_min_temp: data/mid/worldclim/min_temp/minimal_temperatures.tif | db/table ## Load worldclim minimal temperatures raster
	psql -c "drop table if exists worldclim_min_temp;"
	raster2pgsql -M -Y -s 4326 data/mid/worldclim/min_temp/minimal_temperatures.tif -t auto worldclim_min_temp | psql -q
	touch $@

db/table/worldclim_max_temp: data/mid/worldclim/max_temp/maximal_temperatures.tif | db/table ## Load worldclim maximal temperatures raster
	psql -c "drop table if exists worldclim_max_temp;"
	raster2pgsql -M -Y -s 4326 data/mid/worldclim/max_temp/maximal_temperatures.tif -t auto worldclim_max_temp | psql -q
	touch $@

## Worldclim temperatures - create all tables and unite them to one
db/table/worldclim_temperatures_h3: db/table/worldclim_avg_temp db/table/worldclim_min_temp db/table/worldclim_max_temp db/procedure/generate_overviews | db/table ## Worldclim temperatures - create summary H3 table
	psql -f tables/worldclim_temperatures_h3.sql
	psql -c "call generate_overviews('worldclim_temperatures_h3', '{worldclim_avg_temperature, worldclim_min_temperature, worldclim_max_temperature, worldclim_amp_temperature}'::text[], '{avg, min, max, max}'::text[], 8);"
	psql -c "create index on worldclim_temperatures_h3 (h3);"
	touch $@

### END WorldClim temperatures ###

### Powerlines proximity ###

data/in/worldbank_powerlines: | data/in ## Directory for downloading worldbank powerlines gpkg
	mkdir $@

data/in/worldbank_powerlines/grid.gpkg: | data/in/worldbank_powerlines ## Download worldbank powerlines gpkg
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/in/world_bank_powerlines/grid.gpkg $@ --profile geocint_pipeline_sender
	touch $@

data/mid/worldbank_powerlines: | data/mid ## Directory for calculations of worldbank powerlines proximity
	mkdir $@

data/mid/worldbank_powerlines/worldbank_powerlines_proximity.tif: data/in/worldbank_powerlines/grid.gpkg | data/mid/worldbank_powerlines ## Worldbank powerlines proximity - calculate geotif
	bash scripts/global_proximity_map_from_vector.sh data/in/worldbank_powerlines/grid.gpkg grid data/mid/worldbank_powerlines $@
	rm -f data/mid/worldbank_powerlines/north*
	rm -f data/mid/worldbank_powerlines/south*
	rm -f data/mid/worldbank_powerlines/part*
	touch $@

db/table/powerlines_proximity: data/mid/worldbank_powerlines/worldbank_powerlines_proximity.tif | db/table ## Load worldbank powerlines proximity raster
	psql -c "drop table if exists powerlines_proximity;"
	raster2pgsql -M -Y -s 4326 data/mid/worldbank_powerlines/worldbank_powerlines_proximity.tif -t auto powerlines_proximity | psql -q
	touch $@

db/table/powerlines_proximity_h3_r8: db/table/powerlines_proximity | db/table ## Powerlines proximity - create summary H3 table
	psql -f scripts/proximity_raster_to_h3.sql -v table_name=powerlines_proximity -v table_name_h3=powerlines_proximity_h3_r8 -v aggr_func=avg -v item_name=powerlines_proximity_m -v threshold=1200000
	psql -c "create index on powerlines_proximity_h3_r8 (h3);"
	touch $@

### END Powerlines proximity ###

### City Waste management block ###

db/table/waste_containers_h3: db/table/osm db/index/osm_tags_idx db/procedure/generate_overviews | db/table ## create a table with the average number of waste containers within a hexagon or less than 75m apart per hexagon
	psql -f tables/waste_containers_h3.sql
	psql -c "call generate_overviews('waste_containers_h3', '{waste_basket_coverage}'::text[], '{sum}'::text[], 8);"
	touch $@

### End City waste management block ###

### Proximity to populated areas ###

data/in/populated_areas.gpkg: db/table/kontur_population_h3 | data/in ## Get populated areas GPKG
	ogr2ogr -f GPKG -t_srs EPSG:4326 $@ PG:"dbname=gis" -nln "populated" -sql "SELECT h3_cell_to_boundary_geometry(h3), population FROM kontur_population_h3 WHERE population>80 and resolution=8"
	touch $@

data/mid/populated_areas: | data/mid ## Directory for calculations of populated areas proximity
	mkdir $@

data/mid/populated_areas/populated_areas_proximity.tif: data/in/populated_areas.gpkg | data/mid/populated_areas ## Populated areas proximity - calculate geotif
	bash scripts/global_proximity_map_from_vector.sh data/in/populated_areas.gpkg populated data/mid/populated_areas $@
	rm -f data/mid/populated_areas/north*
	rm -f data/mid/populated_areas/south*
	rm -f data/mid/populated_areas/part*
	touch $@

db/table/populated_areas_proximity: data/mid/populated_areas/populated_areas_proximity.tif | db/table ## Load populated areas proximity raster
	psql -c "drop table if exists populated_areas_proximity;"
	raster2pgsql -M -Y -s 4326 data/mid/populated_areas/populated_areas_proximity.tif -t auto populated_areas_proximity | psql -q
	touch $@

db/table/populated_areas_proximity_h3_r8: db/table/populated_areas_proximity | db/table ## Populated areas proximity - create summary H3 table
	psql -f scripts/proximity_raster_to_h3.sql -v table_name=populated_areas_proximity -v table_name_h3=populated_areas_proximity_h3_r8 -v aggr_func=avg -v item_name=populated_areas_proximity_m -v threshold=1200000
	psql -c "create index on populated_areas_proximity_h3_r8 (h3);"
	touch $@

### END Proximity to populated areas ###

### Proximity to electric power substations ###

data/in/power_substations.gpkg: db/index/osm_tags_idx | data/in ## Get power substations GPKG
	ogr2ogr -f GPKG $@ PG:"dbname=gis" -nln "power_substations" -sql "SELECT osm_id, st_centroid(geog)::geometry as geometry FROM osm WHERE tags@>'{\"power\":\"substation\"}'"
	touch $@

data/mid/power_substations: | data/mid ## Directory for calculations of power substations proximity
	mkdir $@

data/mid/power_substations/power_substations_proximity.tif: data/in/power_substations.gpkg | data/mid/power_substations ## power substations proximity - calculate geotif
	bash scripts/global_proximity_map_from_vector.sh data/in/power_substations.gpkg power_substations data/mid/power_substations $@
	rm -f data/mid/power_substations/north*
	rm -f data/mid/power_substations/south*
	rm -f data/mid/power_substations/part*
	touch $@

db/table/power_substations_proximity: data/mid/power_substations/power_substations_proximity.tif | db/table ## Load power substations proximity raster
	psql -c "drop table if exists power_substations_proximity;"
	raster2pgsql -M -Y -s 4326 data/mid/power_substations/power_substations_proximity.tif -t auto power_substations_proximity | psql -q
	touch $@

db/table/power_substations_proximity_h3_r8: db/table/power_substations_proximity | db/table ## Power substations proximity - create summary H3 table
	psql -f scripts/proximity_raster_to_h3.sql -v table_name=power_substations_proximity -v table_name_h3=power_substations_proximity_h3_r8 -v aggr_func=avg -v item_name=power_substations_proximity_m -v threshold=1200000
	psql -c "create index on power_substations_proximity_h3_r8 (h3);"
	touch $@

### END Proximity to electric power substationss ###

### Unite all proximity maps to one and generate overviews
db/table/proximities_h3: db/table/power_substations_proximity_h3_r8 db/table/populated_areas_proximity_h3_r8 db/table/powerlines_proximity_h3_r8 db/table/land_polygons_h3_r8 db/procedure/generate_overviews | db/table ## Unite proximity maps to one table
	psql -f tables/proximities_h3.sql
	psql -c "create index on proximities_h3 (h3);"
	psql -c "call generate_overviews('proximities_h3', '{powerlines_proximity_m, populated_areas_proximity_m, power_substations_proximity_m}'::text[], '{avg, avg, avg}'::text[], 8);"
	touch $@

### Synthetic solar farms placement layer ###

db/table/solar_farms_placement_suitability_synthetic_h3: db/table/proximities_h3 db/table/worldclim_temperatures_h3 db/table/global_solar_atlas_h3 db/table/gebco_2022_h3 db/table/kontur_population_h3 db/procedure/generate_overviews | db/table ## create a table with synthetic solar farms placement suitability (MCDA)
	psql -f tables/solar_farms_placement_suitability_synthetic_h3.sql
	psql -c "call generate_overviews('solar_farms_placement_suitability_synthetic_h3', '{solar_farms_placement_suitability}'::text[], '{avg}'::text[], 8);"
	psql -c "create index on solar_farms_placement_suitability_synthetic_h3 (h3);"
	touch $@

### END Synthetic solar farms placement layer ###

### Existing Solar power panels layer ###

db/table/existing_solar_power_panels_h3: db/table/osm db/index/osm_tags_idx db/procedure/generate_overviews | db/table ## Get existing solar power panels layer
	psql -f tables/existing_solar_power_panels_h3.sql
	psql -c "call generate_overviews('existing_solar_power_panels_h3', '{solar_power_plants}'::text[], '{sum}'::text[], 8);"
	psql -c "create index on existing_solar_power_panels_h3 (h3);"
	touch $@

### End existing Solar power panels layer ###

### Safety index layer - Global Peace Index 2022 ###

db/table/kontur_boundaries_hasc_codes_check: | db/table ## create if not exist table to store hascs that were missed in Kontur Boundaries
	psql -c "drop table if exists kontur_boundaries_hasc_codes_check;"
	psql -c "create table if not exists kontur_boundaries_hasc_codes_check (missed_hasc text, source_of_missed_hasc text, found_at TIMESTAMPTZ DEFAULT NOW());"
	touch $@

db/procedure/transform_hasc_to_h3: db/table/kontur_boundaries db/table/kontur_boundaries_hasc_codes_check | db/procedure ## Transform information with hasc codes to h3 indexes with using kontur_boundaries.
	psql -f procedures/transform_hasc_to_h3.sql
	touch $@

db/table/safety_index_per_country: | db/table ## Get existing solar power panels layer
	psql -c 'drop table if exists safety_index_per_country_in;'
	psql -c 'create table safety_index_per_country_in (iso3 char(3), iso2 char(2), name text, safety_index float);'
	cat static_data/mcda/global_safety_index_2008-2022.csv | psql -c "copy safety_index_per_country_in(iso3, iso2, name, safety_index) from stdin with csv header delimiter ',';"
	psql -c 'drop table if exists safety_index_per_country;'
	psql -c 'create table safety_index_per_country as (select iso3, iso2, name, p.maximum - safety_index as safety_index from safety_index_per_country_in, (select max(safety_index) maximum from safety_index_per_country_in) p);'
	touch $@

db/table/safety_index_h3: db/table/safety_index_per_country db/table/kontur_boundaries db/procedure/generate_overviews db/procedure/transform_hasc_to_h3 | db/table ## transform hasc codes to h3 indexes and generate overviews
	psql -c "call transform_hasc_to_h3('safety_index_per_country', 'safety_index_h3', 'iso2', '{safety_index}'::text[], 8);"
	psql -c "call generate_overviews('safety_index_h3', '{safety_index}'::text[], '{max}'::text[], 8);"
	psql -c "create index on safety_index_h3 (h3);"
	touch $@

data/out/missed_hascs_check: db/procedure/transform_hasc_to_h3 db/table/kontur_boundaries db/table/safety_index_h3 db/table/global_rva_h3 db/table/ndpba_rva_h3 | data/out ## Check if hasc codes were missed im kontur boundaries and send a message
	echo 'List of 15 most frequent missed hasc-codes. Check kontur_boundaries_hasc_codes_check table for additional information.' > $@__MISSED_HASCS_MESSAGE
	echo '```' >> $@__MISSED_HASCS_MESSAGE
	psql --set null=¤ --set linestyle=unicode --set border=2 -qXc "select missed_hasc, count(*) from kontur_boundaries_hasc_codes_check group by 1 order by 2 desc limit 15;" >> $@__MISSED_HASCS_MESSAGE
	echo '```' >> $@__MISSED_HASCS_MESSAGE
	psql -qXtc "select count(*) from kontur_boundaries_hasc_codes_check;" > $@__NUMBER_MISSED_HASCS
	if [ 0 -lt $$(cat $@__NUMBER_MISSED_HASCS) ]; then cat $@__MISSED_HASCS_MESSAGE | python3 scripts/slack_message.py $$SLACK_CHANNEL ${SLACK_BOT_NAME} $$SLACK_BOT_EMOJI; fi
	rm -f $@__MISSED_HASCS_MESSAGE $@__NUMBER_MISSED_HASCS
	touch $@

### End Safety index layer ###

### HOT projects block ###

data/in/hot_projects: | data/in ## input directory for hot projects data
	mkdir -p $@

data/in/hot_projects/hot_projects: data/in/hot_projects | data/in ## Download hot projects data
	seq 0 2000 12000 | parallel 'wget -q -O data/in/hot_projects/hot_projects_{}.geojson "https://api.kontur.io/layers/v2/collections/hotProjects_outlines/items?limit=2000&offset={}"'
	touch $@

db/table/hot_projects: data/in/hot_projects/hot_projects | db/table ##load hot projects data to table
	psql -c "drop table if exists hot_projects;"
	ogr2ogr -append -f PostgreSQL -a_srs EPSG:4326 PG:"dbname=gis" data/in/hot_projects/hot_projects_0.geojson -sql 'select * from hot_projects_0 limit 0' -nln hot_projects --config PG_USE_COPY YES -lco GEOMETRY_NAME=geom
	psql -c "alter table hot_projects drop column mappingtypes;"
	psql -c "alter table hot_projects add column mappingtypes character varying[];"
	ls -S data/in/hot_projects/hot_projects_*.geojson | parallel -j 1 'ogr2ogr -append -f PostgreSQL -a_srs EPSG:4326 PG:"dbname=gis" {} -nln hot_projects --config PG_USE_COPY YES'
	psql -c "update hot_projects set geom = st_makevalid(geom);"
	psql -c "create index on hot_projects using gist(geom);"
	touch $@

### End HOT projects block

### GHS population rasters import block

data/in/ghsl: | data/in ## Directory for ghs population raster files
	mkdir -p $@

data/mid/ghsl: | data/mid ## Directory for ghs population unzipped raster files
	mkdir -p $@

data/in/ghsl/download: | data/in/ghsl ## Download population raster files in parallel
	parallel -a static_data/ghsl/list-of-urls wget -nc -P $(@D) {} --rejected-log=$(@D)/_download-errors.log
	if [ ! -f $(@D)/_download-errors.log ]; then touch $@; fi
	rm -f $(@D)/_download-errors.log

data/mid/ghsl/unzip: data/in/ghsl/download | data/mid/ghsl ## Unzip population raster files in parallel
	rm data/mid/ghsl/*
	ls data/in/ghsl/*.zip | parallel "unzip -o {} -d data/mid/ghsl/"
	rm data/mid/ghsl/*.tif.ovr
	touch $@

db/table/ghsl: data/mid/ghsl/unzip db/procedure/insert_projection_54009 ## Import into db population raster files in parallel
	ls data/mid/ghsl/*.tif | parallel "raster2pgsql -d -M -Y -s 54009 -t auto -e {} {/.} | psql -q"
	touch $@

db/table/ghsl_h3: db/table/ghsl ## Create table with h3 index and population from raster tables in parallel
	ls data/mid/ghsl/*.tif | parallel 'psql -f tables/population_raster_grid_h3_r8.sql -v population_raster={/.} -v population_raster_grid_h3_r8={/.}_h3'
	ls data/mid/ghsl/*.tif | parallel 'psql -c "create index on {/.}_h3 using gist(h3_cell_to_geometry(h3))"'
	touch $@

db/function/ghs_pop_dither: ## Function to dithers ghs population per country
	psql -f functions/ghs_pop_dither.sql
	touch $@

### End GHS population rasters import block

### ghsl india snapshots

db/table/ghsl_h3_dither: db/table/ghsl_h3 ## Create tables for every ghs_pop_year
	ls data/mid/ghsl/*.tif | parallel 'psql -c "drop table if exists {/.}_h3_dither;"'
	ls data/mid/ghsl/*.tif | parallel 'psql -c "create table {/.}_h3_dither(h3 h3index, population integer, geom geometry(geometry,4326));"'
	touch $@

db/table/export_ghsl_h3_dither: db/table/hdx_boundaries db/table/ghsl_h3_dither db/function/ghs_pop_dither ## Dither and insert results in tables
	ls data/mid/ghsl/*.tif | parallel -q psql -c "select ghs_pop_dither('{/.}_h3', '{/.}_h3_dither')"
	touch $@

data/out/ghsl_output: | data/out ## Directory for ghs population gpkg for India, hasc equal IN
	mkdir -p $@

data/out/ghsl_output/export_gpkg: db/table/export_ghsl_h3_dither | data/out/ghsl_output ## Exports gpkg for India, hasc equal IN from tables
	seq 1975 5 2020 | parallel "echo $$(date '+%Y%m%d') {}" | parallel "ogr2ogr -overwrite -f GPKG data/out/ghsl_output/kontur_historical_population_density_for_{1}_IN_{2}.gpkg PG:'dbname=gis' -sql 'select distinct a.h3, a.population, a.geom from ghs_pop_e{1}_globe_r2022a_54009_100_v1_0_h3_dither as a, hdx_boundaries as b where b.hasc ='\''IN'\'' and ST_Intersects(a.geom,b.geom)' -nln kontur_historical_population_density_for_{1}_IN_{2} -lco OVERWRITE=yes"
	touch $@

### End ghsl india snapshots

### Update customviz using hdxloader ###

data/out/hdxloader: | data/in ## Directory for yml files for updates
	mkdir -p $@

db/table/hdx_boundaries_iso3_bbox: db/table/hdx_boundaries db/table/hdx_locations_with_wikicodes | db/table ## Prepare table with iso3 code and bbox
	psql -f tables/hdx_boundaries_iso3_bbox.sql
	touch $@

data/out/hdxloader/hdxloader_update_customviz_boundaries.yml: db/table/hdx_boundaries_iso3_bbox | data/out/hdxloader ## Generate yml files to update custoviz for country_boundaries datasets
	psql -t -A -X -F ";" -c "select * from hdx_boundaries_iso3_bbox;" | awk -F ";" 'BEGIN { print "{" } { printf "\x27%s\x27: {\x27customviz\x27: [{\x27url\x27: \x27https://apps.disaster.ninja/active/?map=2.000/30.000/0.100&app=f70488c2-055c-4599-a080-ded10c47730f&feed=kontur-public&layers=kontur_lines&%s\x27}]},\n", $$1, $$2 } ' | sed '$$ s/\(.*\),)*/\1\n}/' > $@

data/out/hdxloader/hdxloader_update_customviz_population.yml: db/table/hdx_boundaries_iso3_bbox | data/out/hdxloader ## Generate yml files to update custoviz for country_population datasets
	psql -t -A -X -F ";" -c "select * from hdx_boundaries_iso3_bbox;" | awk -F ";" 'BEGIN { print "{" } { printf "\x27%s\x27: {\x27customviz\x27: [{\x27url\x27: \x27https://apps.disaster.ninja/active/?map=2.000/30.000/0.100&app=f70488c2-055c-4599-a080-ded10c47730f&feed=kontur-public&layers=kontur_zmrok%2Cpopulation_density&%s\x27}]},\n", $$1, $$2 } ' | sed '$$ s/\(.*\),)*/\1\n}/' > $@

data/out/hdxloader/hdxloader_update_customviz: data/out/hdxloader/hdxloader_update_customviz_boundaries.yml data/out/hdxloader/hdxloader_update_customviz_population.yml | data/out/hdxloader ## Do actual update
	[ -z $$HDX_API_TOKEN ] && { echo "HDX_API_TOKEN is empty, please set it before running"; exit 1; } || echo "HDX_API_TOKEN is set - OK"
	python3 -m hdxloader update -t country-boundaries --update_by_iso3 --iso3_file data/out/hdxloader/hdxloader_update_customviz_boundaries.yml --hdx-site prod -k $$HDX_API_TOKEN --no-dry-run
	python3 -m hdxloader update -t country-population --update_by_iso3 --iso3_file data/out/hdxloader/hdxloader_update_customviz_population.yml --hdx-site prod -k $$HDX_API_TOKEN --no-dry-run
	psql -c "drop table if exists hdx_boundaries_iso3_bbox;"
	touch $@

### End update customviz using hdxloader ###

### Live Sensor Data integration block
data/in/live_sensor_data_h3.csv: | data/in ## download fresh dump with live sensor hexagonal data
	aws s3 cp s3://geodata-eu-central-1-kontur/private/geocint/data/in/live-sensor/prod/live_sensor_data_h3.csv $@ --profile geocint_pipeline_sender

db/table/live_sensor_data_h3: data/in/live_sensor_data_h3.csv | db/table ## load live sensor hexagonal data to database
	psql -c "drop table if exists live_sensor_data_h3;"
	psql -c "create table live_sensor_data_h3 (h3 h3index, resolution integer generated always as (h3_get_resolution(h3)) stored, stddev_accel double precision);"
	cat data/in/live_sensor_data_h3.csv| psql -c "copy live_sensor_data_h3(h3, stddev_accel) from stdin delimiter ',';"
	touch $@

### End Live Sensor Data integration block

### High Resolution Forest Canopy Height Maps
data/in/raster/meta_forest_canopy_height/download: | data/in/raster/meta_forest_canopy_height ## Download and rescale from 1 meter to 100 meters High Resolution Forest Canopy Height tifs from Data for Good at AWS S3.
	cd data/in/raster/meta_forest_canopy_height; aws s3 ls --profile geocint_pipeline_sender s3://dataforgood-fb-data/forests/v1/alsgedi_global_v6_float/chm/ | tr -s ' ' | cut -d' ' -f4 | grep 'tif$' | parallel 'aws s3 cp --profile geocint_pipeline_sender s3://dataforgood-fb-data/forests/v1/alsgedi_global_v6_float/chm/{} data/in/raster/meta_forest_canopy_height/chm/{} ; gdalwarp -tr 100 100 data/in/raster/meta_forest_canopy_height/chm/{} data/in/raster/meta_forest_canopy_height/chm/100m_{} ; rm {}'
	touch $@

db/table/meta_forest_canopy_height: data/in/raster/meta_forest_canopy_height/download | db/table ## Put forest canopy tiles in table.
	psql -c "drop table if exists meta_forest_canopy_height;"
	find -L data/in/raster/meta_forest_canopy_height/chm -name "*.tif" -type f | head -1 | parallel 'raster2pgsql -p -Y -s 3857 {} -t auto meta_forest_canopy_height | psql -q'
	find -L data/in/raster/meta_forest_canopy_height/chm -name "*.tif" -type f | parallel --eta 'GDAL_CACHEMAX=10000 GDAL_NUM_THREADS=6 raster2pgsql -a -Y -s 3857 {} -t auto meta_forest_canopy_height | psql -q'
	touch $@

db/table/meta_forest_canopy_height_h3: db/table/meta_forest_canopy_height | db/table ## Count height of forest canopy into h3 hexagons and generate overviews.
	psql -f tables/meta_forest_canopy_height_h3.sql
	psql -c "call generate_overviews('meta_forest_canopy_height_h3', '{avg_forest_canopy_height,max_forest_canopy_height}'::text[], '{avg,max}'::text[], 8);"
	touch $@

### Deploy through API

data/out/csv/view_count.csv: db/table/tile_logs | data/out/csv ## extract view_count to csv file 
	psql -q -X -c "copy (select h3, view_count from tile_logs_h3 where h3 is not null and view_count is not null) to stdout with delimiter ',' csv;" > data/out/csv/view_count.csv
	touch $@

data/out/csv/count.csv: db/table/osm_object_count_grid_h3 | data/out/csv ## extract count to csv file 
	psql -q -X -c "copy (select h3, count from osm_object_count_grid_h3 where h3 is not null and count is not null) to stdout with delimiter ',' csv;" > data/out/csv/count.csv
	touch $@

data/out/csv/populated_area_km2.csv: db/table/kontur_population_h3 | data/out/csv ## extract populated_area_km2 to csv file 
	psql -q -X -c "copy (select h3, populated_area / 1000000.0 as populated_area_km2 from kontur_population_h3 where h3 is not null and populated_area is not null) to stdout with delimiter ',' csv;" > data/out/csv/populated_area_km2.csv
	touch $@

data/out/csv/building_count.csv: db/table/osm_object_count_grid_h3 | data/out/csv ## extract building_count to csv file 
	psql -q -X -c "copy (select h3, building_count from osm_object_count_grid_h3 where h3 is not null and building_count is not null) to stdout with delimiter ',' csv;" > data/out/csv/building_count.csv
	touch $@

data/out/csv/highway_length.csv: db/table/osm_road_segments_h3 | data/out/csv ## extract highway_length to csv file 
	psql -q -X -c "copy (select h3, highway_length from osm_road_segments_h3 where h3 is not null and highway_length is not null) to stdout with delimiter ',' csv;" > data/out/csv/highway_length.csv
	touch $@

data/out/csv/total_road_length.csv: db/table/total_road_length_h3 | data/out/csv ## extract total_road_length to csv file 
	psql -q -X -c "copy (select h3, total_road_length from total_road_length_h3 where h3 is not null and total_road_length is not null) to stdout with delimiter ',' csv;" > data/out/csv/total_road_length.csv
	touch $@

data/out/csv/local_hours.csv: db/table/user_hours_h3 | data/out/csv ## extract local_hours to csv file 
	psql -q -X -c "copy (select h3, local_hours from user_hours_h3 where h3 is not null and local_hours is not null) to stdout with delimiter ',' csv;" > data/out/csv/local_hours.csv
	touch $@

data/out/csv/total_hours.csv: db/table/user_hours_h3 | data/out/csv ## extract total_hours to csv file 
	psql -q -X -c "copy (select h3, total_hours from user_hours_h3 where h3 is not null and total_hours is not null) to stdout with delimiter ',' csv;" > data/out/csv/total_hours.csv
	touch $@

data/out/csv/avgmax_ts.csv: db/table/osm_object_count_grid_h3 | data/out/csv ## extract avgmax_ts to csv file 
	psql -q -X -c "copy (select h3, avgmax_ts from osm_object_count_grid_h3 where h3 is not null and avgmax_ts is not null) to stdout with delimiter ',' csv;" > data/out/csv/avgmax_ts.csv
	touch $@

data/out/csv/man_distance_to_fire_brigade.csv: db/table/isodist_fire_stations_h3 | data/out/csv ## extract man_distance_to_fire_brigade to csv file 
	psql -q -X -c "copy (select h3, man_distance as man_distance_to_fire_brigade from isodist_fire_stations_h3 where h3 is not null and man_distance is not null) to stdout with delimiter ',' csv;" > data/out/csv/man_distance_to_fire_brigade.csv
	touch $@

data/out/csv/view_count_bf2402.csv: db/table/tile_logs_bf2402 | data/out/csv ## extract view_count_bf2402 to csv file 
	psql -q -X -c "copy (select h3, view_count_bf2402 from tile_logs_bf2402_h3 where h3 is not null and view_count_bf2402 is not null) to stdout with delimiter ',' csv;" > data/out/csv/view_count_bf2402.csv
	touch $@

data/out/csv/days_mintemp_above_25c_1c.csv: db/table/pf_maxtemp_h3 | data/out/csv ## extract days_mintemp_above_25c_1c to csv file 
	psql -q -X -c "copy (select h3, days_mintemp_above_25c_1c from pf_maxtemp_h3 where h3 is not null and days_mintemp_above_25c_1c is not null) to stdout with delimiter ',' csv;" > data/out/csv/days_mintemp_above_25c_1c.csv
	touch $@

data/out/csv/total_building_count.csv: db/table/building_count_grid_h3 | data/out/csv ## extract total_building_count to csv file 
	psql -q -X -c "copy (select h3, building_count as total_building_count from building_count_grid_h3 where h3 is not null and building_count is not null) to stdout with delimiter ',' csv;" > data/out/csv/total_building_count.csv
	touch $@

data/out/csv/count_6_months.csv: db/table/osm_object_count_grid_h3 | data/out/csv ## extract count_6_months to csv file 
	psql -q -X -c "copy (select h3, count_6_months from osm_object_count_grid_h3 where h3 is not null and count_6_months is not null) to stdout with delimiter ',' csv;" > data/out/csv/count_6_months.csv
	touch $@

data/out/csv/building_count_6_months.csv: db/table/osm_object_count_grid_h3 | data/out/csv ## extract building_count_6_months to csv file 
	psql -q -X -c "copy (select h3, building_count_6_months from osm_object_count_grid_h3 where h3 is not null and building_count_6_months is not null) to stdout with delimiter ',' csv;" > data/out/csv/building_count_6_months.csv
	touch $@

data/out/csv/highway_length_6_months.csv: db/table/osm_road_segments_6_months_h3 | data/out/csv ## extract highway_length_6_months to csv file 
	psql -q -X -c "copy (select h3, highway_length_6_months from osm_road_segments_6_months_h3 where h3 is not null and highway_length_6_months is not null) to stdout with delimiter ',' csv;" > data/out/csv/highway_length_6_months.csv
	touch $@

data/out/csv/osm_users.csv: db/table/osm_object_count_grid_h3 | data/out/csv ## extract osm_users to csv file 
	psql -q -X -c "copy (select h3, osm_users from osm_object_count_grid_h3 where h3 is not null and osm_users is not null) to stdout with delimiter ',' csv;" > data/out/csv/osm_users.csv
	touch $@

data/out/csv/residential.csv: db/table/residential_pop_h3 | data/out/csv ## extract residential to csv file 
	psql -q -X -c "copy (select h3, residential from residential_pop_h3 where h3 is not null and residential is not null) to stdout with delimiter ',' csv;" > data/out/csv/residential.csv
	touch $@

data/out/csv/gdp.csv: db/table/gdp_h3 | data/out/csv ## extract gdp to csv file 
	psql -q -X -c "copy (select h3, gdp from gdp_h3 where h3 is not null and gdp is not null) to stdout with delimiter ',' csv;" > data/out/csv/gdp.csv
	touch $@

data/out/csv/min_ts.csv: db/table/osm_object_count_grid_h3 | data/out/csv ## extract min_ts to csv file 
	psql -q -X -c "copy (select h3, min_ts from osm_object_count_grid_h3 where h3 is not null and min_ts is not null) to stdout with delimiter ',' csv;" > data/out/csv/min_ts.csv
	touch $@

data/out/csv/max_ts.csv: db/table/osm_object_count_grid_h3 | data/out/csv ## extract max_ts to csv file 
	psql -q -X -c "copy (select h3, max_ts from osm_object_count_grid_h3 where h3 is not null and max_ts is not null) to stdout with delimiter ',' csv;" > data/out/csv/max_ts.csv
	touch $@

data/out/csv/wildfires.csv: db/table/global_fires_stat_h3 | data/out/csv ## extract wildfires to csv file 
	psql -q -X -c "copy (select h3, wildfires from global_fires_stat_h3 where h3 is not null and wildfires is not null) to stdout with delimiter ',' csv;" > data/out/csv/wildfires.csv
	touch $@

data/out/csv/covid19_confirmed.csv: db/table/covid19_h3 | data/out/csv ## extract covid19_confirmed to csv file 
	psql -q -X -c "copy (select h3, confirmed as covid19_confirmed from covid19_h3 where h3 is not null and confirmed is not null) to stdout with delimiter ',' csv;" > data/out/csv/covid19_confirmed.csv
	touch $@

data/out/csv/population_prev.csv: db/table/kontur_population_v5_h3 | data/out/csv ## extract population_prev to csv file 
	psql -q -X -c "copy (select h3, population as population_prev from kontur_population_v5_h3 where h3 is not null and population is not null) to stdout with delimiter ',' csv;" > data/out/csv/population_prev.csv
	touch $@

data/out/csv/industrial_area.csv: db/table/osm_landuse_industrial_h3 | data/out/csv ## extract industrial_area to csv file 
	psql -q -X -c "copy (select h3, industrial_area from osm_landuse_industrial_h3 where h3 is not null and industrial_area is not null) to stdout with delimiter ',' csv;" > data/out/csv/industrial_area.csv
	touch $@

data/out/csv/volcanos_count.csv: db/table/osm_volcanos_h3 | data/out/csv ## extract volcanos_count to csv file 
	psql -q -X -c "copy (select h3, volcanos_count from osm_volcanos_h3 where h3 is not null and volcanos_count is not null) to stdout with delimiter ',' csv;" > data/out/csv/volcanos_count.csv
	touch $@

data/out/csv/pop_under_5_total.csv: db/table/us_census_tracts_stats_h3 | data/out/csv ## extract pop_under_5_total to csv file 
	psql -q -X -c "copy (select h3, pop_under_5_total from us_census_tracts_stats_h3 where h3 is not null and pop_under_5_total is not null) to stdout with delimiter ',' csv;" > data/out/csv/pop_under_5_total.csv
	touch $@

data/out/csv/pop_over_65_total.csv: db/table/us_census_tracts_stats_h3 | data/out/csv ## extract pop_over_65_total to csv file 
	psql -q -X -c "copy (select h3, pop_over_65_total from us_census_tracts_stats_h3 where h3 is not null and pop_over_65_total is not null) to stdout with delimiter ',' csv;" > data/out/csv/pop_over_65_total.csv
	touch $@

data/out/csv/poverty_families_total.csv: db/table/us_census_tracts_stats_h3 | data/out/csv ## extract poverty_families_total to csv file 
	psql -q -X -c "copy (select h3, poverty_families_total from us_census_tracts_stats_h3 where h3 is not null and poverty_families_total is not null) to stdout with delimiter ',' csv;" > data/out/csv/poverty_families_total.csv
	touch $@

data/out/csv/pop_disability_total.csv: db/table/us_census_tracts_stats_h3 | data/out/csv ## extract pop_disability_total to csv file 
	psql -q -X -c "copy (select h3, pop_disability_total from us_census_tracts_stats_h3 where h3 is not null and pop_disability_total is not null) to stdout with delimiter ',' csv;" > data/out/csv/pop_disability_total.csv
	touch $@

data/out/csv/pop_not_well_eng_speak.csv: db/table/us_census_tracts_stats_h3 | data/out/csv ## extract pop_not_well_eng_speak to csv file 
	psql -q -X -c "copy (select h3, pop_not_well_eng_speak from us_census_tracts_stats_h3 where h3 is not null and pop_not_well_eng_speak is not null) to stdout with delimiter ',' csv;" > data/out/csv/pop_not_well_eng_speak.csv
	touch $@

data/out/csv/pop_without_car.csv: db/table/us_census_tracts_stats_h3 | data/out/csv ## extract pop_without_car to csv file 
	psql -q -X -c "copy (select h3, pop_without_car from us_census_tracts_stats_h3 where h3 is not null and pop_without_car is not null) to stdout with delimiter ',' csv;" > data/out/csv/pop_without_car.csv
	touch $@

data/out/csv/man_distance_to_hospital.csv: db/table/isodist_hospitals_h3 | data/out/csv ## extract man_distance_to_hospital to csv file 
	psql -q -X -c "copy (select h3, man_distance as man_distance_to_hospital from isodist_hospitals_h3 where h3 is not null and man_distance is not null) to stdout with delimiter ',' csv;" > data/out/csv/man_distance_to_hospital.csv
	touch $@

data/out/csv/man_distance_to_bomb_shelters.csv: db/table/isodist_bomb_shelters_h3 | data/out/csv ## extract man_distance_to_bomb_shelters to csv file 
	psql -q -X -c "copy (select h3, man_distance as man_distance_to_bomb_shelters from isodist_bomb_shelters_h3 where h3 is not null and man_distance is not null) to stdout with delimiter ',' csv;" > data/out/csv/man_distance_to_bomb_shelters.csv
	touch $@

data/out/csv/man_distance_to_charging_stations.csv: db/table/isodist_charging_stations_h3 | data/out/csv ## extract man_distance_to_charging_stations to csv file 
	psql -q -X -c "copy (select h3, man_distance as man_distance_to_charging_stations from isodist_charging_stations_h3 where h3 is not null and man_distance is not null) to stdout with delimiter ',' csv;" > data/out/csv/man_distance_to_charging_stations.csv
	touch $@

data/out/csv/foursquare_places_count.csv: db/table/foursquare_places_h3 | data/out/csv ## extract foursquare_places_count to csv file 
	psql -q -X -c "copy (select h3, foursquare_places_count from foursquare_places_h3 where h3 is not null and foursquare_places_count is not null) to stdout with delimiter ',' csv;" > data/out/csv/foursquare_places_count.csv
	touch $@

data/out/csv/foursquare_visits_count.csv: db/table/foursquare_visits_h3 | data/out/csv ## extract foursquare_visits_count to csv file 
	psql -q -X -c "copy (select h3, foursquare_visits_count from foursquare_visits_h3 where h3 is not null and foursquare_visits_count is not null) to stdout with delimiter ',' csv;" > data/out/csv/foursquare_visits_count.csv
	touch $@

data/out/csv/eatery_count.csv: db/table/osm_places_eatery_h3 | data/out/csv ## extract eatery_count to csv file 
	psql -q -X -c "copy (select h3, eatery_count from osm_places_eatery_h3 where h3 is not null and eatery_count is not null) to stdout with delimiter ',' csv;" > data/out/csv/eatery_count.csv
	touch $@

data/out/csv/food_shops_count.csv: db/table/osm_places_food_shops_h3 | data/out/csv ## extract food_shops_count to csv file 
	psql -q -X -c "copy (select h3, food_shops_count from osm_places_food_shops_h3 where h3 is not null and food_shops_count is not null) to stdout with delimiter ',' csv;" > data/out/csv/food_shops_count.csv
	touch $@

data/out/csv/waste_basket_coverage_area_km2.csv: db/table/waste_containers_h3 | data/out/csv ## extract waste_basket_coverage_area_km2 to csv file 
	psql -q -X -c "copy (select h3, (ST_Area(h3_cell_to_boundary_geography(h3)) / 1000000.0) * waste_basket_coverage / (49.0 * POWER(7, 8 - resolution)) as waste_basket_coverage_area_km2 from waste_containers_h3 where h3 is not null and waste_basket_coverage is not null) to stdout with delimiter ',' csv;" > data/out/csv/waste_basket_coverage_area_km2.csv
	touch $@

data/out/csv/solar_farms_placement_suitability.csv: db/table/solar_farms_placement_suitability_synthetic_h3 | data/out/csv ## extract solar_farms_placement_suitability to csv file 
	psql -q -X -c "copy (select h3, solar_farms_placement_suitability from solar_farms_placement_suitability_synthetic_h3 where h3 is not null and solar_farms_placement_suitability is not null) to stdout with delimiter ',' csv;" > data/out/csv/solar_farms_placement_suitability.csv
	touch $@

data/out/csv/mapswipe_area_km2.csv: db/table/mapswipe_hot_tasking_data_h3 | data/out/csv ## extract mapswipe_area_km2 to csv file 
	psql -q -X -c "copy (select h3, mapswipe_area as mapswipe_area_km2 from mapswipe_hot_tasking_data_h3 where h3 is not null and mapswipe_area is not null) to stdout with delimiter ',' csv;" > data/out/csv/mapswipe_area_km2.csv
	touch $@

data/out/csv/avg_slope_gebco_2022.csv: db/table/gebco_2022_h3 | data/out/csv ## extract avg_slope_gebco_2022 to csv file 
	psql -q -X -c "copy (select h3, avg_slope_gebco_2022 from gebco_2022_h3 where h3 is not null and avg_slope_gebco_2022 is not null) to stdout with delimiter ',' csv;" > data/out/csv/avg_slope_gebco_2022.csv
	touch $@

data/out/csv/avg_elevation_gebco_2022.csv: db/table/gebco_2022_h3 | data/out/csv ## extract avg_elevation_gebco_2022 to csv file 
	psql -q -X -c "copy (select h3, avg_elevation_gebco_2022 from gebco_2022_h3 where h3 is not null and avg_elevation_gebco_2022 is not null) to stdout with delimiter ',' csv;" > data/out/csv/avg_elevation_gebco_2022.csv
	touch $@

data/out/csv/forest.csv: db/table/copernicus_landcover_h3 | data/out/csv ## extract forest to csv file 
	psql -q -X -c "copy (select h3, forest_area as forest from copernicus_landcover_h3 where h3 is not null and forest_area is not null) to stdout with delimiter ',' csv;" > data/out/csv/forest.csv
	touch $@

data/out/csv/evergreen_needle_leaved_forest.csv: db/table/copernicus_landcover_h3 | data/out/csv ## extract evergreen_needle_leaved_forest to csv file 
	psql -q -X -c "copy (select h3, evergreen_needle_leaved_forest from copernicus_landcover_h3 where h3 is not null and evergreen_needle_leaved_forest is not null) to stdout with delimiter ',' csv;" > data/out/csv/evergreen_needle_leaved_forest.csv
	touch $@

data/out/csv/shrubs.csv: db/table/copernicus_landcover_h3 | data/out/csv ## extract shrubs to csv file 
	psql -q -X -c "copy (select h3, shrubs from copernicus_landcover_h3 where h3 is not null and shrubs is not null) to stdout with delimiter ',' csv;" > data/out/csv/shrubs.csv
	touch $@

data/out/csv/herbage.csv: db/table/copernicus_landcover_h3 | data/out/csv ## extract herbage to csv file 
	psql -q -X -c "copy (select h3, herbage from copernicus_landcover_h3 where h3 is not null and herbage is not null) to stdout with delimiter ',' csv;" > data/out/csv/herbage.csv
	touch $@

data/out/csv/unknown_forest.csv: db/table/copernicus_landcover_h3 | data/out/csv ## extract unknown_forest to csv file 
	psql -q -X -c "copy (select h3, unknown_forest from copernicus_landcover_h3 where h3 is not null and unknown_forest is not null) to stdout with delimiter ',' csv;" > data/out/csv/unknown_forest.csv
	touch $@

data/out/csv/avg_ndvi.csv: db/table/ndvi_2019_06_10_h3 | data/out/csv ## extract avg_ndvi to csv file 
	psql -q -X -c "copy (select h3, avg_ndvi from ndvi_2019_06_10_h3 where h3 is not null and avg_ndvi is not null) to stdout with delimiter ',' csv;" > data/out/csv/avg_ndvi.csv
	touch $@

data/out/csv/days_maxtemp_over_32c_1c.csv: db/table/pf_maxtemp_h3 | data/out/csv ## extract days_maxtemp_over_32c_1c to csv file 
	psql -q -X -c "copy (select h3, days_maxtemp_over_32c_1c from pf_maxtemp_h3 where h3 is not null and days_maxtemp_over_32c_1c is not null) to stdout with delimiter ',' csv;" > data/out/csv/days_maxtemp_over_32c_1c.csv
	touch $@

data/out/csv/days_maxtemp_over_32c_2c.csv: db/table/pf_maxtemp_h3 | data/out/csv ## extract days_maxtemp_over_32c_2c to csv file 
	psql -q -X -c "copy (select h3, days_maxtemp_over_32c_2c from pf_maxtemp_h3 where h3 is not null and days_maxtemp_over_32c_2c is not null) to stdout with delimiter ',' csv;" > data/out/csv/days_maxtemp_over_32c_2c.csv
	touch $@

data/out/csv/days_mintemp_above_25c_2c.csv: db/table/pf_maxtemp_h3 | data/out/csv ## extract days_mintemp_above_25c_2c to csv file 
	psql -q -X -c "copy (select h3, days_mintemp_above_25c_2c from pf_maxtemp_h3 where h3 is not null and days_mintemp_above_25c_2c is not null) to stdout with delimiter ',' csv;" > data/out/csv/days_mintemp_above_25c_2c.csv
	touch $@

data/out/csv/days_maxwetbulb_over_32c_1c.csv: db/table/pf_maxtemp_h3 | data/out/csv ## extract days_maxwetbulb_over_32c_1c to csv file 
	psql -q -X -c "copy (select h3, days_maxwetbulb_over_32c_1c from pf_maxtemp_h3 where h3 is not null and days_maxwetbulb_over_32c_1c is not null) to stdout with delimiter ',' csv;" > data/out/csv/days_maxwetbulb_over_32c_1c.csv
	touch $@

data/out/csv/days_maxwetbulb_over_32c_2c.csv: db/table/pf_maxtemp_h3 | data/out/csv ## extract days_maxwetbulb_over_32c_2c to csv file 
	psql -q -X -c "copy (select h3, days_maxwetbulb_over_32c_2c from pf_maxtemp_h3 where h3 is not null and days_maxwetbulb_over_32c_2c is not null) to stdout with delimiter ',' csv;" > data/out/csv/days_maxwetbulb_over_32c_2c.csv
	touch $@

data/out/csv/mandays_maxtemp_over_32c_1c.csv: db/table/pf_maxtemp_h3 | data/out/csv ## extract mandays_maxtemp_over_32c_1c to csv file 
	psql -q -X -c "copy (select h3, mandays_maxtemp_over_32c_1c from pf_maxtemp_h3 where h3 is not null and mandays_maxtemp_over_32c_1c is not null) to stdout with delimiter ',' csv;" > data/out/csv/mandays_maxtemp_over_32c_1c.csv
	touch $@

data/out/csv/hazardous_days_count.csv: db/table/disaster_event_episodes_h3 | data/out/csv ## extract hazardous_days_count to csv file 
	psql -q -X -c "copy (select h3, hazardous_days_count from disaster_event_episodes_h3 where h3 is not null and hazardous_days_count is not null) to stdout with delimiter ',' csv;" > data/out/csv/hazardous_days_count.csv
	touch $@

data/out/csv/earthquake_days_count.csv: db/table/disaster_event_episodes_h3 | data/out/csv ## extract earthquake_days_count to csv file 
	psql -q -X -c "copy (select h3, earthquake_days_count from disaster_event_episodes_h3 where h3 is not null and earthquake_days_count is not null) to stdout with delimiter ',' csv;" > data/out/csv/earthquake_days_count.csv
	touch $@

data/out/csv/wildfire_days_count.csv: db/table/disaster_event_episodes_h3 | data/out/csv ## extract wildfire_days_count to csv file 
	psql -q -X -c "copy (select h3, wildfire_days_count from disaster_event_episodes_h3 where h3 is not null and wildfire_days_count is not null) to stdout with delimiter ',' csv;" > data/out/csv/wildfire_days_count.csv
	touch $@

data/out/csv/drought_days_count.csv: db/table/disaster_event_episodes_h3 | data/out/csv ## extract drought_days_count to csv file 
	psql -q -X -c "copy (select h3, drought_days_count from disaster_event_episodes_h3 where h3 is not null and drought_days_count is not null) to stdout with delimiter ',' csv;" > data/out/csv/drought_days_count.csv
	touch $@

data/out/csv/cyclone_days_count.csv: db/table/disaster_event_episodes_h3 | data/out/csv ## extract cyclone_days_count to csv file 
	psql -q -X -c "copy (select h3, cyclone_days_count from disaster_event_episodes_h3 where h3 is not null and cyclone_days_count is not null) to stdout with delimiter ',' csv;" > data/out/csv/cyclone_days_count.csv
	touch $@

data/out/csv/volcano_days_count.csv: db/table/disaster_event_episodes_h3 | data/out/csv ## extract volcano_days_count to csv file 
	psql -q -X -c "copy (select h3, volcano_days_count from disaster_event_episodes_h3 where h3 is not null and volcano_days_count is not null) to stdout with delimiter ',' csv;" > data/out/csv/volcano_days_count.csv
	touch $@

data/out/csv/flood_days_count.csv: db/table/disaster_event_episodes_h3 | data/out/csv ## extract flood_days_count to csv file 
	psql -q -X -c "copy (select h3, flood_days_count from disaster_event_episodes_h3 where h3 is not null and flood_days_count is not null) to stdout with delimiter ',' csv;" > data/out/csv/flood_days_count.csv
	touch $@

data/out/csv/powerlines.csv: db/table/facebook_medium_voltage_distribution_h3 | data/out/csv ## extract powerlines to csv file 
	psql -q -X -c "copy (select h3, powerlines from facebook_medium_voltage_distribution_h3 where h3 is not null and powerlines is not null) to stdout with delimiter ',' csv;" > data/out/csv/powerlines.csv
	touch $@

data/out/csv/night_lights_intensity.csv: db/table/night_lights_h3 | data/out/csv ## extract night_lights_intensity to csv file 
	psql -q -X -c "copy (select h3, intensity as night_lights_intensity from night_lights_h3 where h3 is not null and intensity is not null) to stdout with delimiter ',' csv;" > data/out/csv/night_lights_intensity.csv
	touch $@

data/out/csv/gsa_ghi.csv: db/table/global_solar_atlas_h3 | data/out/csv ## extract gsa_ghi to csv file 
	psql -q -X -c "copy (select h3, gsa_ghi from global_solar_atlas_h3 where h3 is not null and gsa_ghi is not null) to stdout with delimiter ',' csv;" > data/out/csv/gsa_ghi.csv
	touch $@

data/out/csv/worldclim_avg_temperature.csv: db/table/worldclim_temperatures_h3 | data/out/csv ## extract worldclim_avg_temperature to csv file 
	psql -q -X -c "copy (select h3, worldclim_avg_temperature from worldclim_temperatures_h3 where h3 is not null and worldclim_avg_temperature is not null) to stdout with delimiter ',' csv;" > data/out/csv/worldclim_avg_temperature.csv
	touch $@

data/out/csv/worldclim_min_temperature.csv: db/table/worldclim_temperatures_h3 | data/out/csv ## extract worldclim_min_temperature to csv file 
	psql -q -X -c "copy (select h3, worldclim_min_temperature from worldclim_temperatures_h3 where h3 is not null and worldclim_min_temperature is not null) to stdout with delimiter ',' csv;" > data/out/csv/worldclim_min_temperature.csv
	touch $@

data/out/csv/worldclim_max_temperature.csv: db/table/worldclim_temperatures_h3 | data/out/csv ## extract worldclim_max_temperature to csv file 
	psql -q -X -c "copy (select h3, worldclim_max_temperature from worldclim_temperatures_h3 where h3 is not null and worldclim_max_temperature is not null) to stdout with delimiter ',' csv;" > data/out/csv/worldclim_max_temperature.csv
	touch $@

data/out/csv/worldclim_amp_temperature.csv: db/table/worldclim_temperatures_h3 | data/out/csv ## extract worldclim_amp_temperature to csv file 
	psql -q -X -c "copy (select h3, worldclim_amp_temperature from worldclim_temperatures_h3 where h3 is not null and worldclim_amp_temperature is not null) to stdout with delimiter ',' csv;" > data/out/csv/worldclim_amp_temperature.csv
	touch $@

data/out/csv/powerlines_proximity_m.csv: db/table/proximities_h3 | data/out/csv ## extract powerlines_proximity_m to csv file 
	psql -q -X -c "copy (select h3, powerlines_proximity_m from proximities_h3 where h3 is not null and powerlines_proximity_m is not null) to stdout with delimiter ',' csv;" > data/out/csv/powerlines_proximity_m.csv
	touch $@

data/out/csv/populated_areas_proximity_m.csv: db/table/proximities_h3 | data/out/csv ## extract populated_areas_proximity_m to csv file 
	psql -q -X -c "copy (select h3, populated_areas_proximity_m from proximities_h3 where h3 is not null and populated_areas_proximity_m is not null) to stdout with delimiter ',' csv;" > data/out/csv/populated_areas_proximity_m.csv
	touch $@

data/out/csv/power_substations_proximity_m.csv: db/table/proximities_h3 | data/out/csv ## extract power_substations_proximity_m to csv file 
	psql -q -X -c "copy (select h3, power_substations_proximity_m from proximities_h3 where h3 is not null and power_substations_proximity_m is not null) to stdout with delimiter ',' csv;" > data/out/csv/power_substations_proximity_m.csv
	touch $@

data/out/csv/solar_power_plants.csv: db/table/existing_solar_power_panels_h3 | data/out/csv ## extract solar_power_plants to csv file 
	psql -q -X -c "copy (select h3, solar_power_plants from existing_solar_power_panels_h3 where h3 is not null and solar_power_plants is not null) to stdout with delimiter ',' csv;" > data/out/csv/solar_power_plants.csv
	touch $@

data/out/csv/safety_index.csv: db/table/safety_index_h3 | data/out/csv ## extract safety_index to csv file 
	psql -q -X -c "copy (select h3, safety_index from safety_index_h3 where h3 is not null and safety_index is not null) to stdout with delimiter ',' csv;" > data/out/csv/safety_index.csv
	touch $@

data/out/csv/population.csv: db/table/kontur_population_h3 | data/out/csv ## extract population to csv file 
	psql -q -X -c "copy (select h3, population from kontur_population_h3 where h3 is not null and population is not null) to stdout with delimiter ',' csv;" > data/out/csv/population.csv
	touch $@

data/out/csv/avg_forest_canopy_height.csv: db/table/meta_forest_canopy_height_h3 | data/out/csv ## extract avg_forest_canopy_height to csv file 
	psql -q -X -c "copy (select h3, avg_height as avg_forest_canopy_height from meta_forest_canopy_height_h3 where h3 is not null and avg_height is not null) to stdout with delimiter ',' csv;" > $@

data/out/csv/max_forest_canopy_height.csv: db/table/meta_forest_canopy_height_h3 | data/out/csv ## extract max_forest_canopy_height to csv file 
	psql -q -X -c "copy (select h3, max_height as max_forest_canopy_height from meta_forest_canopy_height_h3 where h3 is not null and max_height is not null) to stdout with delimiter ',' csv;" > $@

data/out/csv/worldbank_tax_rate.csv: db/table/worldbank_tax_rate_h3 | data/out/csv ## extract worldbank_tax_rate to csv file 
	psql -q -X -c "copy (select h3, t2019 as worldbank_total_tax_2019 from worldbank_tax_rate_h3 where h3 is not null and t2019 is not null) to stdout with delimiter ',' csv;" > $@

data/out/csv/years_to_naturalisation.csv: db/table/wikidata_naturalization_gap_h3 | data/out/csv ## extract years_to_naturalisation to csv file 
	psql -q -X -c "copy (select h3, years_to_naturalisation from wikidata_naturalization_gap_h3 where h3 is not null and years_to_naturalisation is not null) to stdout with delimiter ',' csv;" > $@

data/out/csv/multiple_citizenship.csv: db/table/wikidata_naturalization_gap_h3 | data/out/csv ## extract multiple_citizenship to csv file 
	psql -q -X -c "copy (select h3, multiple_citizenship from wikidata_naturalization_gap_h3 where h3 is not null and multiple_citizenship is not null) to stdout with delimiter ',' csv;" > $@

### Deploy block ###
## Deploy dev ##
db/table/insights_api_indicators_list_dev: | db/table ## Refresh insights_api_indicators_list_dev table before new deploy cycle
	psql -c "drop table if exists insights_api_indicators_list_dev;"
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	touch $@

deploy_indicators/dev/uploads/count_upload: data/out/csv/count.csv | deploy_indicators/dev/uploads ## upload count to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/count.csv "count" "OSM: objects count" "[[\"bad\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Total number of objects in a given area according to OpenStreetMap." "World" "daily" "n" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/hazardous_days_count_upload: data/out/csv/hazardous_days_count.csv | deploy_indicators/dev/uploads ## upload hazardous_days_count to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/hazardous_days_count.csv "hazardous_days_count" "Exposure: all disaster types" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)\"]" "Number of days in the last year when severe and extreme disasters of any types were recorded." "World" "daily" "days" "$(date -r db/table/disaster_event_episodes_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/mandays_maxtemp_over_32c_1c_upload: data/out/csv/mandays_maxtemp_over_32c_1c.csv | deploy_indicators/dev/uploads ## upload mandays_maxtemp_over_32c_1c to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/mandays_maxtemp_over_32c_1c.csv "mandays_maxtemp_over_32c_1c" "Man-days above 32°C, (+1°C scenario)" "[[\"good\"], [\"bad\"]]" false false "[\"© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0\"]" "" "World" "daily" "other" "$(date -r db/table/pf_maxtemp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/man_distance_to_fire_brigade_upload: data/out/csv/man_distance_to_fire_brigade.csv | deploy_indicators/dev/uploads ## upload man_distance_to_fire_brigade to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/man_distance_to_fire_brigade.csv "man_distance_to_fire_brigade" "Man-distance to fire brigade" "[[\"good\"], [\"bad\"]]" false false "[\"© Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "" "World" "daily" "other" "$(date -r db/table/isodist_fire_stations_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/food_shops_count_upload: data/out/csv/food_shops_count.csv | deploy_indicators/dev/uploads ## upload food_shops_count to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/food_shops_count.csv "food_shops_count" "OSM: food shops count" "[[\"unimportant\"], [\"important\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of places where you can buy fresh or packaged food products in a given area." "World" "daily" "n" "$(date -r db/table/osm_places_food_shops_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/populated_area_km2_upload: data/out/csv/populated_area_km2.csv | deploy_indicators/dev/uploads ## upload populated_area_km2 to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/populated_area_km2.csv "populated_area_km2" "Populated area" "[[\"unimportant\"], [\"important\"]]" true false "[\"© Kontur https://kontur.io/\", \"Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/\", \"Dataset: Schiavina, Marcello., Freire, Sergio., MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio., MacManus, Kytt., Pesaresi, Martino., Doxsey-Whitfield, Erin., Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World., Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\", \"Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).\", \"NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/\", \"Geoalert Urban Mapping: Chechnya, Moscow region, Tyva - https://github.com/Geoalert/urban-mapping\", \"Unconstrained Individual countries 2020 (100m resolution): WorldPop - https://www.worldpop.org/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "" "World" "daily" "km2" "$(date -r db/table/kontur_population_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/count_6_months_upload: data/out/csv/count_6_months.csv | deploy_indicators/dev/uploads ## upload count_6_months to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/count_6_months.csv "count_6_months" "OSM: objects mapped (6 months)" "[[\"bad\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of objects mapped in OpenStreetMap in the last 6 months." "World" "daily" "n" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/view_count_upload: data/out/csv/view_count.csv | deploy_indicators/dev/uploads ## upload view_count to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/view_count.csv "view_count" "OSM: map views (last 30 days)" "[[\"bad\", \"unimportant\"], [\"good\", \"important\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of tile requests in a given area for the last 30 days." "World" "daily" "n" "$(date -r db/table/tile_logs +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/avgmax_ts_upload: data/out/csv/avgmax_ts.csv | deploy_indicators/dev/uploads ## upload avgmax_ts to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/avgmax_ts.csv "avgmax_ts" "OSM: last edit (avg)" "[[\"bad\", \"unimportant\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Average of latest OpenStreetMap edit dates in a given area." "World" "daily" "unixtime" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/max_ts_upload: data/out/csv/max_ts.csv | deploy_indicators/dev/uploads ## upload max_ts to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/max_ts.csv "max_ts" "OSM: last edit" "[[\"bad\", \"unimportant\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Date of latest OpenStreetMap edit in a given area at highest resolution." "World" "daily" "unixtime" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/min_ts_upload: data/out/csv/min_ts.csv | deploy_indicators/dev/uploads ## upload min_ts to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/min_ts.csv "min_ts" "OSM: first edit" "[[\"good\"], [\"neutral\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Date of earliest OpenStreetMap edit in a given area." "World" "daily" "unixtime" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/osm_users_upload: data/out/csv/osm_users.csv | deploy_indicators/dev/uploads ## upload osm_users to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/osm_users.csv "osm_users" "OSM: contributors count" "[[\"bad\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of users who have edited a given area in OpenStreetMap." "World" "daily" "ppl" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/building_count_upload: data/out/csv/building_count.csv | deploy_indicators/dev/uploads ## upload building_count to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/building_count.csv "building_count" "OSM: buildings count" "[[\"bad\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Total number of buildings in a given area according to OpenStreetMap." "World" "daily" "n" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/building_count_6_months_upload: data/out/csv/building_count_6_months.csv | deploy_indicators/dev/uploads ## upload building_count_6_months to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/building_count_6_months.csv "building_count_6_months" "OSM: new buildings (last 6 months)" "[[\"bad\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of buildings mapped in OpenStreetMap in the last 6 months." "World" "daily" "n" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/highway_length_upload: data/out/csv/highway_length.csv | deploy_indicators/dev/uploads ## upload highway_length to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/highway_length.csv "highway_length" "OSM: road length" "[[\"bad\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Total length of roads in a given area according to OpenStreetMap." "World" "daily" "km" "$(date -r db/table/osm_road_segments_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/highway_length_6_months_upload: data/out/csv/highway_length_6_months.csv | deploy_indicators/dev/uploads ## upload highway_length_6_months to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/highway_length_6_months.csv "highway_length_6_months" "OSM: new road length (last 6 months)" "[[\"bad\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Length of roads mapped in OpenStreetMap in the last 6 months." "World" "daily" "km" "$(date -r db/table/osm_road_segments_6_months_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/total_hours_upload: data/out/csv/total_hours.csv | deploy_indicators/dev/uploads ## upload total_hours to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/total_hours.csv "total_hours" "OSM: contributor activity" "[[\"bad\"], [\"good\"]]" false true "[\"© Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Total number of OpenStreetMap mapping hours by all users in the last 2 years. A mapping hour is an hour in which a user uploaded at least one tagged object." "World" "daily" "h" "$(date -r db/table/user_hours_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/local_hours_upload: data/out/csv/local_hours.csv | deploy_indicators/dev/uploads ## upload local_hours to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/local_hours.csv "local_hours" "OSM: local contributor activity" "[[\"bad\"], [\"good\"]]" false true "[\"© Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of OpenStreetMap mapping hours by active local mappers in the last 2 years. A mapping hour is an hour in which a user uploaded at least one tagged object. Mapper is considered active if they contributed more than 30 mapping hours in the last 2 years. The position of the active mapper is estimated by the region of their highest activity." "World" "daily" "h" "$(date -r db/table/user_hours_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/forest_upload: data/out/csv/forest.csv | deploy_indicators/dev/uploads ## upload forest to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/forest.csv "forest" "Landcover: forest" "[[\"unimportant\"], [\"important\"]]" false true "[\"© Kontur https://kontur.io/\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\"]" "Area covered by forest - where tree canopy is more than 15%." "World" "static" "km2" "$(date -r db/table/copernicus_landcover_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/evergreen_needle_leaved_forest_upload: data/out/csv/evergreen_needle_leaved_forest.csv | deploy_indicators/dev/uploads ## upload evergreen_needle_leaved_forest to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/evergreen_needle_leaved_forest.csv "evergreen_needle_leaved_forest" "Landcover: evergreen needleleaf forest" "[[\"unimportant\"], [\"important\"]]" false true "[\"© Kontur https://kontur.io/\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\"]" "Area covered by either closed or open evergreen needleleaf forest. Almost all needleleaf trees remain green all year. Canopy is never without green foliage. Closed forest has tree canopy >70%. Open forest has top layer - trees 15-70 % - and second layer - mix of shrubs and grassland." "World" "static" "km2" "$(date -r db/table/copernicus_landcover_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/shrubs_upload: data/out/csv/shrubs.csv | deploy_indicators/dev/uploads ## upload shrubs to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/shrubs.csv "shrubs" "Landcover: shrubland" "[[\"unimportant\"], [\"important\"]]" false true "[\"© Kontur https://kontur.io/\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\"]" "Shrubland, or area where vegetation is dominated by woody perennial plants generally less than 5 meters in height, with persistent and woody stems and without any defined main stem. The shrub foliage can be either evergreen or deciduous." "World" "static" "km2" "$(date -r db/table/copernicus_landcover_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/herbage_upload: data/out/csv/herbage.csv | deploy_indicators/dev/uploads ## upload herbage to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/herbage.csv "herbage" "Landcover: herbaceous vegetation" "[[\"unimportant\"], [\"important\"]]" false true "[\"© Kontur https://kontur.io/\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\"]" "Area covered by herbaceous plants. These plants have no persistent woody stems above ground and lack definite firm structure. Tree and shrub cover is less than 10%." "World" "static" "km2" "$(date -r db/table/copernicus_landcover_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/unknown_forest_upload: data/out/csv/unknown_forest.csv | deploy_indicators/dev/uploads ## upload unknown_forest to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/unknown_forest.csv "unknown_forest" "Landcover: unknown forest type" "[[\"unimportant\"], [\"important\"]]" false true "[\"© Kontur https://kontur.io/\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\"]" "Area covered by forest that does not match defined forest types." "World" "static" "km2" "$(date -r db/table/copernicus_landcover_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/gdp_upload: data/out/csv/gdp.csv | deploy_indicators/dev/uploads ## upload gdp to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/gdp.csv "gdp" "Gross Domestic Product" "[[\"bad\"], [\"good\"]]" false true "[\"© Kontur https://kontur.io/\", \"© 2019 The World Bank Group, CC-BY 4.0\", \"Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/\", \"Dataset: Schiavina, Marcello., Freire, Sergio., MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio., MacManus, Kytt., Pesaresi, Martino., Doxsey-Whitfield, Erin., Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World., Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016\", \"Copernicus Global Land Service: Land Cover 100m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, Myroslava Lesiv, Nandin-Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\", \"Microsoft Buildings: Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).\", \"@ OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "A country GDP (Gross Domestic Product) per capita multiplied by the population in a given area. For areas covering multiple countries, a sum of their respective GDP portions is used. GDP is the standard measure of the value created through the production of goods and services in a country during a certain period." "World" "static" "USD" "$(date -r db/table/gdp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/population_prev_upload: data/out/csv/population_prev.csv | deploy_indicators/dev/uploads ## upload population_prev to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/population_prev.csv "population_prev" "Population (previous version)" "[[\"unimportant\"], [\"important\"]]" false false "[\"© Kontur https://kontur.io/\", \"Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/\", \"Dataset: Schiavina, Marcello., Freire, Sergio., MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio., MacManus, Kytt., Pesaresi, Martino., Doxsey-Whitfield, Erin., Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World., Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\", \"Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).\", \"NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/\", \"Geoalert Urban Mapping: Chechnya, Moscow region, Tyva - https://github.com/Geoalert/urban-mapping\", \"Unconstrained Individual countries 2020 (100m resolution): WorldPop - https://www.worldpop.org/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of people living in a given area according to previous version of Kontur Population dataset. The dataset was produced by overlaying the Global Human Settlement Layer (GHSL) with available Facebook population data and constraining known artifacts using OpenStreetMap data." "World" "daily" "ppl" "$(date -r db/table/kontur_population_v5_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/total_building_count_upload: data/out/csv/total_building_count.csv | deploy_indicators/dev/uploads ## upload total_building_count to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/total_building_count.csv "total_building_count" "Total buildings count" "[[\"unimportant\"], [\"important\"]]" true true "[\"© Kontur https://kontur.io/\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\", \"Geoalert Urban Mapping: Chechnya, Moscow region, Tyva - https://github.com/Geoalert/urban-mapping\", \"Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).\", \"NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Estimated number of buildings in a given area based on various data sources." "World" "daily" "n" "$(date -r db/table/building_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/wildfires_upload: data/out/csv/wildfires.csv | deploy_indicators/dev/uploads ## upload wildfires to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/wildfires.csv "wildfires" "Wildfire days" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false false "[\"© NRT VIIRS 375 m Active Fire product VJ114IMGTDL_NRT. Available on-line [https://earthdata.nasa.gov/firms]. doi: 10.5067/FIRMS/VIIRS/VJ114IMGT_NRT.002\", \"NRT VIIRS 375 m Active Fire product VNP14IMGT. Available on-line [https://earthdata.nasa.gov/firms]. doi:10.5067/FIRMS/VIIRS/VNP14IMGT_NRT.002\", \"MODIS Collection 6 NRT Hotspot / Active Fire Detections MCD14DL. Available on-line [https://earthdata.nasa.gov/firms]. doi: 10.5067/FIRMS/MODIS/MCD14DL.NRT.006\", \"MODIS Collection 6 NRT Hotspot / Active Fire Detections MCD14ML. Available on-line [https://earthdata.nasa.gov/firms]. doi: 10.5067/FIRMS/MODIS/MCD14ML\"]" "Number of days per year when a thermal anomaly was recorded in the last 13 months." "World" "daily" "days" "$(date -r db/table/global_fires_stat_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/earthquake_days_count_upload: data/out/csv/earthquake_days_count.csv | deploy_indicators/dev/uploads ## upload earthquake_days_count to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/earthquake_days_count.csv "earthquake_days_count" "Exposure: earthquake" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)\"]" "Number of days in the last year when severe and extreme earthquakes were recorded." "World" "daily" "days" "$(date -r db/table/disaster_event_episodes_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/drought_days_count_upload: data/out/csv/drought_days_count.csv | deploy_indicators/dev/uploads ## upload drought_days_count to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/drought_days_count.csv "drought_days_count" "Exposure: drought" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)\"]" "Number of days in the last year when severe and extreme droughts were recorded." "World" "daily" "days" "$(date -r db/table/disaster_event_episodes_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/cyclone_days_count_upload: data/out/csv/cyclone_days_count.csv | deploy_indicators/dev/uploads ## upload cyclone_days_count to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/cyclone_days_count.csv "cyclone_days_count" "Exposure: cyclone" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)\"]" "Number of days in the last year when severe and extreme cyclones were recorded." "World" "daily" "days" "$(date -r db/table/disaster_event_episodes_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/wildfire_days_count_upload: data/out/csv/wildfire_days_count.csv | deploy_indicators/dev/uploads ## upload wildfire_days_count to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/wildfire_days_count.csv "wildfire_days_count" "Exposure: wildfire" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)\"]" "Number of days in the last year when severe and extreme wildfires were recorded." "World" "daily" "days" "$(date -r db/table/disaster_event_episodes_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/volcano_days_count_upload: data/out/csv/volcano_days_count.csv | deploy_indicators/dev/uploads ## upload volcano_days_count to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/volcano_days_count.csv "volcano_days_count" "Exposure: volcanic eruption" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)\"]" "Number of days in the last year when severe and extreme volcanos were recorded." "World" "daily" "days" "$(date -r db/table/disaster_event_episodes_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/flood_days_count_upload: data/out/csv/flood_days_count.csv | deploy_indicators/dev/uploads ## upload flood_days_count to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/flood_days_count.csv "flood_days_count" "Exposure: flood" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)\"]" "Number of days in the last year when severe and extreme floods were recorded." "World" "daily" "days" "$(date -r db/table/disaster_event_episodes_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/covid19_confirmed_upload: data/out/csv/covid19_confirmed.csv | deploy_indicators/dev/uploads ## upload covid19_confirmed to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/covid19_confirmed.csv "covid19_confirmed" "COVID-19 confirmed сases" "[[\"good\"], [\"bad\"]]" false true "[\"© Data from JHU CSSE COVID-19 Dataset\"]" "Number of COVID-19 confirmed cases for the entire observation period according to the Center for Systems Science and Engineering (CSSE) at Johns Hopkins University (JHU)." "World" "daily" "n" "$(date -r db/table/covid19_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/avg_slope_gebco_2022_upload: data/out/csv/avg_slope_gebco_2022.csv | deploy_indicators/dev/uploads ## upload avg_slope_gebco_2022 to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/avg_slope_gebco_2022.csv "avg_slope_gebco_2022" "Slope (avg)" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"© Data from General Bathymatric Chart of the Oceans, www.gebco.net\"]" "Average surface slope." "World" "static" "deg" "$(date -r db/table/gebco_2022_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/avg_elevation_gebco_2022_upload: data/out/csv/avg_elevation_gebco_2022.csv | deploy_indicators/dev/uploads ## upload avg_elevation_gebco_2022 to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/avg_elevation_gebco_2022.csv "avg_elevation_gebco_2022" "Elevation (avg)" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"© Data from General Bathymatric Chart of the Oceans, www.gebco.net\"]" "Average surface elevation in meters." "World" "static" "m" "$(date -r db/table/gebco_2022_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/industrial_area_upload: data/out/csv/industrial_area.csv | deploy_indicators/dev/uploads ## upload industrial_area to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/industrial_area.csv "industrial_area" "OSM: industrial area" "[[\"unimportant\"], [\"important\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Areas of land used for industrial purposes, which may include facilities such as workshops, factories and warehouses, and their associated infrastructure (car parks, service roads, yards, etc.)." "World" "daily" "km2" "$(date -r db/table/osm_landuse_industrial_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/avg_ndvi_upload: data/out/csv/avg_ndvi.csv | deploy_indicators/dev/uploads ## upload avg_ndvi to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/avg_ndvi.csv "avg_ndvi" "NDVI (avg)" "[[\"bad\"], [\"good\"]]" false true "[\"© Data from Sentinel-2 L2A 120m Mosaic, CC-BY 4.0, https://forum.sentinel-hub.com/c/aws-sentinel\"]" "Average values of Normalized Difference Vegetation Index (NDVI), as of June 2019. Negative values of NDVI (values approaching -1) correspond to water. Values close to zero (-0.1 to 0.1) generally correspond to barren areas of rock, sand, or snow. Low, positive values represent shrub and grassland (approximately 0.2 to 0.4), while high values indicate temperate and tropical rainforests (values approaching 1)." "World" "static" "index" "$(date -r db/table/ndvi_2019_06_10_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/volcanos_count_upload: data/out/csv/volcanos_count.csv | deploy_indicators/dev/uploads ## upload volcanos_count to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/volcanos_count.csv "volcanos_count" "OSM: volcanoes count" "[[\"unimportant\"], [\"important\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of volcanoes in a given area." "World" "daily" "n" "$(date -r db/table/osm_volcanos_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/pop_under_5_total_upload: data/out/csv/pop_under_5_total.csv | deploy_indicators/dev/uploads ## upload pop_under_5_total to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/pop_under_5_total.csv "pop_under_5_total" "Population: under 5" "[[\"unimportant\"], [\"important\"]]" false true "[\"© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html\"]" "Number of children (ages 0-5) in the United States." "The United States of America" "static" "ppl" "$(date -r db/table/us_census_tracts_stats_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/pop_over_65_total_upload: data/out/csv/pop_over_65_total.csv | deploy_indicators/dev/uploads ## upload pop_over_65_total to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/pop_over_65_total.csv "pop_over_65_total" "Population: over 65" "[[\"unimportant\"], [\"important\"]]" false true "[\"© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html\"]" "Number of elderly people (ages 65+) in the United States." "The United States of America" "static" "ppl" "$(date -r db/table/us_census_tracts_stats_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/poverty_families_total_upload: data/out/csv/poverty_families_total.csv | deploy_indicators/dev/uploads ## upload poverty_families_total to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/poverty_families_total.csv "poverty_families_total" "Population: families below poverty line" "[[\"unimportant\", \"good\"], [\"important\"]]" false true "[\"© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html\"]" "Number of households living below the poverty line in the United States." "The United States of America" "static" "n" "$(date -r db/table/us_census_tracts_stats_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/pop_disability_total_upload: data/out/csv/pop_disability_total.csv | deploy_indicators/dev/uploads ## upload pop_disability_total to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/pop_disability_total.csv "pop_disability_total" "Population: with disabilities" "[[\"unimportant\"], [\"important\"]]" false true "[\"© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html\"]" "Number of people with disabilities in the United States based on the U.S. Census Bureaus American Community Survey (ACS). This page describes how disability is defined and collected in the ACS: https://www.census.gov/topics/health/disability/guidance/data-collection-acs.html" "The United States of America" "static" "ppl" "$(date -r db/table/us_census_tracts_stats_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/pop_not_well_eng_speak_upload: data/out/csv/pop_not_well_eng_speak.csv | deploy_indicators/dev/uploads ## upload pop_not_well_eng_speak to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/pop_not_well_eng_speak.csv "pop_not_well_eng_speak" "Population: limited English proficiency" "[[\"good\"], [\"important\", \"bad\"]]" false true "[\"© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html\"]" "Number of people who have difficulty speaking English in the United States." "The United States of America" "static" "ppl" "$(date -r db/table/us_census_tracts_stats_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/pop_without_car_upload: data/out/csv/pop_without_car.csv | deploy_indicators/dev/uploads ## upload pop_without_car to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/pop_without_car.csv "pop_without_car" "Population: without a car" "[[\"neutral\"], [\"important\"]]" false true "[\"© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html\"]" "Number of working people without a car in the United States." "The United States of America" "static" "ppl" "$(date -r db/table/us_census_tracts_stats_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/days_maxtemp_over_32c_1c_upload: data/out/csv/days_maxtemp_over_32c_1c.csv | deploy_indicators/dev/uploads ## upload days_maxtemp_over_32c_1c to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/days_maxtemp_over_32c_1c.csv "days_maxtemp_over_32c_1c" "Days above 32°C (+1°C scenario)" "[[\"good\"], [\"bad\"]]" false true "[\"© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0\"]" "Number of days per year with a daily maximum temperature exceeding 32°C (90°F) at the “recent” climate warming scenario of +1.0°C. In 2017 the average surface temperature passed 1.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science)." "World (-60:60 latitudes)" "static" "days" "$(date -r db/table/pf_maxtemp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/days_maxtemp_over_32c_2c_upload: data/out/csv/days_maxtemp_over_32c_2c.csv | deploy_indicators/dev/uploads ## upload days_maxtemp_over_32c_2c to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/days_maxtemp_over_32c_2c.csv "days_maxtemp_over_32c_2c" "Days above 32°C (+2°C scenario)" "[[\"good\"], [\"bad\"]]" false true "[\"© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0\"]" "Number of days per year with a daily maximum temperature exceeding 32°C (90°F) at the “potential” climate warming scenario of +2.0°C. On the current path of emissions, in the 2040s the average surface temperature will likely pass 2.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science).The displayed values are from a range of simulated years from multiple models. Actual outcomes may prove to be higher or lower than the displayed values." "World (-60:60 latitudes)" "static" "days" "$(date -r db/table/pf_maxtemp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/days_mintemp_above_25c_1c_upload: data/out/csv/days_mintemp_above_25c_1c.csv | deploy_indicators/dev/uploads ## upload days_mintemp_above_25c_1c to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/days_mintemp_above_25c_1c.csv "days_mintemp_above_25c_1c" "Nights above 25°C (+1°C scenario)" "[[\"good\"], [\"bad\"]]" false true "[\"© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0\"]" "Number of days per year with a daily minimum temperature exceeding 25°C (77°F) at the “recent” climate warming scenario of +1.0°C. In 2017 the average surface temperature passed 1.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science). The lowest temperature during the day happens at night when temperatures dip after sunset. The human experience of a “hot” night is relative to location, so a threshold of 20°C is often used for higher latitudes (Europe and the US) and a threshold of 25°C is often used for tropical and equatorial regions." "World (-60:60 latitudes)" "static" "days" "$(date -r db/table/pf_maxtemp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/days_mintemp_above_25c_2c_upload: data/out/csv/days_mintemp_above_25c_2c.csv | deploy_indicators/dev/uploads ## upload days_mintemp_above_25c_2c to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/days_mintemp_above_25c_2c.csv "days_mintemp_above_25c_2c" "Nights above 25°C (+2°C scenario)" "[[\"good\"], [\"bad\"]]" false true "[\"© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0\"]" "Number of days per year with a daily minimum temperature exceeding 25°C (77°F) at the “potential” climate warming scenario of +2.0°C. On the current path of emissions, in the 2040s the average surface temperature will likely pass 2.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science). The lowest temperature during the day happens at night when temperatures dip after sunset. The human experience of a “hot” night is relative to location, so a threshold of 20°C is often used for higher latitudes (Europe and the US) and a threshold of 25°C is often used for tropical and equatorial regions. The displayed values are from a range of simulated years from multiple models. Actual outcomes may prove to be higher or lower than the displayed values." "World (-60:60 latitudes)" "static" "days" "$(date -r db/table/pf_maxtemp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/days_maxwetbulb_over_32c_1c_upload: data/out/csv/days_maxwetbulb_over_32c_1c.csv | deploy_indicators/dev/uploads ## upload days_maxwetbulb_over_32c_1c to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/days_maxwetbulb_over_32c_1c.csv "days_maxwetbulb_over_32c_1c" "Days above 32°C wet-bulb (+1°C scenario)" "[[\"good\"], [\"bad\"]]" false true "[\"© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0\"]" "Number of days per year with a daily maximum wet-bulb temperature exceeding 32°C (90°F) at the “recent” climate warming scenario of +1.0°C. In 2017 the average surface temperature passed 1.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science). Wet-bulb temperature is calculated using temperature and humidity. High wet-bulb temperatures can impair the human body’s ability to self-cool through sweating. 32°C or 90°F wet-bulb can occur at 32°C (90°F) air temperature and 99% relative humidity, or 40°C (104°F) and 55% humidity." "World (-60:60 latitudes)" "static" "days" "$(date -r db/table/pf_maxtemp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/days_maxwetbulb_over_32c_2c_upload: data/out/csv/days_maxwetbulb_over_32c_2c.csv | deploy_indicators/dev/uploads ## upload days_maxwetbulb_over_32c_2c to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/days_maxwetbulb_over_32c_2c.csv "days_maxwetbulb_over_32c_2c" "Days above 32°C wet-bulb (+2°C scenario)" "[[\"good\"], [\"bad\"]]" false true "[\"© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0\"]" "Number of days per year with a daily maximum wet-bulb temperature exceeding 32°C (90°F) at the “potential” climate warming scenario of +2.0°C. On the current path of emissions, in the 2040s the average surface temperature will likely pass 2.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science). Wet-bulb temperature is calculated using temperature and humidity. High wet-bulb temperatures can impair the human body’s ability to self-cool through sweating. 32°C or 90°F wet-bulb can occur at 32°C (90°F) air temperature and 99% relative humidity, or 40°C (104°F) and 55% humidity. The displayed values are from a range of simulated years from multiple models. Actual outcomes may prove to be higher or lower than the displayed values." "World (-60:60 latitudes)" "static" "days" "$(date -r db/table/pf_maxtemp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/man_distance_to_hospital_upload: data/out/csv/man_distance_to_hospital.csv | deploy_indicators/dev/uploads ## upload man_distance_to_hospital to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/man_distance_to_hospital.csv "man_distance_to_hospital" "Man-distance to hospitals" "[[\"good\"], [\"bad\"]]" false false "[\"© Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "" "World" "daily" "other" "$(date -r db/table/isodist_hospitals_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/man_distance_to_bomb_shelters_upload: data/out/csv/man_distance_to_bomb_shelters.csv | deploy_indicators/dev/uploads ## upload man_distance_to_bomb_shelters to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/man_distance_to_bomb_shelters.csv "man_distance_to_bomb_shelters" "Man-distance to bomb shelters" "[[\"good\"], [\"bad\"]]" false false "[\"© Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "" "World" "daily" "other" "$(date -r db/table/isodist_bomb_shelters_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/man_distance_to_charging_stations_upload: data/out/csv/man_distance_to_charging_stations.csv | deploy_indicators/dev/uploads ## upload man_distance_to_charging_stations to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/man_distance_to_charging_stations.csv "man_distance_to_charging_stations" "Man-distance to charging stations" "[[\"good\"], [\"bad\"]]" false false "[\"© Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "" "World" "daily" "other" "$(date -r db/table/isodist_charging_stations_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/total_road_length_upload: data/out/csv/total_road_length.csv | deploy_indicators/dev/uploads ## upload total_road_length to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/total_road_length.csv "total_road_length" "Total road length" "[[\"unimportant\"], [\"important\"]]" true true "[\"©2019 Facebook, Inc. and its affiliates https://github.com/facebookmicrosites/Open-Mapping-At-Facebook/blob/main/LICENSE.md\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\", \"© Kontur https://kontur.io/\"]" "Estimated total road length according to Meta (Facebook) AI and OpenStreetMap data. For places where Meta (Facebook) roads data are unavailable, the estimation is based on statistical regression from Kontur Population data." "World" "daily" "km" "$(date -r db/table/total_road_length_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/view_count_bf2402_upload: data/out/csv/view_count_bf2402.csv | deploy_indicators/dev/uploads ## upload view_count_bf2402 to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/view_count_bf2402.csv "view_count_bf2402" "OSM: map views (Jan 25 - Feb 24, 2022)" "[[\"bad\", \"unimportant\"], [\"good\", \"important\"]]" false true "[\"© Kontur\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of tile requests in a given area for the 30 days before Feb 24, 2022." "World" "daily" "n" "$(date -r db/table/tile_logs_bf2402 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/powerlines_upload: data/out/csv/powerlines.csv | deploy_indicators/dev/uploads ## upload powerlines to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/powerlines.csv "powerlines" "Medium-voltage powerlines distribution (predictive)" "[[\"bad\"], [\"good\"]]" false false "[\"©9999 Facebook, Inc. and its affiliates https://dataforgood.facebook.com/dfg/tools/electrical-distribution-grid-maps\"]" "Facebook has produced a model to help map global medium voltage (MV) grid infrastructure, i.e. the distribution lines which connect high-voltage transmission infrastructure to consumer-serving low-voltage distribution. The data found here are model outputs for six select African countries: Malawi, Nigeria, Uganda, DRC, Cote D’Ivoire, and Zambia. The grid maps are produced using a new methodology that employs various publicly-available datasets (night time satellite imagery, roads, political boundaries, etc) to predict the location of existing MV grid infrastructure." "World" "static" "other" "$(date -r db/table/facebook_medium_voltage_distribution_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/eatery_count_upload: data/out/csv/eatery_count.csv | deploy_indicators/dev/uploads ## upload eatery_count to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/eatery_count.csv "eatery_count" "OSM: eatery places count" "[[\"unimportant\"], [\"important\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of places where you can buy and eat food (such as restaurants, cafés, fast-food outlets, etc.) in a given area." "World" "daily" "n" "$(date -r db/table/osm_places_eatery_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/night_lights_intensity_upload: data/out/csv/night_lights_intensity.csv | deploy_indicators/dev/uploads ## upload night_lights_intensity to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/night_lights_intensity.csv "night_lights_intensity" "Nighttime lights intensity" "[[\"unimportant\"], [\"important\"]]" false true "[\"Earth Observation Group © 2021. https://eogdata.mines.edu/products/vnl/#reference\", \"C. D. Elvidge, K. E. Baugh, M. Zhizhin, and F.-C. Hsu, “Why VIIRS data are superior to DMSP for mapping nighttime lights,” Asia-Pacific Advanced Network 35, vol. 35, p. 62, 2013.\", \"C. D. Elvidge, M. Zhizhin, T. Ghosh, F-C. Hsu, “Annual time series of global VIIRS nighttime lights derived from monthly averages: 2012 to 2019”, Remote Sensing (In press)\"]" "Remote sensing of nighttime light emissions offers a unique perspective for investigations into human behaviors. The Visible Infrared Imaging Radiometer Suite (VIIRS) instruments aboard the Suomi NPP and NOAA-20 satellites provide global daily measurements of nighttime light." "World" "static" "nW_cm2_sr" "$(date -r db/table/night_lights_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/mapswipe_area_km2_upload: data/out/csv/mapswipe_area_km2.csv | deploy_indicators/dev/uploads ## upload mapswipe_area_km2 to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/mapswipe_area_km2.csv "mapswipe_area_km2" "Human activity" "[[\"unimportant\"], [\"important\"]]" false true "[\"Copyright © 2022 MapSwipe https://mapswipe.org/en/privacy.html\"]" "Places were MapSwipe users have detected some human activity through features (i.e. buildings, roadways, waterways, etc.) on satellite images." "World" "daily" "km2" "$(date -r db/table/mapswipe_hot_tasking_data_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/gsa_ghi_upload: data/out/csv/gsa_ghi.csv | deploy_indicators/dev/uploads ## upload gsa_ghi to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/gsa_ghi.csv "gsa_ghi" "Global Horizontal Irradiance (GHI)" "[[\"bad\", \"unimportant\"], [\"good\", \"important\"]]" false true "[\"Copyright © 2022 The World Bank https://globalsolaratlas.info/support/terms-of-use\"]" "Total amount of shortwave terrestrial irradiance received by a surface horizontal to the ground." "World (-60:60 latitudes)" "static" "W_m2" "$(date -r db/table/global_solar_atlas_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/worldclim_avg_temperature_upload: data/out/csv/worldclim_avg_temperature.csv | deploy_indicators/dev/uploads ## upload worldclim_avg_temperature to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/worldclim_avg_temperature.csv "worldclim_avg_temperature" "Air temperature (avg)" "[[\"good\"], [\"bad\"]]" false true "[\"Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html\"]" "Monthly average air temperature according to WorldClim data for the years 1970-2000." "World" "static" "celc_deg" "$(date -r db/table/worldclim_temperatures_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/worldclim_min_temperature_upload: data/out/csv/worldclim_min_temperature.csv | deploy_indicators/dev/uploads ## upload worldclim_min_temperature to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/worldclim_min_temperature.csv "worldclim_min_temperature" "Air temperature (min)" "[[\"bad\"], [\"good\"]]" false true "[\"Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html\"]" "Monthly minimum air temperature according to WorldClim data for the years 1970-2000." "World" "static" "celc_deg" "$(date -r db/table/worldclim_temperatures_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/worldclim_max_temperature_upload: data/out/csv/worldclim_max_temperature.csv | deploy_indicators/dev/uploads ## upload worldclim_max_temperature to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/worldclim_max_temperature.csv "worldclim_max_temperature" "Air temperature (max)" "[[\"good\"], [\"bad\"]]" false true "[\"Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html\"]" "Monthly maximum air temperature according to WorldClim data for the years 1970-2000." "World" "static" "celc_deg" "$(date -r db/table/worldclim_temperatures_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/worldclim_amp_temperature_upload: data/out/csv/worldclim_amp_temperature.csv | deploy_indicators/dev/uploads ## upload worldclim_amp_temperature to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/worldclim_amp_temperature.csv "worldclim_amp_temperature" "Air temperature (amplitude)" "[[\"good\"], [\"bad\"]]" false true "[\"Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html\"]" "Monthly amplitude of air temperatures according to WorldClim data for the years 1970-2000." "World" "static" "celc_deg" "$(date -r db/table/worldclim_temperatures_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/powerlines_proximity_m_upload: data/out/csv/powerlines_proximity_m.csv | deploy_indicators/dev/uploads ## upload powerlines_proximity_m to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/powerlines_proximity_m.csv "powerlines_proximity_m" "Proximity to: powerlines grid" "[[\"important\"], [\"unimportant\"]]" false true "[\"Copyright © OpenStreetMap contributors https://www.openstreetmap.org/copyright\", \"© 2020 The World Bank Group, CC-BY 4.0\"]" "Distance to closest powerline" "World" "static" "m" "$(date -r db/table/proximities_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/waste_basket_coverage_area_km2_upload: data/out/csv/waste_basket_coverage_area_km2.csv | deploy_indicators/dev/uploads ## upload waste_basket_coverage_area_km2 to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/waste_basket_coverage_area_km2.csv "waste_basket_coverage_area_km2" "OSM: waste containers count" "[[\"bad\"], [\"good\"]]" false true "[\"© Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of waste containers in a given area." "World" "daily" "n" "$(date -r db/table/waste_containers_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/populated_areas_proximity_m_upload: data/out/csv/populated_areas_proximity_m.csv | deploy_indicators/dev/uploads ## upload populated_areas_proximity_m to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/populated_areas_proximity_m.csv "populated_areas_proximity_m" "Proximity to densely populated areas" "[[\"good\"], [\"bad\"]]" false true "[\"Copyright © Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Distance to closest Kontur Population cell with population > 80 ppl" "World" "daily" "m" "$(date -r db/table/proximities_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/power_substations_proximity_m_upload: data/out/csv/power_substations_proximity_m.csv | deploy_indicators/dev/uploads ## upload power_substations_proximity_m to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/power_substations_proximity_m.csv "power_substations_proximity_m" "Proximity to power substations, m" "[[\"good\"], [\"bad\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Distance to closest power substation" "World" "daily" "m" "$(date -r db/table/proximities_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/solar_farms_placement_suitability_upload: data/out/csv/solar_farms_placement_suitability.csv | deploy_indicators/dev/uploads ## upload solar_farms_placement_suitability to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/solar_farms_placement_suitability.csv "solar_farms_placement_suitability" "Suitability estimation for solar farms placement" "[[\"bad\"], [\"good\"]]" false true "[\"Copyright © Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\", \"Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html\", \"Copyright © 2022 The World Bank https://globalsolaratlas.info/support/terms-of-use\"]" "Multi-criteria analysis based layer dedicated to estimation of suitability of solar farms placement. 0 means absolutely unsuitable, 1 means perfectly suitable. Analysis is based on solar irradiace, powerlines grid proximity, power substations proximity, elevation slope, minimal and maximal temperatures, populated areas proximity" "World (-60:60 latitudes)" "daily" "index" "$(date -r db/table/solar_farms_placement_suitability_synthetic_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/residential_upload: data/out/csv/residential.csv | deploy_indicators/dev/uploads ## upload residential to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/residential.csv "residential" "Percentage of permanent population" "[[\"unimportant\"], [\"important\"]]" false false "[\"Dataset: Schiavina, Marcello., Freire, Sergio., MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio., MacManus, Kytt., Pesaresi, Martino., Doxsey-Whitfield, Erin., Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World., Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016\"]" "Estimation of residential population percentage according to GHS-POP dataset (2015)" "World" "static" "fract" "$(date -r db/table/residential_pop_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/solar_power_plants_upload: data/out/csv/solar_power_plants.csv | deploy_indicators/dev/uploads ## upload solar_power_plants to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/solar_power_plants.csv "solar_power_plants" "Solar power plants" "[[\"unimportant\"], [\"important\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Total number of solar power plants in a given area according to OpenStreetMap." "World" "daily" "n" "$(date -r db/table/existing_solar_power_panels_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/safety_index_upload: data/out/csv/safety_index.csv | deploy_indicators/dev/uploads ## upload safety_index to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/safety_index.csv "safety_index" "Safety (Global Peace Index 2022)" "[[\"bad\"], [\"good\"]]" false true "[\"© The Institute for Economics and Peace Limited 2022 https://www.visionofhumanity.org/\"]" "The Global Peace Index covers 99.7% of the world’s population, and is calculated using 23 qualitative and quantitative indicators from highly respected sources, and measures the state of peace across three domains: the level of Societal Safety and Security, the extent of Ongoing Domestic and International Conflict, and the degree of Militarisation." "World" "static" "index" "$(date -r db/table/safety_index_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/population_upload: data/out/csv/population.csv | deploy_indicators/dev/uploads ## upload population to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/population.csv "population" "Population" "[[\"unimportant\"], [\"important\"]]" true true "[\"© Kontur https://kontur.io/\", \"Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/\", \"Dataset: Schiavina, Marcello., Freire, Sergio., MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio., MacManus, Kytt., Pesaresi, Martino., Doxsey-Whitfield, Erin., Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World., Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\", \"Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).\", \"NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/\", \"Geoalert Urban Mapping: Chechnya, Moscow region, Tyva - https://github.com/Geoalert/urban-mapping\", \"Unconstrained Individual countries 2020 (100m resolution): WorldPop - https://www.worldpop.org/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of people living in a given area according to Kontur Population dataset. The dataset was produced by overlaying the Global Human Settlement Layer (GHSL) with available Facebook population data and constraining known artifacts using OpenStreetMap data. The datasets detailed methodology is available here: https://data.humdata.org/dataset/kontur-population-dataset" "World" "daily" "ppl" "$(date -r db/table/kontur_population_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/avg_forest_canopy_height_upload: data/out/csv/avg_forest_canopy_height.csv | deploy_indicators/dev/uploads ## upload count to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/avg_forest_canopy_height.csv "avg_forest_canopy_height" "Average forest canopy height" "[[\"bad\", \"unimportant\"], [\"good\", \"important\"]]" false true "[\"High Resolution Canopy Height Maps by WRI and Meta was accessed on 20.05.2024 from https://registry.opendata.aws/dataforgood-fb-forests. Meta and World Resources Institude (WRI) - 2024. High Resolution Canopy Height Maps (CHM). Source imagery for CHM © 2016 Maxar. Accessed 20 may 2024.\"]" "Global and regional Canopy Height Maps (CHM). Created using machine learning models on high-resolution worldwide Maxar satellite imagery." "World" "static" "m" "$(date -r db/table/meta_forest_canopy_height_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/max_forest_canopy_height_upload: data/out/csv/max_forest_canopy_height.csv | deploy_indicators/dev/uploads ## upload count to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/max_forest_canopy_height.csv "max_forest_canopy_height" "Max forest canopy height" "[[\"bad\", \"unimportant\"], [\"good\", \"important\"]]" false true "[\"High Resolution Canopy Height Maps by WRI and Meta was accessed on 20.05.2024 from https://registry.opendata.aws/dataforgood-fb-forests. Meta and World Resources Institude (WRI) - 2024. High Resolution Canopy Height Maps (CHM). Source imagery for CHM © 2016 Maxar. Accessed 20 may 2024.\"]" "Global and regional Canopy Height Maps (CHM). Created using machine learning models on high-resolution worldwide Maxar satellite imagery." "World" "static" "m" "$(date -r db/table/meta_forest_canopy_height_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/worldbank_tax_rate_upload: data/out/csv/worldbank_tax_rate.csv | deploy_indicators/dev/uploads ## upload worldbank_tax_rate to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/worldbank_tax_rate.csv "worldbank_tax_rate" "Total tax and contribution rate (% of profit)" "[[\"good\"], [\"bad\"]]" false true "[\"© 2024 The World Bank Group, Doing Business project (http://www.doingbusiness.org/). NOTE: Doing Business has been discontinued as of 9/16/2021. For more information: https://bit.ly/3CLCbme\"]" "Total tax rate measures the amount of taxes and mandatory contributions payable by businesses after accounting for allowable deductions and exemptions as a share of commercial profits. Taxes withheld (such as personal income tax) or collected and remitted to tax authorities (such as value added taxes, sales taxes or goods and service taxes) are excluded." "World" "static" "perc" "$(date -r db/table/worldbank_tax_rate_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/years_to_naturalisation_upload: data/out/csv/years_to_naturalisation.csv | deploy_indicators/dev/uploads ## upload years_to_naturalisation to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/years_to_naturalisation.csv "years_to_naturalisation" "The Legal residence before naturalization" "[[\"good\"], [\"bad\"]]" false true "[\"This dataset use material from the Wikipedia article https://en.wikipedia.org/wiki/Naturalization, which is released under the https://en.wikipedia.org/wiki/Wikipedia:Text_of_the_Creative_Commons_Attribution-ShareAlike_4.0_International_License.\"]" "The duration of legal residence before a national of a foreign state, without any cultural, historical, or marriage ties or connections to the state in question, can request citizenship under that states naturalization laws." "World" "static" "years" "$(date -r db/table/wikidata_naturalization_gap_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/multiple_citizenship_upload: data/out/csv/multiple_citizenship.csv | deploy_indicators/dev/uploads ## upload multiple_citizenship to insight-api
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh dev data/out/csv/multiple_citizenship.csv "multiple_citizenship" "Possibility to have multiple citizenship" "[[\"bad\"], [\"good\"]]" false true "[\"This dataset use material from the Wikipedia article https://en.wikipedia.org/wiki/Naturalization, which is released under the https://en.wikipedia.org/wiki/Wikipedia:Text_of_the_Creative_Commons_Attribution-ShareAlike_4.0_International_License.\"]" "Possibility to have dual (multiple) citizenship: 0 - no, 1 - with restrictions regulated by local legislation, 2 - dual (multiple) citizenship is allowed." "World" "static" "other" "$(date -r db/table/wikidata_naturalization_gap_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/dev/uploads/upload_dev: deploy_indicators/dev/uploads/population_upload deploy_indicators/dev/uploads/view_count_upload deploy_indicators/dev/uploads/count_upload deploy_indicators/dev/uploads/populated_area_km2_upload deploy_indicators/dev/uploads/building_count_upload deploy_indicators/dev/uploads/highway_length_upload deploy_indicators/dev/uploads/total_road_length_upload deploy_indicators/dev/uploads/local_hours_upload deploy_indicators/dev/uploads/total_hours_upload deploy_indicators/dev/uploads/avgmax_ts_upload deploy_indicators/dev/uploads/man_distance_to_fire_brigade_upload deploy_indicators/dev/uploads/view_count_bf2402_upload deploy_indicators/dev/uploads/days_mintemp_above_25c_1c_upload deploy_indicators/dev/uploads/total_building_count_upload deploy_indicators/dev/uploads/count_6_months_upload deploy_indicators/dev/uploads/building_count_6_months_upload deploy_indicators/dev/uploads/highway_length_6_months_upload deploy_indicators/dev/uploads/osm_users_upload deploy_indicators/dev/uploads/residential_upload deploy_indicators/dev/uploads/gdp_upload deploy_indicators/dev/uploads/min_ts_upload deploy_indicators/dev/uploads/max_ts_upload deploy_indicators/dev/uploads/wildfires_upload deploy_indicators/dev/uploads/covid19_confirmed_upload deploy_indicators/dev/uploads/population_prev_upload deploy_indicators/dev/uploads/industrial_area_upload deploy_indicators/dev/uploads/volcanos_count_upload deploy_indicators/dev/uploads/pop_under_5_total_upload deploy_indicators/dev/uploads/pop_over_65_total_upload deploy_indicators/dev/uploads/poverty_families_total_upload deploy_indicators/dev/uploads/pop_disability_total_upload deploy_indicators/dev/uploads/pop_not_well_eng_speak_upload deploy_indicators/dev/uploads/pop_without_car_upload deploy_indicators/dev/uploads/man_distance_to_hospital_upload deploy_indicators/dev/uploads/man_distance_to_bomb_shelters_upload deploy_indicators/dev/uploads/man_distance_to_charging_stations_upload  deploy_indicators/dev/uploads/eatery_count_upload deploy_indicators/dev/uploads/food_shops_count_upload deploy_indicators/dev/uploads/waste_basket_coverage_area_km2_upload deploy_indicators/dev/uploads/solar_farms_placement_suitability_upload deploy_indicators/dev/uploads/mapswipe_area_km2_upload deploy_indicators/dev/uploads/avg_slope_gebco_2022_upload deploy_indicators/dev/uploads/avg_elevation_gebco_2022_upload deploy_indicators/dev/uploads/forest_upload deploy_indicators/dev/uploads/evergreen_needle_leaved_forest_upload deploy_indicators/dev/uploads/shrubs_upload deploy_indicators/dev/uploads/herbage_upload deploy_indicators/dev/uploads/unknown_forest_upload deploy_indicators/dev/uploads/avg_ndvi_upload deploy_indicators/dev/uploads/days_maxtemp_over_32c_1c_upload deploy_indicators/dev/uploads/days_maxtemp_over_32c_2c_upload deploy_indicators/dev/uploads/days_mintemp_above_25c_2c_upload deploy_indicators/dev/uploads/days_maxwetbulb_over_32c_1c_upload deploy_indicators/dev/uploads/days_maxwetbulb_over_32c_2c_upload deploy_indicators/dev/uploads/mandays_maxtemp_over_32c_1c_upload deploy_indicators/dev/uploads/hazardous_days_count_upload deploy_indicators/dev/uploads/earthquake_days_count_upload deploy_indicators/dev/uploads/wildfire_days_count_upload deploy_indicators/dev/uploads/drought_days_count_upload deploy_indicators/dev/uploads/cyclone_days_count_upload deploy_indicators/dev/uploads/volcano_days_count_upload deploy_indicators/dev/uploads/flood_days_count_upload deploy_indicators/dev/uploads/powerlines_upload deploy_indicators/dev/uploads/night_lights_intensity_upload deploy_indicators/dev/uploads/gsa_ghi_upload deploy_indicators/dev/uploads/worldclim_avg_temperature_upload deploy_indicators/dev/uploads/worldclim_min_temperature_upload deploy_indicators/dev/uploads/worldclim_max_temperature_upload deploy_indicators/dev/uploads/worldclim_amp_temperature_upload deploy_indicators/dev/uploads/powerlines_proximity_m_upload deploy_indicators/dev/uploads/populated_areas_proximity_m_upload deploy_indicators/dev/uploads/power_substations_proximity_m_upload deploy_indicators/dev/uploads/solar_power_plants_upload deploy_indicators/dev/uploads/safety_index_upload deploy_indicators/dev/uploads/avg_forest_canopy_height_upload deploy_indicators/dev/uploads/max_forest_canopy_height_upload deploy_indicators/dev/uploads/worldbank_tax_rate_upload deploy_indicators/dev/uploads/years_to_naturalisation_upload deploy_indicators/dev/uploads/multiple_citizenship_upload| deploy_indicators/dev/uploads ## Control of layer uplodings to Insigths API for DEV without one and area_km2
	touch $@

deploy/dev/cleanup_cache: deploy_indicators/dev/uploads/upload_dev | deploy_indicators/dev ## Clear insights-api cache on DEV.
	bash scripts/check_http_response_code.sh GET https://test-apps02.konturlabs.com/insights-api/cache/cleanUp 200
	touch $@

deploy_indicators/dev/custom_axis/population_area_km2: deploy_indicators/dev/uploads/population_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for population area_km2 axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "population" "area_km2"
	touch $@

deploy_indicators/dev/custom_axis/count_area_km2: deploy_indicators/dev/uploads/count_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for count area_km2 axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "count" "area_km2"
	touch $@

deploy_indicators/dev/custom_axis/building_count_area_km2: deploy_indicators/dev/uploads/building_count_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for building_count area_km2 axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "building_count" "area_km2"
	touch $@

deploy_indicators/dev/custom_axis/local_hours_area_km2: deploy_indicators/dev/uploads/local_hours_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for local_hours area_km2 axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "local_hours" "area_km2"
	touch $@

deploy_indicators/dev/custom_axis/total_hours_area_km2: deploy_indicators/dev/uploads/total_hours_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for total_hours area_km2 axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "total_hours" "area_km2"
	touch $@

deploy_indicators/dev/custom_axis/view_count_area_km2: deploy_indicators/dev/uploads/view_count_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for view_count area_km2 axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "view_count" "area_km2"
	touch $@

deploy_indicators/dev/custom_axis/osm_users_one: deploy_indicators/dev/uploads/osm_users_upload  db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for osm_users one axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "osm_users" "one"
	touch $@

deploy_indicators/dev/custom_axis/total_building_count_area_km2: deploy_indicators/dev/uploads/total_building_count_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for total_building_count area_km2 axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "total_building_count" "area_km2"
	touch $@

deploy_indicators/dev/custom_axis/wildfires_area_km2: deploy_indicators/dev/uploads/wildfires_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for wildfires area_km2 axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "wildfires" "area_km2"
	touch $@

deploy_indicators/dev/custom_axis/forest_area_km2: deploy_indicators/dev/uploads/forest_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for forest area_km2 axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "forest" "area_km2"
	touch $@

deploy_indicators/dev/custom_axis/days_maxtemp_over_32c_1c_one: deploy_indicators/dev/uploads/days_maxtemp_over_32c_1c_upload  db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for days_maxtemp_over_32c_1c one axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "days_maxtemp_over_32c_1c" "one"
	touch $@

deploy_indicators/dev/custom_axis/days_mintemp_above_25c_1c_one: deploy_indicators/dev/uploads/days_mintemp_above_25c_1c_upload  db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for days_mintemp_above_25c_1c one axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "days_mintemp_above_25c_1c" "one"
	touch $@

deploy_indicators/dev/custom_axis/man_distance_to_fire_brigade_one: deploy_indicators/dev/uploads/man_distance_to_fire_brigade_upload  db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for man_distance_to_fire_brigade one axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "man_distance_to_fire_brigade" "one"
	touch $@

deploy_indicators/dev/custom_axis/man_distance_to_hospital_one: deploy_indicators/dev/uploads/man_distance_to_hospital_upload  db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for man_distance_to_hospital one axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "man_distance_to_hospital" "one"
	touch $@

deploy_indicators/dev/custom_axis/highway_length_area_km2: deploy_indicators/dev/uploads/highway_length_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for highway_length area_km2 axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "highway_length" "area_km2"
	touch $@

deploy_indicators/dev/custom_axis/total_road_length_area_km2: deploy_indicators/dev/uploads/total_road_length_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for total_road_length area_km2 axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "total_road_length" "area_km2"
	touch $@

deploy_indicators/dev/custom_axis/view_count_bf2402_one: deploy_indicators/dev/uploads/view_count_bf2402_upload  db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for view_count_bf2402 one axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "view_count_bf2402" "one"
	touch $@

deploy_indicators/dev/custom_axis/view_count_bf2402_area_km2: deploy_indicators/dev/uploads/view_count_bf2402_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for view_count_bf2402 area_km2 axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "view_count_bf2402" "area_km2"
	touch $@

deploy_indicators/dev/custom_axis/powerlines_one: deploy_indicators/dev/uploads/powerlines_upload  db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for powerlines one axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "powerlines" "one"
	touch $@

deploy_indicators/dev/custom_axis/night_lights_intensity_one: deploy_indicators/dev/uploads/night_lights_intensity_upload  db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for night_lights_intensity one axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "night_lights_intensity" "one"
	touch $@

deploy_indicators/dev/custom_axis/man_distance_to_bomb_shelters_one: deploy_indicators/dev/uploads/man_distance_to_bomb_shelters_upload  db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for man_distance_to_bomb_shelters one axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "man_distance_to_bomb_shelters" "one"
	touch $@

deploy_indicators/dev/custom_axis/man_distance_to_charging_stations_one: deploy_indicators/dev/uploads/man_distance_to_charging_stations_upload  db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for man_distance_to_charging_stations one axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "man_distance_to_charging_stations" "one"
	touch $@

deploy_indicators/dev/custom_axis/solar_power_plants_area_km2: deploy_indicators/dev/uploads/solar_power_plants_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for solar_power_plants area_km2 axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "solar_power_plants" "area_km2"
	touch $@

deploy_indicators/dev/custom_axis/volcano_days_count_area_km2: deploy_indicators/dev/uploads/volcano_days_count_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for volcano_days_count area_km2 axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "volcano_days_count" "area_km2"
	touch $@

deploy_indicators/dev/custom_axis/volcano_days_count_one: deploy_indicators/dev/uploads/volcano_days_count_upload  db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for volcano_days_count one axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "volcano_days_count" "one"
	touch $@

deploy_indicators/dev/custom_axis/flood_days_count_area_km2: deploy_indicators/dev/uploads/flood_days_count_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for flood_days_count area_km2 axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "flood_days_count" "area_km2"
	touch $@

deploy_indicators/dev/custom_axis/flood_days_count_one: deploy_indicators/dev/uploads/flood_days_count_upload  db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for flood_days_count one axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "flood_days_count" "one"
	touch $@

deploy_indicators/dev/custom_axis/man_distance_to_bomb_shelters_population: deploy_indicators/dev/uploads/man_distance_to_bomb_shelters_upload deploy_indicators/dev/uploads/population_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for man_distance_to_bomb_shelters population axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "man_distance_to_bomb_shelters" "population"
	touch $@

deploy_indicators/dev/custom_axis/man_distance_to_charging_stations_population: deploy_indicators/dev/uploads/man_distance_to_charging_stations_upload deploy_indicators/dev/uploads/population_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for man_distance_to_charging_stations population axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "man_distance_to_charging_stations" "population"
	touch $@

deploy_indicators/dev/custom_axis/man_distance_to_fire_brigade_population: deploy_indicators/dev/uploads/man_distance_to_fire_brigade_upload deploy_indicators/dev/uploads/population_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for man_distance_to_fire_brigade population axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "man_distance_to_fire_brigade" "population"
	touch $@

deploy_indicators/dev/custom_axis/building_count_total_building_count: deploy_indicators/dev/uploads/building_count_upload deploy_indicators/dev/uploads/total_building_count_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for building_count total_building_count axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "building_count" "total_building_count"
	touch $@

deploy_indicators/dev/custom_axis/waste_basket_coverage_area_km2_populated_area_km2: deploy_indicators/dev/uploads/waste_basket_coverage_area_km2_upload deploy_indicators/dev/uploads/populated_area_km2_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for waste_basket_coverage_area_km2 populated_area_km2 axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "waste_basket_coverage_area_km2" "populated_area_km2"
	touch $@

deploy_indicators/dev/custom_axis/highway_length_total_road_length: deploy_indicators/dev/uploads/highway_length_upload deploy_indicators/dev/uploads/total_road_length_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for highway_length total_road_length axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "highway_length" "total_road_length"
	touch $@

deploy_indicators/dev/custom_axis/eatery_count_one: deploy_indicators/dev/uploads/eatery_count_upload  db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for eatery_count one axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "eatery_count" "one"
	touch $@

deploy_indicators/dev/custom_axis/food_shops_count_one: deploy_indicators/dev/uploads/food_shops_count_upload  db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for food_shops_count one axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "food_shops_count" "one"
	touch $@

deploy_indicators/dev/custom_axis/hazardous_days_count_area_km2: deploy_indicators/dev/uploads/hazardous_days_count_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for hazardous_days_count area_km2 axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "hazardous_days_count" "area_km2"
	touch $@

deploy_indicators/dev/custom_axis/hazardous_days_count_one: deploy_indicators/dev/uploads/hazardous_days_count_upload  db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for hazardous_days_count one axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "hazardous_days_count" "one"
	touch $@

deploy_indicators/dev/custom_axis/earthquake_days_count_area_km2: deploy_indicators/dev/uploads/earthquake_days_count_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for earthquake_days_count area_km2 axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "earthquake_days_count" "area_km2"
	touch $@

deploy_indicators/dev/custom_axis/earthquake_days_count_one: deploy_indicators/dev/uploads/earthquake_days_count_upload  db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for earthquake_days_count one axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "earthquake_days_count" "one"
	touch $@

deploy_indicators/dev/custom_axis/drought_days_count_area_km2: deploy_indicators/dev/uploads/drought_days_count_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for drought_days_count area_km2 axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "drought_days_count" "area_km2"
	touch $@

deploy_indicators/dev/custom_axis/drought_days_count_one: deploy_indicators/dev/uploads/drought_days_count_upload  db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for drought_days_count one axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "drought_days_count" "one"
	touch $@

deploy_indicators/dev/custom_axis/cyclone_days_count_area_km2: deploy_indicators/dev/uploads/cyclone_days_count_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for cyclone_days_count area_km2 axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "cyclone_days_count" "area_km2"
	touch $@

deploy_indicators/dev/custom_axis/cyclone_days_count_one: deploy_indicators/dev/uploads/cyclone_days_count_upload  db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for cyclone_days_count one axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "cyclone_days_count" "one"
	touch $@

deploy_indicators/dev/custom_axis/wildfire_days_count_area_km2: deploy_indicators/dev/uploads/wildfire_days_count_upload db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for wildfire_days_count area_km2 axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "wildfire_days_count" "area_km2"
	touch $@

deploy_indicators/dev/custom_axis/wildfire_days_count_one: deploy_indicators/dev/uploads/wildfire_days_count_upload  db/table/insights_api_indicators_list_dev | deploy_indicators/dev/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for wildfire_days_count one axis on dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh dev "wildfire_days_count" "one"
	touch $@

deploy_indicators/dev/custom_axis/all_custom_axis: deploy_indicators/dev/custom_axis/population_area_km2 deploy_indicators/dev/custom_axis/count_area_km2 deploy_indicators/dev/custom_axis/building_count_area_km2 deploy_indicators/dev/custom_axis/local_hours_area_km2 deploy_indicators/dev/custom_axis/total_hours_area_km2 deploy_indicators/dev/custom_axis/view_count_area_km2 deploy_indicators/dev/custom_axis/osm_users_one deploy_indicators/dev/custom_axis/total_building_count_area_km2 deploy_indicators/dev/custom_axis/wildfires_area_km2 deploy_indicators/dev/custom_axis/forest_area_km2 deploy_indicators/dev/custom_axis/days_maxtemp_over_32c_1c_one deploy_indicators/dev/custom_axis/days_mintemp_above_25c_1c_one deploy_indicators/dev/custom_axis/man_distance_to_fire_brigade_one deploy_indicators/dev/custom_axis/man_distance_to_hospital_one deploy_indicators/dev/custom_axis/highway_length_area_km2 deploy_indicators/dev/custom_axis/total_road_length_area_km2  deploy_indicators/dev/custom_axis/view_count_bf2402_one deploy_indicators/dev/custom_axis/view_count_bf2402_area_km2 deploy_indicators/dev/custom_axis/powerlines_one deploy_indicators/dev/custom_axis/night_lights_intensity_one deploy_indicators/dev/custom_axis/man_distance_to_bomb_shelters_one deploy_indicators/dev/custom_axis/man_distance_to_charging_stations_one deploy_indicators/dev/custom_axis/solar_power_plants_area_km2 deploy_indicators/dev/custom_axis/volcano_days_count_area_km2 deploy_indicators/dev/custom_axis/volcano_days_count_one deploy_indicators/dev/custom_axis/flood_days_count_area_km2 deploy_indicators/dev/custom_axis/flood_days_count_one deploy_indicators/dev/custom_axis/man_distance_to_bomb_shelters_population deploy_indicators/dev/custom_axis/man_distance_to_charging_stations_population deploy_indicators/dev/custom_axis/man_distance_to_fire_brigade_population deploy_indicators/dev/custom_axis/building_count_total_building_count deploy_indicators/dev/custom_axis/waste_basket_coverage_area_km2_populated_area_km2 deploy_indicators/dev/custom_axis/highway_length_total_road_length deploy_indicators/dev/custom_axis/eatery_count_one deploy_indicators/dev/custom_axis/food_shops_count_one deploy_indicators/dev/custom_axis/hazardous_days_count_area_km2 deploy_indicators/dev/custom_axis/hazardous_days_count_one deploy_indicators/dev/custom_axis/earthquake_days_count_area_km2 deploy_indicators/dev/custom_axis/earthquake_days_count_one deploy_indicators/dev/custom_axis/drought_days_count_area_km2 deploy_indicators/dev/custom_axis/drought_days_count_one deploy_indicators/dev/custom_axis/cyclone_days_count_area_km2 deploy_indicators/dev/custom_axis/cyclone_days_count_one deploy_indicators/dev/custom_axis/wildfire_days_count_area_km2 deploy_indicators/dev/custom_axis/wildfire_days_count_one | deploy_indicators/dev/custom_axis ## final target for custom axis deployment to dev
	touch $@

## dev presets upload block
deploy_indicators/dev/presets/osm_quantity: deploy_indicators/dev/uploads/count_upload deploy_indicators/dev/uploads/population_upload db/table/insights_api_indicators_list_dev db/table/bivariate_overlays | deploy_indicators/dev/presets ## Deploy Kontur OpenStreetMap Quantity overlay to dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh dev "count" "area_km2" "population" "area_km2"
	touch $@

deploy_indicators/dev/presets/osm_building_completeness: deploy_indicators/dev/uploads/building_count_upload deploy_indicators/dev/uploads/total_building_count_upload deploy_indicators/dev/uploads/population_upload db/table/insights_api_indicators_list_dev db/table/bivariate_overlays | deploy_indicators/dev/presets ## Deploy Kontur OpenStreetMap Building Completeness overlay to dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh dev "building_count" "total_building_count" "population" "area_km2"
	touch $@

deploy_indicators/dev/presets/osm_road_completeness: deploy_indicators/dev/uploads/highway_length_upload deploy_indicators/dev/uploads/total_road_length_upload deploy_indicators/dev/uploads/population_upload db/table/insights_api_indicators_list_dev db/table/bivariate_overlays | deploy_indicators/dev/presets ## Deploy Kontur OpenStreetMap Road Completeness overlay to dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh dev "highway_length" "total_road_length" "population" "area_km2"
	touch $@

deploy_indicators/dev/presets/osm_mapping_activity: deploy_indicators/dev/uploads/local_hours_upload deploy_indicators/dev/uploads/total_hours_upload db/table/insights_api_indicators_list_dev db/table/bivariate_overlays | deploy_indicators/dev/presets ## Deploy Kontur OpenStreetMap Mapping Activity overlay to dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh dev "local_hours" "area_km2" "total_hours" "area_km2"
	touch $@

deploy_indicators/dev/presets/osm_antiquity: deploy_indicators/dev/uploads/avgmax_ts_upload  deploy_indicators/dev/uploads/view_count_upload db/table/insights_api_indicators_list_dev db/table/bivariate_overlays | deploy_indicators/dev/presets ## Deploy Kontur OpenStreetMap Antiquity overlay to dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh dev "avgmax_ts" "one" "view_count" "area_km2"
	touch $@

deploy_indicators/dev/presets/nighttime_heatwave_risk: deploy_indicators/dev/uploads/days_mintemp_above_25c_1c_upload  deploy_indicators/dev/uploads/population_upload db/table/insights_api_indicators_list_dev db/table/bivariate_overlays | deploy_indicators/dev/presets ## Deploy Kontur Nighttime Heatwave Risk overlay to dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh dev "days_mintemp_above_25c_1c" "one" "population" "area_km2"
	touch $@

deploy_indicators/dev/presets/fire_service_scarcity_risk: deploy_indicators/dev/uploads/man_distance_to_fire_brigade_upload deploy_indicators/dev/uploads/population_upload db/table/insights_api_indicators_list_dev db/table/bivariate_overlays | deploy_indicators/dev/presets ## Deploy Kontur Fire Service Scarcity Risk overlay to dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh dev "man_distance_to_fire_brigade" "population" "population" "area_km2"
	touch $@

deploy_indicators/dev/presets/views_before_after: deploy_indicators/dev/uploads/view_count_bf2402_upload deploy_indicators/dev/uploads/view_count_upload db/table/insights_api_indicators_list_dev db/table/bivariate_overlays | deploy_indicators/dev/presets ## Deploy Kontur OpenStreetMap Views before after overlay to dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh dev "view_count_bf2402" "area_km2" "view_count" "area_km2"
	touch $@

deploy_indicators/dev/presets/ev_charging_availability: deploy_indicators/dev/uploads/man_distance_to_charging_stations_upload deploy_indicators/dev/uploads/population_upload db/table/insights_api_indicators_list_dev db/table/bivariate_overlays | deploy_indicators/dev/presets ## Deploy EV Charging Availability overlay to dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh dev "man_distance_to_charging_stations" "population" "population" "area_km2"
	touch $@

deploy_indicators/dev/presets/waste_containers_availability: deploy_indicators/dev/uploads/waste_basket_coverage_area_km2_upload deploy_indicators/dev/uploads/populated_area_km2_upload deploy_indicators/dev/uploads/population_upload db/table/insights_api_indicators_list_dev db/table/bivariate_overlays | deploy_indicators/dev/presets ## Deploy Waste containers availability overlay to dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh dev "waste_basket_coverage_area_km2" "populated_area_km2" "population" "area_km2"
	touch $@

deploy_indicators/dev/presets/shelters_scarcity_risk: deploy_indicators/dev/uploads/man_distance_to_bomb_shelters_upload deploy_indicators/dev/uploads/population_upload db/table/insights_api_indicators_list_dev db/table/bivariate_overlays | deploy_indicators/dev/presets ## Deploy Shelters Scarcity Risk overlay to dev.
	psql -c "create table if not exists insights_api_indicators_list_dev(j jsonb);"
	bash scripts/update_indicators_list.sh dev | psql -c "copy insights_api_indicators_list_dev(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh dev "man_distance_to_bomb_shelters" "population" "population" "area_km2"
	touch $@

deploy_indicators/dev/presets/all_presets: deploy_indicators/dev/presets/osm_quantity deploy_indicators/dev/presets/osm_building_completeness deploy_indicators/dev/presets/osm_road_completeness deploy_indicators/dev/presets/osm_mapping_activity deploy_indicators/dev/presets/osm_antiquity deploy_indicators/dev/presets/nighttime_heatwave_risk deploy_indicators/dev/presets/fire_service_scarcity_risk deploy_indicators/dev/presets/views_before_after deploy_indicators/dev/presets/ev_charging_availability deploy_indicators/dev/presets/waste_containers_availability deploy_indicators/dev/presets/shelters_scarcity_risk ## final target for presets deployment to dev
	touch $@

## END dev presets upload

## Deploy test ##
db/table/insights_api_indicators_list_test: | db/table ## Refresh insights_api_indicators_list_test table before new deploy cycle
	psql -c "drop table if exists insights_api_indicators_list_test;"
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	touch $@

deploy_indicators/test/uploads/count_upload: data/out/csv/count.csv | deploy_indicators/test/uploads ## upload count to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/count.csv "count" "OSM: objects count" "[[\"bad\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Total number of objects in a given area according to OpenStreetMap." "World" "daily" "n" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/hazardous_days_count_upload: data/out/csv/hazardous_days_count.csv | deploy_indicators/test/uploads ## upload hazardous_days_count to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/hazardous_days_count.csv "hazardous_days_count" "Exposure: all disaster types" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)\"]" "Number of days in the last year when severe and extreme disasters of any types were recorded." "World" "daily" "days" "$(date -r db/table/disaster_event_episodes_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/mandays_maxtemp_over_32c_1c_upload: data/out/csv/mandays_maxtemp_over_32c_1c.csv | deploy_indicators/test/uploads ## upload mandays_maxtemp_over_32c_1c to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/mandays_maxtemp_over_32c_1c.csv "mandays_maxtemp_over_32c_1c" "Man-days above 32°C, (+1°C scenario)" "[[\"good\"], [\"bad\"]]" false false "[\"© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0\"]" "" "World" "daily" "other" "$(date -r db/table/pf_maxtemp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/man_distance_to_fire_brigade_upload: data/out/csv/man_distance_to_fire_brigade.csv | deploy_indicators/test/uploads ## upload man_distance_to_fire_brigade to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/man_distance_to_fire_brigade.csv "man_distance_to_fire_brigade" "Man-distance to fire brigade" "[[\"good\"], [\"bad\"]]" false false "[\"© Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "" "World" "daily" "other" "$(date -r db/table/isodist_fire_stations_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/food_shops_count_upload: data/out/csv/food_shops_count.csv | deploy_indicators/test/uploads ## upload food_shops_count to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/food_shops_count.csv "food_shops_count" "OSM: food shops count" "[[\"unimportant\"], [\"important\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of places where you can buy fresh or packaged food products in a given area." "World" "daily" "n" "$(date -r db/table/osm_places_food_shops_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/populated_area_km2_upload: data/out/csv/populated_area_km2.csv | deploy_indicators/test/uploads ## upload populated_area_km2 to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/populated_area_km2.csv "populated_area_km2" "Populated area" "[[\"unimportant\"], [\"important\"]]" true false "[\"© Kontur https://kontur.io/\", \"Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/\", \"Dataset: Schiavina, Marcello., Freire, Sergio., MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio., MacManus, Kytt., Pesaresi, Martino., Doxsey-Whitfield, Erin., Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World., Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\", \"Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).\", \"NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/\", \"Geoalert Urban Mapping: Chechnya, Moscow region, Tyva - https://github.com/Geoalert/urban-mapping\", \"Unconstrained Individual countries 2020 (100m resolution): WorldPop - https://www.worldpop.org/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "" "World" "daily" "km2" "$(date -r db/table/kontur_population_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/count_6_months_upload: data/out/csv/count_6_months.csv | deploy_indicators/test/uploads ## upload count_6_months to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/count_6_months.csv "count_6_months" "OSM: objects mapped (6 months)" "[[\"bad\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of objects mapped in OpenStreetMap in the last 6 months." "World" "daily" "n" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/view_count_upload: data/out/csv/view_count.csv | deploy_indicators/test/uploads ## upload view_count to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/view_count.csv "view_count" "OSM: map views (last 30 days)" "[[\"bad\", \"unimportant\"], [\"good\", \"important\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of tile requests in a given area for the last 30 days." "World" "daily" "n" "$(date -r db/table/tile_logs +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/avgmax_ts_upload: data/out/csv/avgmax_ts.csv | deploy_indicators/test/uploads ## upload avgmax_ts to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/avgmax_ts.csv "avgmax_ts" "OSM: last edit (avg)" "[[\"bad\", \"unimportant\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Average of latest OpenStreetMap edit dates in a given area." "World" "daily" "unixtime" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/max_ts_upload: data/out/csv/max_ts.csv | deploy_indicators/test/uploads ## upload max_ts to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/max_ts.csv "max_ts" "OSM: last edit" "[[\"bad\", \"unimportant\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Date of latest OpenStreetMap edit in a given area at highest resolution." "World" "daily" "unixtime" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/min_ts_upload: data/out/csv/min_ts.csv | deploy_indicators/test/uploads ## upload min_ts to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/min_ts.csv "min_ts" "OSM: first edit" "[[\"good\"], [\"neutral\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Date of earliest OpenStreetMap edit in a given area." "World" "daily" "unixtime" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/osm_users_upload: data/out/csv/osm_users.csv | deploy_indicators/test/uploads ## upload osm_users to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/osm_users.csv "osm_users" "OSM: contributors count" "[[\"bad\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of users who have edited a given area in OpenStreetMap." "World" "daily" "ppl" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/building_count_upload: data/out/csv/building_count.csv | deploy_indicators/test/uploads ## upload building_count to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/building_count.csv "building_count" "OSM: buildings count" "[[\"bad\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Total number of buildings in a given area according to OpenStreetMap." "World" "daily" "n" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/building_count_6_months_upload: data/out/csv/building_count_6_months.csv | deploy_indicators/test/uploads ## upload building_count_6_months to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/building_count_6_months.csv "building_count_6_months" "OSM: new buildings (last 6 months)" "[[\"bad\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of buildings mapped in OpenStreetMap in the last 6 months." "World" "daily" "n" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/highway_length_upload: data/out/csv/highway_length.csv | deploy_indicators/test/uploads ## upload highway_length to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/highway_length.csv "highway_length" "OSM: road length" "[[\"bad\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Total length of roads in a given area according to OpenStreetMap." "World" "daily" "km" "$(date -r db/table/osm_road_segments_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/highway_length_6_months_upload: data/out/csv/highway_length_6_months.csv | deploy_indicators/test/uploads ## upload highway_length_6_months to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/highway_length_6_months.csv "highway_length_6_months" "OSM: new road length (last 6 months)" "[[\"bad\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Length of roads mapped in OpenStreetMap in the last 6 months." "World" "daily" "km" "$(date -r db/table/osm_road_segments_6_months_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/total_hours_upload: data/out/csv/total_hours.csv | deploy_indicators/test/uploads ## upload total_hours to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/total_hours.csv "total_hours" "OSM: contributor activity" "[[\"bad\"], [\"good\"]]" false true "[\"© Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Total number of OpenStreetMap mapping hours by all users in the last 2 years. A mapping hour is an hour in which a user uploaded at least one tagged object." "World" "daily" "h" "$(date -r db/table/user_hours_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/local_hours_upload: data/out/csv/local_hours.csv | deploy_indicators/test/uploads ## upload local_hours to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/local_hours.csv "local_hours" "OSM: local contributor activity" "[[\"bad\"], [\"good\"]]" false true "[\"© Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of OpenStreetMap mapping hours by active local mappers in the last 2 years. A mapping hour is an hour in which a user uploaded at least one tagged object. Mapper is considered active if they contributed more than 30 mapping hours in the last 2 years. The position of the active mapper is estimated by the region of their highest activity." "World" "daily" "h" "$(date -r db/table/user_hours_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/forest_upload: data/out/csv/forest.csv | deploy_indicators/test/uploads ## upload forest to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/forest.csv "forest" "Landcover: forest" "[[\"unimportant\"], [\"important\"]]" false true "[\"© Kontur https://kontur.io/\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\"]" "Area covered by forest - where tree canopy is more than 15%." "World" "static" "km2" "$(date -r db/table/copernicus_landcover_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/evergreen_needle_leaved_forest_upload: data/out/csv/evergreen_needle_leaved_forest.csv | deploy_indicators/test/uploads ## upload evergreen_needle_leaved_forest to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/evergreen_needle_leaved_forest.csv "evergreen_needle_leaved_forest" "Landcover: evergreen needleleaf forest" "[[\"unimportant\"], [\"important\"]]" false true "[\"© Kontur https://kontur.io/\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\"]" "Area covered by either closed or open evergreen needleleaf forest. Almost all needleleaf trees remain green all year. Canopy is never without green foliage. Closed forest has tree canopy >70%. Open forest has top layer - trees 15-70 % - and second layer - mix of shrubs and grassland." "World" "static" "km2" "$(date -r db/table/copernicus_landcover_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/shrubs_upload: data/out/csv/shrubs.csv | deploy_indicators/test/uploads ## upload shrubs to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/shrubs.csv "shrubs" "Landcover: shrubland" "[[\"unimportant\"], [\"important\"]]" false true "[\"© Kontur https://kontur.io/\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\"]" "Shrubland, or area where vegetation is dominated by woody perennial plants generally less than 5 meters in height, with persistent and woody stems and without any defined main stem. The shrub foliage can be either evergreen or deciduous." "World" "static" "km2" "$(date -r db/table/copernicus_landcover_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/herbage_upload: data/out/csv/herbage.csv | deploy_indicators/test/uploads ## upload herbage to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/herbage.csv "herbage" "Landcover: herbaceous vegetation" "[[\"unimportant\"], [\"important\"]]" false true "[\"© Kontur https://kontur.io/\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\"]" "Area covered by herbaceous plants. These plants have no persistent woody stems above ground and lack definite firm structure. Tree and shrub cover is less than 10%." "World" "static" "km2" "$(date -r db/table/copernicus_landcover_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/unknown_forest_upload: data/out/csv/unknown_forest.csv | deploy_indicators/test/uploads ## upload unknown_forest to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/unknown_forest.csv "unknown_forest" "Landcover: unknown forest type" "[[\"unimportant\"], [\"important\"]]" false true "[\"© Kontur https://kontur.io/\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\"]" "Area covered by forest that does not match defined forest types." "World" "static" "km2" "$(date -r db/table/copernicus_landcover_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/gdp_upload: data/out/csv/gdp.csv | deploy_indicators/test/uploads ## upload gdp to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/gdp.csv "gdp" "Gross Domestic Product" "[[\"bad\"], [\"good\"]]" false true "[\"© Kontur https://kontur.io/\", \"© 2019 The World Bank Group, CC-BY 4.0\", \"Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/\", \"Dataset: Schiavina, Marcello., Freire, Sergio., MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio., MacManus, Kytt., Pesaresi, Martino., Doxsey-Whitfield, Erin., Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World., Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016\", \"Copernicus Global Land Service: Land Cover 100m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, Myroslava Lesiv, Nandin-Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\", \"Microsoft Buildings: Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).\", \"@ OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "A country GDP (Gross Domestic Product) per capita multiplied by the population in a given area. For areas covering multiple countries, a sum of their respective GDP portions is used. GDP is the standard measure of the value created through the production of goods and services in a country during a certain period." "World" "static" "USD" "$(date -r db/table/gdp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/population_prev_upload: data/out/csv/population_prev.csv | deploy_indicators/test/uploads ## upload population_prev to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/population_prev.csv "population_prev" "Population (previous version)" "[[\"unimportant\"], [\"important\"]]" false false "[\"© Kontur https://kontur.io/\", \"Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/\", \"Dataset: Schiavina, Marcello., Freire, Sergio., MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio., MacManus, Kytt., Pesaresi, Martino., Doxsey-Whitfield, Erin., Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World., Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\", \"Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).\", \"NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/\", \"Geoalert Urban Mapping: Chechnya, Moscow region, Tyva - https://github.com/Geoalert/urban-mapping\", \"Unconstrained Individual countries 2020 (100m resolution): WorldPop - https://www.worldpop.org/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of people living in a given area according to previous version of Kontur Population dataset. The dataset was produced by overlaying the Global Human Settlement Layer (GHSL) with available Facebook population data and constraining known artifacts using OpenStreetMap data." "World" "daily" "ppl" "$(date -r db/table/kontur_population_v5_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/total_building_count_upload: data/out/csv/total_building_count.csv | deploy_indicators/test/uploads ## upload total_building_count to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/total_building_count.csv "total_building_count" "Total buildings count" "[[\"unimportant\"], [\"important\"]]" true true "[\"© Kontur https://kontur.io/\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\", \"Geoalert Urban Mapping: Chechnya, Moscow region, Tyva - https://github.com/Geoalert/urban-mapping\", \"Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).\", \"NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Estimated number of buildings in a given area based on various data sources." "World" "daily" "n" "$(date -r db/table/building_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/wildfires_upload: data/out/csv/wildfires.csv | deploy_indicators/test/uploads ## upload wildfires to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/wildfires.csv "wildfires" "Wildfire days" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false false "[\"© NRT VIIRS 375 m Active Fire product VJ114IMGTDL_NRT. Available on-line [https://earthdata.nasa.gov/firms]. doi: 10.5067/FIRMS/VIIRS/VJ114IMGT_NRT.002\", \"NRT VIIRS 375 m Active Fire product VNP14IMGT. Available on-line [https://earthdata.nasa.gov/firms]. doi:10.5067/FIRMS/VIIRS/VNP14IMGT_NRT.002\", \"MODIS Collection 6 NRT Hotspot / Active Fire Detections MCD14DL. Available on-line [https://earthdata.nasa.gov/firms]. doi: 10.5067/FIRMS/MODIS/MCD14DL.NRT.006\", \"MODIS Collection 6 NRT Hotspot / Active Fire Detections MCD14ML. Available on-line [https://earthdata.nasa.gov/firms]. doi: 10.5067/FIRMS/MODIS/MCD14ML\"]" "Number of days per year when a thermal anomaly was recorded in the last 13 months." "World" "daily" "days" "$(date -r db/table/global_fires_stat_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/earthquake_days_count_upload: data/out/csv/earthquake_days_count.csv | deploy_indicators/test/uploads ## upload earthquake_days_count to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/earthquake_days_count.csv "earthquake_days_count" "Exposure: earthquake" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)\"]" "Number of days in the last year when severe and extreme earthquakes were recorded." "World" "daily" "days" "$(date -r db/table/disaster_event_episodes_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/drought_days_count_upload: data/out/csv/drought_days_count.csv | deploy_indicators/test/uploads ## upload drought_days_count to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/drought_days_count.csv "drought_days_count" "Exposure: drought" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)\"]" "Number of days in the last year when severe and extreme droughts were recorded." "World" "daily" "days" "$(date -r db/table/disaster_event_episodes_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/cyclone_days_count_upload: data/out/csv/cyclone_days_count.csv | deploy_indicators/test/uploads ## upload cyclone_days_count to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/cyclone_days_count.csv "cyclone_days_count" "Exposure: cyclone" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)\"]" "Number of days in the last year when severe and extreme cyclones were recorded." "World" "daily" "days" "$(date -r db/table/disaster_event_episodes_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/wildfire_days_count_upload: data/out/csv/wildfire_days_count.csv | deploy_indicators/test/uploads ## upload wildfire_days_count to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/wildfire_days_count.csv "wildfire_days_count" "Exposure: wildfire" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)\"]" "Number of days in the last year when severe and extreme wildfires were recorded." "World" "daily" "days" "$(date -r db/table/disaster_event_episodes_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/volcano_days_count_upload: data/out/csv/volcano_days_count.csv | deploy_indicators/test/uploads ## upload volcano_days_count to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/volcano_days_count.csv "volcano_days_count" "Exposure: volcanic eruption" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)\"]" "Number of days in the last year when severe and extreme volcanos were recorded." "World" "daily" "days" "$(date -r db/table/disaster_event_episodes_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/flood_days_count_upload: data/out/csv/flood_days_count.csv | deploy_indicators/test/uploads ## upload flood_days_count to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/flood_days_count.csv "flood_days_count" "Exposure: flood" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)\"]" "Number of days in the last year when severe and extreme floods were recorded." "World" "daily" "days" "$(date -r db/table/disaster_event_episodes_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/covid19_confirmed_upload: data/out/csv/covid19_confirmed.csv | deploy_indicators/test/uploads ## upload covid19_confirmed to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/covid19_confirmed.csv "covid19_confirmed" "COVID-19 confirmed сases" "[[\"good\"], [\"bad\"]]" false true "[\"© Data from JHU CSSE COVID-19 Dataset\"]" "Number of COVID-19 confirmed cases for the entire observation period according to the Center for Systems Science and Engineering (CSSE) at Johns Hopkins University (JHU)." "World" "daily" "n" "$(date -r db/table/covid19_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/avg_slope_gebco_2022_upload: data/out/csv/avg_slope_gebco_2022.csv | deploy_indicators/test/uploads ## upload avg_slope_gebco_2022 to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/avg_slope_gebco_2022.csv "avg_slope_gebco_2022" "Slope (avg)" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"© Data from General Bathymatric Chart of the Oceans, www.gebco.net\"]" "Average surface slope." "World" "static" "deg" "$(date -r db/table/gebco_2022_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/avg_elevation_gebco_2022_upload: data/out/csv/avg_elevation_gebco_2022.csv | deploy_indicators/test/uploads ## upload avg_elevation_gebco_2022 to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/avg_elevation_gebco_2022.csv "avg_elevation_gebco_2022" "Elevation (avg)" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"© Data from General Bathymatric Chart of the Oceans, www.gebco.net\"]" "Average surface elevation in meters." "World" "static" "m" "$(date -r db/table/gebco_2022_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/industrial_area_upload: data/out/csv/industrial_area.csv | deploy_indicators/test/uploads ## upload industrial_area to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/industrial_area.csv "industrial_area" "OSM: industrial area" "[[\"unimportant\"], [\"important\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Areas of land used for industrial purposes, which may include facilities such as workshops, factories and warehouses, and their associated infrastructure (car parks, service roads, yards, etc.)." "World" "daily" "km2" "$(date -r db/table/osm_landuse_industrial_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/avg_ndvi_upload: data/out/csv/avg_ndvi.csv | deploy_indicators/test/uploads ## upload avg_ndvi to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/avg_ndvi.csv "avg_ndvi" "NDVI (avg)" "[[\"bad\"], [\"good\"]]" false true "[\"© Data from Sentinel-2 L2A 120m Mosaic, CC-BY 4.0, https://forum.sentinel-hub.com/c/aws-sentinel\"]" "Average values of Normalized Difference Vegetation Index (NDVI), as of June 2019. Negative values of NDVI (values approaching -1) correspond to water. Values close to zero (-0.1 to 0.1) generally correspond to barren areas of rock, sand, or snow. Low, positive values represent shrub and grassland (approximately 0.2 to 0.4), while high values indicate temperate and tropical rainforests (values approaching 1)." "World" "static" "index" "$(date -r db/table/ndvi_2019_06_10_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/volcanos_count_upload: data/out/csv/volcanos_count.csv | deploy_indicators/test/uploads ## upload volcanos_count to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/volcanos_count.csv "volcanos_count" "OSM: volcanoes count" "[[\"unimportant\"], [\"important\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of volcanoes in a given area." "World" "daily" "n" "$(date -r db/table/osm_volcanos_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/pop_under_5_total_upload: data/out/csv/pop_under_5_total.csv | deploy_indicators/test/uploads ## upload pop_under_5_total to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/pop_under_5_total.csv "pop_under_5_total" "Population: under 5" "[[\"unimportant\"], [\"important\"]]" false true "[\"© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html\"]" "Number of children (ages 0-5) in the United States." "The United States of America" "static" "ppl" "$(date -r db/table/us_census_tracts_stats_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/pop_over_65_total_upload: data/out/csv/pop_over_65_total.csv | deploy_indicators/test/uploads ## upload pop_over_65_total to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/pop_over_65_total.csv "pop_over_65_total" "Population: over 65" "[[\"unimportant\"], [\"important\"]]" false true "[\"© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html\"]" "Number of elderly people (ages 65+) in the United States." "The United States of America" "static" "ppl" "$(date -r db/table/us_census_tracts_stats_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/poverty_families_total_upload: data/out/csv/poverty_families_total.csv | deploy_indicators/test/uploads ## upload poverty_families_total to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/poverty_families_total.csv "poverty_families_total" "Population: families below poverty line" "[[\"unimportant\", \"good\"], [\"important\"]]" false true "[\"© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html\"]" "Number of households living below the poverty line in the United States." "The United States of America" "static" "n" "$(date -r db/table/us_census_tracts_stats_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/pop_disability_total_upload: data/out/csv/pop_disability_total.csv | deploy_indicators/test/uploads ## upload pop_disability_total to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/pop_disability_total.csv "pop_disability_total" "Population: with disabilities" "[[\"unimportant\"], [\"important\"]]" false true "[\"© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html\"]" "Number of people with disabilities in the United States based on the U.S. Census Bureaus American Community Survey (ACS). This page describes how disability is defined and collected in the ACS: https://www.census.gov/topics/health/disability/guidance/data-collection-acs.html" "The United States of America" "static" "ppl" "$(date -r db/table/us_census_tracts_stats_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@


deploy_indicators/test/uploads/pop_not_well_eng_speak_upload: data/out/csv/pop_not_well_eng_speak.csv | deploy_indicators/test/uploads ## upload pop_not_well_eng_speak to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/pop_not_well_eng_speak.csv "pop_not_well_eng_speak" "Population: limited English proficiency" "[[\"good\"], [\"important\", \"bad\"]]" false true "[\"© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html\"]" "Number of people who have difficulty speaking English in the United States." "The United States of America" "static" "ppl" "$(date -r db/table/us_census_tracts_stats_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/pop_without_car_upload: data/out/csv/pop_without_car.csv | deploy_indicators/test/uploads ## upload pop_without_car to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/pop_without_car.csv "pop_without_car" "Population: without a car" "[[\"neutral\"], [\"important\"]]" false true "[\"© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html\"]" "Number of working people without a car in the United States." "The United States of America" "static" "ppl" "$(date -r db/table/us_census_tracts_stats_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/days_maxtemp_over_32c_1c_upload: data/out/csv/days_maxtemp_over_32c_1c.csv | deploy_indicators/test/uploads ## upload days_maxtemp_over_32c_1c to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/days_maxtemp_over_32c_1c.csv "days_maxtemp_over_32c_1c" "Days above 32°C (+1°C scenario)" "[[\"good\"], [\"bad\"]]" false true "[\"© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0\"]" "Number of days per year with a daily maximum temperature exceeding 32°C (90°F) at the “recent” climate warming scenario of +1.0°C. In 2017 the average surface temperature passed 1.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science)." "World (-60:60 latitudes)" "static" "days" "$(date -r db/table/pf_maxtemp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/days_maxtemp_over_32c_2c_upload: data/out/csv/days_maxtemp_over_32c_2c.csv | deploy_indicators/test/uploads ## upload days_maxtemp_over_32c_2c to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/days_maxtemp_over_32c_2c.csv "days_maxtemp_over_32c_2c" "Days above 32°C (+2°C scenario)" "[[\"good\"], [\"bad\"]]" false true "[\"© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0\"]" "Number of days per year with a daily maximum temperature exceeding 32°C (90°F) at the “potential” climate warming scenario of +2.0°C. On the current path of emissions, in the 2040s the average surface temperature will likely pass 2.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science).The displayed values are from a range of simulated years from multiple models. Actual outcomes may prove to be higher or lower than the displayed values." "World (-60:60 latitudes)" "static" "days" "$(date -r db/table/pf_maxtemp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/days_mintemp_above_25c_1c_upload: data/out/csv/days_mintemp_above_25c_1c.csv | deploy_indicators/test/uploads ## upload days_mintemp_above_25c_1c to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/days_mintemp_above_25c_1c.csv "days_mintemp_above_25c_1c" "Nights above 25°C (+1°C scenario)" "[[\"good\"], [\"bad\"]]" false true "[\"© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0\"]" "Number of days per year with a daily minimum temperature exceeding 25°C (77°F) at the “recent” climate warming scenario of +1.0°C. In 2017 the average surface temperature passed 1.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science). The lowest temperature during the day happens at night when temperatures dip after sunset. The human experience of a “hot” night is relative to location, so a threshold of 20°C is often used for higher latitudes (Europe and the US) and a threshold of 25°C is often used for tropical and equatorial regions." "World (-60:60 latitudes)" "static" "days" "$(date -r db/table/pf_maxtemp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/days_mintemp_above_25c_2c_upload: data/out/csv/days_mintemp_above_25c_2c.csv | deploy_indicators/test/uploads ## upload days_mintemp_above_25c_2c to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/days_mintemp_above_25c_2c.csv "days_mintemp_above_25c_2c" "Nights above 25°C (+2°C scenario)" "[[\"good\"], [\"bad\"]]" false true "[\"© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0\"]" "Number of days per year with a daily minimum temperature exceeding 25°C (77°F) at the “potential” climate warming scenario of +2.0°C. On the current path of emissions, in the 2040s the average surface temperature will likely pass 2.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science). The lowest temperature during the day happens at night when temperatures dip after sunset. The human experience of a “hot” night is relative to location, so a threshold of 20°C is often used for higher latitudes (Europe and the US) and a threshold of 25°C is often used for tropical and equatorial regions. The displayed values are from a range of simulated years from multiple models. Actual outcomes may prove to be higher or lower than the displayed values." "World (-60:60 latitudes)" "static" "days" "$(date -r db/table/pf_maxtemp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/days_maxwetbulb_over_32c_1c_upload: data/out/csv/days_maxwetbulb_over_32c_1c.csv | deploy_indicators/test/uploads ## upload days_maxwetbulb_over_32c_1c to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/days_maxwetbulb_over_32c_1c.csv "days_maxwetbulb_over_32c_1c" "Days above 32°C wet-bulb (+1°C scenario)" "[[\"good\"], [\"bad\"]]" false true "[\"© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0\"]" "Number of days per year with a daily maximum wet-bulb temperature exceeding 32°C (90°F) at the “recent” climate warming scenario of +1.0°C. In 2017 the average surface temperature passed 1.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science). Wet-bulb temperature is calculated using temperature and humidity. High wet-bulb temperatures can impair the human body’s ability to self-cool through sweating. 32°C or 90°F wet-bulb can occur at 32°C (90°F) air temperature and 99% relative humidity, or 40°C (104°F) and 55% humidity." "World (-60:60 latitudes)" "static" "days" "$(date -r db/table/pf_maxtemp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/days_maxwetbulb_over_32c_2c_upload: data/out/csv/days_maxwetbulb_over_32c_2c.csv | deploy_indicators/test/uploads ## upload days_maxwetbulb_over_32c_2c to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/days_maxwetbulb_over_32c_2c.csv "days_maxwetbulb_over_32c_2c" "Days above 32°C wet-bulb (+2°C scenario)" "[[\"good\"], [\"bad\"]]" false true "[\"© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0\"]" "Number of days per year with a daily maximum wet-bulb temperature exceeding 32°C (90°F) at the “potential” climate warming scenario of +2.0°C. On the current path of emissions, in the 2040s the average surface temperature will likely pass 2.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science). Wet-bulb temperature is calculated using temperature and humidity. High wet-bulb temperatures can impair the human body’s ability to self-cool through sweating. 32°C or 90°F wet-bulb can occur at 32°C (90°F) air temperature and 99% relative humidity, or 40°C (104°F) and 55% humidity. The displayed values are from a range of simulated years from multiple models. Actual outcomes may prove to be higher or lower than the displayed values." "World (-60:60 latitudes)" "static" "days" "$(date -r db/table/pf_maxtemp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/man_distance_to_hospital_upload: data/out/csv/man_distance_to_hospital.csv | deploy_indicators/test/uploads ## upload man_distance_to_hospital to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/man_distance_to_hospital.csv "man_distance_to_hospital" "Man-distance to hospitals" "[[\"good\"], [\"bad\"]]" false false "[\"© Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "" "World" "daily" "other" "$(date -r db/table/isodist_hospitals_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/man_distance_to_bomb_shelters_upload: data/out/csv/man_distance_to_bomb_shelters.csv | deploy_indicators/test/uploads ## upload man_distance_to_bomb_shelters to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/man_distance_to_bomb_shelters.csv "man_distance_to_bomb_shelters" "Man-distance to bomb shelters" "[[\"good\"], [\"bad\"]]" false false "[\"© Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "" "World" "daily" "other" "$(date -r db/table/isodist_bomb_shelters_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/man_distance_to_charging_stations_upload: data/out/csv/man_distance_to_charging_stations.csv | deploy_indicators/test/uploads ## upload man_distance_to_charging_stations to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/man_distance_to_charging_stations.csv "man_distance_to_charging_stations" "Man-distance to charging stations" "[[\"good\"], [\"bad\"]]" false false "[\"© Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "" "World" "daily" "other" "$(date -r db/table/isodist_charging_stations_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/total_road_length_upload: data/out/csv/total_road_length.csv | deploy_indicators/test/uploads ## upload total_road_length to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/total_road_length.csv "total_road_length" "Total road length" "[[\"unimportant\"], [\"important\"]]" true true "[\"©2019 Facebook, Inc. and its affiliates https://github.com/facebookmicrosites/Open-Mapping-At-Facebook/blob/main/LICENSE.md\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\", \"© Kontur https://kontur.io/\"]" "Estimated total road length according to Meta (Facebook) AI and OpenStreetMap data. For places where Meta (Facebook) roads data are unavailable, the estimation is based on statistical regression from Kontur Population data." "World" "daily" "km" "$(date -r db/table/total_road_length_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/view_count_bf2402_upload: data/out/csv/view_count_bf2402.csv | deploy_indicators/test/uploads ## upload view_count_bf2402 to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/view_count_bf2402.csv "view_count_bf2402" "OSM: map views (Jan 25 - Feb 24, 2022)" "[[\"bad\", \"unimportant\"], [\"good\", \"important\"]]" false true "[\"© Kontur\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of tile requests in a given area for the 30 days before Feb 24, 2022." "World" "daily" "n" "$(date -r db/table/tile_logs_bf2402 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/powerlines_upload: data/out/csv/powerlines.csv | deploy_indicators/test/uploads ## upload powerlines to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/powerlines.csv "powerlines" "Medium-voltage powerlines distribution (predictive)" "[[\"bad\"], [\"good\"]]" false false "[\"©9999 Facebook, Inc. and its affiliates https://dataforgood.facebook.com/dfg/tools/electrical-distribution-grid-maps\"]" "Facebook has produced a model to help map global medium voltage (MV) grid infrastructure, i.e. the distribution lines which connect high-voltage transmission infrastructure to consumer-serving low-voltage distribution. The data found here are model outputs for six select African countries: Malawi, Nigeria, Uganda, DRC, Cote D’Ivoire, and Zambia. The grid maps are produced using a new methodology that employs various publicly-available datasets (night time satellite imagery, roads, political boundaries, etc) to predict the location of existing MV grid infrastructure." "World" "static" "other" "$(date -r db/table/facebook_medium_voltage_distribution_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/eatery_count_upload: data/out/csv/eatery_count.csv | deploy_indicators/test/uploads ## upload eatery_count to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/eatery_count.csv "eatery_count" "OSM: eatery places count" "[[\"unimportant\"], [\"important\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of places where you can buy and eat food (such as restaurants, cafés, fast-food outlets, etc.) in a given area." "World" "daily" "n" "$(date -r db/table/osm_places_eatery_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/night_lights_intensity_upload: data/out/csv/night_lights_intensity.csv | deploy_indicators/test/uploads ## upload night_lights_intensity to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/night_lights_intensity.csv "night_lights_intensity" "Nighttime lights intensity" "[[\"unimportant\"], [\"important\"]]" false true "[\"Earth Observation Group © 2021. https://eogdata.mines.edu/products/vnl/#reference\", \"C. D. Elvidge, K. E. Baugh, M. Zhizhin, and F.-C. Hsu, “Why VIIRS data are superior to DMSP for mapping nighttime lights,” Asia-Pacific Advanced Network 35, vol. 35, p. 62, 2013.\", \"C. D. Elvidge, M. Zhizhin, T. Ghosh, F-C. Hsu, “Annual time series of global VIIRS nighttime lights derived from monthly averages: 2012 to 2019”, Remote Sensing (In press)\"]" "Remote sensing of nighttime light emissions offers a unique perspective for investigations into human behaviors. The Visible Infrared Imaging Radiometer Suite (VIIRS) instruments aboard the Suomi NPP and NOAA-20 satellites provide global daily measurements of nighttime light." "World" "static" "nW_cm2_sr" "$(date -r db/table/night_lights_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/mapswipe_area_km2_upload: data/out/csv/mapswipe_area_km2.csv | deploy_indicators/test/uploads ## upload mapswipe_area_km2 to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/mapswipe_area_km2.csv "mapswipe_area_km2" "Human activity" "[[\"unimportant\"], [\"important\"]]" false true "[\"Copyright © 2022 MapSwipe https://mapswipe.org/en/privacy.html\"]" "Places were MapSwipe users have detected some human activity through features (i.e. buildings, roadways, waterways, etc.) on satellite images." "World" "daily" "km2" "$(date -r db/table/mapswipe_hot_tasking_data_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/gsa_ghi_upload: data/out/csv/gsa_ghi.csv | deploy_indicators/test/uploads ## upload gsa_ghi to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/gsa_ghi.csv "gsa_ghi" "Global Horizontal Irradiance (GHI)" "[[\"bad\", \"unimportant\"], [\"good\", \"important\"]]" false true "[\"Copyright © 2022 The World Bank https://globalsolaratlas.info/support/terms-of-use\"]" "Total amount of shortwave terrestrial irradiance received by a surface horizontal to the ground." "World (-60:60 latitudes)" "static" "W_m2" "$(date -r db/table/global_solar_atlas_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/worldclim_avg_temperature_upload: data/out/csv/worldclim_avg_temperature.csv | deploy_indicators/test/uploads ## upload worldclim_avg_temperature to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/worldclim_avg_temperature.csv "worldclim_avg_temperature" "Air temperature (avg)" "[[\"good\"], [\"bad\"]]" false true "[\"Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html\"]" "Monthly average air temperature according to WorldClim data for the years 1970-2000." "World" "static" "celc_deg" "$(date -r db/table/worldclim_temperatures_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/worldclim_min_temperature_upload: data/out/csv/worldclim_min_temperature.csv | deploy_indicators/test/uploads ## upload worldclim_min_temperature to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/worldclim_min_temperature.csv "worldclim_min_temperature" "Air temperature (min)" "[[\"bad\"], [\"good\"]]" false true "[\"Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html\"]" "Monthly minimum air temperature according to WorldClim data for the years 1970-2000." "World" "static" "celc_deg" "$(date -r db/table/worldclim_temperatures_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/worldclim_max_temperature_upload: data/out/csv/worldclim_max_temperature.csv | deploy_indicators/test/uploads ## upload worldclim_max_temperature to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/worldclim_max_temperature.csv "worldclim_max_temperature" "Air temperature (max)" "[[\"good\"], [\"bad\"]]" false true "[\"Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html\"]" "Monthly maximum air temperature according to WorldClim data for the years 1970-2000." "World" "static" "celc_deg" "$(date -r db/table/worldclim_temperatures_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/worldclim_amp_temperature_upload: data/out/csv/worldclim_amp_temperature.csv | deploy_indicators/test/uploads ## upload worldclim_amp_temperature to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/worldclim_amp_temperature.csv "worldclim_amp_temperature" "Air temperature (amplitude)" "[[\"good\"], [\"bad\"]]" false true "[\"Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html\"]" "Monthly amplitude of air temperatures according to WorldClim data for the years 1970-2000." "World" "static" "celc_deg" "$(date -r db/table/worldclim_temperatures_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/powerlines_proximity_m_upload: data/out/csv/powerlines_proximity_m.csv | deploy_indicators/test/uploads ## upload powerlines_proximity_m to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/powerlines_proximity_m.csv "powerlines_proximity_m" "Proximity to: powerlines grid" "[[\"important\"], [\"unimportant\"]]" false true "[\"Copyright © OpenStreetMap contributors https://www.openstreetmap.org/copyright\", \"© 2020 The World Bank Group, CC-BY 4.0\"]" "Distance to closest powerline" "World" "static" "m" "$(date -r db/table/proximities_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/waste_basket_coverage_area_km2_upload: data/out/csv/waste_basket_coverage_area_km2.csv | deploy_indicators/test/uploads ## upload waste_basket_coverage_area_km2 to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/waste_basket_coverage_area_km2.csv "waste_basket_coverage_area_km2" "OSM: waste containers count" "[[\"bad\"], [\"good\"]]" false true "[\"© Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of waste containers in a given area." "World" "daily" "n" "$(date -r db/table/waste_containers_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/populated_areas_proximity_m_upload: data/out/csv/populated_areas_proximity_m.csv | deploy_indicators/test/uploads ## upload populated_areas_proximity_m to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/populated_areas_proximity_m.csv "populated_areas_proximity_m" "Proximity to densely populated areas" "[[\"good\"], [\"bad\"]]" false true "[\"Copyright © Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Distance to closest Kontur Population cell with population > 80 ppl" "World" "daily" "m" "$(date -r db/table/proximities_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/power_substations_proximity_m_upload: data/out/csv/power_substations_proximity_m.csv | deploy_indicators/test/uploads ## upload power_substations_proximity_m to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/power_substations_proximity_m.csv "power_substations_proximity_m" "Proximity to power substations, m" "[[\"good\"], [\"bad\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Distance to closest power substation" "World" "daily" "m" "$(date -r db/table/proximities_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/solar_farms_placement_suitability_upload: data/out/csv/solar_farms_placement_suitability.csv | deploy_indicators/test/uploads ## upload solar_farms_placement_suitability to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/solar_farms_placement_suitability.csv "solar_farms_placement_suitability" "Suitability estimation for solar farms placement" "[[\"bad\"], [\"good\"]]" false true "[\"Copyright © Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\", \"Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html\", \"Copyright © 2022 The World Bank https://globalsolaratlas.info/support/terms-of-use\"]" "Multi-criteria analysis based layer dedicated to estimation of suitability of solar farms placement. 0 means absolutely unsuitable, 1 means perfectly suitable. Analysis is based on solar irradiace, powerlines grid proximity, power substations proximity, elevation slope, minimal and maximal temperatures, populated areas proximity" "World (-60:60 latitudes)" "daily" "index" "$(date -r db/table/solar_farms_placement_suitability_synthetic_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/residential_upload: data/out/csv/residential.csv | deploy_indicators/test/uploads ## upload residential to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/residential.csv "residential" "Percentage of permanent population" "[[\"unimportant\"], [\"important\"]]" false false "[\"Dataset: Schiavina, Marcello., Freire, Sergio., MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio., MacManus, Kytt., Pesaresi, Martino., Doxsey-Whitfield, Erin., Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World., Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016\"]" "Estimation of residential population percentage according to GHS-POP dataset (2015)" "World" "static" "fract" "$(date -r db/table/residential_pop_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/solar_power_plants_upload: data/out/csv/solar_power_plants.csv | deploy_indicators/test/uploads ## upload solar_power_plants to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/solar_power_plants.csv "solar_power_plants" "Solar power plants" "[[\"unimportant\"], [\"important\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Total number of solar power plants in a given area according to OpenStreetMap." "World" "daily" "n" "$(date -r db/table/existing_solar_power_panels_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/safety_index_upload: data/out/csv/safety_index.csv | deploy_indicators/test/uploads ## upload safety_index to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/safety_index.csv "safety_index" "Safety (Global Peace Index 2022)" "[[\"bad\"], [\"good\"]]" false true "[\"© The Institute for Economics and Peace Limited 2022 https://www.visionofhumanity.org/\"]" "The Global Peace Index covers 99.7% of the world’s population, and is calculated using 23 qualitative and quantitative indicators from highly respected sources, and measures the state of peace across three domains: the level of Societal Safety and Security, the extent of Ongoing Domestic and International Conflict, and the degree of Militarisation." "World" "static" "index" "$(date -r db/table/safety_index_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/population_upload: data/out/csv/population.csv | deploy_indicators/test/uploads ## upload population to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/population.csv "population" "Population" "[[\"unimportant\"], [\"important\"]]" true true "[\"© Kontur https://kontur.io/\", \"Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/\", \"Dataset: Schiavina, Marcello., Freire, Sergio., MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio., MacManus, Kytt., Pesaresi, Martino., Doxsey-Whitfield, Erin., Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World., Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\", \"Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).\", \"NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/\", \"Geoalert Urban Mapping: Chechnya, Moscow region, Tyva - https://github.com/Geoalert/urban-mapping\", \"Unconstrained Individual countries 2020 (100m resolution): WorldPop - https://www.worldpop.org/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of people living in a given area according to Kontur Population dataset. The dataset was produced by overlaying the Global Human Settlement Layer (GHSL) with available Facebook population data and constraining known artifacts using OpenStreetMap data. The datasets detailed methodology is available here: https://data.humdata.org/dataset/kontur-population-dataset" "World" "daily" "ppl" "$(date -r db/table/kontur_population_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/avg_forest_canopy_height_upload: data/out/csv/avg_forest_canopy_height.csv | deploy_indicators/test/uploads ## upload count to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/avg_forest_canopy_height.csv "avg_forest_canopy_height" "Average forest canopy height" "[[\"bad\", \"unimportant\"], [\"good\", \"important\"]]" false true "[\"High Resolution Canopy Height Maps by WRI and Meta was accessed on 20.05.2024 from https://registry.opendata.aws/dataforgood-fb-forests. Meta and World Resources Institude (WRI) - 2024. High Resolution Canopy Height Maps (CHM). Source imagery for CHM © 2016 Maxar. Accessed 20 may 2024.\"]" "Global and regional Canopy Height Maps (CHM). Created using machine learning models on high-resolution worldwide Maxar satellite imagery." "World" "static" "m" "$(date -r db/table/meta_forest_canopy_height_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/max_forest_canopy_height_upload: data/out/csv/max_forest_canopy_height.csv | deploy_indicators/test/uploads ## upload count to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/max_forest_canopy_height.csv "max_forest_canopy_height" "Max forest canopy height" "[[\"bad\", \"unimportant\"], [\"good\", \"important\"]]" false true "[\"High Resolution Canopy Height Maps by WRI and Meta was accessed on 20.05.2024 from https://registry.opendata.aws/dataforgood-fb-forests. Meta and World Resources Institude (WRI) - 2024. High Resolution Canopy Height Maps (CHM). Source imagery for CHM © 2016 Maxar. Accessed 20 may 2024.\"]" "Global and regional Canopy Height Maps (CHM). Created using machine learning models on high-resolution worldwide Maxar satellite imagery." "World" "static" "m" "$(date -r db/table/meta_forest_canopy_height_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/worldbank_tax_rate_upload: data/out/csv/worldbank_tax_rate.csv | deploy_indicators/test/uploads ## upload worldbank_tax_rate to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/worldbank_tax_rate.csv "worldbank_tax_rate" "Total tax and contribution rate (% of profit)" "[[\"good\"], [\"bad\"]]" false true "[\"© 2024 The World Bank Group, Doing Business project (http://www.doingbusiness.org/). NOTE: Doing Business has been discontinued as of 9/16/2021. For more information: https://bit.ly/3CLCbme\"]" "Total tax rate measures the amount of taxes and mandatory contributions payable by businesses after accounting for allowable deductions and exemptions as a share of commercial profits. Taxes withheld (such as personal income tax) or collected and remitted to tax authorities (such as value added taxes, sales taxes or goods and service taxes) are excluded." "World" "static" "perc" "$(date -r db/table/worldbank_tax_rate_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/years_to_naturalisation_upload: data/out/csv/years_to_naturalisation.csv | deploy_indicators/test/uploads ## upload years_to_naturalisation to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/years_to_naturalisation.csv "years_to_naturalisation" "The Legal residence before naturalization" "[[\"good\"], [\"bad\"]]" false true "[\"This dataset use material from the Wikipedia article https://en.wikipedia.org/wiki/Naturalization, which is released under the https://en.wikipedia.org/wiki/Wikipedia:Text_of_the_Creative_Commons_Attribution-ShareAlike_4.0_International_License.\"]" "The duration of legal residence before a national of a foreign state, without any cultural, historical, or marriage ties or connections to the state in question, can request citizenship under that states naturalization laws." "World" "static" "years" "$(date -r db/table/wikidata_naturalization_gap_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/multiple_citizenship_upload: data/out/csv/multiple_citizenship.csv | deploy_indicators/test/uploads ## upload multiple_citizenship to insight-api
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh test data/out/csv/multiple_citizenship.csv "multiple_citizenship" "Possibility to have multiple citizenship" "[[\"good\"], [\"bad\"]]" false true "[\"This dataset use material from the Wikipedia article https://en.wikipedia.org/wiki/Naturalization, which is released under the https://en.wikipedia.org/wiki/Wikipedia:Text_of_the_Creative_Commons_Attribution-ShareAlike_4.0_International_License.\"]" "Possibility to have dual (multiple) citizenship: 0 - no, 1 - with restrictions regulated by local legislation, 2 - dual (multiple) citizenship is allowed." "World" "static" "other" "$(date -r db/table/wikidata_naturalization_gap_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/test/uploads/upload_test: deploy_indicators/test/uploads/population_upload deploy_indicators/test/uploads/view_count_upload deploy_indicators/test/uploads/count_upload deploy_indicators/test/uploads/populated_area_km2_upload deploy_indicators/test/uploads/building_count_upload deploy_indicators/test/uploads/highway_length_upload deploy_indicators/test/uploads/total_road_length_upload deploy_indicators/test/uploads/local_hours_upload deploy_indicators/test/uploads/total_hours_upload deploy_indicators/test/uploads/avgmax_ts_upload deploy_indicators/test/uploads/man_distance_to_fire_brigade_upload deploy_indicators/test/uploads/view_count_bf2402_upload deploy_indicators/test/uploads/days_mintemp_above_25c_1c_upload deploy_indicators/test/uploads/total_building_count_upload deploy_indicators/test/uploads/count_6_months_upload deploy_indicators/test/uploads/building_count_6_months_upload deploy_indicators/test/uploads/highway_length_6_months_upload deploy_indicators/test/uploads/osm_users_upload deploy_indicators/test/uploads/residential_upload deploy_indicators/test/uploads/gdp_upload deploy_indicators/test/uploads/min_ts_upload deploy_indicators/test/uploads/max_ts_upload deploy_indicators/test/uploads/wildfires_upload deploy_indicators/test/uploads/covid19_confirmed_upload deploy_indicators/test/uploads/population_prev_upload deploy_indicators/test/uploads/industrial_area_upload deploy_indicators/test/uploads/volcanos_count_upload deploy_indicators/test/uploads/pop_under_5_total_upload deploy_indicators/test/uploads/pop_over_65_total_upload deploy_indicators/test/uploads/poverty_families_total_upload deploy_indicators/test/uploads/pop_disability_total_upload deploy_indicators/test/uploads/pop_not_well_eng_speak_upload deploy_indicators/test/uploads/pop_without_car_upload deploy_indicators/test/uploads/man_distance_to_hospital_upload deploy_indicators/test/uploads/man_distance_to_bomb_shelters_upload deploy_indicators/test/uploads/man_distance_to_charging_stations_upload  deploy_indicators/test/uploads/eatery_count_upload deploy_indicators/test/uploads/food_shops_count_upload deploy_indicators/test/uploads/waste_basket_coverage_area_km2_upload deploy_indicators/test/uploads/solar_farms_placement_suitability_upload deploy_indicators/test/uploads/mapswipe_area_km2_upload deploy_indicators/test/uploads/avg_slope_gebco_2022_upload deploy_indicators/test/uploads/avg_elevation_gebco_2022_upload deploy_indicators/test/uploads/forest_upload deploy_indicators/test/uploads/evergreen_needle_leaved_forest_upload deploy_indicators/test/uploads/shrubs_upload deploy_indicators/test/uploads/herbage_upload deploy_indicators/test/uploads/unknown_forest_upload deploy_indicators/test/uploads/avg_ndvi_upload deploy_indicators/test/uploads/days_maxtemp_over_32c_1c_upload deploy_indicators/test/uploads/days_maxtemp_over_32c_2c_upload deploy_indicators/test/uploads/days_mintemp_above_25c_2c_upload deploy_indicators/test/uploads/days_maxwetbulb_over_32c_1c_upload deploy_indicators/test/uploads/days_maxwetbulb_over_32c_2c_upload deploy_indicators/test/uploads/mandays_maxtemp_over_32c_1c_upload deploy_indicators/test/uploads/hazardous_days_count_upload deploy_indicators/test/uploads/earthquake_days_count_upload deploy_indicators/test/uploads/wildfire_days_count_upload deploy_indicators/test/uploads/drought_days_count_upload deploy_indicators/test/uploads/cyclone_days_count_upload deploy_indicators/test/uploads/volcano_days_count_upload deploy_indicators/test/uploads/flood_days_count_upload deploy_indicators/test/uploads/powerlines_upload deploy_indicators/test/uploads/night_lights_intensity_upload deploy_indicators/test/uploads/gsa_ghi_upload deploy_indicators/test/uploads/worldclim_avg_temperature_upload deploy_indicators/test/uploads/worldclim_min_temperature_upload deploy_indicators/test/uploads/worldclim_max_temperature_upload deploy_indicators/test/uploads/worldclim_amp_temperature_upload deploy_indicators/test/uploads/powerlines_proximity_m_upload deploy_indicators/test/uploads/populated_areas_proximity_m_upload deploy_indicators/test/uploads/power_substations_proximity_m_upload deploy_indicators/test/uploads/solar_power_plants_upload deploy_indicators/test/uploads/safety_index_upload deploy_indicators/test/uploads/avg_forest_canopy_height_upload deploy_indicators/test/uploads/max_forest_canopy_height_upload deploy_indicators/test/uploads/worldbank_tax_rate_upload deploy_indicators/test/uploads/years_to_naturalisation_upload deploy_indicators/test/uploads/multiple_citizenship_upload | deploy_indicators/test/uploads ## Control of layer uplodings to Insigths API for TEST - without area_km2 and one
	touch $@

deploy/test/cleanup_cache: deploy_indicators/test/uploads/upload_test | deploy_indicators/test ## Clear insights-api cache on Test.
	bash scripts/check_http_response_code.sh GET https://test-apps.konturlabs.com/insights-api/cache/cleanUp 200
	touch $@

## Custom axis updates block
deploy_indicators/test/custom_axis/population_area_km2: deploy_indicators/test/uploads/population_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for population area_km2 axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "population" "area_km2"
	touch $@

deploy_indicators/test/custom_axis/count_area_km2: deploy_indicators/test/uploads/count_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for count area_km2 axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "count" "area_km2"
	touch $@

deploy_indicators/test/custom_axis/building_count_area_km2: deploy_indicators/test/uploads/building_count_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for building_count area_km2 axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "building_count" "area_km2"
	touch $@

deploy_indicators/test/custom_axis/local_hours_area_km2: deploy_indicators/test/uploads/local_hours_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for local_hours area_km2 axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "local_hours" "area_km2"
	touch $@

deploy_indicators/test/custom_axis/total_hours_area_km2: deploy_indicators/test/uploads/total_hours_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for total_hours area_km2 axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "total_hours" "area_km2"
	touch $@

deploy_indicators/test/custom_axis/view_count_area_km2: deploy_indicators/test/uploads/view_count_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for view_count area_km2 axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "view_count" "area_km2"
	touch $@

deploy_indicators/test/custom_axis/osm_users_one: deploy_indicators/test/uploads/osm_users_upload  db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for osm_users one axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "osm_users" "one"
	touch $@

deploy_indicators/test/custom_axis/total_building_count_area_km2: deploy_indicators/test/uploads/total_building_count_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for total_building_count area_km2 axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "total_building_count" "area_km2"
	touch $@

deploy_indicators/test/custom_axis/wildfires_area_km2: deploy_indicators/test/uploads/wildfires_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for wildfires area_km2 axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "wildfires" "area_km2"
	touch $@

deploy_indicators/test/custom_axis/forest_area_km2: deploy_indicators/test/uploads/forest_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for forest area_km2 axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "forest" "area_km2"
	touch $@

deploy_indicators/test/custom_axis/days_maxtemp_over_32c_1c_one: deploy_indicators/test/uploads/days_maxtemp_over_32c_1c_upload  db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for days_maxtemp_over_32c_1c one axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "days_maxtemp_over_32c_1c" "one"
	touch $@

deploy_indicators/test/custom_axis/days_mintemp_above_25c_1c_one: deploy_indicators/test/uploads/days_mintemp_above_25c_1c_upload  db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for days_mintemp_above_25c_1c one axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "days_mintemp_above_25c_1c" "one"
	touch $@

deploy_indicators/test/custom_axis/man_distance_to_fire_brigade_one: deploy_indicators/test/uploads/man_distance_to_fire_brigade_upload  db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for man_distance_to_fire_brigade one axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "man_distance_to_fire_brigade" "one"
	touch $@

deploy_indicators/test/custom_axis/man_distance_to_hospital_one: deploy_indicators/test/uploads/man_distance_to_hospital_upload  db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for man_distance_to_hospital one axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "man_distance_to_hospital" "one"
	touch $@

deploy_indicators/test/custom_axis/highway_length_area_km2: deploy_indicators/test/uploads/highway_length_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for highway_length area_km2 axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "highway_length" "area_km2"
	touch $@

deploy_indicators/test/custom_axis/total_road_length_area_km2: deploy_indicators/test/uploads/total_road_length_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for total_road_length area_km2 axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "total_road_length" "area_km2"
	touch $@

deploy_indicators/test/custom_axis/view_count_bf2402_one: deploy_indicators/test/uploads/view_count_bf2402_upload  db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for view_count_bf2402 one axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "view_count_bf2402" "one"
	touch $@

deploy_indicators/test/custom_axis/view_count_bf2402_area_km2: deploy_indicators/test/uploads/view_count_bf2402_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for view_count_bf2402 area_km2 axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "view_count_bf2402" "area_km2"
	touch $@

deploy_indicators/test/custom_axis/powerlines_one: deploy_indicators/test/uploads/powerlines_upload  db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for powerlines one axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "powerlines" "one"
	touch $@

deploy_indicators/test/custom_axis/night_lights_intensity_one: deploy_indicators/test/uploads/night_lights_intensity_upload  db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for night_lights_intensity one axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "night_lights_intensity" "one"
	touch $@

deploy_indicators/test/custom_axis/man_distance_to_bomb_shelters_one: deploy_indicators/test/uploads/man_distance_to_bomb_shelters_upload  db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for man_distance_to_bomb_shelters one axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "man_distance_to_bomb_shelters" "one"
	touch $@

deploy_indicators/test/custom_axis/man_distance_to_charging_stations_one: deploy_indicators/test/uploads/man_distance_to_charging_stations_upload  db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for man_distance_to_charging_stations one axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "man_distance_to_charging_stations" "one"
	touch $@

deploy_indicators/test/custom_axis/solar_power_plants_area_km2: deploy_indicators/test/uploads/solar_power_plants_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for solar_power_plants area_km2 axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "solar_power_plants" "area_km2"
	touch $@

deploy_indicators/test/custom_axis/volcano_days_count_area_km2: deploy_indicators/test/uploads/volcano_days_count_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for volcano_days_count area_km2 axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "volcano_days_count" "area_km2"
	touch $@

deploy_indicators/test/custom_axis/volcano_days_count_one: deploy_indicators/test/uploads/volcano_days_count_upload  db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for volcano_days_count one axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "volcano_days_count" "one"
	touch $@

deploy_indicators/test/custom_axis/flood_days_count_area_km2: deploy_indicators/test/uploads/flood_days_count_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for flood_days_count area_km2 axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "flood_days_count" "area_km2"
	touch $@

deploy_indicators/test/custom_axis/flood_days_count_one: deploy_indicators/test/uploads/flood_days_count_upload  db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for flood_days_count one axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "flood_days_count" "one"
	touch $@

deploy_indicators/test/custom_axis/man_distance_to_bomb_shelters_population: deploy_indicators/test/uploads/man_distance_to_bomb_shelters_upload deploy_indicators/test/uploads/population_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for man_distance_to_bomb_shelters population axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "man_distance_to_bomb_shelters" "population"
	touch $@

deploy_indicators/test/custom_axis/man_distance_to_charging_stations_population: deploy_indicators/test/uploads/man_distance_to_charging_stations_upload deploy_indicators/test/uploads/population_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for man_distance_to_charging_stations population axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "man_distance_to_charging_stations" "population"
	touch $@

deploy_indicators/test/custom_axis/man_distance_to_fire_brigade_population: deploy_indicators/test/uploads/man_distance_to_fire_brigade_upload deploy_indicators/test/uploads/population_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for man_distance_to_fire_brigade population axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "man_distance_to_fire_brigade" "population"
	touch $@

deploy_indicators/test/custom_axis/building_count_total_building_count: deploy_indicators/test/uploads/building_count_upload deploy_indicators/test/uploads/total_building_count_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for building_count total_building_count axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "building_count" "total_building_count"
	touch $@

deploy_indicators/test/custom_axis/waste_basket_coverage_area_km2_populated_area_km2: deploy_indicators/test/uploads/waste_basket_coverage_area_km2_upload deploy_indicators/test/uploads/populated_area_km2_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for waste_basket_coverage_area_km2 populated_area_km2 axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "waste_basket_coverage_area_km2" "populated_area_km2"
	touch $@

deploy_indicators/test/custom_axis/highway_length_total_road_length: deploy_indicators/test/uploads/highway_length_upload deploy_indicators/test/uploads/total_road_length_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for highway_length total_road_length axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "highway_length" "total_road_length"
	touch $@

deploy_indicators/test/custom_axis/eatery_count_one: deploy_indicators/test/uploads/eatery_count_upload  db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for eatery_count one axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "eatery_count" "one"
	touch $@

deploy_indicators/test/custom_axis/food_shops_count_one: deploy_indicators/test/uploads/food_shops_count_upload  db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for food_shops_count one axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "food_shops_count" "one"
	touch $@

deploy_indicators/test/custom_axis/hazardous_days_count_area_km2: deploy_indicators/test/uploads/hazardous_days_count_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for hazardous_days_count area_km2 axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "hazardous_days_count" "area_km2"
	touch $@

deploy_indicators/test/custom_axis/hazardous_days_count_one: deploy_indicators/test/uploads/hazardous_days_count_upload  db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for hazardous_days_count one axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "hazardous_days_count" "one"
	touch $@

deploy_indicators/test/custom_axis/earthquake_days_count_area_km2: deploy_indicators/test/uploads/earthquake_days_count_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for earthquake_days_count area_km2 axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "earthquake_days_count" "area_km2"
	touch $@

deploy_indicators/test/custom_axis/earthquake_days_count_one: deploy_indicators/test/uploads/earthquake_days_count_upload  db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for earthquake_days_count one axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "earthquake_days_count" "one"
	touch $@

deploy_indicators/test/custom_axis/drought_days_count_area_km2: deploy_indicators/test/uploads/drought_days_count_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for drought_days_count area_km2 axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "drought_days_count" "area_km2"
	touch $@

deploy_indicators/test/custom_axis/drought_days_count_one: deploy_indicators/test/uploads/drought_days_count_upload  db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for drought_days_count one axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "drought_days_count" "one"
	touch $@

deploy_indicators/test/custom_axis/cyclone_days_count_area_km2: deploy_indicators/test/uploads/cyclone_days_count_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for cyclone_days_count area_km2 axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "cyclone_days_count" "area_km2"
	touch $@

deploy_indicators/test/custom_axis/cyclone_days_count_one: deploy_indicators/test/uploads/cyclone_days_count_upload  db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for cyclone_days_count one axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "cyclone_days_count" "one"
	touch $@

deploy_indicators/test/custom_axis/wildfire_days_count_area_km2: deploy_indicators/test/uploads/wildfire_days_count_upload db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for wildfire_days_count area_km2 axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "wildfire_days_count" "area_km2"
	touch $@

deploy_indicators/test/custom_axis/wildfire_days_count_one: deploy_indicators/test/uploads/wildfire_days_count_upload  db/table/insights_api_indicators_list_test | deploy_indicators/test/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for wildfire_days_count one axis on test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh test "wildfire_days_count" "one"
	touch $@

deploy_indicators/test/custom_axis/all_custom_axis: deploy_indicators/test/custom_axis/population_area_km2 deploy_indicators/test/custom_axis/count_area_km2 deploy_indicators/test/custom_axis/building_count_area_km2 deploy_indicators/test/custom_axis/local_hours_area_km2 deploy_indicators/test/custom_axis/total_hours_area_km2 deploy_indicators/test/custom_axis/view_count_area_km2 deploy_indicators/test/custom_axis/osm_users_one deploy_indicators/test/custom_axis/total_building_count_area_km2 deploy_indicators/test/custom_axis/wildfires_area_km2 deploy_indicators/test/custom_axis/forest_area_km2 deploy_indicators/test/custom_axis/days_maxtemp_over_32c_1c_one deploy_indicators/test/custom_axis/days_mintemp_above_25c_1c_one deploy_indicators/test/custom_axis/man_distance_to_fire_brigade_one deploy_indicators/test/custom_axis/man_distance_to_hospital_one deploy_indicators/test/custom_axis/highway_length_area_km2 deploy_indicators/test/custom_axis/total_road_length_area_km2 deploy_indicators/test/custom_axis/view_count_bf2402_one deploy_indicators/test/custom_axis/view_count_bf2402_area_km2 deploy_indicators/test/custom_axis/powerlines_one deploy_indicators/test/custom_axis/night_lights_intensity_one deploy_indicators/test/custom_axis/man_distance_to_bomb_shelters_one deploy_indicators/test/custom_axis/man_distance_to_charging_stations_one deploy_indicators/test/custom_axis/solar_power_plants_area_km2 deploy_indicators/test/custom_axis/volcano_days_count_area_km2 deploy_indicators/test/custom_axis/volcano_days_count_one deploy_indicators/test/custom_axis/flood_days_count_area_km2 deploy_indicators/test/custom_axis/flood_days_count_one deploy_indicators/test/custom_axis/man_distance_to_bomb_shelters_population deploy_indicators/test/custom_axis/man_distance_to_charging_stations_population deploy_indicators/test/custom_axis/man_distance_to_fire_brigade_population deploy_indicators/test/custom_axis/building_count_total_building_count deploy_indicators/test/custom_axis/waste_basket_coverage_area_km2_populated_area_km2 deploy_indicators/test/custom_axis/highway_length_total_road_length deploy_indicators/test/custom_axis/eatery_count_one deploy_indicators/test/custom_axis/food_shops_count_one deploy_indicators/test/custom_axis/hazardous_days_count_area_km2 deploy_indicators/test/custom_axis/hazardous_days_count_one deploy_indicators/test/custom_axis/earthquake_days_count_area_km2 deploy_indicators/test/custom_axis/earthquake_days_count_one deploy_indicators/test/custom_axis/drought_days_count_area_km2 deploy_indicators/test/custom_axis/drought_days_count_one deploy_indicators/test/custom_axis/cyclone_days_count_area_km2 deploy_indicators/test/custom_axis/cyclone_days_count_one deploy_indicators/test/custom_axis/wildfire_days_count_area_km2 deploy_indicators/test/custom_axis/wildfire_days_count_one | deploy_indicators/test/custom_axis ## final target for custom axis deployment to test
	touch $@

## END Custom axis updates block

## TEST Presets upload block

deploy_indicators/test/presets/osm_quantity: deploy_indicators/test/uploads/count_upload deploy_indicators/test/uploads/population_upload db/table/insights_api_indicators_list_test db/table/bivariate_overlays | deploy_indicators/test/presets ## Deploy Kontur OpenStreetMap Quantity overlay to test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh test "count" "area_km2" "population" "area_km2"
	touch $@

deploy_indicators/test/presets/osm_building_completeness: deploy_indicators/test/uploads/building_count_upload deploy_indicators/test/uploads/total_building_count_upload deploy_indicators/test/uploads/population_upload db/table/insights_api_indicators_list_test db/table/bivariate_overlays | deploy_indicators/test/presets ## Deploy Kontur OpenStreetMap Building Completeness overlay to test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh test "building_count" "total_building_count" "population" "area_km2"
	touch $@

deploy_indicators/test/presets/osm_road_completeness: deploy_indicators/test/uploads/highway_length_upload deploy_indicators/test/uploads/total_road_length_upload deploy_indicators/test/uploads/population_upload db/table/insights_api_indicators_list_test db/table/bivariate_overlays | deploy_indicators/test/presets ## Deploy Kontur OpenStreetMap Road Completeness overlay to test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh test "highway_length" "total_road_length" "population" "area_km2"
	touch $@

deploy_indicators/test/presets/osm_mapping_activity: deploy_indicators/test/uploads/local_hours_upload deploy_indicators/test/uploads/total_hours_upload  db/table/insights_api_indicators_list_test db/table/bivariate_overlays | deploy_indicators/test/presets ## Deploy Kontur OpenStreetMap Mapping Activity overlay to test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh test "local_hours" "area_km2" "total_hours" "area_km2"
	touch $@

deploy_indicators/test/presets/osm_antiquity: deploy_indicators/test/uploads/avgmax_ts_upload  deploy_indicators/test/uploads/view_count_upload db/table/insights_api_indicators_list_test db/table/bivariate_overlays | deploy_indicators/test/presets ## Deploy Kontur OpenStreetMap Antiquity overlay to test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh test "avgmax_ts" "one" "view_count" "area_km2"
	touch $@

deploy_indicators/test/presets/nighttime_heatwave_risk: deploy_indicators/test/uploads/days_mintemp_above_25c_1c_upload  deploy_indicators/test/uploads/population_upload db/table/insights_api_indicators_list_test db/table/bivariate_overlays | deploy_indicators/test/presets ## Deploy Kontur Nighttime Heatwave Risk overlay to test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh test "days_mintemp_above_25c_1c" "one" "population" "area_km2"
	touch $@

deploy_indicators/test/presets/fire_service_scarcity_risk: deploy_indicators/test/uploads/man_distance_to_fire_brigade_upload deploy_indicators/test/uploads/population_upload db/table/insights_api_indicators_list_test db/table/bivariate_overlays | deploy_indicators/test/presets ## Deploy Kontur Fire Service Scarcity Risk overlay to test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh test "man_distance_to_fire_brigade" "population" "population" "area_km2"
	touch $@

deploy_indicators/test/presets/views_before_after: deploy_indicators/test/uploads/view_count_bf2402_upload deploy_indicators/test/uploads/view_count_upload db/table/insights_api_indicators_list_test db/table/bivariate_overlays | deploy_indicators/test/presets ## Deploy Kontur OpenStreetMap Views before after overlay to test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh test "view_count_bf2402" "area_km2" "view_count" "area_km2"
	touch $@

deploy_indicators/test/presets/ev_charging_availability: deploy_indicators/test/uploads/man_distance_to_charging_stations_upload deploy_indicators/test/uploads/population_upload db/table/insights_api_indicators_list_test db/table/bivariate_overlays | deploy_indicators/test/presets ## Deploy EV Charging Availability overlay to test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh test "man_distance_to_charging_stations" "population" "population" "area_km2"
	touch $@

deploy_indicators/test/presets/waste_containers_availability: deploy_indicators/test/uploads/waste_basket_coverage_area_km2_upload deploy_indicators/test/uploads/populated_area_km2_upload deploy_indicators/test/uploads/population_upload db/table/insights_api_indicators_list_test db/table/bivariate_overlays | deploy_indicators/test/presets ## Deploy Waste containers availability overlay to test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh test "waste_basket_coverage_area_km2" "populated_area_km2" "population" "area_km2"
	touch $@

deploy_indicators/test/presets/shelters_scarcity_risk: deploy_indicators/test/uploads/man_distance_to_bomb_shelters_upload deploy_indicators/test/uploads/population_upload db/table/insights_api_indicators_list_test db/table/bivariate_overlays | deploy_indicators/test/presets ## Deploy Shelters Scarcity Risk overlay to test.
	psql -c "create table if not exists insights_api_indicators_list_test(j jsonb);"
	bash scripts/update_indicators_list.sh test | psql -c "copy insights_api_indicators_list_test(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh test "man_distance_to_bomb_shelters" "population" "population" "area_km2"
	touch $@

deploy_indicators/test/presets/all_presets: deploy_indicators/test/presets/osm_quantity deploy_indicators/test/presets/osm_building_completeness deploy_indicators/test/presets/osm_road_completeness deploy_indicators/test/presets/osm_mapping_activity deploy_indicators/test/presets/osm_antiquity deploy_indicators/test/presets/nighttime_heatwave_risk deploy_indicators/test/presets/fire_service_scarcity_risk deploy_indicators/test/presets/views_before_after deploy_indicators/test/presets/ev_charging_availability deploy_indicators/test/presets/waste_containers_availability deploy_indicators/test/presets/shelters_scarcity_risk ## final target for presets deployment to test
	touch $@

## END test upload block

## Deploy prod ##
db/table/insights_api_indicators_list_prod: | db/table ## Refresh insights_api_indicators_list_prod table before new deploy cycle
	psql -c "drop table if exists insights_api_indicators_list_prod;"
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	touch $@

deploy_indicators/prod/uploads/count_upload: data/out/csv/count.csv | deploy_indicators/prod/uploads ## upload count to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/count.csv "count" "OSM: objects count" "[[\"bad\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Total number of objects in a given area according to OpenStreetMap." "World" "daily" "n" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/hazardous_days_count_upload: data/out/csv/hazardous_days_count.csv | deploy_indicators/prod/uploads ## upload hazardous_days_count to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/hazardous_days_count.csv "hazardous_days_count" "Exposure: all disaster types" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)\"]" "Number of days in the last year when severe and extreme disasters of any types were recorded." "World" "daily" "days" "$(date -r db/table/disaster_event_episodes_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/mandays_maxtemp_over_32c_1c_upload: data/out/csv/mandays_maxtemp_over_32c_1c.csv | deploy_indicators/prod/uploads ## upload mandays_maxtemp_over_32c_1c to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/mandays_maxtemp_over_32c_1c.csv "mandays_maxtemp_over_32c_1c" "Man-days above 32°C, (+1°C scenario)" "[[\"good\"], [\"bad\"]]" false false "[\"© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0\"]" "" "World" "daily" "other" "$(date -r db/table/pf_maxtemp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/man_distance_to_fire_brigade_upload: data/out/csv/man_distance_to_fire_brigade.csv | deploy_indicators/prod/uploads ## upload man_distance_to_fire_brigade to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/man_distance_to_fire_brigade.csv "man_distance_to_fire_brigade" "Man-distance to fire brigade" "[[\"good\"], [\"bad\"]]" false false "[\"© Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "" "World" "daily" "other" "$(date -r db/table/isodist_fire_stations_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/food_shops_count_upload: data/out/csv/food_shops_count.csv | deploy_indicators/prod/uploads ## upload food_shops_count to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/food_shops_count.csv "food_shops_count" "OSM: food shops count" "[[\"unimportant\"], [\"important\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of places where you can buy fresh or packaged food products in a given area." "World" "daily" "n" "$(date -r db/table/osm_places_food_shops_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/populated_area_km2_upload: data/out/csv/populated_area_km2.csv | deploy_indicators/prod/uploads ## upload populated_area_km2 to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/populated_area_km2.csv "populated_area_km2" "Populated area" "[[\"unimportant\"], [\"important\"]]" true false "[\"© Kontur https://kontur.io/\", \"Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/\", \"Dataset: Schiavina, Marcello., Freire, Sergio., MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio., MacManus, Kytt., Pesaresi, Martino., Doxsey-Whitfield, Erin., Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World., Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\", \"Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).\", \"NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/\", \"Geoalert Urban Mapping: Chechnya, Moscow region, Tyva - https://github.com/Geoalert/urban-mapping\", \"Unconstrained Individual countries 2020 (100m resolution): WorldPop - https://www.worldpop.org/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "" "World" "daily" "km2" "$(date -r db/table/kontur_population_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/count_6_months_upload: data/out/csv/count_6_months.csv | deploy_indicators/prod/uploads ## upload count_6_months to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/count_6_months.csv "count_6_months" "OSM: objects mapped (6 months)" "[[\"bad\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of objects mapped in OpenStreetMap in the last 6 months." "World" "daily" "n" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/view_count_upload: data/out/csv/view_count.csv | deploy_indicators/prod/uploads ## upload view_count to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/view_count.csv "view_count" "OSM: map views (last 30 days)" "[[\"bad\", \"unimportant\"], [\"good\", \"important\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of tile requests in a given area for the last 30 days." "World" "daily" "n" "$(date -r db/table/tile_logs +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/avgmax_ts_upload: data/out/csv/avgmax_ts.csv | deploy_indicators/prod/uploads ## upload avgmax_ts to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/avgmax_ts.csv "avgmax_ts" "OSM: last edit (avg)" "[[\"bad\", \"unimportant\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Average of latest OpenStreetMap edit dates in a given area." "World" "daily" "unixtime" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/max_ts_upload: data/out/csv/max_ts.csv | deploy_indicators/prod/uploads ## upload max_ts to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/max_ts.csv "max_ts" "OSM: last edit" "[[\"bad\", \"unimportant\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Date of latest OpenStreetMap edit in a given area at highest resolution." "World" "daily" "unixtime" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/min_ts_upload: data/out/csv/min_ts.csv | deploy_indicators/prod/uploads ## upload min_ts to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/min_ts.csv "min_ts" "OSM: first edit" "[[\"good\"], [\"neutral\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Date of earliest OpenStreetMap edit in a given area." "World" "daily" "unixtime" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/osm_users_upload: data/out/csv/osm_users.csv | deploy_indicators/prod/uploads ## upload osm_users to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/osm_users.csv "osm_users" "OSM: contributors count" "[[\"bad\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of users who have edited a given area in OpenStreetMap." "World" "daily" "ppl" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/building_count_upload: data/out/csv/building_count.csv | deploy_indicators/prod/uploads ## upload building_count to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/building_count.csv "building_count" "OSM: buildings count" "[[\"bad\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Total number of buildings in a given area according to OpenStreetMap." "World" "daily" "n" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/building_count_6_months_upload: data/out/csv/building_count_6_months.csv | deploy_indicators/prod/uploads ## upload building_count_6_months to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/building_count_6_months.csv "building_count_6_months" "OSM: new buildings (last 6 months)" "[[\"bad\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of buildings mapped in OpenStreetMap in the last 6 months." "World" "daily" "n" "$(date -r db/table/osm_object_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/highway_length_upload: data/out/csv/highway_length.csv | deploy_indicators/prod/uploads ## upload highway_length to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/highway_length.csv "highway_length" "OSM: road length" "[[\"bad\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Total length of roads in a given area according to OpenStreetMap." "World" "daily" "km" "$(date -r db/table/osm_road_segments_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/highway_length_6_months_upload: data/out/csv/highway_length_6_months.csv | deploy_indicators/prod/uploads ## upload highway_length_6_months to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/highway_length_6_months.csv "highway_length_6_months" "OSM: new road length (last 6 months)" "[[\"bad\"], [\"good\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Length of roads mapped in OpenStreetMap in the last 6 months." "World" "daily" "km" "$(date -r db/table/osm_road_segments_6_months_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/total_hours_upload: data/out/csv/total_hours.csv | deploy_indicators/prod/uploads ## upload total_hours to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/total_hours.csv "total_hours" "OSM: contributor activity" "[[\"bad\"], [\"good\"]]" false true "[\"© Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Total number of OpenStreetMap mapping hours by all users in the last 2 years. A mapping hour is an hour in which a user uploaded at least one tagged object." "World" "daily" "h" "$(date -r db/table/user_hours_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/local_hours_upload: data/out/csv/local_hours.csv | deploy_indicators/prod/uploads ## upload local_hours to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/local_hours.csv "local_hours" "OSM: local contributor activity" "[[\"bad\"], [\"good\"]]" false true "[\"© Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of OpenStreetMap mapping hours by active local mappers in the last 2 years. A mapping hour is an hour in which a user uploaded at least one tagged object. Mapper is considered active if they contributed more than 30 mapping hours in the last 2 years. The position of the active mapper is estimated by the region of their highest activity." "World" "daily" "h" "$(date -r db/table/user_hours_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/forest_upload: data/out/csv/forest.csv | deploy_indicators/prod/uploads ## upload forest to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/forest.csv "forest" "Landcover: forest" "[[\"unimportant\"], [\"important\"]]" false true "[\"© Kontur https://kontur.io/\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\"]" "Area covered by forest - where tree canopy is more than 15%." "World" "static" "km2" "$(date -r db/table/copernicus_landcover_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/evergreen_needle_leaved_forest_upload: data/out/csv/evergreen_needle_leaved_forest.csv | deploy_indicators/prod/uploads ## upload evergreen_needle_leaved_forest to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/evergreen_needle_leaved_forest.csv "evergreen_needle_leaved_forest" "Landcover: evergreen needleleaf forest" "[[\"unimportant\"], [\"important\"]]" false true "[\"© Kontur https://kontur.io/\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\"]" "Area covered by either closed or open evergreen needleleaf forest. Almost all needleleaf trees remain green all year. Canopy is never without green foliage. Closed forest has tree canopy >70%. Open forest has top layer - trees 15-70 % - and second layer - mix of shrubs and grassland." "World" "static" "km2" "$(date -r db/table/copernicus_landcover_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/shrubs_upload: data/out/csv/shrubs.csv | deploy_indicators/prod/uploads ## upload shrubs to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/shrubs.csv "shrubs" "Landcover: shrubland" "[[\"unimportant\"], [\"important\"]]" false true "[\"© Kontur https://kontur.io/\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\"]" "Shrubland, or area where vegetation is dominated by woody perennial plants generally less than 5 meters in height, with persistent and woody stems and without any defined main stem. The shrub foliage can be either evergreen or deciduous." "World" "static" "km2" "$(date -r db/table/copernicus_landcover_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/herbage_upload: data/out/csv/herbage.csv | deploy_indicators/prod/uploads ## upload herbage to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/herbage.csv "herbage" "Landcover: herbaceous vegetation" "[[\"unimportant\"], [\"important\"]]" false true "[\"© Kontur https://kontur.io/\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\"]" "Area covered by herbaceous plants. These plants have no persistent woody stems above ground and lack definite firm structure. Tree and shrub cover is less than 10%." "World" "static" "km2" "$(date -r db/table/copernicus_landcover_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/unknown_forest_upload: data/out/csv/unknown_forest.csv | deploy_indicators/prod/uploads ## upload unknown_forest to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/unknown_forest.csv "unknown_forest" "Landcover: unknown forest type" "[[\"unimportant\"], [\"important\"]]" false true "[\"© Kontur https://kontur.io/\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\"]" "Area covered by forest that does not match defined forest types." "World" "static" "km2" "$(date -r db/table/copernicus_landcover_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/gdp_upload: data/out/csv/gdp.csv | deploy_indicators/prod/uploads ## upload gdp to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/gdp.csv "gdp" "Gross Domestic Product" "[[\"bad\"], [\"good\"]]" false true "[\"© Kontur https://kontur.io/\", \"© 2019 The World Bank Group, CC-BY 4.0\", \"Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/\", \"Dataset: Schiavina, Marcello., Freire, Sergio., MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio., MacManus, Kytt., Pesaresi, Martino., Doxsey-Whitfield, Erin., Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World., Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016\", \"Copernicus Global Land Service: Land Cover 100m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, Myroslava Lesiv, Nandin-Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\", \"Microsoft Buildings: Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).\", \"@ OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "A country GDP (Gross Domestic Product) per capita multiplied by the population in a given area. For areas covering multiple countries, a sum of their respective GDP portions is used. GDP is the standard measure of the value created through the production of goods and services in a country during a certain period." "World" "static" "USD" "$(date -r db/table/gdp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/population_prev_upload: data/out/csv/population_prev.csv | deploy_indicators/prod/uploads ## upload population_prev to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/population_prev.csv "population_prev" "Population (previous version)" "[[\"unimportant\"], [\"important\"]]" false false "[\"© Kontur https://kontur.io/\", \"Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/\", \"Dataset: Schiavina, Marcello., Freire, Sergio., MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio., MacManus, Kytt., Pesaresi, Martino., Doxsey-Whitfield, Erin., Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World., Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\", \"Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).\", \"NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/\", \"Geoalert Urban Mapping: Chechnya, Moscow region, Tyva - https://github.com/Geoalert/urban-mapping\", \"Unconstrained Individual countries 2020 (100m resolution): WorldPop - https://www.worldpop.org/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of people living in a given area according to previous version of Kontur Population dataset. The dataset was produced by overlaying the Global Human Settlement Layer (GHSL) with available Facebook population data and constraining known artifacts using OpenStreetMap data." "World" "daily" "ppl" "$(date -r db/table/kontur_population_v5_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/total_building_count_upload: data/out/csv/total_building_count.csv | deploy_indicators/prod/uploads ## upload total_building_count to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/total_building_count.csv "total_building_count" "Total buildings count" "[[\"unimportant\"], [\"important\"]]" true true "[\"© Kontur https://kontur.io/\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\", \"Geoalert Urban Mapping: Chechnya, Moscow region, Tyva - https://github.com/Geoalert/urban-mapping\", \"Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).\", \"NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Estimated number of buildings in a given area based on various data sources." "World" "daily" "n" "$(date -r db/table/building_count_grid_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/wildfires_upload: data/out/csv/wildfires.csv | deploy_indicators/prod/uploads ## upload wildfires to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/wildfires.csv "wildfires" "Wildfire days" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false false "[\"© NRT VIIRS 375 m Active Fire product VJ114IMGTDL_NRT. Available on-line [https://earthdata.nasa.gov/firms]. doi: 10.5067/FIRMS/VIIRS/VJ114IMGT_NRT.002\", \"NRT VIIRS 375 m Active Fire product VNP14IMGT. Available on-line [https://earthdata.nasa.gov/firms]. doi:10.5067/FIRMS/VIIRS/VNP14IMGT_NRT.002\", \"MODIS Collection 6 NRT Hotspot / Active Fire Detections MCD14DL. Available on-line [https://earthdata.nasa.gov/firms]. doi: 10.5067/FIRMS/MODIS/MCD14DL.NRT.006\", \"MODIS Collection 6 NRT Hotspot / Active Fire Detections MCD14ML. Available on-line [https://earthdata.nasa.gov/firms]. doi: 10.5067/FIRMS/MODIS/MCD14ML\"]" "Number of days per year when a thermal anomaly was recorded in the last 13 months." "World" "daily" "days" "$(date -r db/table/global_fires_stat_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/earthquake_days_count_upload: data/out/csv/earthquake_days_count.csv | deploy_indicators/prod/uploads ## upload earthquake_days_count to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/earthquake_days_count.csv "earthquake_days_count" "Exposure: earthquake" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)\"]" "Number of days in the last year when severe and extreme earthquakes were recorded." "World" "daily" "days" "$(date -r db/table/disaster_event_episodes_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/drought_days_count_upload: data/out/csv/drought_days_count.csv | deploy_indicators/prod/uploads ## upload drought_days_count to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/drought_days_count.csv "drought_days_count" "Exposure: drought" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)\"]" "Number of days in the last year when severe and extreme droughts were recorded." "World" "daily" "days" "$(date -r db/table/disaster_event_episodes_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/cyclone_days_count_upload: data/out/csv/cyclone_days_count.csv | deploy_indicators/prod/uploads ## upload cyclone_days_count to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/cyclone_days_count.csv "cyclone_days_count" "Exposure: cyclone" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)\"]" "Number of days in the last year when severe and extreme cyclones were recorded." "World" "daily" "days" "$(date -r db/table/disaster_event_episodes_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/wildfire_days_count_upload: data/out/csv/wildfire_days_count.csv | deploy_indicators/prod/uploads ## upload wildfire_days_count to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/wildfire_days_count.csv "wildfire_days_count" "Exposure: wildfire" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)\"]" "Number of days in the last year when severe and extreme wildfires were recorded." "World" "daily" "days" "$(date -r db/table/disaster_event_episodes_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/volcano_days_count_upload: data/out/csv/volcano_days_count.csv | deploy_indicators/prod/uploads ## upload volcano_days_count to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/volcano_days_count.csv "volcano_days_count" "Exposure: volcanic eruption" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)\"]" "Number of days in the last year when severe and extreme volcanos were recorded." "World" "daily" "days" "$(date -r db/table/disaster_event_episodes_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/flood_days_count_upload: data/out/csv/flood_days_count.csv | deploy_indicators/prod/uploads ## upload flood_days_count to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/flood_days_count.csv "flood_days_count" "Exposure: flood" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)\"]" "Number of days in the last year when severe and extreme floods were recorded." "World" "daily" "days" "$(date -r db/table/disaster_event_episodes_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/covid19_confirmed_upload: data/out/csv/covid19_confirmed.csv | deploy_indicators/prod/uploads ## upload covid19_confirmed to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/covid19_confirmed.csv "covid19_confirmed" "COVID-19 confirmed сases" "[[\"good\"], [\"bad\"]]" false true "[\"© Data from JHU CSSE COVID-19 Dataset\"]" "Number of COVID-19 confirmed cases for the entire observation period according to the Center for Systems Science and Engineering (CSSE) at Johns Hopkins University (JHU)." "World" "daily" "n" "$(date -r db/table/covid19_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/avg_slope_gebco_2022_upload: data/out/csv/avg_slope_gebco_2022.csv | deploy_indicators/prod/uploads ## upload avg_slope_gebco_2022 to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/avg_slope_gebco_2022.csv "avg_slope_gebco_2022" "Slope (avg)" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"© Data from General Bathymatric Chart of the Oceans, www.gebco.net\"]" "Average surface slope." "World" "static" "deg" "$(date -r db/table/gebco_2022_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/avg_elevation_gebco_2022_upload: data/out/csv/avg_elevation_gebco_2022.csv | deploy_indicators/prod/uploads ## upload avg_elevation_gebco_2022 to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/avg_elevation_gebco_2022.csv "avg_elevation_gebco_2022" "Elevation (avg)" "[[\"good\", \"unimportant\"], [\"bad\", \"important\"]]" false true "[\"© Data from General Bathymatric Chart of the Oceans, www.gebco.net\"]" "Average surface elevation in meters." "World" "static" "m" "$(date -r db/table/gebco_2022_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/industrial_area_upload: data/out/csv/industrial_area.csv | deploy_indicators/prod/uploads ## upload industrial_area to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/industrial_area.csv "industrial_area" "OSM: industrial area" "[[\"unimportant\"], [\"important\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Areas of land used for industrial purposes, which may include facilities such as workshops, factories and warehouses, and their associated infrastructure (car parks, service roads, yards, etc.)." "World" "daily" "km2" "$(date -r db/table/osm_landuse_industrial_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/avg_ndvi_upload: data/out/csv/avg_ndvi.csv | deploy_indicators/prod/uploads ## upload avg_ndvi to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/avg_ndvi.csv "avg_ndvi" "NDVI (avg)" "[[\"bad\"], [\"good\"]]" false true "[\"© Data from Sentinel-2 L2A 120m Mosaic, CC-BY 4.0, https://forum.sentinel-hub.com/c/aws-sentinel\"]" "Average values of Normalized Difference Vegetation Index (NDVI), as of June 2019. Negative values of NDVI (values approaching -1) correspond to water. Values close to zero (-0.1 to 0.1) generally correspond to barren areas of rock, sand, or snow. Low, positive values represent shrub and grassland (approximately 0.2 to 0.4), while high values indicate temperate and tropical rainforests (values approaching 1)." "World" "static" "index" "$(date -r db/table/ndvi_2019_06_10_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/volcanos_count_upload: data/out/csv/volcanos_count.csv | deploy_indicators/prod/uploads ## upload volcanos_count to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/volcanos_count.csv "volcanos_count" "OSM: volcanoes count" "[[\"unimportant\"], [\"important\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of volcanoes in a given area." "World" "daily" "n" "$(date -r db/table/osm_volcanos_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/pop_under_5_total_upload: data/out/csv/pop_under_5_total.csv | deploy_indicators/prod/uploads ## upload pop_under_5_total to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/pop_under_5_total.csv "pop_under_5_total" "Population: under 5" "[[\"unimportant\"], [\"important\"]]" false true "[\"© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html\"]" "Number of children (ages 0-5) in the United States." "The United States of America" "static" "ppl" "$(date -r db/table/us_census_tracts_stats_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/pop_over_65_total_upload: data/out/csv/pop_over_65_total.csv | deploy_indicators/prod/uploads ## upload pop_over_65_total to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/pop_over_65_total.csv "pop_over_65_total" "Population: over 65" "[[\"unimportant\"], [\"important\"]]" false true "[\"© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html\"]" "Number of elderly people (ages 65+) in the United States." "The United States of America" "static" "ppl" "$(date -r db/table/us_census_tracts_stats_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/poverty_families_total_upload: data/out/csv/poverty_families_total.csv | deploy_indicators/prod/uploads ## upload poverty_families_total to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/poverty_families_total.csv "poverty_families_total" "Population: families below poverty line" "[[\"unimportant\", \"good\"], [\"important\"]]" false true "[\"© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html\"]" "Number of households living below the poverty line in the United States." "The United States of America" "static" "n" "$(date -r db/table/us_census_tracts_stats_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/pop_disability_total_upload: data/out/csv/pop_disability_total.csv | deploy_indicators/prod/uploads ## upload pop_disability_total to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/pop_disability_total.csv "pop_disability_total" "Population: with disabilities" "[[\"unimportant\"], [\"important\"]]" false true "[\"© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html\"]" "Number of people with disabilities in the United States based on the U.S. Census Bureaus American Community Survey (ACS). This page describes how disability is defined and collected in the ACS: https://www.census.gov/topics/health/disability/guidance/data-collection-acs.html" "The United States of America" "static" "ppl" "$(date -r db/table/us_census_tracts_stats_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/pop_not_well_eng_speak_upload: data/out/csv/pop_not_well_eng_speak.csv | deploy_indicators/prod/uploads ## upload pop_not_well_eng_speak to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/pop_not_well_eng_speak.csv "pop_not_well_eng_speak" "Population: limited English proficiency" "[[\"good\"], [\"important\", \"bad\"]]" false true "[\"© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html\"]" "Number of people who have difficulty speaking English in the United States." "The United States of America" "static" "ppl" "$(date -r db/table/us_census_tracts_stats_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/pop_without_car_upload: data/out/csv/pop_without_car.csv | deploy_indicators/prod/uploads ## upload pop_without_car to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/pop_without_car.csv "pop_without_car" "Population: without a car" "[[\"neutral\"], [\"important\"]]" false true "[\"© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html\"]" "Number of working people without a car in the United States." "The United States of America" "static" "ppl" "$(date -r db/table/us_census_tracts_stats_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/days_maxtemp_over_32c_1c_upload: data/out/csv/days_maxtemp_over_32c_1c.csv | deploy_indicators/prod/uploads ## upload days_maxtemp_over_32c_1c to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/days_maxtemp_over_32c_1c.csv "days_maxtemp_over_32c_1c" "Days above 32°C (+1°C scenario)" "[[\"good\"], [\"bad\"]]" false true "[\"© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0\"]" "Number of days per year with a daily maximum temperature exceeding 32°C (90°F) at the “recent” climate warming scenario of +1.0°C. In 2017 the average surface temperature passed 1.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science)." "World (-60:60 latitudes)" "static" "days" "$(date -r db/table/pf_maxtemp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/days_maxtemp_over_32c_2c_upload: data/out/csv/days_maxtemp_over_32c_2c.csv | deploy_indicators/prod/uploads ## upload days_maxtemp_over_32c_2c to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/days_maxtemp_over_32c_2c.csv "days_maxtemp_over_32c_2c" "Days above 32°C (+2°C scenario)" "[[\"good\"], [\"bad\"]]" false true "[\"© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0\"]" "Number of days per year with a daily maximum temperature exceeding 32°C (90°F) at the “potential” climate warming scenario of +2.0°C. On the current path of emissions, in the 2040s the average surface temperature will likely pass 2.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science).The displayed values are from a range of simulated years from multiple models. Actual outcomes may prove to be higher or lower than the displayed values." "World (-60:60 latitudes)" "static" "days" "$(date -r db/table/pf_maxtemp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/days_mintemp_above_25c_1c_upload: data/out/csv/days_mintemp_above_25c_1c.csv | deploy_indicators/prod/uploads ## upload days_mintemp_above_25c_1c to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/days_mintemp_above_25c_1c.csv "days_mintemp_above_25c_1c" "Nights above 25°C (+1°C scenario)" "[[\"good\"], [\"bad\"]]" false true "[\"© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0\"]" "Number of days per year with a daily minimum temperature exceeding 25°C (77°F) at the “recent” climate warming scenario of +1.0°C. In 2017 the average surface temperature passed 1.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science). The lowest temperature during the day happens at night when temperatures dip after sunset. The human experience of a “hot” night is relative to location, so a threshold of 20°C is often used for higher latitudes (Europe and the US) and a threshold of 25°C is often used for tropical and equatorial regions." "World (-60:60 latitudes)" "static" "days" "$(date -r db/table/pf_maxtemp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/days_mintemp_above_25c_2c_upload: data/out/csv/days_mintemp_above_25c_2c.csv | deploy_indicators/prod/uploads ## upload days_mintemp_above_25c_2c to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/days_mintemp_above_25c_2c.csv "days_mintemp_above_25c_2c" "Nights above 25°C (+2°C scenario)" "[[\"good\"], [\"bad\"]]" false true "[\"© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0\"]" "Number of days per year with a daily minimum temperature exceeding 25°C (77°F) at the “potential” climate warming scenario of +2.0°C. On the current path of emissions, in the 2040s the average surface temperature will likely pass 2.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science). The lowest temperature during the day happens at night when temperatures dip after sunset. The human experience of a “hot” night is relative to location, so a threshold of 20°C is often used for higher latitudes (Europe and the US) and a threshold of 25°C is often used for tropical and equatorial regions. The displayed values are from a range of simulated years from multiple models. Actual outcomes may prove to be higher or lower than the displayed values." "World (-60:60 latitudes)" "static" "days" "$(date -r db/table/pf_maxtemp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/days_maxwetbulb_over_32c_1c_upload: data/out/csv/days_maxwetbulb_over_32c_1c.csv | deploy_indicators/prod/uploads ## upload days_maxwetbulb_over_32c_1c to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/days_maxwetbulb_over_32c_1c.csv "days_maxwetbulb_over_32c_1c" "Days above 32°C wet-bulb (+1°C scenario)" "[[\"good\"], [\"bad\"]]" false true "[\"© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0\"]" "Number of days per year with a daily maximum wet-bulb temperature exceeding 32°C (90°F) at the “recent” climate warming scenario of +1.0°C. In 2017 the average surface temperature passed 1.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science). Wet-bulb temperature is calculated using temperature and humidity. High wet-bulb temperatures can impair the human body’s ability to self-cool through sweating. 32°C or 90°F wet-bulb can occur at 32°C (90°F) air temperature and 99% relative humidity, or 40°C (104°F) and 55% humidity." "World (-60:60 latitudes)" "static" "days" "$(date -r db/table/pf_maxtemp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/days_maxwetbulb_over_32c_2c_upload: data/out/csv/days_maxwetbulb_over_32c_2c.csv | deploy_indicators/prod/uploads ## upload days_maxwetbulb_over_32c_2c to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/days_maxwetbulb_over_32c_2c.csv "days_maxwetbulb_over_32c_2c" "Days above 32°C wet-bulb (+2°C scenario)" "[[\"good\"], [\"bad\"]]" false true "[\"© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0\"]" "Number of days per year with a daily maximum wet-bulb temperature exceeding 32°C (90°F) at the “potential” climate warming scenario of +2.0°C. On the current path of emissions, in the 2040s the average surface temperature will likely pass 2.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science). Wet-bulb temperature is calculated using temperature and humidity. High wet-bulb temperatures can impair the human body’s ability to self-cool through sweating. 32°C or 90°F wet-bulb can occur at 32°C (90°F) air temperature and 99% relative humidity, or 40°C (104°F) and 55% humidity. The displayed values are from a range of simulated years from multiple models. Actual outcomes may prove to be higher or lower than the displayed values." "World (-60:60 latitudes)" "static" "days" "$(date -r db/table/pf_maxtemp_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/man_distance_to_hospital_upload: data/out/csv/man_distance_to_hospital.csv | deploy_indicators/prod/uploads ## upload man_distance_to_hospital to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/man_distance_to_hospital.csv "man_distance_to_hospital" "Man-distance to hospitals" "[[\"good\"], [\"bad\"]]" false false "[\"© Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "" "World" "daily" "other" "$(date -r db/table/isodist_hospitals_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/man_distance_to_bomb_shelters_upload: data/out/csv/man_distance_to_bomb_shelters.csv | deploy_indicators/prod/uploads ## upload man_distance_to_bomb_shelters to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/man_distance_to_bomb_shelters.csv "man_distance_to_bomb_shelters" "Man-distance to bomb shelters" "[[\"good\"], [\"bad\"]]" false false "[\"© Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "" "World" "daily" "other" "$(date -r db/table/isodist_bomb_shelters_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/man_distance_to_charging_stations_upload: data/out/csv/man_distance_to_charging_stations.csv | deploy_indicators/prod/uploads ## upload man_distance_to_charging_stations to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/man_distance_to_charging_stations.csv "man_distance_to_charging_stations" "Man-distance to charging stations" "[[\"good\"], [\"bad\"]]" false false "[\"© Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "" "World" "daily" "other" "$(date -r db/table/isodist_charging_stations_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/total_road_length_upload: data/out/csv/total_road_length.csv | deploy_indicators/prod/uploads ## upload total_road_length to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/total_road_length.csv "total_road_length" "Total road length" "[[\"unimportant\"], [\"important\"]]" true true "[\"©2019 Facebook, Inc. and its affiliates https://github.com/facebookmicrosites/Open-Mapping-At-Facebook/blob/main/LICENSE.md\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\", \"© Kontur https://kontur.io/\"]" "Estimated total road length according to Meta (Facebook) AI and OpenStreetMap data. For places where Meta (Facebook) roads data are unavailable, the estimation is based on statistical regression from Kontur Population data." "World" "daily" "km" "$(date -r db/table/total_road_length_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/view_count_bf2402_upload: data/out/csv/view_count_bf2402.csv | deploy_indicators/prod/uploads ## upload view_count_bf2402 to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/view_count_bf2402.csv "view_count_bf2402" "OSM: map views (Jan 25 - Feb 24, 2022)" "[[\"bad\", \"unimportant\"], [\"good\", \"important\"]]" false true "[\"© Kontur\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of tile requests in a given area for the 30 days before Feb 24, 2022." "World" "daily" "n" "$(date -r db/table/tile_logs_bf2402 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/powerlines_upload: data/out/csv/powerlines.csv | deploy_indicators/prod/uploads ## upload powerlines to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/powerlines.csv "powerlines" "Medium-voltage powerlines distribution (predictive)" "[[\"bad\"], [\"good\"]]" false false "[\"©9999 Facebook, Inc. and its affiliates https://dataforgood.facebook.com/dfg/tools/electrical-distribution-grid-maps\"]" "Facebook has produced a model to help map global medium voltage (MV) grid infrastructure, i.e. the distribution lines which connect high-voltage transmission infrastructure to consumer-serving low-voltage distribution. The data found here are model outputs for six select African countries: Malawi, Nigeria, Uganda, DRC, Cote D’Ivoire, and Zambia. The grid maps are produced using a new methodology that employs various publicly-available datasets (night time satellite imagery, roads, political boundaries, etc) to predict the location of existing MV grid infrastructure." "World" "static" "other" "$(date -r db/table/facebook_medium_voltage_distribution_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/eatery_count_upload: data/out/csv/eatery_count.csv | deploy_indicators/prod/uploads ## upload eatery_count to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/eatery_count.csv "eatery_count" "OSM: eatery places count" "[[\"unimportant\"], [\"important\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of places where you can buy and eat food (such as restaurants, cafés, fast-food outlets, etc.) in a given area." "World" "daily" "n" "$(date -r db/table/osm_places_eatery_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/night_lights_intensity_upload: data/out/csv/night_lights_intensity.csv | deploy_indicators/prod/uploads ## upload night_lights_intensity to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/night_lights_intensity.csv "night_lights_intensity" "Nighttime lights intensity" "[[\"unimportant\"], [\"important\"]]" false true "[\"Earth Observation Group © 2021. https://eogdata.mines.edu/products/vnl/#reference\", \"C. D. Elvidge, K. E. Baugh, M. Zhizhin, and F.-C. Hsu, “Why VIIRS data are superior to DMSP for mapping nighttime lights,” Asia-Pacific Advanced Network 35, vol. 35, p. 62, 2013.\", \"C. D. Elvidge, M. Zhizhin, T. Ghosh, F-C. Hsu, “Annual time series of global VIIRS nighttime lights derived from monthly averages: 2012 to 2019”, Remote Sensing (In press)\"]" "Remote sensing of nighttime light emissions offers a unique perspective for investigations into human behaviors. The Visible Infrared Imaging Radiometer Suite (VIIRS) instruments aboard the Suomi NPP and NOAA-20 satellites provide global daily measurements of nighttime light." "World" "static" "nW_cm2_sr" "$(date -r db/table/night_lights_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/mapswipe_area_km2_upload: data/out/csv/mapswipe_area_km2.csv | deploy_indicators/prod/uploads ## upload mapswipe_area_km2 to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/mapswipe_area_km2.csv "mapswipe_area_km2" "Human activity" "[[\"unimportant\"], [\"important\"]]" false true "[\"Copyright © 2022 MapSwipe https://mapswipe.org/en/privacy.html\"]" "Places were MapSwipe users have detected some human activity through features (i.e. buildings, roadways, waterways, etc.) on satellite images." "World" "daily" "km2" "$(date -r db/table/mapswipe_hot_tasking_data_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/gsa_ghi_upload: data/out/csv/gsa_ghi.csv | deploy_indicators/prod/uploads ## upload gsa_ghi to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/gsa_ghi.csv "gsa_ghi" "Global Horizontal Irradiance (GHI)" "[[\"bad\", \"unimportant\"], [\"good\", \"important\"]]" false true "[\"Copyright © 2022 The World Bank https://globalsolaratlas.info/support/terms-of-use\"]" "Total amount of shortwave terrestrial irradiance received by a surface horizontal to the ground." "World (-60:60 latitudes)" "static" "W_m2" "$(date -r db/table/global_solar_atlas_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/worldclim_avg_temperature_upload: data/out/csv/worldclim_avg_temperature.csv | deploy_indicators/prod/uploads ## upload worldclim_avg_temperature to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/worldclim_avg_temperature.csv "worldclim_avg_temperature" "Air temperature (avg)" "[[\"good\"], [\"bad\"]]" false true "[\"Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html\"]" "Monthly average air temperature according to WorldClim data for the years 1970-2000." "World" "static" "celc_deg" "$(date -r db/table/worldclim_temperatures_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/worldclim_min_temperature_upload: data/out/csv/worldclim_min_temperature.csv | deploy_indicators/prod/uploads ## upload worldclim_min_temperature to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/worldclim_min_temperature.csv "worldclim_min_temperature" "Air temperature (min)" "[[\"bad\"], [\"good\"]]" false true "[\"Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html\"]" "Monthly minimum air temperature according to WorldClim data for the years 1970-2000." "World" "static" "celc_deg" "$(date -r db/table/worldclim_temperatures_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/worldclim_max_temperature_upload: data/out/csv/worldclim_max_temperature.csv | deploy_indicators/prod/uploads ## upload worldclim_max_temperature to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/worldclim_max_temperature.csv "worldclim_max_temperature" "Air temperature (max)" "[[\"good\"], [\"bad\"]]" false true "[\"Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html\"]" "Monthly maximum air temperature according to WorldClim data for the years 1970-2000." "World" "static" "celc_deg" "$(date -r db/table/worldclim_temperatures_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/worldclim_amp_temperature_upload: data/out/csv/worldclim_amp_temperature.csv | deploy_indicators/prod/uploads ## upload worldclim_amp_temperature to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/worldclim_amp_temperature.csv "worldclim_amp_temperature" "Air temperature (amplitude)" "[[\"good\"], [\"bad\"]]" false true "[\"Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html\"]" "Monthly amplitude of air temperatures according to WorldClim data for the years 1970-2000." "World" "static" "celc_deg" "$(date -r db/table/worldclim_temperatures_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/powerlines_proximity_m_upload: data/out/csv/powerlines_proximity_m.csv | deploy_indicators/prod/uploads ## upload powerlines_proximity_m to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/powerlines_proximity_m.csv "powerlines_proximity_m" "Proximity to: powerlines grid" "[[\"important\"], [\"unimportant\"]]" false true "[\"Copyright © OpenStreetMap contributors https://www.openstreetmap.org/copyright\", \"© 2020 The World Bank Group, CC-BY 4.0\"]" "Distance to closest powerline" "World" "static" "m" "$(date -r db/table/proximities_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/waste_basket_coverage_area_km2_upload: data/out/csv/waste_basket_coverage_area_km2.csv | deploy_indicators/prod/uploads ## upload waste_basket_coverage_area_km2 to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/waste_basket_coverage_area_km2.csv "waste_basket_coverage_area_km2" "OSM: waste containers count" "[[\"bad\"], [\"good\"]]" false true "[\"© Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of waste containers in a given area." "World" "daily" "n" "$(date -r db/table/waste_containers_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/populated_areas_proximity_m_upload: data/out/csv/populated_areas_proximity_m.csv | deploy_indicators/prod/uploads ## upload populated_areas_proximity_m to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/populated_areas_proximity_m.csv "populated_areas_proximity_m" "Proximity to densely populated areas" "[[\"good\"], [\"bad\"]]" false true "[\"Copyright © Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Distance to closest Kontur Population cell with population > 80 ppl" "World" "daily" "m" "$(date -r db/table/proximities_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/power_substations_proximity_m_upload: data/out/csv/power_substations_proximity_m.csv | deploy_indicators/prod/uploads ## upload power_substations_proximity_m to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/power_substations_proximity_m.csv "power_substations_proximity_m" "Proximity to power substations, m" "[[\"good\"], [\"bad\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Distance to closest power substation" "World" "daily" "m" "$(date -r db/table/proximities_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/solar_farms_placement_suitability_upload: data/out/csv/solar_farms_placement_suitability.csv | deploy_indicators/prod/uploads ## upload solar_farms_placement_suitability to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/solar_farms_placement_suitability.csv "solar_farms_placement_suitability" "Suitability estimation for solar farms placement" "[[\"bad\"], [\"good\"]]" false true "[\"Copyright © Kontur https://kontur.io/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\", \"Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html\", \"Copyright © 2022 The World Bank https://globalsolaratlas.info/support/terms-of-use\"]" "Multi-criteria analysis based layer dedicated to estimation of suitability of solar farms placement. 0 means absolutely unsuitable, 1 means perfectly suitable. Analysis is based on solar irradiace, powerlines grid proximity, power substations proximity, elevation slope, minimal and maximal temperatures, populated areas proximity" "World (-60:60 latitudes)" "daily" "index" "$(date -r db/table/solar_farms_placement_suitability_synthetic_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/residential_upload: data/out/csv/residential.csv | deploy_indicators/prod/uploads ## upload residential to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/residential.csv "residential" "Percentage of permanent population" "[[\"unimportant\"], [\"important\"]]" false false "[\"Dataset: Schiavina, Marcello., Freire, Sergio., MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio., MacManus, Kytt., Pesaresi, Martino., Doxsey-Whitfield, Erin., Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World., Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016\"]" "Estimation of residential population percentage according to GHS-POP dataset (2015)" "World" "static" "fract" "$(date -r db/table/residential_pop_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/solar_power_plants_upload: data/out/csv/solar_power_plants.csv | deploy_indicators/prod/uploads ## upload solar_power_plants to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/solar_power_plants.csv "solar_power_plants" "Solar power plants" "[[\"unimportant\"], [\"important\"]]" false true "[\"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Total number of solar power plants in a given area according to OpenStreetMap." "World" "daily" "n" "$(date -r db/table/existing_solar_power_panels_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/safety_index_upload: data/out/csv/safety_index.csv | deploy_indicators/prod/uploads ## upload safety_index to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/safety_index.csv "safety_index" "Safety (Global Peace Index 2022)" "[[\"bad\"], [\"good\"]]" false true "[\"© The Institute for Economics and Peace Limited 2022 https://www.visionofhumanity.org/\"]" "The Global Peace Index covers 99.7% of the world’s population, and is calculated using 23 qualitative and quantitative indicators from highly respected sources, and measures the state of peace across three domains: the level of Societal Safety and Security, the extent of Ongoing Domestic and International Conflict, and the degree of Militarisation." "World" "static" "index" "$(date -r db/table/safety_index_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/population_upload: data/out/csv/population.csv | deploy_indicators/prod/uploads ## upload population to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/population.csv "population" "Population" "[[\"unimportant\"], [\"important\"]]" true true "[\"© Kontur https://kontur.io/\", \"Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/\", \"Dataset: Schiavina, Marcello., Freire, Sergio., MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio., MacManus, Kytt., Pesaresi, Martino., Doxsey-Whitfield, Erin., Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World., Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016\", \"Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050\", \"Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).\", \"NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/\", \"Geoalert Urban Mapping: Chechnya, Moscow region, Tyva - https://github.com/Geoalert/urban-mapping\", \"Unconstrained Individual countries 2020 (100m resolution): WorldPop - https://www.worldpop.org/\", \"© OpenStreetMap contributors https://www.openstreetmap.org/copyright\"]" "Number of people living in a given area according to Kontur Population dataset. The dataset was produced by overlaying the Global Human Settlement Layer (GHSL) with available Facebook population data and constraining known artifacts using OpenStreetMap data. The datasets detailed methodology is available here: https://data.humdata.org/dataset/kontur-population-dataset" "World" "daily" "ppl" "$(date -r db/table/kontur_population_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/avg_forest_canopy_height_upload: data/out/csv/avg_forest_canopy_height.csv | deploy_indicators/prod/uploads ## upload count to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/avg_forest_canopy_height.csv "avg_forest_canopy_height" "Average forest canopy height" "[[\"bad\", \"unimportant\"], [\"good\", \"important\"]]" false true "[\"High Resolution Canopy Height Maps by WRI and Meta was accessed on 20.05.2024 from https://registry.opendata.aws/dataforgood-fb-forests. Meta and World Resources Institude (WRI) - 2024. High Resolution Canopy Height Maps (CHM). Source imagery for CHM © 2016 Maxar. Accessed 20 may 2024.\"]" "Global and regional Canopy Height Maps (CHM). Created using machine learning models on high-resolution worldwide Maxar satellite imagery." "World" "static" "m" "$(date -r db/table/meta_forest_canopy_height_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/max_forest_canopy_height_upload: data/out/csv/max_forest_canopy_height.csv | deploy_indicators/prod/uploads ## upload count to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/max_forest_canopy_height.csv "max_forest_canopy_height" "Max forest canopy height" "[[\"bad\", \"unimportant\"], [\"good\", \"important\"]]" false true "[\"High Resolution Canopy Height Maps by WRI and Meta was accessed on 20.05.2024 from https://registry.opendata.aws/dataforgood-fb-forests. Meta and World Resources Institude (WRI) - 2024. High Resolution Canopy Height Maps (CHM). Source imagery for CHM © 2016 Maxar. Accessed 20 may 2024.\"]" "Global and regional Canopy Height Maps (CHM). Created using machine learning models on high-resolution worldwide Maxar satellite imagery." "World" "static" "m" "$(date -r db/table/meta_forest_canopy_height_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/worldbank_tax_rate_upload: data/out/csv/worldbank_tax_rate.csv | deploy_indicators/prod/uploads ## upload worldbank_tax_rate to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/worldbank_tax_rate.csv "worldbank_tax_rate" "Total tax and contribution rate (% of profit)" "[[\"good\"], [\"bad\"]]" false true "[\"© 2024 The World Bank Group, Doing Business project (http://www.doingbusiness.org/). NOTE: Doing Business has been discontinued as of 9/16/2021. For more information: https://bit.ly/3CLCbme\"]" "Total tax rate measures the amount of taxes and mandatory contributions payable by businesses after accounting for allowable deductions and exemptions as a share of commercial profits. Taxes withheld (such as personal income tax) or collected and remitted to tax authorities (such as value added taxes, sales taxes or goods and service taxes) are excluded." "World" "static" "perc" "$(date -r db/table/worldbank_tax_rate_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/years_to_naturalisation_upload: data/out/csv/years_to_naturalisation.csv | deploy_indicators/prod/uploads ## upload years_to_naturalisation to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/years_to_naturalisation.csv "years_to_naturalisation" "The Legal residence before naturalization" "[[\"good\"], [\"bad\"]]" false true "[\"This dataset use material from the Wikipedia article https://en.wikipedia.org/wiki/Naturalization, which is released under the https://en.wikipedia.org/wiki/Wikipedia:Text_of_the_Creative_Commons_Attribution-ShareAlike_4.0_International_License.\"]" "The duration of legal residence before a national of a foreign state, without any cultural, historical, or marriage ties or connections to the state in question, can request citizenship under that states naturalization laws." "World" "static" "years" "$(date -r db/table/wikidata_naturalization_gap_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/multiple_citizenship_upload: data/out/csv/multiple_citizenship.csv | deploy_indicators/prod/uploads ## upload multiple_citizenship to insight-api
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_csv_to_insights_api.sh prod data/out/csv/multiple_citizenship.csv "multiple_citizenship" "Possibility to have multiple citizenship" "[[\"good\"], [\"bad\"]]" false true "[\"This dataset use material from the Wikipedia article https://en.wikipedia.org/wiki/Naturalization, which is released under the https://en.wikipedia.org/wiki/Wikipedia:Text_of_the_Creative_Commons_Attribution-ShareAlike_4.0_International_License.\"]" "Possibility to have dual (multiple) citizenship: 0 - no, 1 - with restrictions regulated by local legislation, 2 - dual (multiple) citizenship is allowed." "World" "static" "other" "$(date -r db/table/wikidata_naturalization_gap_h3 +'%Y-%m-%dT%H:%M:%SZ')"
	touch $@

deploy_indicators/prod/uploads/upload_prod: deploy_indicators/prod/uploads/population_upload deploy_indicators/prod/uploads/view_count_upload deploy_indicators/prod/uploads/count_upload deploy_indicators/prod/uploads/populated_area_km2_upload deploy_indicators/prod/uploads/building_count_upload deploy_indicators/prod/uploads/highway_length_upload deploy_indicators/prod/uploads/total_road_length_upload deploy_indicators/prod/uploads/local_hours_upload deploy_indicators/prod/uploads/total_hours_upload deploy_indicators/prod/uploads/avgmax_ts_upload deploy_indicators/prod/uploads/man_distance_to_fire_brigade_upload deploy_indicators/prod/uploads/view_count_bf2402_upload deploy_indicators/prod/uploads/days_mintemp_above_25c_1c_upload deploy_indicators/prod/uploads/total_building_count_upload deploy_indicators/prod/uploads/count_6_months_upload deploy_indicators/prod/uploads/building_count_6_months_upload deploy_indicators/prod/uploads/highway_length_6_months_upload deploy_indicators/prod/uploads/osm_users_upload deploy_indicators/prod/uploads/residential_upload deploy_indicators/prod/uploads/gdp_upload deploy_indicators/prod/uploads/min_ts_upload deploy_indicators/prod/uploads/max_ts_upload deploy_indicators/prod/uploads/wildfires_upload deploy_indicators/prod/uploads/covid19_confirmed_upload deploy_indicators/prod/uploads/population_prev_upload deploy_indicators/prod/uploads/industrial_area_upload deploy_indicators/prod/uploads/volcanos_count_upload deploy_indicators/prod/uploads/pop_under_5_total_upload deploy_indicators/prod/uploads/pop_over_65_total_upload deploy_indicators/prod/uploads/poverty_families_total_upload deploy_indicators/prod/uploads/pop_disability_total_upload deploy_indicators/prod/uploads/pop_not_well_eng_speak_upload deploy_indicators/prod/uploads/pop_without_car_upload deploy_indicators/prod/uploads/man_distance_to_hospital_upload deploy_indicators/prod/uploads/man_distance_to_bomb_shelters_upload deploy_indicators/prod/uploads/man_distance_to_charging_stations_upload  deploy_indicators/prod/uploads/eatery_count_upload deploy_indicators/prod/uploads/food_shops_count_upload deploy_indicators/prod/uploads/waste_basket_coverage_area_km2_upload deploy_indicators/prod/uploads/solar_farms_placement_suitability_upload deploy_indicators/prod/uploads/mapswipe_area_km2_upload deploy_indicators/prod/uploads/avg_slope_gebco_2022_upload deploy_indicators/prod/uploads/avg_elevation_gebco_2022_upload deploy_indicators/prod/uploads/forest_upload deploy_indicators/prod/uploads/evergreen_needle_leaved_forest_upload deploy_indicators/prod/uploads/shrubs_upload deploy_indicators/prod/uploads/herbage_upload deploy_indicators/prod/uploads/unknown_forest_upload deploy_indicators/prod/uploads/avg_ndvi_upload deploy_indicators/prod/uploads/days_maxtemp_over_32c_1c_upload deploy_indicators/prod/uploads/days_maxtemp_over_32c_2c_upload deploy_indicators/prod/uploads/days_mintemp_above_25c_2c_upload deploy_indicators/prod/uploads/days_maxwetbulb_over_32c_1c_upload deploy_indicators/prod/uploads/days_maxwetbulb_over_32c_2c_upload deploy_indicators/prod/uploads/mandays_maxtemp_over_32c_1c_upload deploy_indicators/prod/uploads/hazardous_days_count_upload deploy_indicators/prod/uploads/earthquake_days_count_upload deploy_indicators/prod/uploads/wildfire_days_count_upload deploy_indicators/prod/uploads/drought_days_count_upload deploy_indicators/prod/uploads/cyclone_days_count_upload deploy_indicators/prod/uploads/volcano_days_count_upload deploy_indicators/prod/uploads/flood_days_count_upload deploy_indicators/prod/uploads/powerlines_upload deploy_indicators/prod/uploads/night_lights_intensity_upload deploy_indicators/prod/uploads/gsa_ghi_upload deploy_indicators/prod/uploads/worldclim_avg_temperature_upload deploy_indicators/prod/uploads/worldclim_min_temperature_upload deploy_indicators/prod/uploads/worldclim_max_temperature_upload deploy_indicators/prod/uploads/worldclim_amp_temperature_upload deploy_indicators/prod/uploads/powerlines_proximity_m_upload deploy_indicators/prod/uploads/populated_areas_proximity_m_upload deploy_indicators/prod/uploads/power_substations_proximity_m_upload deploy_indicators/prod/uploads/solar_power_plants_upload deploy_indicators/prod/uploads/safety_index_upload deploy_indicators/prod/uploads/avg_forest_canopy_height_upload deploy_indicators/prod/uploads/max_forest_canopy_height_upload deploy_indicators/prod/uploads/worldbank_tax_rate_upload deploy_indicators/prod/uploads/years_to_naturalisation_upload deploy_indicators/prod/uploads/multiple_citizenship_upload | deploy_indicators/prod/uploads ## Control of layer uplodings to Insigths API for prod without one and area_km2
	touch $@

deploy/prod/cleanup_cache: deploy_indicators/prod/uploads/upload_prod | deploy_indicators/prod ## Clear insights-api cache on PROD.
	bash scripts/check_http_response_code.sh GET https://apps.kontur.io/insights-api/cache/cleanUp 200
	touch $@

deploy_indicators/prod/custom_axis/population_area_km2: deploy_indicators/prod/uploads/population_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for population area_km2 axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "population" "area_km2"
	touch $@

deploy_indicators/prod/custom_axis/count_area_km2: deploy_indicators/prod/uploads/count_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for count area_km2 axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "count" "area_km2"
	touch $@

deploy_indicators/prod/custom_axis/building_count_area_km2: deploy_indicators/prod/uploads/building_count_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for building_count area_km2 axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "building_count" "area_km2"
	touch $@

deploy_indicators/prod/custom_axis/local_hours_area_km2: deploy_indicators/prod/uploads/local_hours_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for local_hours area_km2 axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "local_hours" "area_km2"
	touch $@

deploy_indicators/prod/custom_axis/total_hours_area_km2: deploy_indicators/prod/uploads/total_hours_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for total_hours area_km2 axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "total_hours" "area_km2"
	touch $@

deploy_indicators/prod/custom_axis/view_count_area_km2: deploy_indicators/prod/uploads/view_count_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for view_count area_km2 axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "view_count" "area_km2"
	touch $@

deploy_indicators/prod/custom_axis/osm_users_one: deploy_indicators/prod/uploads/osm_users_upload  db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for osm_users one axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "osm_users" "one"
	touch $@

deploy_indicators/prod/custom_axis/total_building_count_area_km2: deploy_indicators/prod/uploads/total_building_count_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for total_building_count area_km2 axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "total_building_count" "area_km2"
	touch $@

deploy_indicators/prod/custom_axis/wildfires_area_km2: deploy_indicators/prod/uploads/wildfires_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for wildfires area_km2 axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "wildfires" "area_km2"
	touch $@

deploy_indicators/prod/custom_axis/forest_area_km2: deploy_indicators/prod/uploads/forest_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for forest area_km2 axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "forest" "area_km2"
	touch $@

deploy_indicators/prod/custom_axis/days_maxtemp_over_32c_1c_one: deploy_indicators/prod/uploads/days_maxtemp_over_32c_1c_upload  db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for days_maxtemp_over_32c_1c one axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "days_maxtemp_over_32c_1c" "one"
	touch $@

deploy_indicators/prod/custom_axis/days_mintemp_above_25c_1c_one: deploy_indicators/prod/uploads/days_mintemp_above_25c_1c_upload  db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for days_mintemp_above_25c_1c one axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "days_mintemp_above_25c_1c" "one"
	touch $@

deploy_indicators/prod/custom_axis/man_distance_to_fire_brigade_one: deploy_indicators/prod/uploads/man_distance_to_fire_brigade_upload  db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for man_distance_to_fire_brigade one axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "man_distance_to_fire_brigade" "one"
	touch $@

deploy_indicators/prod/custom_axis/man_distance_to_hospital_one: deploy_indicators/prod/uploads/man_distance_to_hospital_upload  db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for man_distance_to_hospital one axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "man_distance_to_hospital" "one"
	touch $@

deploy_indicators/prod/custom_axis/highway_length_area_km2: deploy_indicators/prod/uploads/highway_length_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for highway_length area_km2 axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "highway_length" "area_km2"
	touch $@

deploy_indicators/prod/custom_axis/total_road_length_area_km2: deploy_indicators/prod/uploads/total_road_length_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for total_road_length area_km2 axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "total_road_length" "area_km2"
	touch $@

deploy_indicators/prod/custom_axis/view_count_bf2402_one: deploy_indicators/prod/uploads/view_count_bf2402_upload  db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for view_count_bf2402 one axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "view_count_bf2402" "one"
	touch $@

deploy_indicators/prod/custom_axis/view_count_bf2402_area_km2: deploy_indicators/prod/uploads/view_count_bf2402_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for view_count_bf2402 area_km2 axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "view_count_bf2402" "area_km2"
	touch $@

deploy_indicators/prod/custom_axis/powerlines_one: deploy_indicators/prod/uploads/powerlines_upload  db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for powerlines one axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "powerlines" "one"
	touch $@

deploy_indicators/prod/custom_axis/night_lights_intensity_one: deploy_indicators/prod/uploads/night_lights_intensity_upload  db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for night_lights_intensity one axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "night_lights_intensity" "one"
	touch $@

deploy_indicators/prod/custom_axis/man_distance_to_bomb_shelters_one: deploy_indicators/prod/uploads/man_distance_to_bomb_shelters_upload  db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for man_distance_to_bomb_shelters one axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "man_distance_to_bomb_shelters" "one"
	touch $@

deploy_indicators/prod/custom_axis/man_distance_to_charging_stations_one: deploy_indicators/prod/uploads/man_distance_to_charging_stations_upload  db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for man_distance_to_charging_stations one axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "man_distance_to_charging_stations" "one"
	touch $@

deploy_indicators/prod/custom_axis/solar_power_plants_area_km2: deploy_indicators/prod/uploads/solar_power_plants_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for solar_power_plants area_km2 axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "solar_power_plants" "area_km2"
	touch $@

deploy_indicators/prod/custom_axis/volcano_days_count_area_km2: deploy_indicators/prod/uploads/volcano_days_count_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for volcano_days_count area_km2 axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "volcano_days_count" "area_km2"
	touch $@

deploy_indicators/prod/custom_axis/volcano_days_count_one: deploy_indicators/prod/uploads/volcano_days_count_upload  db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for volcano_days_count one axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "volcano_days_count" "one"
	touch $@

deploy_indicators/prod/custom_axis/flood_days_count_area_km2: deploy_indicators/prod/uploads/flood_days_count_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for flood_days_count area_km2 axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "flood_days_count" "area_km2"
	touch $@

deploy_indicators/prod/custom_axis/flood_days_count_one: deploy_indicators/prod/uploads/flood_days_count_upload  db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for flood_days_count one axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "flood_days_count" "one"
	touch $@

deploy_indicators/prod/custom_axis/man_distance_to_bomb_shelters_population: deploy_indicators/prod/uploads/man_distance_to_bomb_shelters_upload deploy_indicators/prod/uploads/population_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for man_distance_to_bomb_shelters population axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "man_distance_to_bomb_shelters" "population"
	touch $@

deploy_indicators/prod/custom_axis/man_distance_to_charging_stations_population: deploy_indicators/prod/uploads/man_distance_to_charging_stations_upload deploy_indicators/prod/uploads/population_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for man_distance_to_charging_stations population axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "man_distance_to_charging_stations" "population"
	touch $@

deploy_indicators/prod/custom_axis/man_distance_to_fire_brigade_population: deploy_indicators/prod/uploads/man_distance_to_fire_brigade_upload deploy_indicators/prod/uploads/population_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for man_distance_to_fire_brigade population axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "man_distance_to_fire_brigade" "population"
	touch $@

deploy_indicators/prod/custom_axis/building_count_total_building_count: deploy_indicators/prod/uploads/building_count_upload deploy_indicators/prod/uploads/total_building_count_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for building_count total_building_count axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "building_count" "total_building_count"
	touch $@

deploy_indicators/prod/custom_axis/waste_basket_coverage_area_km2_populated_area_km2: deploy_indicators/prod/uploads/waste_basket_coverage_area_km2_upload deploy_indicators/prod/uploads/populated_area_km2_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for waste_basket_coverage_area_km2 populated_area_km2 axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "waste_basket_coverage_area_km2" "populated_area_km2"
	touch $@

deploy_indicators/prod/custom_axis/highway_length_total_road_length: deploy_indicators/prod/uploads/highway_length_upload deploy_indicators/prod/uploads/total_road_length_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for highway_length total_road_length axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "highway_length" "total_road_length"
	touch $@

deploy_indicators/prod/custom_axis/eatery_count_one: deploy_indicators/prod/uploads/eatery_count_upload  db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for eatery_count one axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "eatery_count" "one"
	touch $@

deploy_indicators/prod/custom_axis/food_shops_count_one: deploy_indicators/prod/uploads/food_shops_count_upload  db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for food_shops_count one axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "food_shops_count" "one"
	touch $@

deploy_indicators/prod/custom_axis/hazardous_days_count_area_km2: deploy_indicators/prod/uploads/hazardous_days_count_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for hazardous_days_count area_km2 axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "hazardous_days_count" "area_km2"
	touch $@

deploy_indicators/prod/custom_axis/hazardous_days_count_one: deploy_indicators/prod/uploads/hazardous_days_count_upload  db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for hazardous_days_count one axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "hazardous_days_count" "one"
	touch $@

deploy_indicators/prod/custom_axis/earthquake_days_count_area_km2: deploy_indicators/prod/uploads/earthquake_days_count_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for earthquake_days_count area_km2 axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "earthquake_days_count" "area_km2"
	touch $@

deploy_indicators/prod/custom_axis/earthquake_days_count_one: deploy_indicators/prod/uploads/earthquake_days_count_upload  db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for earthquake_days_count one axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "earthquake_days_count" "one"
	touch $@

deploy_indicators/prod/custom_axis/drought_days_count_area_km2: deploy_indicators/prod/uploads/drought_days_count_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for drought_days_count area_km2 axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "drought_days_count" "area_km2"
	touch $@

deploy_indicators/prod/custom_axis/drought_days_count_one: deploy_indicators/prod/uploads/drought_days_count_upload  db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for drought_days_count one axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "drought_days_count" "one"
	touch $@

deploy_indicators/prod/custom_axis/cyclone_days_count_area_km2: deploy_indicators/prod/uploads/cyclone_days_count_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for cyclone_days_count area_km2 axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "cyclone_days_count" "area_km2"
	touch $@

deploy_indicators/prod/custom_axis/cyclone_days_count_one: deploy_indicators/prod/uploads/cyclone_days_count_upload  db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for cyclone_days_count one axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "cyclone_days_count" "one"
	touch $@

deploy_indicators/prod/custom_axis/wildfire_days_count_area_km2: deploy_indicators/prod/uploads/wildfire_days_count_upload db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for wildfire_days_count area_km2 axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "wildfire_days_count" "area_km2"
	touch $@

deploy_indicators/prod/custom_axis/wildfire_days_count_one: deploy_indicators/prod/uploads/wildfire_days_count_upload  db/table/insights_api_indicators_list_prod | deploy_indicators/prod/custom_axis db/table/bivariate_axis_overrides ## Deploy custom values for wildfire_days_count one axis on prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_custom_axis_to_insights_api.sh prod "wildfire_days_count" "one"
	touch $@

deploy_indicators/prod/custom_axis/all_custom_axis: deploy_indicators/prod/custom_axis/population_area_km2 deploy_indicators/prod/custom_axis/count_area_km2 deploy_indicators/prod/custom_axis/building_count_area_km2 deploy_indicators/prod/custom_axis/local_hours_area_km2 deploy_indicators/prod/custom_axis/total_hours_area_km2 deploy_indicators/prod/custom_axis/view_count_area_km2 deploy_indicators/prod/custom_axis/osm_users_one deploy_indicators/prod/custom_axis/total_building_count_area_km2 deploy_indicators/prod/custom_axis/wildfires_area_km2 deploy_indicators/prod/custom_axis/forest_area_km2 deploy_indicators/prod/custom_axis/days_maxtemp_over_32c_1c_one deploy_indicators/prod/custom_axis/days_mintemp_above_25c_1c_one deploy_indicators/prod/custom_axis/man_distance_to_fire_brigade_one deploy_indicators/prod/custom_axis/man_distance_to_hospital_one deploy_indicators/prod/custom_axis/highway_length_area_km2 deploy_indicators/prod/custom_axis/total_road_length_area_km2  deploy_indicators/prod/custom_axis/view_count_bf2402_one deploy_indicators/prod/custom_axis/view_count_bf2402_area_km2 deploy_indicators/prod/custom_axis/powerlines_one deploy_indicators/prod/custom_axis/night_lights_intensity_one deploy_indicators/prod/custom_axis/man_distance_to_bomb_shelters_one deploy_indicators/prod/custom_axis/man_distance_to_charging_stations_one deploy_indicators/prod/custom_axis/solar_power_plants_area_km2 deploy_indicators/prod/custom_axis/volcano_days_count_area_km2 deploy_indicators/prod/custom_axis/volcano_days_count_one deploy_indicators/prod/custom_axis/flood_days_count_area_km2 deploy_indicators/prod/custom_axis/flood_days_count_one deploy_indicators/prod/custom_axis/man_distance_to_bomb_shelters_population deploy_indicators/prod/custom_axis/man_distance_to_charging_stations_population deploy_indicators/prod/custom_axis/man_distance_to_fire_brigade_population deploy_indicators/prod/custom_axis/building_count_total_building_count deploy_indicators/prod/custom_axis/waste_basket_coverage_area_km2_populated_area_km2 deploy_indicators/prod/custom_axis/highway_length_total_road_length deploy_indicators/prod/custom_axis/eatery_count_one deploy_indicators/prod/custom_axis/food_shops_count_one deploy_indicators/prod/custom_axis/hazardous_days_count_area_km2 deploy_indicators/prod/custom_axis/hazardous_days_count_one deploy_indicators/prod/custom_axis/earthquake_days_count_area_km2 deploy_indicators/prod/custom_axis/earthquake_days_count_one deploy_indicators/prod/custom_axis/drought_days_count_area_km2 deploy_indicators/prod/custom_axis/drought_days_count_one deploy_indicators/prod/custom_axis/cyclone_days_count_area_km2 deploy_indicators/prod/custom_axis/cyclone_days_count_one deploy_indicators/prod/custom_axis/wildfire_days_count_area_km2 deploy_indicators/prod/custom_axis/wildfire_days_count_one | deploy_indicators/prod/custom_axis ## final target for custom axis deployment to prod
	touch $@

## PROD presets upload block
deploy_indicators/prod/presets/osm_quantity: deploy_indicators/prod/uploads/count_upload deploy_indicators/prod/uploads/population_upload db/table/insights_api_indicators_list_prod db/table/bivariate_overlays | deploy_indicators/prod/presets ## Deploy Kontur OpenStreetMap Quantity overlay to prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh prod "count" "area_km2" "population" "area_km2"
	touch $@

deploy_indicators/prod/presets/osm_building_completeness: deploy_indicators/prod/uploads/building_count_upload deploy_indicators/prod/uploads/total_building_count_upload deploy_indicators/prod/uploads/population_upload db/table/insights_api_indicators_list_prod db/table/bivariate_overlays | deploy_indicators/prod/presets ## Deploy Kontur OpenStreetMap Building Completeness overlay to prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh prod "building_count" "total_building_count" "population" "area_km2"
	touch $@

deploy_indicators/prod/presets/osm_road_completeness: deploy_indicators/prod/uploads/highway_length_upload deploy_indicators/prod/uploads/total_road_length_upload deploy_indicators/prod/uploads/population_upload db/table/insights_api_indicators_list_prod db/table/bivariate_overlays | deploy_indicators/prod/presets ## Deploy Kontur OpenStreetMap Road Completeness overlay to prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh prod "highway_length" "total_road_length" "population" "area_km2"
	touch $@

deploy_indicators/prod/presets/osm_mapping_activity: deploy_indicators/prod/uploads/local_hours_upload deploy_indicators/prod/uploads/total_hours_upload  db/table/insights_api_indicators_list_prod db/table/bivariate_overlays | deploy_indicators/prod/presets ## Deploy Kontur OpenStreetMap Mapping Activity overlay to prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh prod "local_hours" "area_km2" "total_hours" "area_km2"
	touch $@

deploy_indicators/prod/presets/osm_antiquity: deploy_indicators/prod/uploads/avgmax_ts_upload  deploy_indicators/prod/uploads/view_count_upload db/table/insights_api_indicators_list_prod db/table/bivariate_overlays | deploy_indicators/prod/presets ## Deploy Kontur OpenStreetMap Antiquity overlay to prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh prod "avgmax_ts" "one" "view_count" "area_km2"
	touch $@

deploy_indicators/prod/presets/nighttime_heatwave_risk: deploy_indicators/prod/uploads/days_mintemp_above_25c_1c_upload  deploy_indicators/prod/uploads/population_upload db/table/insights_api_indicators_list_prod db/table/bivariate_overlays | deploy_indicators/prod/presets ## Deploy Kontur Nighttime Heatwave Risk overlay to prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh prod "days_mintemp_above_25c_1c" "one" "population" "area_km2"
	touch $@

deploy_indicators/prod/presets/fire_service_scarcity_risk: deploy_indicators/prod/uploads/man_distance_to_fire_brigade_upload deploy_indicators/prod/uploads/population_upload db/table/insights_api_indicators_list_prod db/table/bivariate_overlays | deploy_indicators/prod/presets ## Deploy Kontur Fire Service Scarcity Risk overlay to prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh prod "man_distance_to_fire_brigade" "population" "population" "area_km2"
	touch $@

deploy_indicators/prod/presets/views_before_after: deploy_indicators/prod/uploads/view_count_bf2402_upload deploy_indicators/prod/uploads/view_count_upload db/table/insights_api_indicators_list_prod db/table/bivariate_overlays | deploy_indicators/prod/presets ## Deploy Kontur OpenStreetMap Views before after overlay to prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh prod "view_count_bf2402" "area_km2" "view_count" "area_km2"
	touch $@

deploy_indicators/prod/presets/ev_charging_availability: deploy_indicators/prod/uploads/man_distance_to_charging_stations_upload deploy_indicators/prod/uploads/population_upload db/table/insights_api_indicators_list_prod db/table/bivariate_overlays | deploy_indicators/prod/presets ## Deploy EV Charging Availability overlay to prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh prod "man_distance_to_charging_stations" "population" "population" "area_km2"
	touch $@

deploy_indicators/prod/presets/waste_containers_availability: deploy_indicators/prod/uploads/waste_basket_coverage_area_km2_upload deploy_indicators/prod/uploads/populated_area_km2_upload deploy_indicators/prod/uploads/population_upload db/table/insights_api_indicators_list_prod db/table/bivariate_overlays | deploy_indicators/prod/presets ## Deploy Waste containers availability overlay to prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh prod "waste_basket_coverage_area_km2" "populated_area_km2" "population" "area_km2"
	touch $@

deploy_indicators/prod/presets/shelters_scarcity_risk: deploy_indicators/prod/uploads/man_distance_to_bomb_shelters_upload deploy_indicators/prod/uploads/population_upload db/table/insights_api_indicators_list_prod db/table/bivariate_overlays | deploy_indicators/prod/presets ## Deploy Shelters Scarcity Risk overlay to prod.
	psql -c "create table if not exists insights_api_indicators_list_prod(j jsonb);"
	bash scripts/update_indicators_list.sh prod | psql -c "copy insights_api_indicators_list_prod(j) from stdin;"
	bash scripts/upload_presets_to_insights_api.sh prod "man_distance_to_bomb_shelters" "population" "population" "area_km2"
	touch $@

deploy_indicators/prod/presets/all_presets: deploy_indicators/prod/presets/osm_quantity deploy_indicators/prod/presets/osm_building_completeness deploy_indicators/prod/presets/osm_road_completeness deploy_indicators/prod/presets/osm_mapping_activity deploy_indicators/prod/presets/osm_antiquity deploy_indicators/prod/presets/nighttime_heatwave_risk deploy_indicators/prod/presets/fire_service_scarcity_risk deploy_indicators/prod/presets/views_before_after deploy_indicators/prod/presets/ev_charging_availability deploy_indicators/prod/presets/waste_containers_availability deploy_indicators/prod/presets/shelters_scarcity_risk ## final target for presets deployment to prod.
	touch $@

## END PROD presets upload block

### END Deploy through API