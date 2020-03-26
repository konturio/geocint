all: weekly daily

weekly: deploy/geocint/isochrone_tables

daily: deploy/_all data/population/population_api_tables.sqld.gz data/kontur_population.gpkg.gz db/table/covid19

clean:
	rm -rf data/planet-latest-updated.osm.pbf deploy/ data/tiles
	profile_make_clean data/planet-latest-updated.osm.pbf data/covid19/_csv
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

deploy:
	mkdir -p $@

deploy/lima:
	mkdir -p $@

# We use sonic.kontur.io as a staging server to test the software before setting it live at lima.kontur.io.
deploy/sonic:
	mkdir -p $@

deploy/dollar:
	mkdir -p $@

deploy/geocint:
	mkdir -p $@

deploy/_all: deploy/geocint/stats_tiles deploy/lima/stats_tiles deploy/geocint/users_tiles deploy/lima/users_tiles deploy/sonic/population_api_tables deploy/lima/population_api_tables
	touch $@

deploy/geocint/isochrone_tables: db/table/osm_road_segments db/index/osm_road_segments_seg_id_node_from_node_to_seg_geom_idx db/index/osm_road_segments_seg_geom_idx
	touch $@

data/planet-latest.osm.pbf: | data
	wget -t inf https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf -O $@
	# TODO: smoke check correctness of file
	touch $@

data/planet-latest-updated.osm.pbf: data/planet-latest.osm.pbf | data
	rm -f data/planet-diff.osc
	if [ -f data/planet-latest.seq ]; then pyosmium-get-changes -vv -s 50000 --server "https://planet.osm.org/replication/hour/" -f data/planet-latest.seq -o data/planet-diff.osc; else pyosmium-get-changes -vv -s 50000 --server "https://planet.osm.org/replication/hour/" -O data/planet-latest.osm.pbf -f data/planet-latest.seq -o data/planet-diff.osc; fi
	rm -f data/planet-latest-updated.osm.pbf data/planet-latest-updated.osm.pbf.meta.json
	osmium apply-changes data/planet-latest.osm.pbf data/planet-diff.osc -f pbf,pbf_compression=false -o data/planet-latest-updated.osm.pbf
	# TODO: smoke check correctness of file
	cp -lf data/planet-latest-updated.osm.pbf data/planet-latest.osm.pbf
	touch $@

data/covid19: | data
	mkdir -p $@

data/covid19/_csv: | data/covid19
	wget "https://data.humdata.org/hxlproxy/data/download/time_series-ncov-Confirmed.csv?dest=data_edit&filter01=explode&explode-header-att01=date&explode-value-att01=value&filter02=rename&rename-oldtag02=%23affected%2Bdate&rename-newtag02=%23date&rename-header02=Date&filter03=rename&rename-oldtag03=%23affected%2Bvalue&rename-newtag03=%23affected%2Binfected%2Bvalue%2Bnum&rename-header03=Value&filter04=clean&clean-date-tags04=%23date&filter05=sort&sort-tags05=%23date&sort-reverse05=on&filter06=sort&sort-tags06=%23country%2Bname%2C%23adm1%2Bname&tagger-match-all=on&tagger-default-tag=%23affected%2Blabel&tagger-01-header=province%2Fstate&tagger-01-tag=%23adm1%2Bname&tagger-02-header=country%2Fregion&tagger-02-tag=%23country%2Bname&tagger-03-header=lat&tagger-03-tag=%23geo%2Blat&tagger-04-header=long&tagger-04-tag=%23geo%2Blon&header-row=1&url=https%3A%2F%2Fraw.githubusercontent.com%2FCSSEGISandData%2FCOVID-19%2Fmaster%2Fcsse_covid_19_data%2Fcsse_covid_19_time_series%2Ftime_series_19-covid-Confirmed.csv" -O data/covid19/time_series-ncov-Confirmed.csv
	wget "https://data.humdata.org/hxlproxy/data/download/time_series-ncov-Deaths.csv?dest=data_edit&filter01=explode&explode-header-att01=date&explode-value-att01=value&filter02=rename&rename-oldtag02=%23affected%2Bdate&rename-newtag02=%23date&rename-header02=Date&filter03=rename&rename-oldtag03=%23affected%2Bvalue&rename-newtag03=%23affected%2Bkilled%2Bvalue%2Bnum&rename-header03=Value&filter04=clean&clean-date-tags04=%23date&filter05=sort&sort-tags05=%23date&sort-reverse05=on&filter06=sort&sort-tags06=%23country%2Bname%2C%23adm1%2Bname&tagger-match-all=on&tagger-default-tag=%23affected%2Blabel&tagger-01-header=province%2Fstate&tagger-01-tag=%23adm1%2Bname&tagger-02-header=country%2Fregion&tagger-02-tag=%23country%2Bname&tagger-03-header=lat&tagger-03-tag=%23geo%2Blat&tagger-04-header=long&tagger-04-tag=%23geo%2Blon&header-row=1&url=https%3A%2F%2Fraw.githubusercontent.com%2FCSSEGISandData%2FCOVID-19%2Fmaster%2Fcsse_covid_19_data%2Fcsse_covid_19_time_series%2Ftime_series_19-covid-Deaths.csv" -O data/covid19/time_series-ncov-Deaths.csv
	wget "https://data.humdata.org/hxlproxy/data/download/time_series-ncov-Recovered.csv?dest=data_edit&filter01=explode&explode-header-att01=date&explode-value-att01=value&filter02=rename&rename-oldtag02=%23affected%2Bdate&rename-newtag02=%23date&rename-header02=Date&filter03=rename&rename-oldtag03=%23affected%2Bvalue&rename-newtag03=%23affected%2Brecovered%2Bvalue%2Bnum&rename-header03=Value&filter04=clean&clean-date-tags04=%23date&filter05=sort&sort-tags05=%23date&sort-reverse05=on&filter06=sort&sort-tags06=%23country%2Bname%2C%23adm1%2Bname&tagger-match-all=on&tagger-default-tag=%23affected%2Blabel&tagger-01-header=province%2Fstate&tagger-01-tag=%23adm1%2Bname&tagger-02-header=country%2Fregion&tagger-02-tag=%23country%2Bname&tagger-03-header=lat&tagger-03-tag=%23geo%2Blat&tagger-04-header=long&tagger-04-tag=%23geo%2Blon&header-row=1&url=https%3A%2F%2Fraw.githubusercontent.com%2FCSSEGISandData%2FCOVID-19%2Fmaster%2Fcsse_covid_19_data%2Fcsse_covid_19_time_series%2Ftime_series_19-covid-Recovered.csv" -O data/covid19/time_series-ncov-Recovered.csv
	touch $@

db/table/covid19: data/covid19/_csv db/table/kontur_population_h3 db/index/osm_tags_idx
	psql -c 'drop table if exists covid19_in;'
	psql -c 'create table covid19_in ( province text, country text, lat float, lon float, date timestamptz, value int, status text);'
	cat data/covid19/time_series-ncov-Confirmed.csv | tail -n +2 | psql -c "set time zone utc;copy covid19_in (province, country, lat, lon, date, value) from stdin with csv header;"
	psql -c "update covid19_in set status='confirmed' where status is null;"
	cat data/covid19/time_series-ncov-Deaths.csv | tail -n +2 | psql -c "set time zone utc;copy covid19_in (province, country, lat, lon, date, value) from stdin with csv header;"
	psql -c "update covid19_in set status='dead' where status is null;"
	cat data/covid19/time_series-ncov-Recovered.csv | tail -n +2 | psql -c "set time zone utc;copy covid19_in (province, country, lat, lon, date, value) from stdin with csv header;"
	psql -c "update covid19_in set status='recovered' where status is null;"
	psql -f tables/covid19.sql
	touch $@

db/table/osm: data/planet-latest-updated.osm.pbf | db/table
	psql -c "drop table if exists osm;"
	osmium export -c osmium.config.json -f pg data/planet-latest.osm.pbf  -v --progress | psql -1 -c 'create table osm(geog geography, osm_type text, osm_id bigint, osm_user text, ts timestamptz, way_nodes bigint[], tags jsonb);alter table osm alter geog set storage external, alter osm_type set storage main, alter osm_user set storage main, alter way_nodes set storage external, alter tags set storage external, set (fillfactor=100); copy osm from stdin freeze;'
	psql -c "vacuum analyze osm;"
	touch $@

db/table/osm_meta: data/planet-latest-updated.osm.pbf | db/table
	psql -c "drop table if exists osm_meta;"
	rm -f data/planet-latest-updated.osm.pbf.meta.json
	osmium fileinfo data/planet-latest.osm.pbf -ej > data/planet-latest.osm.pbf.meta.json
	cat data/planet-latest.osm.pbf.meta.json | jq -c . | psql -1 -c 'create table osm_meta(meta jsonb); copy osm_meta from stdin freeze;'
	touch $@

db/function/osm_way_nodes_to_segments: | db/function
	psql -f functions/osm_way_nodes_to_segments.sql
	touch $@

db/function/h3: | db/function
	psql -f functions/h3.sql
	touch $@

db/function/calculate_h3_res: | db/function/h3
	psql -f functions/calculate_h3_res.sql
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
	psql -c "create index osm_road_segments_seg_geom_walk_time_idx on osm_road_segments using brin (seg_geom, walk_time);"
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

db/table/osm_unpopulated: db/index/osm_tags_idx | db/table
	psql -f tables/osm_unpopulated.sql
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

db/table/osm_building_count_grid_h3_r8: db/index/osm_tags_idx
	psql -f tables/osm_building_count_grid_h3_r8.sql
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

db/table/population_grid_h3_r8: db/table/population_vector | db/table
	psql -f tables/population_grid_h3_r8.sql
	touch $@

db/table/osm_local_active_users: db/function/h3 db/table/osm_user_count_grid_h3 | db/table
	psql -f tables/osm_local_active_users.sql
	touch $@

db/table/user_hours_h3: db/function/h3 db/table/osm_user_count_grid_h3 db/table/osm_local_active_users | db/table
	psql -f tables/user_hours_h3.sql
	touch $@

db/table/osm_object_count_grid_h3: db/table/osm db/function/h3 | db/table
	psql -f tables/osm_object_count_grid_h3.sql
	touch $@

db/table/kontur_population_h3: db/table/population_grid_h3_r8 db/table/osm_building_count_grid_h3_r8 db/table/osm_unpopulated db/table/osm_water_polygons db/function/h3 | db/table
	psql -f tables/kontur_population_h3.sql
	touch $@

data/kontur_population.gpkg.gz: db/table/kontur_population_h3
	rm -f $@
	rm -f data/kontur_population.gpkg
	ogr2ogr -f GPKG data/kontur_population.gpkg PG:'dbname=gis' -sql "select geom, population from kontur_population_h3 where population>0 and resolution=8 order by h3" -lco "SPATIAL_INDEX=NO" -nln kontur_population
	cd data/; pigz kontur_population.gpkg

db/table/residential_pop_h3: db/table/kontur_population_h3 db/table/ghs_globe_residential_vector | db/table
	psql -f tables/residential_pop_h3.sql
	touch $@

db/table/stat_h3: db/table/osm_object_count_grid_h3 db/table/residential_pop_h3 db/table/gdp_h3 db/table/user_hours_h3 | db/table
	psql -f tables/stat_h3.sql
	touch $@

db/table/bivariate_axis: db/table/bivariate_copyrights db/table/stat_h3 | data/tiles/stat
	psql -f tables/bivariate_axis.sql
	touch $@

db/table/bivariate_overlays: db/table/osm_meta | db/table
	psql -f tables/bivariate_overlays.sql
	touch $@

db/table/bivariate_copyrights: | db/table
	psql -f tables/bivariate_copyrights.sql
	touch $@

data/tiles/stats_tiles.tar.bz2: db/table/bivariate_axis db/table/bivariate_overlays db/table/bivariate_copyrights db/table/stat_h3 db/table/osm_meta | data/tiles
	bash ./scripts/generate_tiles.sh stats | parallel --eta
	psql -q -X -f scripts/export_osm_bivariate_map_axis.sql | sed s#\\\\\\\\#\\\\#g > data/tiles/stats/stat.json
	cd data/tiles/stats/; tar cvf ../stats_tiles.tar.bz2  --use-compress-prog=pbzip2 ./

deploy/geocint/stats_tiles: data/tiles/stats_tiles.tar.bz2 | deploy/geocint
	sudo mkdir -p /var/www/tiles; sudo chmod 777 /var/www/tiles
	rm -rf /var/www/tiles/stats_new; mkdir -p /var/www/tiles/stats_new
	cp -a data/tiles/stats/. /var/www/tiles/stats_new/
	rm -rf /var/www/tiles/stats_old
	mv /var/www/tiles/stats /var/www/tiles/stats_old; mv /var/www/tiles/stats_new /var/www/tiles/stats
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
	'
	touch $@

data/tiles/users_tiles.tar.bz2: db/table/osm_users_hex db/table/osm_meta db/function/calculate_h3_res | data/tiles
	bash ./scripts/generate_tiles.sh users | parallel --eta
	cd data/tiles/users/; tar cjvf ../users_tiles.tar.bz2 ./

deploy/geocint/users_tiles: data/tiles/users_tiles.tar.bz2 | deploy/geocint
	sudo mkdir -p /var/www/tiles; sudo chmod 777 /var/www/tiles
	rm -rf /var/www/tiles/users_new; mkdir -p /var/www/tiles/users_new
	cp -a data/tiles/users/. /var/www/tiles/users_new/
	rm -rf /var/www/tiles/users_old
	mv /var/www/tiles/users /var/www/tiles/users_old; mv /var/www/tiles/users_new /var/www/tiles/users
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
	'
	touch $@

data/population/population_api_tables.sqld.gz: db/table/stat_h3 | data/population
# crafting production friendly SQL dump
	bash -c "cat scripts/population_api_dump_header.sql <(pg_dump --no-owner -t stat_h3 | sed 's/ public.stat_h3 / public.stat_h3__new /; s/^CREATE INDEX stat_h3_geom_zoom_idx.*//;') scripts/population_api_dump_footer.sql | pigz" > $@__TMP
	mv $@__TMP $@
	touch $@

deploy/sonic/population_api_tables: data/population/population_api_tables.sqld.gz | deploy/sonic
	ansible sonic_population_api -m file -a 'path=$$HOME/tmp state=directory mode=0770'
	ansible sonic_population_api -m copy -a 'src=data/population/population_api_tables.sqld.gz dest=$$HOME/tmp/population_api_tables.sqld.gz'
	ansible sonic_population_api -m postgresql_db -a 'name=population-api maintenance_db=population-api login_user=population-api login_host=localhost state=restore target=$$HOME/tmp/population_api_tables.sqld.gz'
	ansible sonic_population_api -m file -a 'path=$$HOME/tmp/population_api_tables.sqld.gz state=absent'
# we do not remove $$HOME/tmp/population_api_tables.sqld.gz on the staging server intentionally
	touch $@

deploy/lima/population_api_tables: data/population/population_api_tables.sqld.gz | deploy/lima
	ansible lima_population_api -m file -a 'path=$$HOME/tmp state=directory mode=0770'
	ansible lima_population_api -m copy -a 'src=data/population/population_api_tables.sqld.gz dest=$$HOME/tmp/population_api_tables.sqld.gz'
	ansible lima_population_api -m postgresql_db -a 'name=population-api maintenance_db=population-api login_user=population-api login_host=localhost state=restore target=$$HOME/tmp/population_api_tables.sqld.gz'
	ansible lima_population_api -m file -a 'path=$$HOME/tmp/population_api_tables.sqld.gz state=absent'
	touch $@
