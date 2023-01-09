clean:
	rm -rf db/* data/* deploy/*

basemap_tiles: deploy/s3/basemap.mbtiles ## [FINAL] All basemap related targets, temporarily removed from main build.
	touch $@

data: ## Temporary file based datasets. Located on bcache. Some files could be returned to SSD.
	mkdir -p $@

scripts: ## scripts that perform transformation on top of table without creating new one
	mkdir -p $@

db: ## Directory for storing database objects creation footprints.
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

data/in: | data  ## Input data, downloaded from elsewhere.
	mkdir -p $@

data/mid: | data ## Intermediate data (retiles, unpacks, reprojections, …) that can be removed daily.
	mkdir -p $@

data/out: | data ## Generated final data (tiles, dumps, etc).
	mkdir -p $@

deploy:  ## Directory for deployment targets footprints.
	mkdir -p $@

deploy/prod: | deploy ## We use lima.kontur.io as a production server.
	mkdir -p $@

deploy/test: | deploy ## We use sonic.kontur.io as a staging server to test software before setting it live to prod.
	mkdir -p $@

deploy/dev: | deploy ## Target-created directory for deployments on test server zigzag.kontur.io
	mkdir -p $@

deploy/geocint: | deploy ## We use geocint as a GIS development server.
	mkdir -p $@

deploy/s3: | deploy ## Target-created directory for deployments on S3.
	mkdir -p $@

data/planet-latest.osm.pbf: | data ## Download latest planet OSM pbf extraction through Bit torrent and rename it to planet-latest.osm.pbf.
	rm -f data/planet-*.osm.pbf data/planet-latest.seq data/planet-latest.osm.pbf.meta.json
	cd data; aria2c https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf.torrent --seed-time=0
	mv data/planet-*.osm.pbf $@
	rm -f data/planet-*.osm.pbf.torrent
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
	psql -c "alter table land_polygons_vector alter column geom type geometry(multipolygon, 3857) using ST_Multi(ST_Transform(ST_ClipByBox2D(geom, ST_Transform(ST_TileEnvelope(0,0,0),4326)), 3857));"
	touch $@

data/in/topology_boundaries.geojson: | data/in
	wget https://geodata-eu-central-1-kontur-public.s3.eu-central-1.amazonaws.com/kontur_datasets/topology_boundaries.geojson.gz -O data/in/topology_boundaries.geojson.gz
	pigz -d data/in/topology_boundaries.geojson.gz

db/table/kontur_topology_boundary: data/in/topology_boundaries.geojson | db/table
	ogr2ogr -f PostgreSQL PG:"dbname=gis" -a_srs EPSG:3857 data/in/topology_boundaries.geojson -nln kontur_topology_boundary -lco GEOMETRY_NAME=geom
	touch $@

db/table/osm2pgsql: db/table/kontur_topology_boundary data/planet-latest.osm.pbf | db/table ## Yet another OpenStreetMap import into database (because we need OSM data in osm2pgsql schema for Kothic).
	psql -c "create extension if not exists hstore;"
	osm2pgsql --style osm2pgsql_styles/basemap.lua --flat-nodes data/osm2pgsql_flat_nodes --slim --number-processes 32 --output=flex --create data/planet-latest.osm.pbf
	touch $@

db/table/osm2pgsql_with_boundaries: db/table/osm2pgsql | db/table
	psql -c "insert into planet_osm_line (osm_id, boundary, admin_level, maritime, way) select -osm_id as osm_id, 'administrative' as boundary, admin_level, nullif(maritime, false), geom as way from kontur_topology_boundary;"
	touch $@

db/table/osm2pgsql_fill_lang: db/table/osm2pgsql_with_boundaries | db/table ## fill missing name:[lang]
	psql -f scripts/osm2pgsql_fill_lang.sql
	touch $@

db/index/planet_osm_polygon_way_area_idx: db/table/osm2pgsql_fill_lang | db/index ## index for basemap low zoom queries
	psql -c "create index planet_osm_polygon_way_area_idx on planet_osm_polygon using btree(way_area);"
	touch $@

db/index/planet_osm_polygon_natural_idx: db/table/osm2pgsql_fill_lang | db/index ## index for basemap low zoom queries
	psql -c "create index planet_osm_polygon_natural_idx on planet_osm_polygon using btree(\"natural\");"
	touch $@

db/index/planet_osm_polygon_admin_level_idx: db/table/osm2pgsql_fill_lang | db/index ## index for basemap low zoom queries
	psql -c "create index planet_osm_polygon_admin_level_idx on planet_osm_polygon using btree(\"admin_level\");"
	touch $@

db/index/planet_osm_line_admin_level_idx: db/table/osm2pgsql_fill_lang | db/index ## index for basemap low zoom queries
	psql -c "create index planet_osm_line_admin_level_idx on planet_osm_line using btree(\"admin_level\");"
	touch $@

db/index/planet_osm_line_highway_idx: db/table/osm2pgsql_fill_lang | db/index ## index for basemap low zoom queries
	psql -c "create index planet_osm_line_highway_idx on planet_osm_line using btree(\"highway\");"
	touch $@

db/index/planet_osm_point_place_idx: db/table/osm2pgsql_fill_lang | db/index ## index for basemap low zoom queries
	psql -c "create index planet_osm_point_place_idx on planet_osm_point using btree(\"place\");"
	touch $@

db/index/planet_osm_point_capital_idx: db/table/osm2pgsql_fill_lang | db/index ## index for basemap low zoom queries
	psql -c "create index planet_osm_point_capital_idx on planet_osm_point using btree(\"capital\");"
	touch $@

db/index/planet_osm__all: db/index/planet_osm_polygon_way_area_idx db/index/planet_osm_polygon_natural_idx db/index/planet_osm_polygon_admin_level_idx db/index/planet_osm_line_admin_level_idx db/index/planet_osm_line_highway_idx db/index/planet_osm_point_place_idx db/index/planet_osm_point_capital_idx ## Aggregate target for osm2pgsql import indexes
	touch $@

kothic/src/komap.py: ## Clone Kothic from GIT
	git clone -b master --single-branch https://github.com/kothic/kothic.git

tile_generator/tile_generator: tile_generator/main.go tile_generator/go.mod  ## Compile tile_generator with GO
	cd tile_generator; go get; go build -o tile_generator

data/basemap.sql: kothic/src/komap.py | db/function scripts ## Generate SQL functions for further scripts generating (basemap_z[0-16] routines in database).
	python2 kothic/src/komap.py \
		--renderer=mvt-sql \
		--stylesheet styles/ninja.mapcss \
		--stylesheet styles/mapsme_mod/style-clear/style.mapcss \
		--osm2pgsql-style osm2pgsql_styles/default.style \
		--locale en,es,de,ru,be,pl,uk,id,ar,th,ko,ja  \
		> data/basemap.sql
	touch $@

data/basemap.mbtiles: tile_generator/tile_generator data/basemap.sql db/index/planet_osm__all db/table/land_polygons_vector | data ## Generating vector tiles.
	rm -f data/basemap.mbtiles
	tile_generator/tile_generator -j 32 --min-zoom 0 --max-zoom 14 --sql-query-filepath 'data/basemap.sql' --db-config 'dbname=gis user=gis' --output-mbtiles $@

data/basemap: | data ## Directory for MAPCSS styles, icon sprites and font glyphs used with vector tiles.
	mkdir -p $@

data/basemap/glyphs: | data/basemap ## Directory for font glyphs used in JSON styles with vector tiles.
	mkdir -p $@

data/basemap/sprite: | data/basemap ## Directory for icon sprites used in JSON styles with vector tiles.
	mkdir -p $@

data/basemap/metadata: | data/basemap ## Directory for JSON styles used with vector tiles.
	mkdir -p $@

data/basemap/metadata/dev: | data/basemap/metadata ## JSON styles used with vector tiles for TEST DVLP server (because they are path specific).
	mkdir -p $@

data/basemap/metadata/test: | data/basemap/metadata ## JSON styles used with vector tiles for TEST QA server (because they are path specific).
	mkdir -p $@

data/basemap/metadata/prod: | data/basemap/metadata ## JSON styles used with vector tiles for PROD server (because they are path specific).
	mkdir -p $@

data/basemap/glyphs_all: | data/basemap/glyphs ## Target that generates glyphs (SDF) from TTFs using OpenMapTiles font builder.
	rm -rf basemap/omt_fonts
	git clone https://github.com/openmaptiles/fonts.git basemap/omt_fonts
	cd basemap/omt_fonts; npm i
	cd basemap/omt_fonts; node generate.js
	cp -r basemap/omt_fonts/_output/. data/basemap/glyphs
	touch $@

data/basemap/sprite_all: | data/basemap/sprite ## Build sprites currently fetched from Mapbox.
	cp -r sprite/. data/basemap/sprite
	touch $@

data/basemap/metadata/dev/style_night_no_globe_view_support.json: kothic/src/komap.py scripts/patch_style_add_unfolded_globe_view_dummy_layers.py | data/basemap/metadata/dev ## Generating of Night style JSON for TEST DVLP server.
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/mapsme_mod/style-night/style.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://test-apps02.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://test-api02.konturlabs.com/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		> $@

data/basemap/metadata/dev/style_night.json: data/basemap/metadata/dev/style_night_no_globe_view_support.json ## Patch style to support unfolded globe-view
	python3 scripts/patch_style_add_unfolded_globe_view_dummy_layers.py data/basemap/metadata/dev/style_night_no_globe_view_support.json > $@

data/basemap/metadata/dev/style_day_no_globe_view_support.json: styles/ninja.mapcss scripts/patch_style_add_unfolded_globe_view_dummy_layers.py kothic/src/komap.py | data/basemap/metadata/dev ## Generating of Ninja style JSON for Geocint server.
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/ninja.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://test-apps02.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://test-api02.konturlabs.com/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		--sprite-url https://test-api02.konturlabs.com/layers/tiles/basemap/sprite \
		> $@

data/basemap/metadata/dev/style_day.json: data/basemap/metadata/dev/style_day_no_globe_view_support.json ## Patch style to support unfolded globe-view
	python3 scripts/patch_style_add_unfolded_globe_view_dummy_layers.py data/basemap/metadata/dev/style_day_no_globe_view_support.json > $@

data/basemap/metadata/dev/style_day_en.json: styles/ninja.mapcss kothic/src/komap.py | data/basemap/metadata/dev ## Generating of Ninja style JSON for Geocint server. (language=en)
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/ninja.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://test-apps02.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://test-api02.konturlabs.com/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		--sprite-url https://test-api02.konturlabs.com/layers/tiles/basemap/sprite \
		--locale en \
		--label-fallback "int_name,name" \
		> $@

data/basemap/metadata/dev/style_ninja.json: kothic/src/komap.py data/basemap/metadata/dev/style_day_en.json | data/basemap/metadata/dev ## Patch style to fall into osm.org tile starting from z10
	cat data/basemap/metadata/dev/style_day_en.json > $@

data/basemap/metadata/dev/style_ninja_latin_languages.json: styles/ninja.mapcss kothic/src/komap.py | data/basemap/metadata/dev ## Generating of Ninja style JSON for Latin like languages.
	for lang in en es de uk id ; do \
		python2 kothic/src/komap.py \
			--attribution-text "© OpenStreetMap" \
			--minzoom 0 \
			--maxzoom 24 \
			--renderer=mapbox-style-language \
			--stylesheet styles/ninja.mapcss \
			--tiles-max-zoom 14 \
			--tiles-url https://test-apps02.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
			--glyphs-url https://test-api02.konturlabs.com/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
			--sprite-url https://test-api02.konturlabs.com/layers/tiles/basemap/sprite \
			--locale $$lang \
			--label-fallback "int_name,name" \
			> data/basemap/metadata/dev/style_ninja_$$lang.json; \
	done

data/basemap/metadata/dev/style_ninja_non_latin_languages.json: styles/ninja.mapcss kothic/src/komap.py | data/basemap/metadata/dev ## Generating of Ninja style JSON for NON Latin like languages.
	for lang in ar th ko ja ; do \
		python2 kothic/src/komap.py \
			--attribution-text "© OpenStreetMap" \
			--minzoom 0 \
			--maxzoom 24 \
			--renderer=mapbox-style-language \
			--stylesheet styles/ninja.mapcss \
			--tiles-max-zoom 14 \
			--tiles-url https://test-apps02.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
			--glyphs-url https://test-api02.konturlabs.com/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
			--sprite-url https://test-api02.konturlabs.com/layers/tiles/basemap/sprite \
			--locale $$lang \
			> data/basemap/metadata/dev/style_ninja_$$lang.json; \
	done

data/basemap/metadata/test/style_ninja_latin_languages.json: styles/ninja.mapcss kothic/src/komap.py | data/basemap/metadata/test ## Generating of Ninja style JSON for Latin like languages.
	for lang in en es de uk id ; do \
		python2 kothic/src/komap.py \
			--attribution-text "© OpenStreetMap" \
			--minzoom 0 \
			--maxzoom 24 \
			--renderer=mapbox-style-language \
			--stylesheet styles/ninja.mapcss \
			--tiles-max-zoom 14 \
			--tiles-url https://test-apps.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
			--glyphs-url https://test-api.konturlabs.com/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
			--sprite-url https://test-api.konturlabs.com/layers/tiles/basemap/sprite \
			--locale $$lang \
			--label-fallback "int_name,name" \
			> data/basemap/metadata/test/style_ninja_$$lang.json; \
	done

data/basemap/metadata/test/style_ninja_non_latin_languages.json: styles/ninja.mapcss kothic/src/komap.py | data/basemap/metadata/test ## Generating of Ninja style JSON for NON Latin like languages.
	for lang in ar th ko ja ; do \
		python2 kothic/src/komap.py \
			--attribution-text "© OpenStreetMap" \
			--minzoom 0 \
			--maxzoom 24 \
			--renderer=mapbox-style-language \
			--stylesheet styles/ninja.mapcss \
			--tiles-max-zoom 14 \
			--tiles-url https://test-apps.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
			--glyphs-url https://test-api.konturlabs.com/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
			--sprite-url https://test-api.konturlabs.com/layers/tiles/basemap/sprite \
			--locale $$lang \
			> data/basemap/metadata/test/style_ninja_$$lang.json; \
	done

data/basemap/metadata/prod/style_ninja_latin_languages.json: styles/ninja.mapcss kothic/src/komap.py | data/basemap/metadata/test ## Generating of Ninja style JSON for Latin like languages.
	for lang in en es de uk id ; do \
		python2 kothic/src/komap.py \
			--attribution-text "© OpenStreetMap" \
			--minzoom 0 \
			--maxzoom 24 \
			--renderer=mapbox-style-language \
			--stylesheet styles/ninja.mapcss \
			--tiles-max-zoom 14 \
			--tiles-url https://apps.kontur.io/tileserver/data/basemap/{z}/{x}/{y}.pbf \
			--glyphs-url https://api.kontur.io/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
			--sprite-url https://api.kontur.io/layers/tiles/basemap/sprite \
			--locale $$lang \
			--label-fallback "int_name,name" \
			> data/basemap/metadata/prod/style_ninja_$$lang.json; \
	done

data/basemap/metadata/prod/style_ninja_non_latin_languages.json: styles/ninja.mapcss kothic/src/komap.py | data/basemap/metadata/test ## Generating of Ninja style JSON for NON Latin like languages.
	for lang in ar th ko ja ; do \
		python2 kothic/src/komap.py \
			--attribution-text "© OpenStreetMap" \
			--minzoom 0 \
			--maxzoom 24 \
			--renderer=mapbox-style-language \
			--stylesheet styles/ninja.mapcss \
			--tiles-max-zoom 14 \
			--tiles-url https://apps.kontur.io/tileserver/data/basemap/{z}/{x}/{y}.pbf \
			--glyphs-url https://api.kontur.io/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
			--sprite-url https://api.kontur.io/layers/tiles/basemap/sprite \
			--locale $$lang \
			> data/basemap/metadata/prod/style_ninja_$$lang.json; \
	done

data/basemap/metadata/dev/style_night_latin_languages.json: styles/ninja.mapcss kothic/src/komap.py | data/basemap/metadata/dev ## Generating of Ninja style JSON for Latin like languages.
	for lang in en es de uk id ; do \
		python2 kothic/src/komap.py \
			--attribution-text "© OpenStreetMap" \
			--minzoom 0 \
			--maxzoom 24 \
			--renderer=mapbox-style-language \
			--stylesheet styles/mapsme_mod/style-night/style.mapcss \
			--tiles-max-zoom 14 \
			--tiles-url https://test-apps02.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
			--glyphs-url https://test-api02.konturlabs.com/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
			--locale $$lang \
			--label-fallback "int_name,name" \
			> data/basemap/metadata/dev/style_night_$$lang.json; \
	done

data/basemap/metadata/dev/style_night_non_latin_languages.json: styles/ninja.mapcss kothic/src/komap.py | data/basemap/metadata/dev ## Generating of Ninja style JSON for NON Latin like languages.
	for lang in ar th ko ja ru ; do \
		python2 kothic/src/komap.py \
			--attribution-text "© OpenStreetMap" \
			--minzoom 0 \
			--maxzoom 24 \
			--renderer=mapbox-style-language \
			--stylesheet styles/mapsme_mod/style-night/style.mapcss \
			--tiles-max-zoom 14 \
			--tiles-url https://test-apps02.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
			--glyphs-url https://test-api02.konturlabs.com/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
			--locale $$lang \
			> data/basemap/metadata/dev/style_night_$$lang.json; \
	done

data/basemap/metadata/test/style_night_latin_languages.json: styles/ninja.mapcss kothic/src/komap.py | data/basemap/metadata/test ## Generating of Ninja style JSON for Latin like languages.
	for lang in en es de uk id ; do \
		python2 kothic/src/komap.py \
			--attribution-text "© OpenStreetMap" \
			--minzoom 0 \
			--maxzoom 24 \
			--renderer=mapbox-style-language \
			--stylesheet styles/mapsme_mod/style-night/style.mapcss \
			--tiles-max-zoom 14 \
			--tiles-url https://test-apps.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
			--glyphs-url https://test-api.konturlabs.com/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
			--locale $$lang \
			--label-fallback "int_name,name" \
			> data/basemap/metadata/test/style_night_$$lang.json; \
	done

data/basemap/metadata/test/style_night_non_latin_languages.json: styles/ninja.mapcss kothic/src/komap.py | data/basemap/metadata/test ## Generating of Ninja style JSON for NON Latin like languages.
	for lang in ar th ko ja ; do \
		python2 kothic/src/komap.py \
			--attribution-text "© OpenStreetMap" \
			--minzoom 0 \
			--maxzoom 24 \
			--renderer=mapbox-style-language \
			--stylesheet styles/mapsme_mod/style-night/style.mapcss \
			--tiles-max-zoom 14 \
			--tiles-url https://test-apps.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
			--glyphs-url https://test-api.konturlabs.com/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
			--locale $$lang \
			> data/basemap/metadata/test/style_night_$$lang.json; \
	done

data/basemap/metadata/prod/style_night_latin_languages.json: styles/ninja.mapcss kothic/src/komap.py | data/basemap/metadata/test ## Generating of Ninja style JSON for Latin like languages.
	for lang in en es de uk id ; do \
		python2 kothic/src/komap.py \
			--attribution-text "© OpenStreetMap" \
			--minzoom 0 \
			--maxzoom 24 \
			--renderer=mapbox-style-language \
			--stylesheet styles/mapsme_mod/style-night/style.mapcss \
			--tiles-max-zoom 14 \
			--tiles-url https://apps.kontur.io/tileserver/data/basemap/{z}/{x}/{y}.pbf \
			--glyphs-url https://api.kontur.io/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
			--locale $$lang \
			--label-fallback "int_name,name" \
			> data/basemap/metadata/prod/style_night_$$lang.json; \
	done

data/basemap/metadata/prod/style_night_non_latin_languages.json: styles/ninja.mapcss kothic/src/komap.py | data/basemap/metadata/test ## Generating of Ninja style JSON for NON Latin like languages.
	for lang in ar th ko ja ; do \
		python2 kothic/src/komap.py \
			--attribution-text "© OpenStreetMap" \
			--minzoom 0 \
			--maxzoom 24 \
			--renderer=mapbox-style-language \
			--stylesheet styles/mapsme_mod/style-night/style.mapcss \
			--tiles-max-zoom 14 \
			--tiles-url https://apps.kontur.io/tileserver/data/basemap/{z}/{x}/{y}.pbf \
			--glyphs-url https://api.kontur.io/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
			--locale $$lang \
			> data/basemap/metadata/prod/style_night_$$lang.json; \
	done

data/basemap/metadata/test/style_day_no_globe_view_support.json: kothic/src/komap.py scripts/patch_style_add_unfolded_globe_view_dummy_layers.py | data/basemap/metadata/test ## Generating of Ninja style JSON for TEST QA server.
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/ninja.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://test-apps.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://test-api.konturlabs.com/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		--sprite-url https://test-api.konturlabs.com/layers/tiles/basemap/sprite \
		> $@

data/basemap/metadata/test/style_day.json: data/basemap/metadata/test/style_day_no_globe_view_support.json ## Patch style to support unfolded globe-view
	python3 scripts/patch_style_add_unfolded_globe_view_dummy_layers.py data/basemap/metadata/test/style_day_no_globe_view_support.json > $@

data/basemap/metadata/test/style_day_en.json: kothic/src/komap.py | data/basemap/metadata/test ## Generating of Ninja style JSON for TEST QA server. (language=en)
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/ninja.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://test-apps.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://test-api.konturlabs.com/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		--sprite-url https://test-api.konturlabs.com/layers/tiles/basemap/sprite \
		--locale en \
		--label-fallback "int_name,name" \
		> $@

data/basemap/metadata/test/style_ninja.json: kothic/src/komap.py data/basemap/metadata/test/style_day_en.json | data/basemap/metadata/test ## Patch style to fall into osm.org tile starting from z10
	cat data/basemap/metadata/test/style_day_en.json > $@

data/basemap/metadata/test/style_night_no_globe_view_support.json: kothic/src/komap.py scripts/patch_style_add_unfolded_globe_view_dummy_layers.py | data/basemap/metadata/test ## Generating of Night style JSON for TEST QA server.
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/mapsme_mod/style-night/style.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://test-apps.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://test-api.konturlabs.com/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		> $@

data/basemap/metadata/test/style_night.json: data/basemap/metadata/test/style_night_no_globe_view_support.json ## Patch style to support unfolded globe-view
	python3 scripts/patch_style_add_unfolded_globe_view_dummy_layers.py data/basemap/metadata/test/style_night_no_globe_view_support.json > $@

data/basemap/metadata/test/style_night_en.json: kothic/src/komap.py | data/basemap/metadata/test ## Generating of Night style JSON for TEST QA server. (language=en)
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/mapsme_mod/style-night/style.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://test-apps.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://test-api.konturlabs.com/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		--locale en \
		--label-fallback "int_name,name" \
		> $@

data/basemap/metadata/prod/style_day_no_globe_view_support.json: kothic/src/komap.py scripts/patch_style_add_unfolded_globe_view_dummy_layers.py | data/basemap/metadata/prod ## Generating of Ninja style JSON for PROD server.
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/ninja.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://apps.kontur.io/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://api.kontur.io/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		--sprite-url https://api.kontur.io/layers/tiles/basemap/sprite \
		> $@

data/basemap/metadata/prod/style_day.json: data/basemap/metadata/prod/style_day_no_globe_view_support.json ## Patch style to support unfolded globe-view
	python3 scripts/patch_style_add_unfolded_globe_view_dummy_layers.py data/basemap/metadata/prod/style_day_no_globe_view_support.json > $@

data/basemap/metadata/prod/style_day_en.json: kothic/src/komap.py | data/basemap/metadata/prod ## Generating of Ninja style JSON for PROD server. (language=en)
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/ninja.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://apps.kontur.io/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://api.kontur.io/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		--sprite-url https://api.kontur.io/layers/tiles/basemap/sprite \
		--locale en \
		--label-fallback "int_name,name" \
		> $@

data/basemap/metadata/prod/style_ninja.json: data/basemap/metadata/prod/style_day_en.json kothic/src/komap.py | data/basemap/metadata/prod ## Patch style to fall into osm.org tile starting from z10
	cat data/basemap/metadata/prod/style_day_en.json > $@

data/basemap/metadata/prod/style_night_no_globe_view_support.json: kothic/src/komap.py scripts/patch_style_add_unfolded_globe_view_dummy_layers.py | data/basemap/metadata/prod ## Generating of Night style JSON for PROD server.
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/mapsme_mod/style-night/style.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://apps.kontur.io/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://api.kontur.io/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		> $@

data/basemap/metadata/prod/style_night.json: data/basemap/metadata/prod/style_night_no_globe_view_support.json ## Patch style to support unfolded globe-view
	python3 scripts/patch_style_add_unfolded_globe_view_dummy_layers.py data/basemap/metadata/prod/style_night_no_globe_view_support.json > $@

data/basemap/metadata/prod/style_night_en.json: kothic/src/komap.py | data/basemap/metadata/prod ## Generating of Night style JSON for PROD server. (language=en)
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/mapsme_mod/style-night/style.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://apps.kontur.io/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://api.kontur.io/layers/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		--locale en \
		--label-fallback "int_name,name" \
		> $@

deploy/geocint/basemap_mapcss: data/basemap/metadata/dev/style_ninja.json data/basemap/metadata/dev/style_day.json data/basemap/metadata/dev/style_night.json | deploy/geocint ## Deploy JSON styles for vector tiles on geocint.
	cp data/basemap/metadata/dev/style_ninja.json /var/www/html/basemap/style_ninja.json
	cp data/basemap/metadata/dev/style_day.json /var/www/html/basemap/style_mwm.json
	cp data/basemap/metadata/dev/style_night.json /var/www/html/basemap/style_mwm_night.json
	touch $@

deploy/s3/basemap.mbtiles: data/basemap.mbtiles | deploy/s3 ## deploy basemap.mbtiles to S3
	aws s3 cp data/basemap.mbtiles $(S3_BASEMAP_PATH)
	touch $@

deploy/dev/basemap: data/basemap/metadata/dev/style_night_non_latin_languages.json data/basemap/metadata/dev/style_night_latin_languages.json data/basemap/metadata/dev/style_ninja.json data/basemap/metadata/dev/style_ninja_latin_languages.json data/basemap/metadata/dev/style_ninja_non_latin_languages.json data/basemap/metadata/dev/style_day.json data/basemap/metadata/dev/style_day_en.json data/basemap/metadata/dev/style_night.json data/basemap/glyphs_all data/basemap/sprite_all | deploy/dev ## Transfer and deploy tar archive with tiles, glyphs and styles on DEV server.
	aws s3 cp --recursive data/basemap/metadata/dev s3://basemap-locker01/DEV/styles
	aws s3 cp --recursive data/basemap/glyphs s3://basemap-locker01/DEV/glyphs
	aws s3 cp --recursive data/basemap/sprite s3://basemap-locker01/DEV/sprite
	touch $@

deploy/test/basemap: data/basemap/metadata/test/style_night_non_latin_languages.json data/basemap/metadata/test/style_night_latin_languages.json data/basemap/metadata/test/style_ninja.json data/basemap/metadata/test/style_day.json data/basemap/metadata/test/style_day_en.json data/basemap/metadata/test/style_ninja_latin_languages.json data/basemap/metadata/test/style_ninja_non_latin_languages.json data/basemap/metadata/test/style_night.json data/basemap/metadata/test/style_night_en.json data/basemap/glyphs_all data/basemap/sprite_all | deploy/test ## Transfer and deploy tar archive with tiles, glyphs and styles on TEST server.
	aws s3 cp --recursive data/basemap/metadata/test s3://basemap-locker01/TEST/styles
	aws s3 cp --recursive data/basemap/glyphs s3://basemap-locker01/TEST/glyphs
	aws s3 cp --recursive data/basemap/sprite s3://basemap-locker01/TEST/sprite
	touch $@

deploy/prod/basemap: data/basemap/metadata/prod/style_night_non_latin_languages.json data/basemap/metadata/prod/style_night_latin_languages.json data/basemap/metadata/prod/style_ninja.json data/basemap/metadata/prod/style_day.json data/basemap/metadata/prod/style_day_en.json data/basemap/metadata/prod/style_ninja_latin_languages.json data/basemap/metadata/prod/style_ninja_non_latin_languages.json data/basemap/metadata/prod/style_night.json data/basemap/metadata/prod/style_night_en.json data/basemap/glyphs_all data/basemap/sprite_all | deploy/prod ## Transfer and deploy tar archive with tiles, glyphs and styles on PROD server.
	aws s3 cp --recursive data/basemap/metadata/prod s3://basemap-locker01/PROD/styles
	aws s3 cp --recursive data/basemap/glyphs s3://basemap-locker01/PROD/glyphs
	aws s3 cp --recursive data/basemap/sprite s3://basemap-locker01/PROD/sprite
	touch $@
