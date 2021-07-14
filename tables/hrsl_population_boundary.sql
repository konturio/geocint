drop table if exists hrsl_population_boundary;

create table hrsl_population_boundary as (
    with countries as (
        select gid,
               gid_0 "iso",
               name_0 "name",
               perimeter "perimeter",
               area "area",
               ST_Subdivide(geom_4326) "geom"
        from gadm_countries_boundary,
             ST_Transform(geom, 4326) "geom_4326",
             ST_Perimeter(geom_4326) "perimeter",
             ST_Area(geom_4326) "area"
    ),
    covered_by_rasters as (
        select c.iso,
               c.name,
               /*
               "exacly_covered" is designed to improve query speed. if the number of intersected rasters with country
               multiplied by the minimum raster size (width or height) is greater than the perimeter of the entire
               country - the country fully contains at least one raster.

               coefficient "0.75" is introduced for cases where the country has no coverage, but fully contains
               several raster bounds.
               */
               c.perimeter < count(r) * least(
                   min(ST_PixelWidth(r.rast) * ST_Width(r.rast)),
                   min(ST_PixelHeight(r.rast) * ST_Height(r.rast))
               ) * 0.75 "exacly_covered"
        from countries c,
             hrsl_population_raster r
        where ST_Intersects(c.geom, ST_ConvexHull(r.rast))
        group by c.iso, c.name, c.perimeter
    ),
    covered_by_pixels as (
        select c.iso,
               c.name,
               bool_or(
                   exists(
                       select from st_pixelascentroids(r.rast, 1) p
                       where ST_Intersects(c.geom, p.geom)
                   )
               ) "pixel_within",
               sum(ST_Area(ST_Intersection(ST_ConvexHull(r.rast), c.geom))) / c.area "coverage"
        from countries c,
             hrsl_population_raster r
        where ST_Intersects(c.geom, ST_ConvexHull(r.rast))
        and c.iso in (select cr.iso from covered_by_rasters cr where not cr.exacly_covered)
        group by c.iso, c.name, c.area
    )
    select gid, iso, name, ST_Transform(geom, 3857) "geom"
    from countries
    where iso in (
        select iso from covered_by_rasters where exacly_covered
        union all
        select iso from covered_by_pixels where pixel_within and coverage > 0.1
    )
);

create index hrsl_population_boundary_geom_idx on hrsl_population_boundary using gist(geom);
