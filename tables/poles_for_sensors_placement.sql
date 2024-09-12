-- prepare county geometry
drop table if exists gat_geom;
select st_transform(geom, 3857) geom  into gat_geom from gatlinburg;

create index on gat_geom using gist(geom);

-- extract data from stat_h3 for county area
drop table if exists gat_stat;
select s.*,
       ST_Transform(h3_cell_to_boundary_geometry(s.h3), 3857) as geom
    into gat_stat from (select h3_cell_to_children(h3, 10) as h3, 
       total_road_length, 
       avg_elevation_gebco_2022, 
       builtup, 
       forest, 
       null::float as population
 from (select * from stat_h3 s, gat_geom g where resolution = 8 and st_intersects(s.geom, g.geom)) a) s;

-- join with population data on resolution 10
drop table if exists gat_kp_h3r11;
select k.* into gat_kp_h3r11 from kp_h3r11 k, gat_geom g where st_intersects(g.geom, k.geom) and k.resolution = 10;
update gat_stat set population = k.population from gat_kp_h3r11 k where k.h3 = gat_stat.h3;

-- remove temporary tables
drop table if exists gat_geom;
drop table if exists gat_kp_h3r11;

-- calculate intersections between county hexagons and area of concern
alter table gat_stat add column nareas integer;
drop table if exists gat_count;
select h3, count(*) into gat_count from gat_stat g, areas_of_concern_upd c where st_intersects(g.geom, st_transform(c.geom, 3857)) group by h3;
update gat_stat set nareas = g.count from gat_count g where g.h3 = gat_stat.h3; 
update gat_stat set nareas = 0 where nareas is null;

-- enrich data with historical fires count
alter table gat_stat add column fires_count integer;
update gat_stat set fires_count = fires_count from gatlinburg_historical_fires_h3_r10 g where g.h3 = gat_stat.h3;

-- calculate cost for county hexagons vased on mcda
alter table gat_stat add column cost float;
drop table if exists gat_cost;
select h3, coalesce((nareas - min(nareas) OVER ()) / stddev(nareas) OVER (), 0) + 
                coalesce((total_road_length - min(total_road_length) OVER ()) / stddev(total_road_length) OVER (), 0) + 
                coalesce((population - min(population) OVER ()) / stddev(population) OVER (), 0) + 
                coalesce((avg_elevation_gebco_2022 - min(avg_elevation_gebco_2022) OVER ()) / stddev(avg_elevation_gebco_2022) OVER (), 0) + 
                coalesce((builtup - min(builtup) OVER ()) / stddev(builtup) OVER (), 0) + 
                coalesce((forest - min(forest) OVER ()) / stddev(forest) OVER (), 0) +
                coalesce((fires_count - min(fires_count) OVER ()) / stddev(fires_count) OVER (), 0) as cost into gat_cost from gat_stat ;
update gat_stat set cost = t.cost from gat_cost t where t.h3 = gat_stat.h3;

-- remove temporary tables
drop table if exists gat_cost;
drop table if exists gat_count;

create index on gat_stat using gist(geom);

-- just keep this code block as a first approach - use weighted centroids of clusters instead of poles
-- -- clusterize hexagons
-- drop table if exists proposed_points;
-- create table proposed_points as
-- select
--     geom,cost,
--     ST_ClusterKMeans(
--         ST_Force4D(
--             ST_Transform(ST_Force3D(geom), 4978), -- cluster in 3D XYZ CRS
--             mvalue := cost
--         ),
--         120,                      -- aim to generate at least 20 clusters
--         max_radius := 1600  -- but generate more to make each under 3000 km radius
--     ) over () as cid
-- from
--     gat_stat;

-- -- transform cluster areas to centroids (proposed sensors placement)
-- drop table if exists proposed_centroids ;
-- create table proposed_centroids as (
--     select st_centroid(st_collect(geom)) as geom, 
--            row_number() over (order by sum(cost) desc) n, 
--            sum(cost),
--            ST_MakePoint(SUM(ST_X(st_centroid(geom)) * cost) / SUM(cost), SUM(ST_Y(st_centroid(geom)) * cost) / SUM(cost)) AS weighted_centroid
--     from proposed_points group by cid 
-- );

-- create temporary copy of gat_stat table
drop table if exists gat_stat_copy;
select h3, cost, geom into gat_stat_copy from gat_stat;
create index on gat_stat_copy using gist(geom);

-- calculate costs for each pole
drop table if exists gat_poles;
create table gat_poles as (
    select objectid    as objectid,
           sum(c.cost) as cost,
           source,
           g.geom      as geom
    from gatlinburg_poles g,
         gat_stat c
    where ST_Intersects(st_transform(g.geom,3857),c.geom)
);

-- crate temporary poly tables with points represented as a buffer area, to speedup future calculations 
drop table if exists gpranked;
select objectid as id, 
       cost     as cost_source, 
       cost, 
       row_number() over (order by cost desc) n, 
       null::integer as rank, 
       st_buffer(st_transform(geom, 3857),1608) geom 
into gpranked from gat_poles;

-- set rank to the most suitable poles and reestimate costs for other in loop
-- all poles should take their reestimated cost and rank if reestimated cost > 0
do
$$
declare 
    counter integer := 1;
begin 
    while 0 < (select count(*) from gpranked where rank is null) loop
        raise notice 'Counter %', counter;        

        update gat_stat_copy set cost = 0 from (select geom from gpranked where rank is null order by cost desc limit 1) a
            where ST_Intersects(a.geom,gat_stat_copy.geom);

        update gpranked set rank = counter where id in (select id from gpranked where rank is null order by cost desc limit 1);

        update gpranked set cost = sq.updated_cost 
            from gpranked g inner join 
                 (select n.id, 
                         sum(t.cost) as updated_cost 
                  from gpranked n, 
                       gat_stat_copy t 
                  where st_intersects(n.geom,t.geom) and n.cost > 0 and rank is null group by n.id) as sq on g.id = sq.id where gpranked.id = sq.id;

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
    from gat_poles g,
         gpranked t
    where g.objectid = t.id
);

-- remove temporary tables
drop table if exists gpranked;

-- enrich gat_stat table with updated costs, to keep information about ares
-- that weren't covered with sensors
alter table gat_stat add column updated_cost numeric;
update table gat_stat set updated_cost = g.cost from gat_stat_copy g where gat_stat.h3 = g.h3; 

-- calculate 1 mile buffer buffer
drop table  if exists wildfire_sensors_placement_1_mile_buffer;
create table wildfire_sensors_placement_1_mile_buffer as (
    select updated_rank, 
           cost_source, 
           cost, 
           st_buffer(st_transform(geom,3857), 1608) as buffer_1_mile 
    from poles_for_sensors_placement 
    where updated_cost > 0
);

-- remove temporary tables
drop table if exists gat_stat_copy;
