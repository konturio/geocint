drop table if exists covid19_population_h3_r8;
create table covid19_population_h3_r8 as
    (
        select *,
               null::int as admin_id
        from
            kontur_population_h3 h
        where
            resolution = 8
    );
create index on covid19_population_h3_r8 using gist (h3::geometry);

update covid19_population_h3_r8 h
set
    admin_id = id
from
    covid19_admin_subdivided a
where
    ST_DWithin(h.h3::geometry, a.geom, 0);

update covid19_population_h3_r8 h
set
    admin_id = a.admin_id
from
    covid19_us_counties a
where
    ST_DWithin(h.h3::geometry, a.geom, 0);

vacuum analyse covid19_population_h3_r8;
create index on covid19_population_h3_r8 (admin_id);
