all: _db/function/isochrone

data:
	mkdir $@

_db:
	mkdir $@

_db/function: | _db
	mkdir $@

_db/table: | _db
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

_db/table/osm: data/planet-latest-updated.osm.pbf | _db/table
	psql -f "drop table if exists osm;"
	osmium export -c osmium.config.json -f pg data/planet-latest.osm.pbf  -v --progress | psql -1 -c 'create table osm(geog geography, osm_type text, osm_id bigint, way_nodes bigint[], tags jsonb);copy osm from stdin freeze;'
	touch $@

_db/function/osm_way_nodes_to_segments: | _db/function
	psql -f functions/osm_way_nodes_to_segments.sql
	touch $@

_db/function/ST_ClosestPointWithZ: | _db/function
	psql -f functions/ST_ClosestPointWithZ.sql
	touch $@

_db/table/osm_road_segments: _db/table/osm _db/function/ST_ClosestPointWithZ _db/function/osm_way_nodes_to_segments
	psql -f tables/osm_road_segments.sql
	touch $@

_db/index/osm_tags_idx: db/table/osm | _db/index
	psql -c "create index osm_tags_idx on osm using gin (tags);"
	touch $@

_db/index/osm_geog_idx: db/table/osm | _db/index
	psql -c "create index osm_geog_idx on osm using gist (geog);"
	touch $@

_db/index/osm_road_segments_osm_id_node_from_node_to_seg_geom_idx: db/table/osm_road_segments | _db/index
	psql -c "create index osm_road_segments_osm_id_node_from_node_to_seg_geom_idx on osm_road_segments (osm_id, node_from, node_to, seg_geom);
	touch $@

_db/index/osm_road_segments_seg_geom_idx: db/table/osm_road_segments | _db/index
	psql -c "create index osm_road_segments_seg_geom_idx on osm_road_segments using gist (seg_geom);
	touch $@

_db/function/isochrone: _db/table/osm_road_segments _db/index/osm_road_segments_osm_id_node_from_node_to_seg_geom_idx _db/index/osm_road_segments_seg_geom_idx _db/function/ST_ClosestPointWithZ
	psql -f functions/isochrone.sql
	touch $@