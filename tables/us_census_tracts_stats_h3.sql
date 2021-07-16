drop table if exists us_census_tracts_stats_h3;
create table us_census_tracts_stats_h3 as (
    select h3_polyfill((geom), 8)        as h3,
           count(pop_under_5_total)      as pop_under_5_total,
           count(pop_over_65_total)      as pop_under_65_total,
           count(poverty_families_total) as poverty_families_total,
           count(pop_disability_total)   as pop_disability_total,
           count(pop_not_well_eng_speak) as pop_not_well_eng_speak,
           count(pop_without_car)        as pop_without_car,
           8::int                        as resolution
    from us_census_tracts_stats
    group by 1
);

alter table us_census_tracts_stats_h3
    set (parallel_workers = 32);
