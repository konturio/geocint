drop table if exists osm_quality_bivariate_tiles;
create table osm_quality_bivariate_tiles as (
    select
        z,
        x,
        y,
        --ST_Intersection(ST_Union(geom), TileBBOX(z, x, y)) as geom, -- slow and unnecessary, will be clipped anyway
        ST_Simplify(ST_Union(geom), 0) as geom,
        bivariate_class
    from
            (select 8::integer as z) as zoom,
            generate_series(0, (2 ^ z)::integer) x,
            generate_series(0, (2 ^ z)::integer) y,
            lateral (select * from osm_quality_bivariate_grid_1000 where geom && TileBBOX(z, x, y)) g
    group by z, x, y, bivariate_class
);
create index on osm_quality_bivariate_tiles using gist(geom);
