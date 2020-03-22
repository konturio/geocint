drop table if exists covid19_admin;
create table covid19_admin (
    id       serial,
    province text,
    country  text,
    geog     geography,
    bounds   geometry,
    tags     jsonb,
    area     float
);

insert into covid19_admin (geog, province, country)
select distinct ST_SetSRID(ST_MakePoint(lon, lat), 4326), province, country
from
    covid19_in;

update covid19_admin set geog = 'SRID=4326;POINT(  15.3136   -4.3276)' where country like 'Congo%';
update covid19_admin set geog = 'SRID=4326;POINT(  -144.2731 -16.4381 )' where province like '%Polynesia';


create table tmp_all_admin as ( select tags, geog from osm where tags @> '{"boundary":"administrative"}' );
create index on tmp_all_admin using gist (geog);
create index on tmp_all_admin using gin (tags);
delete from tmp_all_admin where ST_GeometryType(geog::geometry) = 'ST_Point';
delete from tmp_all_admin where ST_GeometryType(geog::geometry) = 'ST_LineString';
update covid19_admin a
set
    (bounds, tags, area) = ( select geog::geometry, tags, ST_Area(geog)
                             from
                                 tmp_all_admin o
                             where
                                 --          not tags @> '{"admin_level":"2"}' and
                                 _ST_DWithinUncached(a.geog, o.geog, 100000)
                             order by
                                 least(
                                     levenshtein(coalesce(province, country), tags ->> 'name:en'),
                                     levenshtein(coalesce(province, country), tags ->> 'int_name'),
                                     levenshtein(coalesce(province, country), tags ->> 'name'),
                                     levenshtein(province || ' (' || country || ')', tags ->> 'name'), -- Saint-Martin (France)
                                     levenshtein(province || ' County', tags ->> 'name'), -- Minnehaha, SD is not Minnesota
                                     levenshtein('Republic ' || replace(coalesce(province, country), ', South', ''),
                                                 tags ->> 'official_name:en') -- "Korea, South" is "South Korea"
                                     ),
                                 _ST_DistanceUncached(a.geog, o.geog),
                                 ST_Area(geog) desc
                             limit 1
    );
create index on covid19_admin using gist (bounds);
drop table if exists covid19_admin_subdivided;
create table covid19_admin_subdivided as ( select id, ST_Subdivide(bounds) as geom, area
                                           from
                                               covid19_admin
                                           order by 2 );
create index on covid19_admin_subdivided using gist (geom);
update covid19_admin_subdivided a
set
    geom = ST_Difference(geom, ( select ST_Union(geom)
                                 from
                                     covid19_admin_subdivided b
                                 where
                                       ST_Intersects(a.geom, b.geom)
                                   and a.area > b.area ))
where
    exists(select from covid19_admin_subdivided b where ST_Intersects(a.geom, b.geom) and a.area > b.area);
with
    complex_areas_to_subdivide as (
        delete from covid19_admin_subdivided
            where ST_NPoints(geom) > 100
            returning id, area, geom
    )
insert
into covid19_admin_subdivided (id, area, geom)
select
    id, area,
    ST_Subdivide(geom) as geom
from
    complex_areas_to_subdivide;
vacuum full covid19_admin_subdivided;

alter table kontur_population_h3
    set (parallel_workers=32);
analyse kontur_population_h3;
create table covid19_population_h3_r6 as
    (
        select *,
               null::int as admin_id
        from
            kontur_population_h3 h
        where
            resolution = 6
    );

create index on covid19_population_h3_r6 using gist ((h3::geometry));
update covid19_population_h3_r6 h
set
    admin_id = id
from
    covid19_admin_subdivided a
where
    ST_DWithin(h.h3::geometry, a.geom, 0);

vacuum analyse covid19_population_h3_r6;
create index on covid19_population_h3_r6 (admin_id);

alter table covid19_admin
    add column population int;
update covid19_admin set population = ( select sum(population) from covid19_population_h3_r6 where id = admin_id );
select country, province, population from covid19_admin order by population desc;

alter table covid19_in
    add column admin_id int;
update covid19_in a
set
    admin_id = b.id
from
    covid19_admin b
where
      a.province is not distinct from b.province
  and a.country is not distinct from b.country;
drop table if exists covid19_log;
create table covid19_log as (
    select
        a.date,
        a.admin_id,
        a.value as confirmed,
        coalesce(b.value, 0) as recovered,
        coalesce(c.value, 0) as dead,
        d.population
    from
        covid19_in              a
        left join covid19_in    b on a.date = b.date and a.admin_id = b.admin_id
        left join covid19_in    c on a.date = c.date and a.admin_id = c.admin_id
        join      covid19_admin d on a.admin_id = d.id
    where
          a.status = 'confirmed'
      and b.status = 'recovered'
      and c.status = 'dead'
);

drop table if exists covid19_hex;
create table covid19_hex as (
    select
        a.date,
        b.*,
        coalesce(c.population, b.population) as total_population,
        coalesce(c.confirmed::float * b.population / c.population, 0) as confirmed,
        coalesce(c.recovered::float * b.population / c.population, 0) as recovered,
        coalesce(c.dead::float * b.population / c.population, 0) as dead
    from
            ( select distinct date from covid19_log ) as a
            left join covid19_population_h3_r6           b on true
            left join covid19_log                        c on c.date = a.date and b.admin_id = c.admin_id
    order by a.date, b.h3
);

drop table if exists covid19_dithered;
create table covid19_dithered (
    like covid19_hex
);

do
$$
    declare
        err_confirmed float;
        err_recovered float;
        err_dead      float;
        out_confirmed float;
        out_recovered float;
        out_dead      float;
        row           record;
    begin
        err_confirmed = 0;
        err_recovered = 0;
        err_dead = 0;
        for row in ( select * from covid19_hex order by date, h3 ) loop
            err_confirmed = err_confirmed + coalesce(row.confirmed, 0);
            err_recovered = err_recovered + coalesce(row.recovered, 0);
            err_dead = err_dead + coalesce(row.dead, 0);
            if err_confirmed > 1 then
                out_confirmed = floor(err_confirmed);
                out_recovered = least(floor(err_recovered), out_confirmed);
                out_dead = least(floor(err_dead), out_confirmed);
                insert into
                    covid19_dithered (geom, h3, date, population, admin_id, total_population, confirmed, recovered,
                                      dead)
                values
                (row.geom,
                 row.h3,
                 row.date,
                 row.population - out_dead,
                 row.admin_id,
                 row.total_population,
                 out_confirmed,
                 out_recovered,
                 out_dead);
                err_confirmed = err_confirmed - out_confirmed;
                err_recovered = err_recovered - out_recovered;
                err_dead = err_dead - out_dead;
                --raise warning '% % % % % %', out_dead,out_recovered,out_confirmed,err_dead,err_recovered,err_confirmed;
            end if;
        end loop;
    end;
$$;
create index on covid19_dithered using gist (date, geom);