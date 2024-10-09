-- filter stat table to exclude hexagons closer than a half of mile to existed poles
drop table if exists gatlinburg_stat_h3_r10_filtred;
create table gatlinburg_stat_h3_r10_filtred as (
    select s.*
    from gatlinburg_stat_h3_r10 s,
         gatlinburg_poles p
    where not ST_Dwithin(s.geom, ST_Transform(p.geom, 3857), 1608.3/2)
);

-- generate clusters to fill empty spaces
drop table if exists gatlinburg_stat_h3_r10_clusters;
create table gatlinburg_stat_h3_r10_clusters as (
    select geom,
           cost,
           ST_ClusterKMeans(
         ST_Force4D(
               ST_Transform(ST_Force3D(geom), 4978), -- cluster in 3D XYZ CRS
               mvalue := cost),
        120, -- aim to generate at least 120 clusters
           max_radius := 1608.3/2 - h3_get_hexagon_edge_length_avg(10,'m') -- but generate more to make each under half of mile radius (taking into account h3 r10 radius)
           ) over () as cid
    from gatlinburg_stat_h3_r10_filtred
);

-- transform cluster areas to centroids (proposed sensors placement)
drop table if exists proposed_centroids ;
create table proposed_centroids as (
    select ST_Setsrid(ST_Centroid(ST_Collect(geom)),3857) as geom, 
           row_number() over (order by sum(cost) desc) n, 
           sum(cost),
           ST_WeightedCentroids(geom, cost) AS weighted_centroid
    from gatlinburg_stat_h3_r10_clusters group by cid
);

-- generate 1 scenario - 25 points in one cluster (poles + centroids)
-- merge poles with candidates
drop table if exists gatlinburg_candidates_in;
create table gatlinburg_candidates_in as (
    select a.* 
    from (select source as source,
                 id as id,
                 geom
          from gatlinburg_poles
          union all
          select 'centroid' as source,
                 n + 10000 as id,
                 ST_Transform(ST_Setsrid(geom,3857),4326) geom
          from prop_cent_filtered) a,
        gatlinburg g
    where ST_Within(a.geom,g.geom)
);

-- calculate costs for each pole
drop table if exists gatlinburg_candidates;
create table gatlinburg_candidates as (
    select source,
           id, 
           sum(c.cost) as cost,
           null::numeric as dist_network,
           row_number() over (order by sum(cost) desc) rank,
           g.geom::geography as geog           
    from gatlinburg_candidates_in g,
         gatlinburg_stat_h3_r10 c
    where ST_Dwithin(ST_Transform(g.geom,3857), c.geom, 4824.9) -- 3 mile zone
    group by 1,2,4,6
);

-- drop temporary table
drop table if exists gatlinburg_candidates_in;
drop table if exists gatlinburg_stat_h3_r10_filtred;
drop table if exists gatlinburg_stat_h3_r10_clusters;

-- chose best location in cycle, to fix local maximum
drop table if exists gatlinburg_candidates_copy;
create table gatlinburg_candidates_copy as (select * from gatlinburg_candidates);

-- choose the best point by cost as a start point
drop table if exists proposed_points_1_scenario;
create table proposed_points_1_scenario as (select * from gatlinburg_candidates where rank = 1);

-- -- uncomment this block to chose median pole as a start point
-- drop table if exists proposed_points_1_scenario;
-- create table proposed_points_1_scenario as (select source, id, cost, dist_network, 1 as rank, geog
--                                  from gatlinburg_candidates_copy
--                                  order by ST_Distance(geog, ST_Transform(
--                                          (select ST_GeometricMedian(ST_Collect(ST_Force4D(
--                                                  ST_Transform(ST_Force3D(ST_Centroid(geom)), 4978), -- cluster in 3D XYZ CRS
--                                                  mvalue := cost
--                                              )))
--                                           from gatlinburg_stat_h3_r10), 4326)::geography)
--                                  limit 1);

-- initialize first neighbors with distance to seed pole
update gatlinburg_candidates_copy
set dist_network = ST_Distance(gatlinburg_candidates_copy.geog,k.geog)
from (select geog from proposed_points_1_scenario) k
where ST_Dwithin(gatlinburg_candidates_copy.geog,k.geog,3216.6);

-- use nested cycle with 5 iteration to optimize cluster placement
-- after first naive attempt move starting point to the nearest to cluster centroid point
-- do 5 iterations to make sure that no more changes between iterations (it will means that local maximum matched)
do
$$
declare
    out_counter integer := 1;
begin
    while out_counter < 6 loop --(select count(*) from gatlinburg_poles_ranked where rank is null and cost > 0) loop
        raise notice 'out counter %', out_counter;

        -- choose best 25 points
        do
        $rr$
        declare
            counter integer := 1;
        begin
            while counter < 25 loop --(select count(*) from gatlinburg_poles_ranked where rank is null and cost > 0) loop
                raise notice 'Counter %', counter;

                insert into proposed_points_1_scenario (select source, id, cost, dist_network, counter + 1, geog
                                                        from gatlinburg_candidates_copy
                                                        where dist_network > 1608.3
                                                        order by cost desc limit 1);

                update gatlinburg_candidates_copy
                set dist_network = ST_Distance(gatlinburg_candidates_copy.geog,k.geog)
                from (select ST_Collect(geog::geometry)::geography as geog
                      from proposed_points_1_scenario) k
                where ST_Dwithin(gatlinburg_candidates_copy.geog,k.geog,3216.6);

                counter := counter + 1;
            end loop;
        end;
        $rr$;

        -- generate output final table for first scenario
        drop table if exists proposed_points_1_scenario_output;
        create table proposed_points_1_scenario_output as (select * from proposed_points_1_scenario);

        -- generate 1 mile buffer zone for proposed output points
        drop table if exists proposed_points_v4_buffer_1_mile_1_clusters;
        create table proposed_points_v4_buffer_1_mile_1_clusters as (
            select source,
                   id,
                   cost,
                   ST_Buffer(geog, 1608.3)::geometry as buffer_1_mile
            from proposed_points_1_scenario_output
        );

        -- take fresh candidates table for new iteration
        drop table if exists gatlinburg_candidates_copy;
        create table gatlinburg_candidates_copy as (select * from gatlinburg_candidates);

        -- find cluster centroid
        drop table if exists gatlinburg_pp_median_centoid;
        create table gatlinburg_pp_median_centoid as (
            select ST_GeometricMedian(
                    ST_Collect(
                           ST_Force4D(
                               ST_Transform(
                                       ST_Force3D(geog::geometry), 4978), -- cluster in 3D XYZ CRS
                                       mvalue := cost
                                    ))) as geom
            from proposed_points_1_scenario
        );

        -- find new start point
        drop table if exists proposed_points_1_scenario;
        create table proposed_points_1_scenario as (
             select source,
                    id,
                    cost,
                    dist_network,
                    1 as rank,
                    geog
             from gatlinburg_candidates_copy
             order by ST_Distance(geog, ST_Transform((select geom from gatlinburg_pp_median_centoid), 4326)::geography)
             limit 1
        );

        -- initialize first neighbors with distance to seed pole
        update gatlinburg_candidates_copy
        set dist_network = ST_Distance(gatlinburg_candidates_copy.geog,k.geog)
        from (select geog from proposed_points_1_scenario) k
        where ST_Dwithin(gatlinburg_candidates_copy.geog,k.geog,3216.6);

        out_counter := out_counter + 1;
    end loop;
end;
$$;

-- drop temporary table
drop table if exists gatlinburg_candidates_copy;
drop table if exists proposed_points_1_scenario;

-- finish of the 1 scenario

-- generate 2 scenario - 13 points in first cluster (only poles) and 12 in second cluster (poles + centroids)

-- rebuild table with candidates to exclude centroids
drop table if exists gatlinburg_candidates_in;
create table gatlinburg_candidates_in as (
    select a.*
    from (select source as source,
                 id as id,
                 geom from gatlinburg_poles) a,
        gatlinburg g
    where st_within(a.geom,g.geom) -- only poles
);

-- calculate costs for each pole
drop table if exists gatlinburg_candidates;
create table gatlinburg_candidates as (
    select source,
           id,
           sum(c.cost) as cost,
           null::numeric as dist_network,
           row_number() over (order by sum(cost) desc) rank,
           g.geom::geography as geog
    from gatlinburg_candidates_in g,
         gatlinburg_stat_h3_r10 c
    where ST_Dwithin(ST_Transform(g.geom,3857), c.geom, 4824.9) -- 3 mile zone
    group by 1,2,4,6
);

-- drop temporary table
drop table if exists gatlinburg_candidates_in;

drop table if exists gatlinburg_candidates_copy;
create table gatlinburg_candidates_copy as (select * from gatlinburg_candidates);

-- choose seed point for the first cluster
drop table if exists proposed_points_2_scenario_first_cluster;
create table proposed_points_2_scenario_first_cluster as (select * from gatlinburg_candidates where rank = 1);

-- initialize first neighbors with distance to seed pole
update gatlinburg_candidates_copy
set dist_network = ST_Distance(gatlinburg_candidates_copy.geog,k.geog)
from (select geog from proposed_points_2_scenario_first_cluster) k
where ST_Dwithin(gatlinburg_candidates_copy.geog,k.geog,3216.6);

-- choose best 13 poles to first cluster
do
$$
declare
    counter integer := 1;
begin
    while counter < 13 loop
        raise notice 'Counter %', counter;

        insert into proposed_points_2_scenario_first_cluster (select source,
                                                                     id,
                                                                     cost,
                                                                     dist_network,
                                                                     counter + 1,
                                                                     geog
                                                              from gatlinburg_candidates_copy
                                                              where dist_network > 1608.3
                                                              order by cost desc limit 1);

        update gatlinburg_candidates_copy
        set dist_network = ST_Distance(gatlinburg_candidates_copy.geog,k.geog)
        from (select ST_Collect(geog::geometry)::geography as geog
              from proposed_points_2_scenario_first_cluster) k
        where ST_Dwithin(gatlinburg_candidates_copy.geog,k.geog,3216.6);

        counter := counter + 1;
    end loop;
end;
$$;

-- rebuild table with candidates to include cantroids for second iteration
drop table if exists gatlinburg_candidates_in;
create table gatlinburg_candidates_in as (
    select a.*
    from (select source as source,
                 id as id,
                 geom
          from gatlinburg_poles
          union all
          select 'centroid' as source,
                 n + 10000 as id,
                 ST_Transform(ST_Setsrid(geom,3857),4326) geom
          from prop_cent_filtered) a,
        gatlinburg g
    where st_within(a.geom,g.geom)
);

-- calculate costs for each pole
drop table if exists gatlinburg_candidates;
create table gatlinburg_candidates as (
    select source,
           id,
           sum(c.cost) as cost,
           null::numeric as dist_network,
           row_number() over (order by sum(cost) desc) rank,
           g.geom::geography as geog
    from gatlinburg_candidates_in g,
         gatlinburg_stat_h3_r10 c
    where ST_Dwithin(ST_Transform(g.geom,3857), c.geom, 4824.9) -- 3 mile zone
    group by 1,2,4,6
);

-- drop temporary table
drop table if exists gatlinburg_candidates_in;

-- run algorithm again to build second cluster oyt of 3-mile zone of first
drop table if exists gatlinburg_candidates_copy;
create table gatlinburg_candidates_copy as (select * from gatlinburg_candidates);

-- initialize points with distance to seed pole
update gatlinburg_candidates_copy
set dist_network = ST_Distance(gatlinburg_candidates_copy.geog,k.geog)
from (select ST_Collect(geog::geometry)::geography as geog
      from proposed_points_2_scenario_first_cluster) k
where ST_Dwithin(gatlinburg_candidates_copy.geog,k.geog,4824.9);

-- remove points in 3 mile zone of first cluster
delete from gatlinburg_candidates_copy where dist_network is not null;

drop table if exists proposed_points_2_scenario_second_cluster;
create table proposed_points_2_scenario_second_cluster as (
    select source,
           id,
           cost,
           dist_network,
           1 as rank,
           geog
    from gatlinburg_candidates_copy
    order by cost desc limit 1
);

-- initialize first neighbors with distance to seed pole
update gatlinburg_candidates_copy
set dist_network = ST_Distance(gatlinburg_candidates_copy.geog,k.geog)
from (select geog from proposed_points_2_scenario_second_cluster order by cost desc limit 1) k
where ST_Dwithin(gatlinburg_candidates_copy.geog,k.geog,3216.6);

-- choose best 12 poles to second cluster
do
$$
declare
    counter integer := 1;
begin
    while counter < 12 loop
        raise notice 'Counter %', counter;

        insert into proposed_points_2_scenario_second_cluster (select source,
                                                                      id,
                                                                      cost,
                                                                      dist_network,
                                                                      counter + 1,
                                                                      geog
                                                               from gatlinburg_candidates_copy
                                                               where dist_network > 1608.3
                                                               order by cost desc limit 1);

        update gatlinburg_candidates_copy
        set dist_network = ST_Distance(gatlinburg_candidates_copy.geog,k.geog)
        from (select ST_Collect(geog::geometry)::geography as geog
              from proposed_points_2_scenario_second_cluster) k
        where ST_Dwithin(gatlinburg_candidates_copy.geog,k.geog,3216.6);

        counter := counter + 1;
    end loop;
end;
$$;

-- calculate 1 mile buffer buffer for 2 scenario output
drop table  if exists proposed_points_v4_buffer_1_mile_2_clusters;
create table proposed_points_v4_buffer_1_mile_2_clusters as (
    select rank as updated_rank,
           cost,
           dist_network,
           ST_Buffer(geog, 1608.3)::geometry as buffer_1_mile
    from proposed_points_2_scenario_first_cluster
    union all
    select rank as updated_rank,
           cost,
           dist_network,
           ST_Buffer(geog, 1608.3)::geometry as buffer_1_mile
    from proposed_points_2_scenario_second_cluster
);

-- merge 2 clusters to single output table
drop table if exists proposed_points_2_scenario_output;
create table proposed_points_2_scenario_output as (
    select k.*,
           1 as cid
    from proposed_points_2_scenario_first_cluster k
    union all
    select p.*,
           2 as cid
    from proposed_points_2_scenario_second_cluster p
);

-- drop temporary tables
drop table if exists gatlinburg_candidates_copy;
drop table if exists proposed_points_2_scenario_first_cluster;
drop table if exists proposed_points_2_scenario_second_cluster;
