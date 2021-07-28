drop table if exists ghs_globe_gaps;
create table ghs_globe_gaps with (parallel_workers = 32) as
select rid, gaps "geom"
from ghs_globe_population_raster r,
     ST_MapAlgebra(
             r.rast,
             1,
             '1BB',
             'CASE WHEN [rast1.val] > 0 AND [rast1.val] < 1 THEN 1 ELSE 0 END',
             0
         ) gaps_mask,
     ST_MakeValid(ST_Transform(ST_Polygon(gaps_mask, 1), 4326)) "gaps"
where gaps_mask is not null
  and gaps is not null;

create index on ghs_globe_gaps using gist (geom);

drop table if exists ghs_globe_population_boundary;
create table ghs_globe_population_boundary with (parallel_workers = 32) as
with countries as (
    select gid,
           gid_0 "iso",
           name_0 "name",
           area,
           ST_Subdivide(geom_4326) "geom"
    from gadm_countries_boundary,
         ST_Transform(geom, 4326) "geom_4326",
         ST_Area(geom_4326) "area"
),
     ghs_has_gaps as (
         select c.iso,
                sum(ST_Area(ST_Intersection(g.geom, c.geom))) / c.area > 0.1 "has_gaps"
         from countries c
                  left outer join
              ghs_globe_gaps g
              on (ST_Intersects(c.geom, g.geom))
         group by c.iso, c.area)
select c.*
from countries c
where exists(select from ghs_has_gaps g where c.iso = g.iso and not has_gaps);

drop table ghs_globe_gaps;