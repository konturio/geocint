drop table if exists belarus_boundary;
create table belarus_boundary as (
    select ST_AsGeoJSON(belarus)
    from (select geog::geometry as polygon
          from osm
          where osm_type = 'relation'
            and osm_id = 59065
            and tags @>
                '{"boundary":"administrative"}'
         ) belarus
);