drop table if exists kontur_population_in;
create table kontur_population_in as (
    select coalesce(a.h3, b.h3)        as h3,
           coalesce(building_count, 0) as building_count,
           coalesce(population, 0)     as population,
           false                       as has_water,
           false                       as probably_unpopulated
    from osm_building_count_grid_h3_r8 a
             full join population_grid_h3_r8_osm_scaled b on a.h3 = b.h3
);

alter table kontur_population_in
    set (parallel_workers=32);

drop table if exists kontur_population_mid1;
create table kontur_population_mid1 as (
    select a.*,
           hex.area / 1000000.0 as area_km2,
           hex.geom             as geom
    from kontur_population_in a
             join ST_HexagonFromH3(h3) hex on true
);

alter table kontur_population_mid1
    set (parallel_workers=32);

drop table kontur_population_in;
create index on kontur_population_mid1 (h3);

drop table if exists zero_pop_h3;
create table zero_pop_h3 as (
    select h3
    from kontur_population_mid1 p
    where exists(select from osm_water_polygons w where ST_Intersects(p.geom, w.geom))
);

update kontur_population_mid1 p
set has_water            = true,
    probably_unpopulated = true
from zero_pop_h3 z
where z.h3 = p.h3;

drop table if exists zero_pop_h3;
create table zero_pop_h3 as (
    select h3
    from kontur_population_mid1 p
    where
-- TODO: osm_unpopulated has invalid geometries and it fails here if we use ST_Intersects. Stubbing with ST_DWithin(,0) for now.
        exists(select from osm_unpopulated z where ST_DWithin(p.geom, z.geom, 0))
      and not p.probably_unpopulated
);
update kontur_population_mid1 p
set probably_unpopulated = true
from zero_pop_h3 z
where z.h3 = p.h3;
drop table if exists zero_pop_h3;

drop table if exists nonzero_pop_h3;
create table nonzero_pop_h3 as (
    select h3
    from kontur_population_mid1 p
    where
-- TODO: osm_residential_landuse has invalid geometries and it fails here if we use ST_Intersects. Stubbing with ST_DWithin(,0) for now.
        exists(select from osm_residential_landuse z where ST_DWithin(p.geom, z.geom, 0))
      and p.probably_unpopulated
);

update kontur_population_mid1 p
set probably_unpopulated = false
from nonzero_pop_h3 z
where z.h3 = p.h3;

drop table if exists nonzero_pop_h3;

drop table if exists kontur_population_mid2;
create table kontur_population_mid2
(
    h3         h3index,
    population float,
    resolution integer
);

do
$$
    declare
        carry   float;
        cur_pop float;
        max_pop float;
        cur_row record;
    begin
        carry = 0;
        for cur_row in (select * from kontur_population_mid1 order by h3)
            loop
                cur_pop = cur_row.population + carry;
                -- Population density of Manila is 46178 people/km2 and that's highest on planet
                max_pop = 46200;

                if (cur_row.probably_unpopulated and cur_row.building_count = 0)
                then
                    max_pop = 0;
                end if;
                if cur_row.building_count > 0 and cur_pop < 1
                then
                    cur_pop = 1;
                end if;
                if (cur_row.building_count / 2) > cur_pop
                then
                    cur_pop = cur_row.building_count / 2;
                end if;
                if cur_pop < 0
                then
                    cur_pop = 0;
                end if;
                if (cur_pop / cur_row.area_km2) > max_pop
                then
                    cur_pop = max_pop * cur_row.area_km2;
                end if;

                cur_pop = floor(cur_pop);

                carry = cur_row.population + carry - cur_pop;
                if cur_pop > 0
                then
                    insert into kontur_population_mid2 (h3, population, resolution)
                    values (cur_row.h3, cur_pop, 8);
                end if;
            end loop;
        raise notice 'unprocessed carry %', carry;
    end;
$$;
drop table kontur_population_mid1;

do
$$
    declare
        res integer;
    begin
        res = 8;
        while res > 0
            loop
                insert into kontur_population_mid2 (h3, population, resolution)
                select h3_to_parent(h3) as h3, sum(population) as population, (res - 1) as resolution
                from kontur_population_mid2
                where resolution = res
                group by 1;
                res = res - 1;
            end loop;
    end;
$$;

drop table if exists kontur_population_h3;
create table kontur_population_h3 as (
    select p.resolution,
           h.geom,
           h.area,
           p.h3,
           p.population as population
    from kontur_population_mid2 p,
         ST_HexagonFromH3(h3) h
);

create index on kontur_population_h3 using gist (resolution, geom);

drop table if exists kontur_population_mid2;
