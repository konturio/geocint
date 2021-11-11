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

-- generate H3 level 7 grid with data from original source. h8 takes more than 8 hours
drop table if exists pf_maxtemp_h3_r7;
create table pf_maxtemp_h3_r7 as (select distinct h3_to_children(h3, 7)           as h3,
                                                  h3_to_children(h3, 7)::geometry as geom
                                  from pf_maxtemp_h3_r4);
create index on pf_maxtemp_h3_r7 using gist (geom);


drop table if exists pf_maxtemp_idw_h3;
create table pf_maxtemp_idw_h3
as
with nearest_points as (
    select h3,
           dist,
           days_maxtemp_over_32c_1c,
           days_maxtemp_over_32c_2c,
           days_mintemp_above_25c_1c,
           days_mintemp_above_25c_2c,
           days_maxwetbulb_over_32c_1c,
           days_maxwetbulb_over_32c_2c
    from pf_maxtemp_h3_r7
             cross join lateral (
        select days_maxtemp_over_32c_1c,
               days_maxtemp_over_32c_2c,
               days_mintemp_above_25c_1c,
               days_mintemp_above_25c_2c,
               days_maxwetbulb_over_32c_1c,
               days_maxwetbulb_over_32c_2c,
               ST_Distance(pf_maxtemp_h3_r7.geom::geography, pf_maxtemp_all.geom::geography) AS dist
        from pf_maxtemp_all
        order by pf_maxtemp_all.geom <-> pf_maxtemp_h3_r7.geom
        limit 4
        ) grid)

select h3,
       7::integer as resolution,
       (SUM(days_maxtemp_over_32c_1c / dist) / SUM(1 / dist)) as days_maxtemp_over_32c_1c,
       (SUM(days_maxtemp_over_32c_2c / dist) / SUM(1 / dist)) as days_maxtemp_over_32c_2c,
       (SUM(days_mintemp_above_25c_1c / dist) / SUM(1 / dist)) as days_mintemp_above_25c_1c,
       (SUM(days_mintemp_above_25c_2c / dist) / SUM(1 / dist)) as days_mintemp_above_25c_2c,
       (SUM(days_maxwetbulb_over_32c_1c / dist) / SUM(1 / dist)) as days_maxwetbulb_over_32c_1c,
       (SUM(days_maxwetbulb_over_32c_2c / dist) / SUM(1 / dist)) as days_maxwetbulb_over_32c_2c
from nearest_points
group by h3;

drop table if exists pf_maxtemp_h3_r7;

insert into pf_maxtemp_idw_h3 (h3, resolution,
                               days_maxtemp_over_32c_1c, days_maxtemp_over_32c_2c,
                               days_mintemp_above_25c_1c, days_mintemp_above_25c_2c,
                               days_maxwetbulb_over_32c_1c, days_maxwetbulb_over_32c_2c)
select h3_to_children(h3, 8) as h3,
       8::integer            as resolution,
       days_maxtemp_over_32c_1c,
       days_maxtemp_over_32c_2c,
       days_mintemp_above_25c_1c,
       days_mintemp_above_25c_2c,
       days_maxwetbulb_over_32c_1c,
       days_maxwetbulb_over_32c_2c
from pf_maxtemp_idw_h3;

call generate_overviews('pf_maxtemp_idw_h3', '{days_maxtemp_over_32c_1c, days_maxtemp_over_32c_2c, days_mintemp_above_25c_1c, days_mintemp_above_25c_2c, days_maxwetbulb_over_32c_1c, days_maxwetbulb_over_32c_2c}'::text[], '{avg, avg, avg, avg, avg, avg}'::text[], 7);

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
