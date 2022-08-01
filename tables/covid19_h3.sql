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
                );

alter table covid19_in
    add column if not exists admin_id integer;
update covid19_in a
set
    admin_id = b.id
from
    covid19_admin b
where
      a.province is not distinct from b.province
  and a.country is not distinct from b.country;


alter table covid19_us_confirmed_in
    add column if not exists admin_id integer;
update covid19_us_confirmed_in a
set
    admin_id = b.admin_id
from
    covid19_us_counties b
where
      a.fips = b.fips_code;

alter table covid19_us_deaths_in
    add column if not exists admin_id integer;
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
        coalesce(a.value, 0) as confirmed,
        coalesce(b.value, 0) as recovered,
        coalesce(c.value, 0) as dead,
        d.population
    from
        covid19_in              a
        left join  covid19_in   b on a.admin_id = b.admin_id and b.status = 'recovered'
        left join  covid19_in   c on a.admin_id = c.admin_id and c.status = 'dead'
        join      covid19_admin d on a.admin_id = d.id
    where
          a.status = 'confirmed'
);

insert into covid19_log (date, admin_id, confirmed, recovered, dead, population)
    select distinct
        a.date as date,
        a.admin_id as admin_id,
        coalesce(a.value, 0) as confirmed,
        0::integer as recovered,
        coalesce(b.value, 0) as dead,
        d.population
    from
        covid19_us_confirmed_in a
        left join covid19_us_deaths_in b on a.admin_id = b.admin_id
        join covid19_us_counties d on a.admin_id = d.admin_id
;

drop table if exists covid19_hex;
create table covid19_hex as (
    select
        a.date,
        b.*,
        8::int as resolution,
        coalesce(c.population, b.population) as total_population,
        coalesce(c.confirmed::float * b.population / c.population, 0) as confirmed,
        coalesce(c.recovered::float * b.population / c.population, 0) as recovered,
        coalesce(c.dead::float * b.population / c.population, 0) as dead
    from
            (select max(date) as date from covid19_log) as a
            left join covid19_population_h3_r8           b on true
            left join covid19_log                        c on b.admin_id = c.admin_id
    order by a.date, b.h3
);

drop table if exists covid19_h3;
create table covid19_h3 (
    like covid19_hex
);

--dithering (comments was added by Andrei Valasiuk 26.07.2022)
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
        err_confirmed = 0; -- sum confirmed
        err_recovered = 0; -- sum recovered
        err_dead = 0;      -- sum dead

        --Sort by date and h3 from old to new and read row per row
        for row in ( select * from covid19_hex order by date, h3 ) loop

            -- Increase confirmed sum with new confirmed cases
            err_confirmed = err_confirmed + coalesce(row.confirmed, 0);
            -- Increase recovered sum with new recovered cases
            err_recovered = err_recovered + coalesce(row.recovered, 0);
            -- Increase dead sum with new dead cases
            err_dead = err_dead + coalesce(row.dead, 0);

            --Check if in this hex we actually have confirmed cases
            if err_confirmed > 1 then
                -- floor - rounded up any positive or negative decimal value as smaller than the argument
                -- e.g. make a number of confirmed cases integer
                out_confirmed = floor(err_confirmed);
                -- if number of recovered less then number of confirmed - get number of recovered
                -- if number of recovered more then number of confirmed - get number of confirmed as the number of recovered
                out_recovered = least(floor(err_recovered), out_confirmed);
                -- see comments for previous line
                -- Number of dead always less or equal the number of confirmed
                out_dead = least(floor(err_dead), out_confirmed);
                insert into
                    covid19_h3 (geom, h3, date, population, admin_id, total_population, resolution,
                                      confirmed, recovered, dead)
                values
                (row.geom,
                 row.h3,
                 row.date,
                 row.population - out_dead,
                 row.admin_id,
                 row.total_population,
                 row.resolution,
                 out_confirmed,
                 out_recovered,
                 out_dead);

                -- If there is some part of confirmed people, which we don't use because of floor rounding
                -- move this part to next hex to make sure if the number of peoples in hex is integer
                -- f.ex. floor(31.5) - we will use 31 as out_confirmed and move 0.5 to next hex 
                err_confirmed = err_confirmed - out_confirmed;
                -- If there is more recovered than we need, move difference to next hex
                err_recovered = err_recovered - out_recovered;
                -- see previous comment
                err_dead = err_dead - out_dead;
                --raise warning '% % % % % %', out_dead,out_recovered,out_confirmed,err_dead,err_recovered,err_confirmed;
            end if;
        end loop;
    end;
$$;

create index on covid19_h3 using gist (date, geom);

drop table if exists covid19_population_h3_r8;
drop table if exists covid19_hex;
drop table if exists covid19_log;