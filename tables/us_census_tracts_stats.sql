-- Calculate population for us_census_tract_boundaries
drop table if exists us_census_tracts_population;
create table us_census_tracts_population as (
    select affgeoid,
           sum(population) as population
    from us_census_tracts_population_h3_r8
    group by 1
);

-- Join us census data with tracts boundaries
drop table if exists us_census_tracts_stats;
create table us_census_tracts_stats as (
    select c.id_tract               as id_tract,
           c.tract_name             as tract_name,
           c.pop_under_5_total      as pop_under_5_total,
           c.pop_over_65_total      as pop_over_65_total,
           c.poverty_families_total as poverty_families_total,
           c.pop_disability_total   as pop_disability_total,
           c.pop_not_well_eng_speak as pop_not_well_eng_speak,
           c.pop_without_car        as pop_without_car,
           b.geom                   as geom,
           p.population             as population
    from us_census_tracts_stats_in c
         join us_census_tract_boundaries_subdivide b
                on c.id_tract = b.affgeoid
         join us_census_tracts_population p
                on c.id_tract = p.affgeoid
);

-- Remove temporary tables
drop table if exists us_census_tract_boundaries_subdivide;
drop table if exists us_census_tracts_population;
drop table if exists us_census_tracts_stats_in;

create index on us_census_tracts_stats using gist (geom);