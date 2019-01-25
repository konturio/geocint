all: db/function/isochrone db/index/osm_geog_idx db/index/osm_tags_idx

clean:
	rm -rf db/ data/planet-latest-updated.osm.pbf

data:
	mkdir $@

db:
	mkdir $@

db/function: | db
	mkdir $@

db/table: | db
	mkdir $@

db/index: | db
	mkdir $@

data/planet-latest.osm.pbf: | data
	wget https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf -O $@
	# TODO: smoke check correctness of file
	touch $@

data/planet-latest-updated.osm.pbf: data/planet-latest.osm.pbf | data
	osmupdate data/planet-latest.osm.pbf data/planet-latest-updated.osm.pbf
	# TODO: smoke check correctness of file
	mv data/planet-latest-updated.osm.pbf data.planet-latest.osm.pbf
	touch $@

db/table/osm: data/planet-latest-updated.osm.pbf | db/table
	psql -c "drop table if exists osm;"
	osmium export -c osmium.config.json -f pg data/planet-latest.osm.pbf  -v --progress | psql -1 -c 'create table osm(geog geography, osm_type text, osm_id bigint, way_nodes bigint[], tags jsonb);copy osm from stdin freeze;'
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

db/function/isochrone: db/table/osm_road_segments db/index/osm_road_segments_osm_id_node_from_node_to_seg_geom_idx db/index/osm_road_segments_seg_geom_idx db/function/ST_ClosestPointWithZ
	psql -f functions/isochrone.sql
	touch $@
