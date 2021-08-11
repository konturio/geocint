drop table if exists us_census_tracts_stats_h3_in;
create table us_census_tracts_stats_h3_in as (
    select distinct on (h3_polyfill((geom), 8)) h3_polyfill((geom), 8) as h3,
           h3_to_geometry(h3_polyfill(geom, 8)) as geom,
           id_tract
    from us_census_tracts_stats
    order by 1
);

create index on us_census_tracts_stats_h3_in using gist(geom);

drop table if exists us_census_tracts_stats_h3;
create table us_census_tracts_stats_h3 as (
    select h3_polyfill((geom), 8)      as h3,
           pop_under_5_total / h3_count               as pop_under_5_total,
           pop_over_65_total / h3_count               as pop_over_65_total,
           poverty_families_total / h3_count          as poverty_families_total,
           pop_disability_total / h3_count            as pop_disability_total,
           pop_not_well_eng_speak / h3_count          as pop_not_well_eng_speak,
           pop_without_car / h3_count                 as pop_without_car,
           8::int                                     as resolution
    from us_census_tracts_stats u,
    lateral (select u.id_tract, count(h3) as h3_count
             from us_census_tracts_stats_h3_in h
             where ST_Intersects(h.geom, u.geom)
             and h.geom && u.geom
    group by 1) x
    where x.id_tract = u.id_tract
);
