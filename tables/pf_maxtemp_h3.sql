-- collect all date into one table
drop table if exists pf_maxtemp_all;
create table pf_maxtemp_all as (select di.days_maxtemp_over_32c_1c::float,
                                       di.days_maxtemp_over_32c_2c::float,
                                       ni.days_mintemp_above_25c_1c::float,
                                       ni.days_mintemp_above_25c_2c::float,
                                       bi.days_maxwetbulb_over_32c_1c::float,
                                       bi.days_maxwetbulb_over_32c_2c::float,
                                       di.geom
                                from pf_days_maxtemp_in as di
                                         join pf_nights_maxtemp_in as ni on ST_Intersects(di.geom, ni.geom)
                                         join pf_days_wet_bulb_in as bi on ST_Intersects(di.geom, bi.geom)
);

create index on pf_maxtemp_all using gist (geom);


-- generate H3 level 4 grid covering at least one point in 22*22 km original grid
drop table if exists pf_maxtemp_h3_r4;
create table pf_maxtemp_h3_r4 as (select distinct h3_geo_to_h3(geom, 4) as h3
                                  from pf_maxtemp_all);

-- generate H3 level 8 grid with data from original source
drop table if exists pf_maxtemp_h3_r8;
create table pf_maxtemp_h3_r8 as (select distinct h3_to_children(h3, 8)           as h3,
                                                  h3_to_children(h3, 8)::geometry as geom
                                  from pf_maxtemp_h3_r4);
create index on pf_maxtemp_h3_r8 using gist (geom);


drop table if exists pf_maxtemp_idw_h3;
create table pf_maxtemp_idw_h3
(
    h3                          h3index,
    resolution                  float,
    days_maxtemp_over_32c_1c    float,
    days_maxtemp_over_32c_2c    float,
    days_mintemp_above_25c_1c   float,
    days_mintemp_above_25c_2c   float,
    days_maxwetbulb_over_32c_1c float,
    days_maxwetbulb_over_32c_2c float
);


with nearest_points as (
    select h3,
           dist,
           days_maxtemp_over_32c_1c    as z1,
           days_maxtemp_over_32c_2c    as z2,
           days_mintemp_above_25c_1c   as z3,
           days_mintemp_above_25c_2c   as z4,
           days_maxwetbulb_over_32c_1c as z5,
           days_maxwetbulb_over_32c_2c as z6
    from pf_maxtemp_all
             CROSS JOIN LATERAL (
        SELECT h3,
               pf_maxtemp_h3_r8.geom                                   as h3_geom,
               ST_Distance(pf_maxtemp_h3_r8.geom::geography, pf_maxtemp_all.geom::geography) AS dist
        FROM pf_maxtemp_h3_r8
        ORDER BY pf_maxtemp_all.geom <-> pf_maxtemp_h3_r8.geom
        LIMIT 4
        ) grid)
insert
into pf_maxtemp_idw_h3 (h3, resolution,
                        days_maxtemp_over_32c_1c, days_maxtemp_over_32c_2c,
                        days_mintemp_above_25c_1c, days_mintemp_above_25c_2c,
                        days_maxwetbulb_over_32c_1c, days_maxwetbulb_over_32c_2c)
select h3,
       8::integer,
       (SUM(z1 / dist) / SUM(1 / dist)) as d32_1,
       (SUM(z2 / dist) / SUM(1 / dist)) as d32_2,
       (SUM(z3 / dist) / SUM(1 / dist)) as n25_1,
       (SUM(z4 / dist) / SUM(1 / dist)) as n25_2,
       (SUM(z5 / dist) / SUM(1 / dist)) as b32_1,
       (SUM(z6 / dist) / SUM(1 / dist)) as b32_2
from nearest_points
group by h3;

drop table if exists pf_maxtemp_h3_r8;

call generate_overviews('pf_maxtemp_idw_h3', '{days_maxtemp_over_32c_1c, days_maxtemp_over_32c_2c, days_mintemp_above_25c_1c, days_mintemp_above_25c_2c, days_maxwetbulb_over_32c_1c, days_maxwetbulb_over_32c_2c}'::text[], '{avg, avg, avg, avg, avg, avg}'::text[], 8);

-- The output table contains a lot of interpolated values that are all-zero.
-- Trim them out, we don't need to output cells for them.
delete
from pf_maxtemp_idw_h3
where days_maxtemp_over_32c_1c = 0
  and days_maxtemp_over_32c_2c = 0
  and days_mintemp_above_25c_1c = 0
  and days_mintemp_above_25c_2c = 0
  and days_maxwetbulb_over_32c_1c = 0
  and days_maxwetbulb_over_32c_2c = 0;

drop table if exists pf_maxtemp_h3;
create table pf_maxtemp_h3 as
    (select pf.h3,
            pf.resolution,
            days_maxtemp_over_32c_1c,
            days_mintemp_above_25c_1c,
            (days_maxtemp_over_32c_1c * population) as mandays_maxtemp_over_32c_1c,
            days_maxtemp_over_32c_2c,
            days_mintemp_above_25c_2c,
            days_maxwetbulb_over_32c_1c,
            days_maxwetbulb_over_32c_2c
     from pf_maxtemp_idw_h3 pf
              left join kontur_population_h3 kp on pf.h3 = kp.h3);

drop table if exists pf_maxtemp_idw_h3;