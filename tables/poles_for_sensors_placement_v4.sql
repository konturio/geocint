drop table if exists gat_poles_3857;
create table gat_poles_3857 as (
    select st_transform(geom, 3857) as geom
                                from gat_poles
);

drop table if exists gat_stat_filtred;
create table gat_stat_filtred as (
    select s.*
    from gat_stat s,
         gat_poles_3857 p
    where not st_dwithin(s.geom, p.geom, 804)
);

drop table if exists gat_stat_clusters;
create table gat_stat_clusters as (
    select geom,
           cost,
           ST_ClusterKMeans(
         ST_Force4D(
               ST_Transform(ST_Force3D(geom), 4978), -- cluster in 3D XYZ CRS
               mvalue := cost),
        120, -- aim to generate at least 20 clusters
           max_radius := 765 -- but generate more to make each under 3000 km radius
           ) over () as cid
    from gat_stat_filtred
);

-- transform cluster areas to centroids (proposed sensors placement)
drop table if exists proposed_centroids ;
create table proposed_centroids as (
    select st_setsrid(st_centroid(st_collect(geom)),3857) as geom, 
           row_number() over (order by sum(cost) desc) n, 
           sum(cost),
           ST_MakePoint(SUM(ST_X(st_centroid(geom)) * cost) / SUM(cost), SUM(ST_Y(st_centroid(geom)) * cost) / SUM(cost)) AS weighted_centroid
    from gat_stat_clusters group by cid
);

-- merge poles with candidates
drop table if exists gat_cand_in;
create table gat_cand_in as (
    select a.* 
    from (select source as source, id as id, geom from gat_poles union all select 'centroid' as source, n + 10000 as id, st_transform(st_setsrid(geom,3857),4326) geom from prop_cent_filtered) a, gatlinburg g where st_within(a.geom,g.geom)
--     from (select source as source, id as id, geom from gat_poles) a, gatlinburg g where st_within(a.geom,g.geom) -- only poles
);

-- calculate costs for each pole
drop table if exists gat_cand;
create table gat_cand as (
    select source,
           id, 
           sum(c.cost) as cost,
           null::numeric as dist_network,
           row_number() over (order by sum(cost) desc) rank,
           g.geom::geography as geog           
    from gat_cand_in g,
         gat_stat c
    -- where st_dwithin(st_transform(g.geom,3857), c.geom, 1608) -- 1 mile zone
    where st_dwithin(st_transform(g.geom,3857), c.geom, 4824) -- 3 mile zone
    -- where st_dwithin(st_transform(g.geom,3857), c.geom, 3216) and not st_dwithin(st_transform(g.geom,3857), c.geom, 1608)
    group by 1,2,4,6
);

-- drop table if exists gat_cand_copy;
-- create table gat_cand_copy as (select * from gat_cand);
--
-- drop table if exists proposed_points25;
-- create table proposed_points25 as (select * from gat_cand where rank = 1);

-- -- chose median pole as a start point
-- create table proposed_points as (select source, id, cost, dist_network, 1 as rank, geog
--                                  from gat_cand_copy
--                                  order by ST_Distance(geog, ST_Transform(
--                                          (select ST_GeometricMedian(st_collect(ST_Force4D(
--                                                  ST_Transform(ST_Force3D(st_centroid(geom)), 4978), -- cluster in 3D XYZ CRS
--                                                  mvalue := cost
--                                              )))
--                                           --into pp_tst
--                                           from gat_stat), 4326)::geography)
--                                  limit 1);
--
-- update gat_cand set dist_network = st_distance(gat_cand.geog,k.geog) from (select geog from proposed_points) k where st_dwithin(gat_cand.geog,k.geog,3216);

-- -- just place first 25 poles
-- update gat_cand_copy set dist_network = st_distance(gat_cand_copy.geog,k.geog) from (select geog from proposed_points25) k where st_dwithin(gat_cand_copy.geog,k.geog,3216);
--
-- do
-- $$
-- declare
--     counter integer := 1;
-- begin
--     while counter < 25 loop --(select count(*) from gpranked where rank is null and cost > 0) loop
--         raise notice 'Counter %', counter;
--
--         insert into proposed_points25 (select source, id, cost, dist_network, counter + 1, geog from gat_cand_copy where dist_network > 1608 order by cost desc limit 1);
--
--         update gat_cand_copy set dist_network = st_distance(gat_cand_copy.geog,k.geog)
--             from (select st_collect(geog::geometry)::geography as geog from proposed_points25) k where st_dwithin(gat_cand_copy.geog,k.geog,3216);
--
--         counter := counter + 1;
--     end loop;
-- end;
-- $$;

-- chose best location in cycle, to fix local maximum
drop table if exists gat_cand_copy;
create table gat_cand_copy as (select * from gat_cand);

drop table if exists proposed_points25;
create table proposed_points25 as (select * from gat_cand where rank = 1);

-- initialize first neighbors with distance to seed pole
update gat_cand_copy set dist_network = st_distance(gat_cand_copy.geog,k.geog) from (select geog from proposed_points25) k where st_dwithin(gat_cand_copy.geog,k.geog,3216);

do
$$
declare
    out_counter integer := 1;
begin
    while out_counter < 6 loop --(select count(*) from gpranked where rank is null and cost > 0) loop
        raise notice 'out counter %', out_counter;

        do
        $rr$
        declare
            counter integer := 1;
        begin
            while counter < 25 loop --(select count(*) from gpranked where rank is null and cost > 0) loop
                raise notice 'Counter %', counter;

                insert into proposed_points25 (select source, id, cost, dist_network, counter + 1, geog from gat_cand_copy where dist_network > 1608 order by cost desc limit 1);

                update gat_cand_copy set dist_network = st_distance(gat_cand_copy.geog,k.geog)
                    from (select st_collect(geog::geometry)::geography as geog from proposed_points25) k where st_dwithin(gat_cand_copy.geog,k.geog,3216);

                counter := counter + 1;
            end loop;
        end;
        $rr$;

        drop table if exists proposed_points25_output;
        create table proposed_points25_output as (select * from proposed_points25);

        drop table if exists proposed_points25_output_1mile;
        create table proposed_points25_output_1mile as (select source, id, cost, st_buffer(geog, 1608) as buffer_1_mile from proposed_points25_output);

        drop table if exists gat_cand_copy;
        create table gat_cand_copy as (select * from gat_cand);

        drop table if exists gat_pp_median_centoid;
        create table gat_pp_median_centoid as (select ST_GeometricMedian(st_collect(ST_Force4D(
                                                 ST_Transform(ST_Force3D(geog::geometry), 4978), -- cluster in 3D XYZ CRS
                                                 mvalue := cost
                                             ))) as geom from proposed_points25);

        drop table if exists proposed_points25;
        create table proposed_points25 as (select source, id, cost, dist_network, 1 as rank, geog
                                 from gat_cand_copy
                                 order by ST_Distance(geog, ST_Transform(
                                         (select geom from gat_pp_median_centoid), 4326)::geography)
                                 limit 1);

        update gat_cand_copy set dist_network = st_distance(gat_cand_copy.geog,k.geog) from (select geog from proposed_points25) k where st_dwithin(gat_cand_copy.geog,k.geog,3216);

        out_counter := out_counter + 1;
    end loop;
end;
$$;

-- -- run algorithm again to build second cluster oyt of 3-mile zone of first
-- drop table if exists gat_cand_copy;
-- create table gat_cand_copy as (select * from gat_cand);
--
-- update gat_cand_copy set dist_network = st_distance(gat_cand_copy.geog,k.geog)
--             from (select st_collect(geog::geometry)::geography as geog from proposed_points) k where st_dwithin(gat_cand_copy.geog,k.geog,4824);
-- delete from gat_cand_copy where dist_network is not null;
--
-- drop table if exists proposed_points1;
-- create table proposed_points1 as (select source, id, cost, dist_network, 1 as rank, geog from gat_cand_copy order by cost desc limit 1);
--
-- update gat_cand_copy set dist_network = st_distance(gat_cand_copy.geog,k.geog) from (select geog from gat_cand_copy order by cost desc limit 1) k where st_dwithin(gat_cand_copy.geog,k.geog,3216);
--
-- do
-- $$
-- declare
--     counter integer := 1;
-- begin
--     while counter < 12 loop --(select count(*) from gpranked where rank is null and cost > 0) loop
--         raise notice 'Counter %', counter;
--
--         insert into proposed_points1 (select source, id, cost, dist_network, counter + 1, geog from gat_cand_copy where dist_network > 1608 order by cost desc limit 1);
--
--         update gat_cand_copy set dist_network = st_distance(gat_cand_copy.geog,k.geog)
--             from (select st_collect(geog::geometry)::geography as geog from proposed_points1) k where st_dwithin(gat_cand_copy.geog,k.geog,3216);
--
--         counter := counter + 1;
--     end loop;
-- end;
-- $$;
--
-- -- calculate 1 mile buffer buffer
-- drop table  if exists proposed_points_v4_buffer_1_mile;
-- create table proposed_points_v4_buffer_1_mile as (
--     select rank as updated_rank,
--            cost,
--            dist_network,
--            st_buffer(geog, 1608) as buffer_1_mile
--     from proposed_points
--     union all
--     select rank as updated_rank,
--            cost,
--            dist_network,
--            st_buffer(geog, 1608) as buffer_1_mile
--     from proposed_points1
-- );


-- -- multiple clusters code
-- drop table if exists two_clusters_4326;
-- create table two_clusters_4326 as (select cost, cid, st_transform(geom, 4326) as geom from two_clusters);
-- create index on two_clusters_4326 using gist(geom);
--
-- drop table if exists gat_clusters_poles;
-- create table gat_clusters_poles as (
--     select a.* , g,cid as cid
--     -- from (select source as source, id as id, geom from gat_poles union all select 'centroid' as source, n + 10000 as id, st_transform(st_setsrid(geom,3857),4326) geom from prop_cent_filtered) a, gatlinburg g where st_within(a.geom,g.geom)
--     from (select source as source, id as id, geom
--           from gat_poles) a, two_clusters_4326 t, gatlinburg g
--           where st_intersects(a.geom,t.geom) and st_within(a.geom,g.geom) -- only poles
-- );
--
-- -- calculate costs for each pole
-- drop table if exists gat_clusters_cand;
-- create table gat_clusters_cand as (
--     select source,
--            id,
--            sum(c.cost) as cost,
--            null::numeric as dist_network,
--            row_number() over (partition by cid order by sum(cost) desc) rank,
--            cid,
--            g.geom::geography as geog
--     from gat_clusters_poles g,
--          gat_stat c
--     -- where st_dwithin(st_transform(g.geom,3857), c.geom, 1608) -- 1 mile zone
--     where st_dwithin(st_transform(g.geom,3857), c.geom, 4824) -- 2 mile zone
--     -- where st_dwithin(st_transform(g.geom,3857), c.geom, 3216) and not st_dwithin(st_transform(g.geom,3857), c.geom, 1608)
--     group by 1,2,4,6,7
-- );
--
-- update gat_clusters_cand set dist_network = st_distance(gat_clusters_cand.geog,k.geog) from (select geog, cid from gat_clusters_cand where rank = 1) k where st_dwithin(gat_clusters_cand.geog,k.geog,3216) and gat_clusters_cand.cid = k.cid ;
--
-- drop table if exists gat_clusters_cand_copy;
-- create table gat_clusters_cand_copy as (select * from gat_clusters_cand);
--
-- -- select cid, count(*) from gat_clusters_cand group by 1
--
-- drop table if exists clusters_proposed_points;
-- create table clusters_proposed_points as (select * from gat_clusters_cand where rank = 1);
--
-- do
-- $$
-- declare
--     counter integer := 1;
-- begin
--     while counter < 13 loop --(select count(*) from gpranked where rank is null and cost > 0) loop
--         raise notice 'Counter %', counter;
--
--         -- insert into clusters_proposed_points (select source, id, cost, dist_network, counter + 1, cid, geog from gat_clusters_cand_copy where dist_network > 1608 order by cost desc limit 1);
--
--         insert into clusters_proposed_points (select source, id, cost, dist_network, counter + 1, cid, geog from (select *, rank() OVER (PARTITION BY cid ORDER BY cost desc) as upd_rank from gat_clusters_cand where dist_network > 1608) a where upd_rank = 1);
--
--         update gat_clusters_cand_copy set dist_network = st_distance(gat_clusters_cand_copy.geog,k.geog)
--             from (select st_collect(geog::geometry)::geography as geog, cid from clusters_proposed_points group by cid) k where st_dwithin(gat_clusters_cand_copy.geog,k.geog,3216) and gat_clusters_cand_copy.cid = k.cid;
--
--         counter := counter + 1;
--     end loop;
-- end;
-- $$;