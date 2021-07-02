drop table if exists hrsl_population_boundary;
create table hrsl_population_boundary as (
    select gid, gid_0 "iso", name_0 "name", ST_Subdivide(geom) AS "geom"
    from gadm_countries_boundary g,
         lateral ST_Transform(g.geom, 4326) "geom_4326"
    where exists(
                  select
                  from hrsl_population_raster r
                  where ST_Intersects(r.rast, geom_4326, 1)
                    and exists(
                          select
                          from ST_PixelAsCentroids(r.rast, 1) p
                          where ST_Intersects(geom_4326, p.geom)
                      )
              )
);
