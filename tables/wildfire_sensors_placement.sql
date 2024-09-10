-- prepare county geometry
drop table gat_geom if exists;
select st_transform(geom, 3857) geom  into gat_geom from gatlinburg;

create index on gat_geom using gist(geom);

-- extract data from stat_h3 for county area
drop table gat_stat if exists;
create table gat_stat as (
    select s.* from stat_h3 s, gat_geom g where resolution = 8 and st_intersects(s.geom, g.geom)
);

-- calculate intersections between county hexagons and area of concern
alter table gat_stat add column nareas integer;
select h3, count(*) into gat_count from gat_stat g, areas_of_concern c where st_intersects(g.geom, st_transform(c.geom, 3857)) group by h3;
update gat_stat set nareas = g.count from gat_count g where g.h3 = gat_stat.h3; 
update gat_stat set nareas = 0 where nareas is null; 

alter table gat_stat add column cost float;

-- calculate cost for county hexagons vased on mcda
drop table gat_cost if exists;
select h3, (nareas - min(nareas) OVER ()) / stddev(nareas) OVER () + 
                (total_road_length - min(total_road_length) OVER ()) / stddev(total_road_length) OVER () + 
                (population - min(population) OVER ()) / stddev(population) OVER () + 
                (avg_elevation_gebco_2022 - min(avg_elevation_gebco_2022) OVER ()) / stddev(avg_elevation_gebco_2022) OVER () + 
                (builtup - min(builtup) OVER ()) / stddev(builtup) OVER () + 
                (forest - min(forest) OVER ()) / stddev(forest) OVER () as cost into gat_cost from gat_stat ;
update gat_stat set cost = t.cost from gat_cost t where t.h3 = gat_stat.h3;

-- clusterize hexagons
drop table proposed_points if exists;
create table proposed_points as
select
    geom,cost,
    ST_ClusterKMeans(
        ST_Force4D(
            ST_Transform(ST_Force3D(geom), 4978), -- cluster in 3D XYZ CRS
            mvalue := cost
        ),
        40,                      -- aim to generate at least 20 clusters
        max_radius := 4000    -- but generate more to make each under 3000 km radius
    ) over () as cid
from
    gat_stat;

-- transform cluster areas to centroids (proposed sensors placement)
drop table proposed_centroids if exists;
create table proposed_centroids as select st_centroid(st_collect(geom)) as geom, row_number() over (order by sum(cost) desc) n, sum(cost) from proposed_points group by cid ;

-- calculate buffers
drop table proposed_centroids_buffers if exists;
create table proposed_centroids_buffers as (
    select n, sum, st_buffer(geom, 2000) as buffer2000, st_buffer(geom, 4000) as buffer4000 from proposed_centroids order by nareas
);