-- this version prepare hexagonal grid and implement selection flow that allows to set rank
-- to the most suitable poles and reestimate costs for other in loop
-- all poles should take their reestimated cost and rank if reestimated cost

-- prepare county geometry
drop table if exists gatlinburg_geom;
create table gatlinburg_geom as (
    select ST_Buffer(geom::geography,1608.3)::geometry geom
    from gatlinburg
);

create index on gatlinburg_geom using gist(geom);

-- extract data from stat_h3 for county area
drop table if exists gatlinburg_stat_h3_r10;
create table gatlinburg_stat_h3_r10 as (
    select s.*,
           ST_Transform(h3_cell_to_boundary_geometry(s.h3), 3857) as geom
    from (select h3_cell_to_children(h3, 10) as h3, 
                 total_road_length,
                 avg_slope_gebco_2022, 
                 forest,
                 builtup,
                 gsa_ghi,
                 null::float as population
          from stat_h3 s, 
               gatlinburg_geom g 
          where resolution = 8 
                and ST_Intersects(s.geom, ST_Transform(g.geom,3857))) s
); 

-- join with population data on resolution 10
drop table if exists gatlinburg_kp_h3r11;
create table gatlinburg_kp_h3r11 as (
    select k.* 
    from kp_h3r11 k, 
         gatlinburg_geom g 
    where ST_Intersects(ST_Transform(g.geom,3857), k.geom)
          and k.resolution = 10
);

update gatlinburg_stat_h3_r10
set population = k.population
from gatlinburg_kp_h3r11 k
where k.h3 = gatlinburg_stat_h3_r10.h3;

-- remove temporary tables
drop table if exists gatlinburg_geom;
drop table if exists gatlinburg_kp_h3r11;

-- calculate intersections between county hexagons and area of concern
alter table gatlinburg_stat_h3_r10 add column nareas integer;
drop table if exists gatlinburg_count;
create table gatlinburg_count as (
    select h3,
           count(*)
    from gatlinburg_stat_h3_r10 g, 
         areas_of_concern c 
    where ST_Intersects(g.geom, ST_Transform(c.geom, 3857))
    group by h3
);

update gatlinburg_stat_h3_r10
set nareas = g.count
from gatlinburg_count g
where g.h3 = gatlinburg_stat_h3_r10.h3;

update gatlinburg_stat_h3_r10
set nareas = 0
where nareas is null;

-- enrich data with historical fires count
-- alter table gatlinburg_stat_h3_r10 add column fires_count integer;
-- update gatlinburg_stat_h3_r10 set fires_count = g.fires_count from gatlinburg_historical_fires_h3_r10 g where g.h3 = gatlinburg_stat_h3_r10.h3;

update gatlinburg_stat_h3_r10
set nareas = 1
where nareas > 0;

update gatlinburg_stat_h3_r10
set total_road_length = 1
where total_road_length > 0;

-- calculate cost for county hexagons based on mcda
alter table gatlinburg_stat_h3_r10 add column cost float;

-- implement cost calculation with mcda based on stat_h3 indicators
drop table if exists gatlinburg_cost;
create table gatlinburg_cost as (
    select h3,
           coalesce((forest - min(forest) OVER ()) / (max(forest) OVER () - min(forest) OVER ()), 0) +
           coalesce((nareas - min(nareas) OVER ()) / (max(nareas) OVER () - min(nareas) OVER ()), 0) +
           coalesce((total_road_length - min(total_road_length) OVER ()) / (max(total_road_length) OVER () - min(total_road_length) OVER ()), 0) +
           (1-coalesce((population - min(population) OVER ()) / (max(population) OVER () - min(population) OVER ()), 0)) +
           coalesce((avg_slope_gebco_2022 - min(avg_slope_gebco_2022) OVER ()) / (max(avg_slope_gebco_2022) OVER () - min(avg_slope_gebco_2022) OVER ()), 0) +
           coalesce((gsa_ghi - min(gsa_ghi) OVER ()) / (max(gsa_ghi) OVER () - min(gsa_ghi) OVER ()), 0)
           as cost
    from gatlinburg_stat_h3_r10
); 
update gatlinburg_stat_h3_r10
set cost = t.cost
from gatlinburg_cost t
where t.h3 = gatlinburg_stat_h3_r10.h3;

-- remove temporary tables
drop table if exists gatlinburg_cost;
drop table if exists gatlinburg_count;

create index on gatlinburg_stat_h3_r10 using gist(geom);

-- just keep this code block as a first approach - use weighted centroids of clusters instead of poles
-- clusterize hexagons
drop table if exists clusterized_hexagons;
create table clusterized_hexagons as
select
    geom,cost,
    ST_ClusterKMeans(
        ST_Force4D(
            ST_Transform(ST_Force3D(geom), 4978), -- cluster in 3D XYZ CRS
            mvalue := cost
        ),
        120, -- aim to generate at least 120 clusters
        max_radius := 1608.3 - h3_get_hexagon_edge_length_avg(10,'m')  -- but generate more to make each under mile radius (taking into account h3 r10 radius)
    ) over () as cid
from gatlinburg_stat_h3_r10;

-- transform cluster areas to centroids (proposed sensors placement)
drop table if exists proposed_centroids ;
create table proposed_centroids as (
    select st_centroid(st_collect(geom)) as geom, 
           row_number() over (order by sum(cost) desc) n, 
           sum(cost),
           ST_WeightedCentroids(geom, cost) AS weighted_centroid
    from clusterized_hexagons group by cid
);

-- create temporary copy of gatlinburg_stat_h3_r10 table
drop table if exists gatlinburg_stat_h3_r10_copy;
create table gatlinburg_stat_h3_r10_copy as (
    select h3, 
           cost, 
           st_transform(geom,4326) as geom
    from gatlinburg_stat_h3_r10
);

create index on gatlinburg_stat_h3_r10_copy using gist(geom);

-- calculate costs for each pole
drop table if exists gatlinburg_poles_with_calculated_cost;
create table gatlinburg_poles_with_calculated_cost as (
    select objectid    as objectid, -- id in source table, keep to be able to make fast join with source info
           id, -- id in table after merge all sources
           sum(c.cost) as cost,
           priority,
           source,
           g.geom      as geom
    from gatlinburg_poles g,
         gatlinburg_stat_h3_r10 c
    where ST_Intersects(ST_Transform(g.geom,3857),c.geom)
    group by 1,2,4,5,6
);

-- crate temporary poly tables with points represented as a buffer area, to speedup future calculations 
drop table if exists gatlinburg_poles_ranked;
create table gatlinburg_poles_ranked as (
    select id   as id, 
           cost as cost_source, 
           priority,
           cost, 
           row_number() over (order by cost desc) n, 
           null::integer as rank, 
           ST_Buffer(geom::geography,1608.3)::geometry as geom
    from gatlinburg_poles_with_calculated_cost
);
create index on gatlinburg_poles_ranked using btree(cost);
create index on gatlinburg_poles_ranked using gist(geom);

-- set rank to the most suitable poles and reestimate costs for other in loop
-- all poles should take their reestimated cost and rank if reestimated cost > 0
do
$$
declare 
    counter integer := 1;
    cur_pole record;
begin 
    while 0 < (select count(*) from gatlinburg_poles_ranked where rank is null and cost > 0) loop
        raise notice 'Counter %', counter;

        -- store current pole in cur_pole variable
        select * into cur_pole
            from gatlinburg_poles_ranked
            where rank is null
            order by cost desc limit 1;

        -- zero out surrounding hexagons
        update gatlinburg_stat_h3_r10_copy g
        set cost = 0
--         from cur_pole a
        where ST_Intersects(cur_pole.geom,g.geom);

        -- set pole rank
        update gatlinburg_poles_ranked
        set rank = counter
        where id = cur_pole.id;

        -- reestimate cost for remaining hexagons
        update gatlinburg_poles_ranked
        set cost = sq.updated_cost
        from gatlinburg_poles_ranked g inner join
             (select n.id,
                     sum(t.cost) as updated_cost
              from gatlinburg_poles_ranked n,
                   gatlinburg_stat_h3_r10_copy t
              where ST_Intersects(n.geom, t.geom)
                    and n.cost > 0
                    and rank is null
                    -- reestimate only for recently changed area
                    and ST_Intersects(n.geom, (select geom
                                               from gatlinburg_poles_ranked
                                               where rank is not null
                                               order by rank desc limit 1))
                    group by n.id) as sq
        on g.id = sq.id
        where gatlinburg_poles_ranked.id = sq.id;

        counter := counter + 1;
    end loop;
end;
$$;

-- create final table with poles after cost reestimation
drop table if exists poles_for_sensors_placement;
create table poles_for_sensors_placement as (
    select g.objectid,
           g.source,
           g.cost as cost_source,
           t.cost as updated_cost,
           t.n    as source_rank,
           t.rank as updated_rank,
           g.geom 
    from gatlinburg_poles_with_calculated_cost g,
         gatlinburg_poles_ranked t
    where g.id = t.id
);

-- remove temporary tables
drop table if exists gatlinburg_poles_ranked;

-- enrich gatlinburg_stat_h3_r10 table with updated costs, to keep information about ares
-- that weren't covered with sensors
alter table gatlinburg_stat_h3_r10 add column updated_cost numeric;
update gatlinburg_stat_h3_r10
set updated_cost = g.cost
from gatlinburg_stat_h3_r10_copy g
where gatlinburg_stat_h3_r10.h3 = g.h3;

-- calculate 1 mile buffer
drop table  if exists wildfire_sensors_placement_1_mile_buffer;
create table wildfire_sensors_placement_1_mile_buffer as (
    select updated_rank, 
           cost_source, 
           updated_cost,
           ST_Buffer(geom::geography,1608.3)::geometry as buffer_1_mile
    from poles_for_sensors_placement 
    where updated_cost > 0
);

-- remove temporary tables
drop table if exists gatlinburg_stat_h3_r10_copy;
drop table if exists gatlinburg_poles_with_calculated_cost;
