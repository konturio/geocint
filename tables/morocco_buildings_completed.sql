drop table if exists morocco_buildings_benchmark_h3;
create table morocco_buildings_benchmark_h3 as (
     select selected_buildings,
           h3_geo_to_h3(ST_PointOnSurface(wkb_geometry), 9) as h3,
           count(*)
    from morocco_buildings_benchmark
    group by 1, 2
);

drop table if exists morocco_buildings_benchmark_hex;
create table morocco_buildings_benchmark_hex as (
    select m.selected_buildings,
           h.geom
    from morocco_buildings_benchmark_h3 m,
         ST_HexagonFromH3(h3) h
);

update morocco_buildings_benchmark_h3
set selected_buildings = 'non_splitted'
where selected_buildings is null;

drop table if exists morocco_buildings_completed;
create table morocco_buildings_completed as (
    select count(*),
           (select count(selected_buildings) from agadir_hex where selected_buildings = 'split')::float / (select count(*) from agadir_hex)::float as ready_buildings
    from morocco_buildings_benchmark
);
