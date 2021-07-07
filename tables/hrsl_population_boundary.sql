drop table if exists hrsl_population_raster_coverage;
create table hrsl_population_raster_coverage as (
    select  st_subdivide((st_dump(st_unaryunion(c.geom))).geom) as geom
    from (
        select unnest(st_clusterintersecting(
             st_snaptogrid(st_envelope(r.rast), 1. / 3600)
            )) "geom"
        from hrsl_population_raster r
    ) "c"
);

drop index if exists hrsl_population_raster_coverage_geom_idx;
create index hrsl_population_raster_coverage_geom_idx on hrsl_population_raster_coverage using gist(geom);

drop table if exists hrsl_population_boundary;
create table hrsl_population_boundary as (
    with countries as (
        select gid, gid_0, name_0, st_subdivide(geom) "geom" from gadm_countries_boundary
    ),
    data as (
        select gid_0,
               name_0,
               st_area(b_geom) "boundary_area",
               sum(coverage_area) "coverage_area",
               sum((coverage_area = st_area(c.geom))::integer) "inner_coverage"
        from countries g,
             hrsl_population_raster_coverage c,
             lateral st_transform(g.geom, 4326) b_geom,
             lateral st_area(st_intersection(c.geom, b_geom)) "coverage_area"
        where st_intersects(b_geom, c.geom)
        group by g.gid_0, g.name_0, b_geom),
    stats as (
        select gid_0, name_0,
               sum(coverage_area) / sum(boundary_area) "coverage", -- ratio of raster coverage to country boundary
               sum("inner_coverage") "inner_coverage" -- number of raster areas that are entirely within country boundary
        from data
    	group by gid_0, name_0
    )
    select b.gid, b.gid_0 "iso", b.name_0 "name", st_subdivide(st_transform(b.geom, 4326)) AS "geom"
    from gadm_countries_boundary b
    where b.gid_0 in (
        select s.gid_0
        from stats s
        where s.coverage > 0.5
           or (s.coverage > 0.1 and s.inner_coverage > 0)
    )
);

drop table if exists hrsl_population_raster_coverage;
