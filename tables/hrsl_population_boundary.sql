drop table if exists hrsl_population_boundary;
create table hrsl_population_boundary as (
    with countries as (
        select tags ->> 'ISO3166-1:alpha3' "iso",
               name,
               ST_Area(geom)               "area",
               geom                        "geom"
        from kontur_boundaries
        where admin_level = '2'
          -- remove countries with hrsl population worse than ghs
          and tags ->> 'ISO3166-1:alpha3' not in
              ('BGR', 'COL', 'DOM', 'ERI', 'GRC', 'IRL', 'MDG', 'NPL', 'ZWE')
    ),
         subdivided_country as (
             select iso, name, area, ST_Subdivide(geom) "geom"
             from countries
         ),
         subdivided_boundary as (
             select ST_Subdivide(ST_Boundary(geom)) "geom"
             from countries
         ),
         boundary_rasters as (
             select distinct on (r.rid) r.rid, r.rast
             from hrsl_population_raster r,
                  subdivided_boundary c
             where ST_Intersects(c.geom, ST_ConvexHull(r.rast))
             order by r.rid
         ),
         rasters_in_countries as (
             select distinct on (c.iso, r.rid) c.iso, c.area, r.rid, r.rast
             from subdivided_country c,
                  hrsl_population_raster r
             where ST_Intersects(ST_ConvexHull(r.rast), c.geom)
             order by c.iso, r.rid
         ),
         covered_by_rasters as (
             select r.iso, sum(ST_Area(ST_ConvexHull(r.rast))) / area "coverage"
             from rasters_in_countries r
             where r.rid not in (select b.rid from boundary_rasters b)
             group by r.iso, r.area
         ),
         covered_by_pixels as (
             select r.iso,
                    sum(ST_Area(p.geom)) / r.area "coverage"
             from rasters_in_countries r,
                  ST_PixelAsPolygons(r.rast) p,
                  countries c
             where r.iso not in (select iso from covered_by_rasters where coverage > 0.01)
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

create index on hrsl_population_boundary using gist (geom);
