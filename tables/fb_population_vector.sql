set client_min_messages to warning;
drop table if exists fb_population_vector;
create table fb_population_vector as (
  select
    centroid,
    geom,
    r.val as population
  from
    (
      select
        ST_Transform(ST_SetSRID(geom, 4326), 3857)              as geom,
        ST_Transform(ST_SetSRID(ST_Centroid(geom), 4326), 3857) as centroid,
        val
      from
        (
          select *
          from
            (select (ST_PixelAsPolygons(rast)).* from fb_population_raster) z
          where
            val > 0
        ) z
    ) r
);

create index on fb_population_vector using gist (geom);
