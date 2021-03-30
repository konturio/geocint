drop table if exists osm_buildings_japan;
create table osm_buildings_japan as (
    select building,
           street,
           hno,
           (select array_to_string(array_agg(a), ', ')
            from unnest(
                         case
                             when levels ~* '[0-9]*;[0-9]*'
                                 then string_to_array(levels, '; ')
                             when levels ~* '[0-9]*,[0-9]*'
                                 then string_to_array(levels, ', ')
                             when levels ~* '-?[0-9]+\.*[0-9]*'
                                 then string_to_array(substring(levels from '-?[0-9]+\.*[0-9]*'), '')
                             when levels ~* '-?[０-９]+\.*[０-９]*'
                                 then string_to_array(substring(levels from '-?[０-９]+\.*[０-９]*'), '')
                             end)
                     as t(a)) as levels,
           height,
           use,
           "name",
           geom
    from osm_buildings b
    where ST_Dimension(geom) != 1
      and ST_DWithin(
            b.geom, (
                select geog::geometry
                from osm
                where tags @> '{"name:en":"Japan", "boundary":"administrative"}'
                  and osm_id = 382313
                  and osm_type = 'relation'),
            0)
);
