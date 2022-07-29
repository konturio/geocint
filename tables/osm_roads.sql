drop table if exists osm_roads;
create table osm_roads as (
    select
        osm_id,
        osm_type,
        ts,
        geog::geometry as geom,
        way_nodes,
        tags ->> 'name' as name,
        case
            when
                    tags @> '{"foot":"yes"}' or
                    tags @> '{"highway":"residential"}' or
                    tags @> '{"highway":"service"}' or
                    tags @> '{"highway":"track"}' or
                    tags @> '{"highway":"living_street"}' or
                    tags @> '{"highway":"pedestrian"}' or
                    tags @> '{"highway":"footway"}' or
                    tags @> '{"sidewalk":"left"}' or
                    tags @> '{"sidewalk":"right"}' or
                    tags @> '{"sidewalk":"both"}' or
                    tags @> '{"sidewalk":"yes"}'
                then
                1.4 -- 5 km/hr
            when
                    tags @> '{"highway":"steps"}' or
                    tags @> '{"highway":"cycleway"}'
                then
                1.0 -- 3.6 km/hr
            when
                    tags @> '{"foot":"no"}' or
                    tags @> '{"access":"no"}' or
                    tags @> '{"highway":"motorway"}' or
                    tags @> '{"highway":"motorway_link"}' or
                    tags @> '{"highway":"trunk"}' or
                    tags @> '{"highway":"trunk_link"}' or
                    tags @> '{"highway":"primary"}' or
                    tags @> '{"highway":"primary_link"}' or
                    tags @> '{"highway":"secondary"}' or
                    tags @> '{"highway":"secondary_link"}' or
                    tags @> '{"tunnel":"yes"}'
                then null
            else
                1.4 -- 5 km/hr
        end as walk_speed,
        case
            when
                    tags @> '{"access":"no"}' or
                    tags @> '{"highway":"pedestrian"}' or
                    tags @> '{"highway":"footway"}' or
                    tags @> '{"highway":"steps"}' or
                    tags @> '{"highway":"cycleway"}'
                then null
            else
                11.11 -- 40 km/hr
        end as drive_speed
    from
        osm
    where
          tags ? 'highway'
      and osm_type = 'way'
      and ST_GeometryType(geog::geometry) = 'ST_LineString'
      and not tags @> '{"highway":"proposed"}' -- count only existed roads
      and not tags @> '{"highway":"dummy"}' -- special case
      and ST_Y(ST_StartPoint(geog::geometry)) > -60   -- do not count roads in Antarctic
    order by ts
);

-- Create index on ts to use further for cleaning facebook roads
create index on osm_roads using brin(ts);
