update covid19_admin
set
    population = ( select sum(population)
from
    covid19_population_h3_r8
where
      id = admin_id );

update covid19_us_counties
set
    population = ( select sum(population)
from
    covid19_population_h3_r8
where
      covid19_us_counties.admin_id = covid19_population_h3_r8.admin_id
        --and covid19_us_counties.population is null
                );

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


alter table covid19_us_confirmed_in
    add column admin_id int;
update covid19_us_confirmed_in a
set
    admin_id = b.admin_id
from
    covid19_us_counties b
where
      a.fips = b.fips_code;

alter table covid19_us_deaths_in
    add column admin_id int;
update covid19_us_deaths_in a
set
    admin_id = b.admin_id
from
    covid19_us_counties b
where
      a.fips = b.fips_code;


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

insert into covid19_log (date, admin_id, confirmed, population)
    select
        a.date as date,
        a.admin_id,
        coalesce(a.value, 0) as confirmed,
        d.population
    from
        covid19_us_confirmed_in              a
        join      covid19_us_counties d on a.admin_id = d.admin_id
;


insert into covid19_log (date, admin_id, dead, population)
    select
        a.date as date,
        a.admin_id,
        coalesce(a.value, 0) as dead,
        d.population
    from
        covid19_us_deaths_in              a
        join      covid19_us_counties d on a.admin_id = d.admin_id
;


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
            left join covid19_population_h3_r8           b on true
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
drop table if exists tmp_all_admin;
