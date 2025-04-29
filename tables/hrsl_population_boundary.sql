-- create a copy of gadm_boundaries table with geometry in EPSG:4326 to use the index in when creating hrsl_population_boundary table.
drop table if exists gadm_boundaries_4326_in;
create table gadm_boundaries_4326_in as (
    select gid_0                         "iso",
           name_0                        "name",
           ST_Area(geom_4326::geography) "area",
           geom_4326                     "geom"
    from gadm_countries_boundary,
         ST_Transform(geom, 4326) "geom_4326"
         -- remove countries with HRSL population worse than GHS
    where gid_0 not in ('BGR', 'COL', 'DOM', 'ERI', 'GRC', 'IRL', 'MDG', 'NPL', 'ZWE', 'CHL')
);

create index on gadm_boundaries_4326_in using gist (geom);

drop table if exists gadm_subdivided_country;
create table gadm_subdivided_country as (
    select iso, 
           name, 
           area, 
           ST_Subdivide(geom) as geom
    from gadm_boundaries_4326_in
);

create index on gadm_subdivided_country using gist (geom);

drop table if exists gadm_subdivided_boundary;
create table gadm_subdivided_boundary as (
    select ST_Subdivide(ST_Boundary(geom)) as geom
    from gadm_boundaries_4326_in
);

create index on gadm_subdivided_boundary using gist (geom);

-- select rasters covering each country.
drop table if exists hrsl_rasters_in_countries;
create table hrsl_rasters_in_countries as (
             select distinct on (c.iso, r.rid) c.iso, c.area, r.rid, r.rast
             from gadm_subdivided_country c,
                  hrsl_population_raster r
             where ST_Intersects(ST_ConvexHull(r.rast), c.geom)
             order by c.iso, r.rid
);

create index on hrsl_rasters_in_countries using btree (rid);

-- select all rasters lying on the border of countries.
drop table if exists hrsl_boundary_rasters;
create table hrsl_boundary_rasters as (  
    select distinct r.rid
    from hrsl_population_raster r,
         gadm_subdivided_boundary c
    where ST_Intersects(c.geom, ST_ConvexHull(r.rast))
);

create index on hrsl_boundary_rasters(rid);

-- calculate the coverage of rasters that are entirely within each country.
drop table if exists hrsl_covered_by_rasters;
create table hrsl_covered_by_rasters as ( 
    select r.iso, 
           sum(ST_Area(ST_ConvexHull(r.rast)::geography)) / area as coverage
    from hrsl_rasters_in_countries r
    where r.rid not in (select b.rid from hrsl_boundary_rasters b)
    group by r.iso, r.area
);

-- calculate the coverage of pixels in countries excluding covered_by_rasters with coverage more than 1%.
drop table if exists hrsl_covered_by_pixels;
create table hrsl_covered_by_pixels as (
    select r.iso,
           sum(ST_Area(p.geom::geography)) / r.area "coverage"
    from hrsl_rasters_in_countries r,
         ST_PixelAsPolygons(r.rast) p,
         gadm_boundaries_4326_in c
    where r.iso in (select iso from hrsl_covered_by_rasters where coverage <= 0.01)
          and r.iso = c.iso
          and ST_Intersects(c.geom, ST_Centroid(p.geom))
    group by r.iso, r.area
);

drop table if exists hrsl_population_boundary;
create table hrsl_population_boundary as (
    select iso, name, geom
    from gadm_subdivided_country c
    where c.iso in (
        select iso
        from hrsl_covered_by_rasters
        where coverage > 0.01
        union all
        select iso
        from hrsl_covered_by_pixels
        where coverage > 0.01
    )
);

create index on hrsl_population_boundary using gist (geom);

drop table gadm_boundaries_4326_in;
drop table if exists gadm_subdivided_country;
drop table if exists gadm_subdivided_boundary;
drop table if exists hrsl_rasters_in_countries;
drop table if exists hrsl_boundary_rasters;
drop table if exists hrsl_covered_by_pixels;
