drop table if exists z8_grid;
create table z8_grid as (
    select
        z,
        x,
        y,
        TileBBOX(z, x, y) as geom
    from
            (select 8::integer as z) as zoom,
            generate_series(0, (2 ^ z)::integer) as x,
            generate_series(0, (2 ^ z)::integer) as y
);

drop table if exists osm_quality_bivariate_tiles;
create table osm_quality_bivariate_tiles as (
    select
        z,
        x,
        y,
        ST_Intersection(ST_Simplify(ST_Union(q.geom), 0), g.geom) as geom,
        bivariate_class
    from
        z8_grid g
            join osm_quality_bivariate_grid_1000 q on g.geom && q.geom and g.geom && q.geom
    group by z, x, y, bivariate_class, g.geom
);
create index on osm_quality_bivariate_tiles using gist (geom);
