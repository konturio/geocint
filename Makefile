all: deploy/geocint/isochrone_tables

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

data/wb: | data
	mkdir -p $@

data/wb/gdp: | data/wb
	mkdir -p $@

deploy:
	mkdir -p $@

deploy/geocint: | deploy
	mkdir -p $@

deploy/geocint/isochrone_tables: db/table/osm_road_segments db/table/osm_road_segments_new db/index/osm_road_segments_new_seg_id_node_from_node_to_seg_geom_idx db/index/osm_road_segments_new_seg_geom_idx
	touch $@

data/planet-latest.osm.pbf: | data
	wget -t inf https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf -O $@
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

db/table/osm: db/table
	psql -c "drop table if exists osm;"
	OSMIUM_POOL_THREADS=8 OSMIUM_MAX_INPUT_QUEUE_SIZE=100 OSMIUM_MAX_OSMDATA_QUEUE_SIZE=100 OSMIUM_MAX_OUTPUT_QUEUE_SIZE=100 OSMIUM_MAX_WORK_QUEUE_SIZE=100 numactl --preferred=1 -N 1 osmium export -i dense_mmap_array -c osmium.config.json -f pg BY.pbf  -v --progress | psql -1 -c 'create table osm(geog geography, osm_type text, osm_id bigint, osm_user text, ts timestamptz, way_nodes bigint[], tags jsonb);alter table osm alter geog set storage external, alter osm_type set storage main, alter osm_user set storage main, alter way_nodes set storage external, alter tags set storage external, set (fillfactor=100); copy osm from stdin freeze;'
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
