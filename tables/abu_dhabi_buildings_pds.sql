drop table if exists abu_dhabi_buildings_pds;
create table abu_dhabi_buildings_pds as (
    with buildings_volume as (
        select b.id,
               b.building_height,
               ST_Area(b.geom::geography) * b.building_height "volume",
               b.geom
        from abu_dhabi_buildings b
    )
    select b.id,
           b.building_height                             "height",
           round(b.volume)::integer                      "volume",
           round(b.volume / v.volume * 1511768)::integer "pds", -- The number 1511768 is the estimated population of Abu Dhabi in 2021.
           ST_Transform(b.geom, 3857)                    "geom"
    from buildings_volume b,
         (select sum(volume) "volume" from buildings_volume) v
    order by b.id
);

create index on abu_dhabi_buildings_pds using gist (geom);