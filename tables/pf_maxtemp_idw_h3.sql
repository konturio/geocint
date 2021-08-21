drop table if exists pf_maxtemp_all;
create table pf_maxtemp_all as (select di.days_maxtemp_over_32c_1c,
                                       di.days_maxtemp_over_32c_2c,
                                       ni.days_mintemp_above_25c_1c,
                                       ni.days_mintemp_above_25c_2c,
                                       bi.days_maxwetbulb_over_32c_1c,
                                       bi.days_maxwetbulb_over_32c_2c,
                                       di.geom
                                from pf_days_maxtemp_in as di
                                         join pf_nights_maxtemp_in as ni on ST_Intersects(di.geom, ni.geom)
                                         join pf_days_wet_bulb_in as bi on ST_Intersects(di.geom, bi.geom)
);

create index on pf_maxtemp_all using gist (geom);

drop table if exists pf_days_maxtemp_in;
drop table if exists pf_nights_maxtemp_in;
drop table if exists pf_days_wet_bulb_in;

drop table if exists pf_maxtemp_h3_r4;
create table pf_maxtemp_h3_r4 as (select distinct h3_geo_to_h3(geom, 4) as h3
                                  from pf_maxtemp_all);

drop table if exists pf_maxtemp_h3_r5;
create table pf_maxtemp_h3_r5 as (select distinct h3_to_children(h3)           as h3,
                                                  h3_to_children(h3)::geometry as geom
                                  from pf_maxtemp_h3_r4);
create index on pf_maxtemp_h3_r5 using gist (geom);


drop table if exists pf_maxtemp_idw_h3;
create table pf_maxtemp_idw_h3
(
    h3                          h3index,
    resolution                  integer,
    days_maxtemp_over_32c_1c    integer,
    days_maxtemp_over_32c_2c    integer,
    days_mintemp_above_25c_1c   integer,
    days_mintemp_above_25c_2c   integer,
    days_maxwetbulb_over_32c_1c integer,
    days_maxwetbulb_over_32c_2c integer
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
               pf_maxtemp_h3_r5.geom                                   as h3_geom,
               ST_Distance(pf_maxtemp_h3_r5.geom::geography, pf_maxtemp_all.geom::geography) AS dist
        FROM pf_maxtemp_h3_r5
        ORDER BY pf_maxtemp_all.geom <-> pf_maxtemp_h3_r5.geom
        LIMIT 4
        ) grid)
insert
into pf_maxtemp_idw_h3 (h3, resolution,
                        days_maxtemp_over_32c_1c, days_maxtemp_over_32c_2c,
                        days_mintemp_above_25c_1c, days_mintemp_above_25c_2c,
                        days_maxwetbulb_over_32c_1c, days_maxwetbulb_over_32c_2c)
select h3,
       5::integer,
       floor(SUM(z1 / dist) / SUM(1 / dist)) as d32_1,
       floor(SUM(z2 / dist) / SUM(1 / dist)) as d32_2,
       floor(SUM(z3 / dist) / SUM(1 / dist)) as n25_1,
       floor(SUM(z4 / dist) / SUM(1 / dist)) as n25_2,
       floor(SUM(z5 / dist) / SUM(1 / dist)) as b32_1,
       floor(SUM(z6 / dist) / SUM(1 / dist)) as b32_2
from nearest_points
group by h3;

drop table if exists pf_maxtemp_h3_r5;

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


-- generate overviews [8-6]
do
$$
    declare
        res integer;
    begin
        res = 8;
        while res > 6
            loop
                insert into pf_maxtemp_idw_h3 (h3,
                                               resolution,
                                               days_maxtemp_over_32c_1c,
                                               days_maxtemp_over_32c_2c,
                                               days_mintemp_above_25c_1c,
                                               days_mintemp_above_25c_2c,
                                               days_maxwetbulb_over_32c_1c,
                                               days_maxwetbulb_over_32c_2c)
                select h3_to_parent(h3) as h3,
                       (res - 1)        as resolution,
                       max(days_maxtemp_over_32c_1c),
                       max(days_maxtemp_over_32c_2c),
                       max(days_mintemp_above_25c_1c),
                       max(days_mintemp_above_25c_2c),
                       max(days_maxwetbulb_over_32c_1c),
                       max(days_maxwetbulb_over_32c_2c)
                from pf_maxtemp_idw_h3
                where resolution = res
                group by 1;
                res = res - 1;
            end loop;
    end;
$$;


-- generate overviews [4-1]
do
$$
    declare
        res integer;
    begin
        res = 5;
        while res > 0
            loop
                insert into pf_maxtemp_idw_h3 (h3,
                                               resolution,
                                               days_maxtemp_over_32c_1c,
                                               days_maxtemp_over_32c_2c,
                                               days_mintemp_above_25c_1c,
                                               days_mintemp_above_25c_2c,
                                               days_maxwetbulb_over_32c_1c,
                                               days_maxwetbulb_over_32c_2c)
                select h3_to_parent(h3) as h3,
                       (res - 1)        as resolution,
                       floor(avg(days_maxtemp_over_32c_1c)),
                       floor(avg(days_maxtemp_over_32c_2c)),
                       floor(avg(days_mintemp_above_25c_1c)),
                       floor(avg(days_mintemp_above_25c_2c)),
                       floor(avg(days_maxwetbulb_over_32c_1c)),
                       floor(avg(days_maxwetbulb_over_32c_2c))
                from pf_maxtemp_idw_h3
                where resolution = res
                group by 1;
                res = res - 1;
            end loop;
    end;
$$;-- The output table contains a lot of interpolated values that are all-zero.
-- Trim them out, we don't need to output cells for them.
delete
from
    pf_maxtemp_idw_h3
where
      days_maxtemp_over_32c_1c = 0
  and days_maxtemp_over_32c_2c = 0
  and days_mintemp_above_25c_1c = 0
  and days_mintemp_above_25c_2c = 0
  and days_maxwetbulb_over_32c_1c = 0
  and days_maxwetbulb_over_32c_2c = 0;