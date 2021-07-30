drop table if exists us_census_tracts_stats_h3;
create table us_census_tracts_stats_h3 as (
    select h3_polyfill((geom), 8)      as h3,
           sum(pop_under_5_total)      as pop_under_5_total,
           sum(pop_over_65_total)      as pop_over_65_total,
           sum(poverty_families_total) as poverty_families_total,
           sum(pop_disability_total)   as pop_disability_total,
           sum(pop_not_well_eng_speak) as pop_not_well_eng_speak,
           sum(pop_without_car)        as pop_without_car,
           8::int                      as resolution
    from us_census_tracts_stats
    group by 1
);
