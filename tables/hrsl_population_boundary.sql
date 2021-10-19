-- create a copy of gadm_boundaries table with geometry in EPSG:4326 to use the index in when creating hrsl_population_boundary table.
drop table if exists ykyslomed.gadm_boundaries_4326_in;
create table ykyslomed.gadm_boundaries_4326_in as (
    select gid_0                         "iso",
           name_0                        "name",
           ST_Area(geom_4326::geography) "area",
           geom_4326                     "geom"
    from gadm_countries_boundary,
         ST_Transform(geom, 4326) "geom_4326"
         -- remove countries with HRSL population worse than GHS
    where gid_0 not in ('BGR', 'COL', 'DOM', 'ERI', 'GRC', 'IRL', 'MDG', 'NPL', 'ZWE')
);

create index on ykyslomed.gadm_boundaries_4326_in using gist (geom);

drop table if exists ykyslomed.hrsl_population_boundary;
create table ykyslomed.hrsl_population_boundary as (
    with subdivided_country as (
        select iso, name, area, ST_Subdivide(geom) "geom"
        from ykyslomed.gadm_boundaries_4326_in
    ),
         subdivided_boundary as (
             select ST_Subdivide(ST_Boundary(geom)) "geom"
             from ykyslomed.gadm_boundaries_4326_in
         ),
         -- select all rasters lying on the border of countries.
         boundary_rasters as (
             select distinct on (r.rid) r.rid, r.rast
             from hrsl_population_raster r,
                  subdivided_boundary c
             where ST_Intersects(c.geom, ST_ConvexHull(r.rast))
             order by r.rid
         ),
         -- select rasters covering each country.
         rasters_in_countries as (
             select distinct on (c.iso, r.rid) c.iso, c.area, r.rid, r.rast
             from subdivided_country c,
                  hrsl_population_raster r
             where ST_Intersects(ST_ConvexHull(r.rast), c.geom)
             order by c.iso, r.rid
         ),
         -- calculate the coverage of rasters that are entirely within each country.
         covered_by_rasters as (
             select r.iso, sum(ST_Area(ST_ConvexHull(r.rast)::geography)) / area "coverage"
             from rasters_in_countries r
             where r.rid not in (select b.rid from boundary_rasters b)
             group by r.iso, r.area
         ),
         -- calculate the coverage of pixels in countries excluding covered_by_rasters with coverage more than 1%.
         covered_by_pixels as (
             select r.iso,
                    sum(ST_Area(p.geom::geography)) / r.area "coverage"
             from rasters_in_countries r,
                  ST_PixelAsPolygons(r.rast) p,
                  ykyslomed.gadm_boundaries_4326_in c
             where r.iso in (select iso from covered_by_rasters where coverage <= 0.01)
               and r.iso = c.iso
               and ST_Intersects(c.geom, ST_Centroid(p.geom))
             group by r.iso, r.area
         )
    select iso, name, geom
    from subdivided_country c
    where c.iso in (
        select iso
        from covered_by_rasters
        where coverage > 0.01
        union all
        select iso
        from covered_by_pixels
        where coverage > 0.01
    )
);

create index on ykyslomed.hrsl_population_boundary using gist (geom);

drop table ykyslomed.gadm_boundaries_4326_in;
