drop table if exists osm_object_count_grid_h3_with_population_tmp;
create table osm_object_count_grid_h3_with_population_tmp as (
    select coalesce(a.resolution, b.resolution) as resolution,
           coalesce(a.resolution, b.resolution) as zoom,
           coalesce(a.h3, b.h3)                 as h3,
           coalesce(a.count, 0)                 as count,
           coalesce(building_count, 0)          as building_count,
           coalesce(highway_length, 0)          as highway_length,
           coalesce(amenity_count, 0)           as amenity_count,
           coalesce(osm_users, 0)               as osm_users,
           coalesce(osm_local_users, 0)         as osm_local_users,
           coalesce(c.user_count, 0)            as osm_users_recent,
           d.osm_user                           as top_user,
           d.count                              as top_user_objects,
           coalesce(population, 0)              as population,
           avg_ts                               as avg_ts,
           max_ts                               as max_ts,
           p90_ts                               as p90_ts,
	   false as has_water,
	   false as probably_unpopulated
    from osm_object_count_grid_h3 a
             full join population_grid_h3 b on a.resolution = b.resolution and a.h3 = b.h3
             left join osm_user_count_grid_h3_normalized c on a.resolution = c.resolution and a.h3 = c.h3
             left join osm_users_hex d on a.resolution = d.resolution and a.h3 = d.h3
    order by 1, 2
);

alter table osm_object_count_grid_h3_with_population_tmp set (parallel_workers=32);

drop table if exists osm_object_count_grid_h3_with_population_tmp2;
create table osm_object_count_grid_h3_with_population_tmp2 as (
    select a.*,
           hex.area / 1000000.0 as area_km2,
           hex.geom             as geom
    from osm_object_count_grid_h3_with_population_tmp a
             join ST_HexagonFromH3(h3) hex on true
);
alter table osm_object_count_grid_h3_with_population_tmp2 set (parallel_workers=32);

drop table osm_object_count_grid_h3_with_population_tmp;
create index on osm_object_count_grid_h3_with_population_tmp2 (zoom);
create index on osm_object_count_grid_h3_with_population_tmp2 (h3);

drop table if exists zero_pop_h3;
create table zero_pop_h3 as (
	select h3 from osm_object_count_grid_h3_with_population_tmp2 p where exists(select from osm_water_polygons w where ST_Intersects(p.geom, w.geom)) and p.zoom=8
);

update osm_object_count_grid_h3_with_population_tmp2 p
    set has_water = true, probably_unpopulated=true
    from zero_pop_h3 z
    where z.h3=p.h3;


drop table if exists zero_pop_h3;
create table zero_pop_h3 as (
        select h3 from osm_object_count_grid_h3_with_population_tmp2 p where exists(select from osm_unused z where ST_Intersects(p.geom, z.geom)) and p.zoom=8 and not p.probably_unpopulated
);

update osm_object_count_grid_h3_with_population_tmp2 p
    set probably_unpopulated=true
    from zero_pop_h3 z
    where z.h3=p.h3;

drop table if exists zero_pop_h3;


drop table if exists osm_pop_tmp;
create table osm_pop_tmp (
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
        for cur_row in ( select *
                         from osm_object_count_grid_h3_with_population_tmp2
                         where resolution = 8
                         order by h3 )
            loop
                cur_pop = cur_row.population + carry;
                -- Population density of Manila is 46178 people/km2 and that's highest on planet
                max_pop = 46200;

                if (cur_row.probably_unpopulated and cur_row.building_count=0)
                then
                    max_pop = 0;
                end if;
                if cur_row.building_count > 0 and cur_pop < 1
                then
                    cur_pop = 1;
                end if;
                if (cur_row.building_count/2) > cur_pop
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
                    insert into osm_pop_tmp (h3, population, resolution)
                    values (cur_row.h3, cur_pop, 8);
                end if;
                --         raise notice '% pop, % new pop, % carry, % buildings ', cur_row.population, cur_pop, carry, cur_row.building_count;
            end loop;
        raise notice 'unprocessed carry %', carry;
    end;
$$;


do
$$
    declare
        res   integer;
    begin
        res = 8;
        while res > 0
            loop
                insert into osm_pop_tmp (h3, population, resolution) 
                    select h3_to_parent(h3) as h3, sum(population) as population, (res - 1) as resolution from osm_pop_tmp where resolution = res group by 1;
                res = res - 1;
            end loop;
    end;
$$;


alter table osm_object_count_grid_h3_with_population_tmp2 rename column population to population_raw;

drop table if exists osm_object_count_grid_h3_with_population;
create table osm_object_count_grid_h3_with_population as (
    select a.*,
           coalesce(p.population,0) as population
    from osm_object_count_grid_h3_with_population_tmp2 a
        full outer join osm_pop_tmp p on p.h3 = a.h3
);

drop table osm_object_count_grid_h3_with_population_tmp2;
drop table if exists osm_pop_tmp;

create index on osm_object_count_grid_h3_with_population using gist (geom, zoom);

vacuum osm_object_count_grid_h3_with_population;
