drop table if exists ghs_globe_population_vector;
create table ghs_globe_population_vector as (
  select
    centroid,
    geom,
    r.val as people
  from
    (
      select
        ST_Transform(ST_SetSRID(geom, 54009), 3857)              as geom,
        ST_Transform(ST_SetSRID(ST_Centroid(geom), 54009), 3857) as centroid,
        val
      from
        (
          select *
          from
            (select (ST_PixelAsPolygons(rast)).* from ghs_globe_population_raster) z
          where
            val > 0
        ) z
    ) r
    where
        ST_IsValid(geom)
);

create index on ghs_globe_population_vector using gist (geom);
