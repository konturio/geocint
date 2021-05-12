drop table if exists osm_unpopulated;
create table osm_unpopulated as (
    select
        osm_type,
        osm_id,
        tags ->> 'natural' as natural,
        tags ->> 'landuse' as landuse,
        tags ->> 'population' as population,
        tags ->> 'highway' as highway,
        ST_MakeValid(ST_Transform(ST_ClipByBox2D(geog::geometry, ST_Transform(ST_TileEnvelope(0,0,0),4326)), 3857)) as geom
    from
        osm
    where
        (tags?'natural' or tags?'landuse' or tags?'population' or tags?'highway')
	and
	(
	        (tags ->> 'natural') in ('wood', 'glacier', 'wetland', 'sand')
	        or (tags ->> 'landuse') in ('forest', 'quarry', 'farmland')
	        or tags @> '{"population":"0"}'
	        or (tags ->> 'highway') in ('motorway','trunk', 'primary', 'secondary', 'tertiary')
	)
    order by _ST_SortableHash(geog::geometry)
);

create index on osm_unpopulated using gist (geom);
