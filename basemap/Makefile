clean:
	rm -rf db/* data/* deploy/*

basemap_all: deploy/s3/basemap.mbtiles ## [FINAL] All basemap related targets, temporarily removed from main build.
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

deploy/lima: | deploy ## We use lima.kontur.io as a production server.
	mkdir -p $@

deploy/sonic: | deploy ## We use sonic.kontur.io as a staging server to test software before setting it live to prod.
	mkdir -p $@

deploy/zigzag: | deploy ## Target-created directory for deployments on test server zigzag.kontur.io
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

db/table/osm2pgsql: data/planet-latest.osm.pbf | db/table ## Yet another OpenStreetMap import into database (because we need OSM data in osm2pgsql schema for Kothic).
	psql -c "create extension if not exists hstore;"
	osm2pgsql --style osm2pgsql_styles/basemap.lua --flat-nodes data/osm2pgsql_flat_nodes --slim --number-processes 32 --output=flex --create data/planet-latest.osm.pbf
	touch $@

db/index/planet_osm_polygon_way_area_idx: db/table/osm2pgsql | db/index ## index for basemap low zoom queries
	psql -c "create index planet_osm_polygon_way_area_idx on planet_osm_polygon using btree(way_area);"
	touch $@

db/index/planet_osm_polygon_natural_idx: db/table/osm2pgsql | db/index ## index for basemap low zoom queries
	psql -c "create index planet_osm_polygon_natural_idx on planet_osm_polygon using btree(\"natural\");"
	touch $@

db/index/planet_osm_polygon_admin_level_idx: db/table/osm2pgsql | db/index ## index for basemap low zoom queries
	psql -c "create index planet_osm_polygon_admin_level_idx on planet_osm_polygon using btree(\"admin_level\");"
	touch $@

db/index/planet_osm_line_admin_level_idx: db/table/osm2pgsql | db/index ## index for basemap low zoom queries
	psql -c "create index planet_osm_line_admin_level_idx on planet_osm_line using btree(\"admin_level\");"
	touch $@

db/index/planet_osm_line_highway_idx: db/table/osm2pgsql | db/index ## index for basemap low zoom queries
	psql -c "create index planet_osm_line_highway_idx on planet_osm_line using btree(\"highway\");"
	touch $@

db/index/planet_osm_point_place_idx: db/table/osm2pgsql | db/index ## index for basemap low zoom queries
	psql -c "create index planet_osm_point_place_idx on planet_osm_point using btree(\"place\");"
	touch $@

db/index/planet_osm_point_capital_idx: db/table/osm2pgsql | db/index ## index for basemap low zoom queries
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
		--locale en,ru,be,pl,uk \
		> data/basemap.sql
	touch $@

data/basemap.mbtiles: tile_generator/tile_generator data/basemap.sql db/index/planet_osm__all db/table/land_polygons_vector | data ## Generating vector tiles.
	rm data/basemap.mbtiles
	tile_generator/tile_generator -j 32 --min-zoom 0 --max-zoom 14 --sql-query-filepath 'data/basemap.sql' --db-config 'dbname=gis user=gis' --output-mbtiles $@

data/basemap: | data ## Directory for MAPCSS styles, icon sprites and font glyphs used with vector tiles.
	mkdir -p $@

data/basemap/glyphs: | data/basemap ## Directory for font glyphs used in JSON styles with vector tiles.
	mkdir -p $@

data/basemap/sprite: | data/basemap ## Directory for icon sprites used in JSON styles with vector tiles.
	mkdir -p $@

data/basemap/metadata: | data/basemap ## Directory for JSON styles used with vector tiles.
	mkdir -p $@

data/basemap/metadata/zigzag: | data/basemap/metadata ## JSON styles used with vector tiles for TEST DVLP server (because they are path specific).
	mkdir -p $@

data/basemap/metadata/sonic: | data/basemap/metadata ## JSON styles used with vector tiles for TEST QA server (because they are path specific).
	mkdir -p $@

data/basemap/metadata/lima: | data/basemap/metadata ## JSON styles used with vector tiles for PROD server (because they are path specific).
	mkdir -p $@

data/basemap/glyphs_all: | data/basemap/glyphs ## Target that generates glyphs (SDF) from TTFs using OpenMapTiles font builder.
	rm -rf basemap/omt_fonts
	git clone https://github.com/openmaptiles/fonts.git basemap/omt_fonts
	cd basemap/omt_fonts; npm i
	cd basemap/omt_fonts; node generate.js
	cp -r basemap/omt_fonts/_output/. data/basemap/glyphs
	touch $@

data/basemap/sprite_all: | data/basemap/sprite ## Build sprites currently fetched from Mapbox.
	cp -r basemap/sprite/. data/basemap/sprite
	touch $@

data/basemap/metadata/zigzag/style_night_no_globe_view_support.json: kothic/src/komap.py scripts/patch_style_add_unfolded_globe_view_dummy_layers.py | data/basemap/metadata/zigzag ## Generating of Night style JSON for TEST DVLP server.
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/mapsme_mod/style-night/style.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://test-apps02.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://zigzag.kontur.io/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		> $@

data/basemap/metadata/zigzag/style_night.json: data/basemap/metadata/zigzag/style_night_no_globe_view_support.json ## Patch style to support unfolded globe-view
	python scripts/patch_style_add_unfolded_globe_view_dummy_layers.py data/basemap/metadata/zigzag/style_night_no_globe_view_support.json > $@

data/basemap/metadata/zigzag/style_night_ru.json: kothic/src/komap.py | data/basemap/metadata/zigzag ## Generating of Night style JSON for TEST DVLP server. (language=ru)
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/mapsme_mod/style-night/style.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://test-apps02.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://zigzag.kontur.io/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		--locale ru \
		> $@

data/basemap/metadata/zigzag/style_night_en.json: kothic/src/komap.py | data/basemap/metadata/zigzag ## Generating of Night style JSON for TEST DVLP server. (language=en)
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/mapsme_mod/style-night/style.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://test-apps02.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://zigzag.kontur.io/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		--locale en \
		> $@

data/basemap/metadata/zigzag/style_day_no_globe_view_support.json: styles/ninja.mapcss scripts/patch_style_add_unfolded_globe_view_dummy_layers.py kothic/src/komap.py | data/basemap/metadata/zigzag ## Generating of Ninja style JSON for Geocint server.
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/ninja.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://test-apps02.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://zigzag.kontur.io/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		--sprite-url https://zigzag.kontur.io/tiles/basemap/sprite \
		> $@

data/basemap/metadata/zigzag/style_day.json: data/basemap/metadata/zigzag/style_day_no_globe_view_support.json ## Patch style to support unfolded globe-view
	python scripts/patch_style_add_unfolded_globe_view_dummy_layers.py data/basemap/metadata/zigzag/style_day_no_globe_view_support.json > $@

data/basemap/metadata/zigzag/style_day_en.json: styles/ninja.mapcss kothic/src/komap.py | data/basemap/metadata/zigzag ## Generating of Ninja style JSON for Geocint server. (language=en)
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/ninja.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://test-apps02.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://zigzag.kontur.io/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		--sprite-url https://zigzag.kontur.io/tiles/basemap/sprite \
		--locale en \
		> $@

data/basemap/metadata/zigzag/style_ninja.json: kothic/src/komap.py data/basemap/metadata/zigzag/style_day_en.json | data/basemap/metadata/zigzag ## Patch style to fall into osm.org tile starting from z10
	cat data/basemap/metadata/zigzag/style_day_en.json > $@

data/basemap/metadata/sonic/style_day_no_globe_view_support.json: kothic/src/komap.py scripts/patch_style_add_unfolded_globe_view_dummy_layers.py | data/basemap/metadata/sonic ## Generating of Ninja style JSON for TEST QA server.
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/ninja.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://test-apps.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://sonic.kontur.io/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		--sprite-url https://sonic.kontur.io/tiles/basemap/sprite \
		> $@

data/basemap/metadata/sonic/style_day.json: data/basemap/metadata/sonic/style_day_no_globe_view_support.json ## Patch style to support unfolded globe-view
	python scripts/patch_style_add_unfolded_globe_view_dummy_layers.py data/basemap/metadata/sonic/style_day_no_globe_view_support.json > $@

data/basemap/metadata/sonic/style_day_en.json: kothic/src/komap.py | data/basemap/metadata/sonic ## Generating of Ninja style JSON for TEST QA server. (language=en)
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/ninja.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://test-apps.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://sonic.kontur.io/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		--sprite-url https://sonic.kontur.io/tiles/basemap/sprite \
		--locale en \
		> $@

data/basemap/metadata/sonic/style_ninja.json: kothic/src/komap.py data/basemap/metadata/sonic/style_day_en.json | data/basemap/metadata/sonic ## Patch style to fall into osm.org tile starting from z10
	cat data/basemap/metadata/sonic/style_day_en.json > $@

data/basemap/metadata/sonic/style_night_no_globe_view_support.json: kothic/src/komap.py scripts/patch_style_add_unfolded_globe_view_dummy_layers.py | data/basemap/metadata/sonic ## Generating of Night style JSON for TEST QA server.
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/mapsme_mod/style-night/style.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://test-apps.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://sonic.kontur.io/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		> $@

data/basemap/metadata/sonic/style_night.json: data/basemap/metadata/sonic/style_night_no_globe_view_support.json ## Patch style to support unfolded globe-view
	python scripts/patch_style_add_unfolded_globe_view_dummy_layers.py data/basemap/metadata/sonic/style_night_no_globe_view_support.json > $@

data/basemap/metadata/sonic/style_night_en.json: kothic/src/komap.py | data/basemap/metadata/sonic ## Generating of Night style JSON for TEST QA server. (language=en)
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/mapsme_mod/style-night/style.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://test-apps.konturlabs.com/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://sonic.kontur.io/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		--locale en \
		> $@

data/basemap/metadata/lima/style_day_no_globe_view_support.json: kothic/src/komap.py scripts/patch_style_add_unfolded_globe_view_dummy_layers.py | data/basemap/metadata/lima ## Generating of Ninja style JSON for PROD server.
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/ninja.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://apps.kontur.io/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://disaster.ninja/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		--sprite-url https://disaster.ninja/tiles/basemap/sprite \
		> $@

data/basemap/metadata/lima/style_day.json: data/basemap/metadata/lima/style_day_no_globe_view_support.json ## Patch style to support unfolded globe-view
	python scripts/patch_style_add_unfolded_globe_view_dummy_layers.py data/basemap/metadata/lima/style_day_no_globe_view_support.json > $@

data/basemap/metadata/lima/style_day_en.json: kothic/src/komap.py | data/basemap/metadata/lima ## Generating of Ninja style JSON for PROD server. (language=en)
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/ninja.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://apps.kontur.io/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://disaster.ninja/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		--sprite-url https://disaster.ninja/tiles/basemap/sprite \
		--locale en \
		> $@

data/basemap/metadata/lima/style_ninja.json: data/basemap/metadata/lima/style_day_en.json kothic/src/komap.py | data/basemap/metadata/lima ## Patch style to fall into osm.org tile starting from z10
	cat data/basemap/metadata/lima/style_day_en.json > $@

data/basemap/metadata/lima/style_night_no_globe_view_support.json: kothic/src/komap.py scripts/patch_style_add_unfolded_globe_view_dummy_layers.py | data/basemap/metadata/lima ## Generating of Night style JSON for PROD server.
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/mapsme_mod/style-night/style.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://apps.kontur.io/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://disaster.ninja/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		> $@

data/basemap/metadata/lima/style_night.json: data/basemap/metadata/lima/style_night_no_globe_view_support.json ## Patch style to support unfolded globe-view
	python scripts/patch_style_add_unfolded_globe_view_dummy_layers.py data/basemap/metadata/lima/style_night_no_globe_view_support.json > $@

data/basemap/metadata/lima/style_night_en.json: kothic/src/komap.py | data/basemap/metadata/lima ## Generating of Night style JSON for PROD server. (language=en)
	python2 kothic/src/komap.py \
		--attribution-text "© OpenStreetMap" \
		--minzoom 0 \
		--maxzoom 24 \
		--renderer=mapbox-style-language \
		--stylesheet styles/mapsme_mod/style-night/style.mapcss \
		--tiles-max-zoom 14 \
		--tiles-url https://apps.kontur.io/tileserver/data/basemap/{z}/{x}/{y}.pbf \
		--glyphs-url https://disaster.ninja/tiles/basemap/glyphs/{fontstack}/{range}.pbf \
		--locale en \
		> $@

deploy/geocint/basemap_mapcss: data/basemap/metadata/zigzag/style_ninja.json data/basemap/metadata/zigzag/style_day.json data/basemap/metadata/zigzag/style_night.json | deploy/geocint ## Deploy JSON styles for vector tiles on geocint.
	cp data/basemap/metadata/zigzag/style_ninja.json /var/www/html/basemap/style_ninja.json
	cp data/basemap/metadata/zigzag/style_day.json /var/www/html/basemap/style_mwm.json
	cp data/basemap/metadata/zigzag/style_night.json /var/www/html/basemap/style_mwm_night.json
	touch $@

data/basemap/zigzag.tar.bz2: data/basemap/metadata/zigzag/style_night_ru.json data/basemap/metadata/zigzag/style_night_en.json data/basemap/metadata/zigzag/style_ninja.json data/basemap/metadata/zigzag/style_day.json data/basemap/metadata/zigzag/style_day_en.json data/basemap/metadata/zigzag/style_night.json data/basemap/glyphs_all data/basemap/sprite_all ## Combine tiles, glyphs and styles into one tar for further transfer to TEST DVLP server.
	tar cvf $@ --use-compress-prog=pbzip2 -C data/basemap glyphs -C sprite . -C ../metadata/zigzag .

data/basemap/sonic.tar.bz2: data/basemap/metadata/sonic/style_ninja.json data/basemap/metadata/sonic/style_day.json data/basemap/metadata/sonic/style_day_en.json data/basemap/metadata/sonic/style_night.json data/basemap/metadata/sonic/style_night_en.json data/basemap/glyphs_all data/basemap/sprite_all ## Combine tiles, glyphs and styles into one tar for further transfer to TEST QA server.
	tar cvf $@ --use-compress-prog=pbzip2 -C data/basemap glyphs -C sprite . -C ../metadata/sonic .

data/basemap/lima.tar.bz2: data/basemap/metadata/lima/style_ninja.json data/basemap/metadata/lima/style_day.json data/basemap/metadata/lima/style_day_en.json data/basemap/metadata/lima/style_night.json data/basemap/metadata/lima/style_night_en.json data/basemap/glyphs_all data/basemap/sprite_all ## Combine tiles, glyphs and styles into one tar for further transfer to PROD server.
	tar cvf $@ --use-compress-prog=pbzip2 -C data/basemap glyphs -C sprite . -C ../metadata/lima .

deploy/s3/basemap.mbtiles: data/basemap.mbtiles | deploy/s3 ## deploy basemap.mbtiles to S3
	aws s3 cp data/basemap.mbtiles $(S3_BASEMAP_PATH)
	touch $@

deploy/zigzag/basemap: deploy/zigzag/basemap.mbtiles data/basemap/zigzag.tar.bz2 | deploy/zigzag ## Transfer and deploy tar archive with tiles, glyphs and styles on TEST DVLP server.
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

deploy/sonic/basemap: deploy/sonic/basemap.mbtiles data/basemap/sonic.tar.bz2 | deploy/sonic ## Transfer and deploy tar archive with tiles, glyphs and styles on TEST QA server.
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

deploy/lima/basemap: deploy/lima/basemap.mbtiles data/basemap/lima.tar.bz2 | deploy/lima ## Transfer and deploy tar archive with tiles, glyphs and styles on PROD server.
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
