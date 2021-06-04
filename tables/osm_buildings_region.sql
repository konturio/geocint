drop table if exists :tbl_name_buildings;
create table :tbl_name_buildings as (
    select building,
           street,
           hno,
           levels,
           height,
           use,
           "name",
           geom
    from osm_buildings b
    where ST_Dimension(geom) != 1
      and ST_DWithin(
            b.geom, (
                select geom
                from osm_admin_boundaries
                where osm_id = :osm_id
                and osm_type = 'relation'),
            0)
);

drop table if exists :tbl_name_region;
create table :tbl_name_region as(
    select osm_id as id,
           name,
           geom
           from osm_admin_boundaries
                where osm_id = :osm_id
                  and osm_type = 'relation');

