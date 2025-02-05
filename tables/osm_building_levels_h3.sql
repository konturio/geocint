drop table if exists osm_buildings_parts_in;
create table osm_buildings_parts_in as (
    select geog::geometry                            as geom,
           parse_integer(tags ->> 'building:levels') as levels,
           parse_float(tags ->> 'height')            as height
    from osm o
    where tags ? 'building:part'
          and (tags ? 'building:levels' or tags ? 'height')
);

drop table if exists osm_building_levels_h3;
create table osm_building_levels_h3 as (
    select h3,
           coalesce(max(levels), ceil(max(height)/3), null) as max_levels,
           coalesce(avg(levels), ceil(avg(height)/3), null) as avg_levels,
           8 as resolution
    from (select h3_lat_lng_to_cell(ST_PointOnSurface(geom)::point, 8) as h3,
                 levels,
                 height
          from osm_buildings
          where (levels < 165 and levels >= 0) or (height < 840 and levels is null and height >= 0)
          union all
          select h3_lat_lng_to_cell(ST_PointOnSurface(geom)::point, 8) as h3,
                  levels,
                  height
          from osm_buildings_parts_in
          where (levels < 165 and levels >= 0) or (height < 840 and levels is null and height >= 0))
    group by 1
);

drop table if exists osm_buildings_parts_in;

call generate_overviews('osm_building_levels_h3', '{max_levels,avg_levels}'::text[], '{max,avg}'::text[], 8);
