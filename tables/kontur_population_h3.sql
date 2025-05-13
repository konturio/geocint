-- combine population_grid_h3_r11 with building_count_grid_h3
-- to avoid unscalled values after dithering
-- union all population and building h3 hexagon tables
drop table if exists kontur_population_in;
create table kontur_population_in as (
    select h3,
           false                            as probably_unpopulated,
           coalesce(max(building_count), 0) as building_count,
           coalesce(max(population), 0)     as population

    from (
             select h3,
                    building_count as building_count,
                    null::float    as population
             from building_count_grid_h3
             where resolution = 11
             union all
             select h3,
                    null::float as building_count,
                    population  as population
             from population_grid_h3_r11
             where population > 0
             order by 1
         ) z
    group by 1
);

-- generate geometries and areas for hexagons
drop table if exists kontur_population_mid1m;
create table kontur_population_mid1m as (
    select a.*,
           ST_Area(h3_cell_to_boundary_geography(a.h3)) / 1000000.0 as area_km2,
           ST_Transform(h3_cell_to_boundary_geometry(a.h3), 3857) as geom
    from kontur_population_in a
);
create index on kontur_population_mid1m using brin (geom);

drop table kontur_population_in;

-- move out Morocco's population to settle it by urban mask data later
update kontur_population_mid1m
set probably_unpopulated = true
where ST_Intersects(
              geom,
              (
                  select ST_Transform(
                                 (select geog::geometry
                                  from osm
                                  where tags @> '{"admin_level":"2"}'
                                    and osm_id = 3630439
                                    and osm_type = 'relation'
                                 ), 3857
                             )
              )
          );

-- generate table with zero populated h3 hexagons
drop table if exists zero_pop_h3;
create table zero_pop_h3 as (
    select h3
    from (
        select h3
        from kontur_population_mid1m p
        where exists(select from osm_water_polygons w where ST_Intersects(p.geom, w.geom))
        union all
        select h3
        from kontur_population_mid1m p
        -- TODO: osm_unpopulated has invalid geometries and it fails here if we use ST_Intersects. Stubbing with
        --  ST_DWithin(,0) for now. osm_water_polygons has valid geometries, so we use ST_Intersects.
        where exists(select from osm_unpopulated z where ST_DWithin(p.geom, z.geom, 0))
        order by 1
        ) "u"
    group by 1
);

-- generate table with marked h3 hexagons which have zero population
drop table if exists kontur_population_mid2m;
create table kontur_population_mid2m as (
    select p.h3,
           (z is not null) or probably_unpopulated as "probably_unpopulated",
           building_count,
           population,
           area_km2,
           geom
    from kontur_population_mid1m p
        left outer join zero_pop_h3 z
            on (z.h3 = p.h3));

drop table kontur_population_mid1m;

create index on kontur_population_mid2m (probably_unpopulated) where probably_unpopulated;

-- generate table with non-zero population h3 hexagons settled on residential and other places
drop table if exists nonzero_pop_h3;
create table nonzero_pop_h3 as (
    select h3
    from kontur_population_mid2m p
    where
-- TODO: osm_residential_landuse has invalid geometries and it fails here if we use ST_Intersects. Stubbing with ST_DWithin(,0) for now.
        exists(select from osm_residential_landuse z where ST_DWithin(p.geom, z.geom, 0))
      and p.probably_unpopulated
);

-- mark hexagons which are probably populated
update kontur_population_mid2m p
set probably_unpopulated = false
from nonzero_pop_h3 z
where z.h3 = p.h3;

drop table if exists nonzero_pop_h3;

-- mark hexagons which are probably populated
update kontur_population_mid2m p
set population = building_count / 2
where population is null and building_count is not null
      or ((building_count / 2) > population) ;

drop table if exists kontur_population_grid_h3_r11_in;
create table kontur_population_grid_h3_r11_in as (
    select h3,
           probably_unpopulated,
           building_count,
           population,
           h3::geometry         as geom,
           area_km2,
           null::integer        as osm_id
    from kontur_population_mid2m
);

drop table kontur_population_mid2m;
create index on kontur_population_grid_h3_r11_in using gist(geom);
create index on kontur_population_grid_h3_r11_in using btree(osm_id);

drop table if exists prescale_to_osm_boundaries_unclipped_subdivided;
create table prescale_to_osm_boundaries_unclipped_subdivided as (
    select p.osm_id,
           p.admin_level,
           ST_Subdivide(p.geom, 50) as geom
    from prescale_to_osm_boundaries_unclipped p
);

create index on prescale_to_osm_boundaries_unclipped using gist(geom);

-- we use this way to match h3 hexes with pairs osm_id + coefficient to make sure 
-- that we don't miss populated hexes that have centroid on sea
drop table if exists kontur_population_grid_h3_r11_in2;
create table kontur_population_grid_h3_r11_in2 as (
        select distinct on (h3) h3,
                                osm_id
        from   (select p.h3,
                       n.osm_id,
                       n.admin_level
                from kontur_population_grid_h3_r11_in p,
                     prescale_to_osm_boundaries_unclipped_subdivided n
                where ST_Intersects(p.geom, n.geom)
             ) a order by h3, admin_level desc
);

-- mark hexagons which are probably populated
update kontur_population_grid_h3_r11_in p
set osm_id = z.osm_id
from kontur_population_grid_h3_r11_in2 z
where z.h3 = p.h3;

drop table if exists kontur_population_grid_h3_r11_in2;

-- Calculate Kontur population for each boundary
drop table if exists prescale_boundary_with_population;
create table prescale_boundary_with_population as (
        with sum_population as (
                select osm_id,
                        -- Calculate kontur population for each boundary from prescale table
                        -- We need for '+1' in the end to make sure special case of 
                        --"population sum in all hexagons was 0 but has to be not 0" is handled.               
                        -- coalesce(round(sum(h.population)), 0) + 1 as population
                        coalesce(sum(population), 0) + 1 as population
                from kontur_population_grid_h3_r11_in h
                group by 1
)
        select  b.osm_id,
                b.population                                   as boundary_population, 
                sum(p.population)                              as grid_population,
                b.population::float / sum(p.population)::float as coefficient
        from prescale_to_osm_boundaries b
        left join sum_population p using(osm_id)
        group by b.osm_id, b.population
);

-- Scale kontur_population_grid_h3_r11_in 
drop table if exists kontur_population_grid_h3_r11_in_scaled;
create table kontur_population_grid_h3_r11_in_scaled as (
        select distinct on (h3) p.h3,
               p.probably_unpopulated,
               p.building_count,
               p.population * b.coefficient as population,
               b.osm_id,
               p.area_km2        
        from kontur_population_grid_h3_r11_in p,
             prescale_boundary_with_population b
        where p.osm_id = b.osm_id
);

create index on kontur_population_grid_h3_r11_in_scaled using btree (h3);

-- Combine scaled and raw data to final population grid
drop table if exists kontur_population_grid_h3_r11_mid;
create table kontur_population_grid_h3_r11_mid as (
    select  coalesce(g.h3, p.h3)                      as h3,
            coalesce(g.probably_unpopulated, p.probably_unpopulated) as probably_unpopulated,
            coalesce(g.building_count, p.building_count)             as building_count,
            coalesce(g.population, p.population)                     as population,
            coalesce(g.osm_id, p.osm_id)                             as osm_id,
            (g.h3 is not null) or null::boolean                      as is_scaled,
            coalesce(g.area_km2, p.area_km2)                         as area_km2
    from kontur_population_grid_h3_r11_in_scaled g 
         full outer join kontur_population_grid_h3_r11_in p
         on p.h3 = g.h3
);

create index on kontur_population_grid_h3_r11_mid using gist (population);

-- Dither to transform float population to integer
drop table if exists kontur_population_mid3m;
create table kontur_population_mid3m
(
    h3         h3index,
    population float,
    resolution integer
);

-- produce population counts
do
$$
    declare
        carry   float;
        cur_pop float;
        max_pop float;
        cur_row record;
    begin
        carry = 0;
        for cur_row in (select * from kontur_population_grid_h3_r11_mid order by h3)
            loop
                -- if row was scaled to 0 - skip dithering process
                continue when cur_row.population = 0 and cur_row.is_scaled;

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
                    insert into kontur_population_mid3m (h3, population, resolution)
                    values (cur_row.h3, cur_pop, 11);
                end if;
            end loop;
        raise notice 'unprocessed carry %', carry;
    end;
$$;

-- add populated area column
drop table if exists kontur_population_mid4m;
create table kontur_population_mid4m as (
    select p.h3,
           p.population as population,
           p.resolution,
           ST_Area(h3_cell_to_boundary_geography(p.h3)) as populated_area
    from kontur_population_mid3m p
);

drop table if exists kontur_population_mid3m;

-- populate people to lower resolution hexagons
call generate_overviews('kontur_population_mid4m', '{population, populated_area}'::text[], '{sum, sum}'::text[], 11);

-- final table with population density, area, geometry and h3 hexagons
drop table if exists kontur_population_h3;
create table kontur_population_h3 as (
    select p.resolution,
           ST_Transform(h3_cell_to_boundary_geometry(p.h3), 3857) as geom,
           ST_Area(h3_cell_to_boundary_geography(p.h3)) as area,
           p.populated_area,
           p.h3,
           p.population as population
    from kontur_population_mid4m p
);

drop table if exists kontur_population_mid4m;
create index on kontur_population_h3 using gist (resolution, geom);
create index on kontur_population_h3 (h3);
