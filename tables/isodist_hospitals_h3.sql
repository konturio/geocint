drop table if exists isodist_hospitals_h3_distinct;
create table isodist_hospitals_h3_distinct as (
    select h3, min(distance) distance, geom
    from isochrone_destinations_h3_r8
    where type = 'hospital'
    group by h3, geom
    order by h3
);
create index on isodist_hospitals_h3_distinct using gist(geom);

drop table if exists isodist_hospitals_h3;
create table isodist_hospitals_h3 as (
    select h3, 8 resolution, round(min(distance) / 1000)::integer distance
    from (
             select c.h3, d.distance
             from countries_h3_r8 c
                  cross join lateral (
                 select s.h3, s.distance + ST_Distance(c.h3::geography, s.h3::geography) distance
                 from isodist_hospitals_h3_distinct s
                 order by c.geom <-> s.geom
                 limit 1
                 ) d
             union all
             select h3, distance
             from isodist_hospitals_h3_distinct
         ) f
    group by h3
);

drop table isodist_hospitals_h3_distinct;
