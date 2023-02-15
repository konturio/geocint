-- MATCH GEOM FROM KONTUR_BOUNDARIES BY HASC
drop table if exists bnds_in;

create table bnds_in as
select k.kontur_admin_level,
    k.geom,
    g."raw_population_exposure_index",
    g."raw_economic_exposure",
    g."relative_population_exposure_index",
    g."relative_economic_exposure",
    g."poverty",
    g."economic_dependency",
    g."maternal_mortality",
    g."infant_mortality",
    g."malnutrition",
    g."population_change",
    g."urban_pop_change",
    g."school_enrollment",
    g."years_of_schooling",
    g."fem_to_male_labor",
    g."proportion_of_female_seats_in_government",
    g."life_expectancy",
    g."protected_area",
    g."physicians_per_10000_persons",
    g."nurse_midwife_per_10k",
    g."distance_to_hospital",
    g."hbeds_per_10000_persons",
    g."distance_to_port",
    g."road_density",
    g."households_with_fixed_phone",
    g."households_with_cell_phone",
    g."voter_participation"
from kontur_boundaries k,
    ndpba_rva_indexes g
where g.hasc = k.hasc_wiki;

-- TAKE LOWEST ADMIN LEVEL
drop table if exists ndpba_rva_h3;

create table ndpba_rva_h3 as
select distinct on (h3) h3_polygon_to_cells(ST_Subdivide(geom), 8) as h3,
    8 as resolution,
    "raw_population_exposure_index",
    "raw_economic_exposure",
    "relative_population_exposure_index",
    "relative_economic_exposure",
    "poverty",
    "economic_dependency",
    "maternal_mortality",
    "infant_mortality",
    "malnutrition",
    "population_change",
    "urban_pop_change",
    "school_enrollment",
    "years_of_schooling",
    "fem_to_male_labor",
    "proportion_of_female_seats_in_government",
    "life_expectancy",
    "protected_area",
    "physicians_per_10000_persons",
    "nurse_midwife_per_10k",
    "distance_to_hospital",
    "hbeds_per_10000_persons",
    "distance_to_port",
    "road_density",
    "households_with_fixed_phone",
    "households_with_cell_phone",
    "voter_participation"
from bnds_in
order by h3, kontur_admin_level desc;

-- drop temporary table
drop table if exists bnds_in;