drop table if exists abu_dhabi_buildings_population;
create table abu_dhabi_buildings_population as (
    with buildings_volume as (
        select b.id,
               ST_Area(b.geom::geography) * b.building_height volume,
               ST_PointOnSurface(b.geom)                      geom
        from abu_dhabi_buildings b
    )
    select b.id,
           round(b.volume / v.volume * 1511768)::integer population, -- The number 1511768 is the estimated population of Abu Dhabi in 2021.
           b.geom
    from buildings_volume b,
         (select sum(volume) volume from buildings_volume) v
    order by b.id
);

create index on abu_dhabi_buildings_population using gist (geom);