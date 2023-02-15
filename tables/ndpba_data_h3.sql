-- Create h3 coverage from ndpba statistics using kontur boundaries
-- Using 6th resolution as initial to obtain adequate averages at 4th (basic) on borders
drop table if exists ndpba_data_h3_in;
create table ndpba_data_h3_in as
	select h3_polygon_to_cells(st_subdivide(kb.geom), 6) h3,
	       ndpba.raw_economic_exposure,
	       ndpba.relative_economic_exposure,
	       ndpba.poverty,
	       ndpba.economic_dependency,
	       ndpba.maternal_mortality,
	       ndpba.infant_mortality,
	       ndpba.malnutrition,
	       ndpba.population_change,
	       ndpba.urban_pop_change,
	       ndpba.school_enrollment,
	       ndpba.years_of_schooling,
	       ndpba.fem_to_male_labor,
	       ndpba.proportion_of_female_seats_in_government,
	       ndpba.life_expectancy,
	       ndpba.protected_area,
	       ndpba.distance_to_hospital,
	       ndpba.distance_to_port,
	       ndpba.road_density,
	       ndpba.households_with_fixed_phone,
	       ndpba.households_with_cell_phone,
	       ndpba.voter_participation,
	       ndpba.physicians_per_10000_persons,
	       ndpba.nurse_midwife_per_10k,
	       ndpba.hbeds_per_10000_persons
    from kontur_boundaries kb
        join ndpba_data ndpba
            on kb.hasc = ndpba.hasc;

-- scale to 4th resolution with calculating averages on borders
drop table if exists ndpba_data_h3;
create table ndpba_data_h3 as
	select h3_cell_to_parent(h3, 4) as h3,
	       avg(raw_economic_exposure) as raw_economic_exposure,
	       avg(relative_economic_exposure) as relative_economic_exposure,
	       avg(poverty) as poverty,
	       avg(economic_dependency) as economic_dependency,
	       avg(maternal_mortality) as maternal_mortality,
	       avg(infant_mortality) as infant_mortality,
	       avg(malnutrition) as malnutrition,
	       avg(population_change) as population_change,
	       avg(urban_pop_change) as urban_pop_change,
	       avg(school_enrollment) as school_enrollment,
	       avg(years_of_schooling) as years_of_schooling,
	       avg(fem_to_male_labor) as fem_to_male_labor,
	       avg(proportion_of_female_seats_in_government) as proportion_of_female_seats_in_government,
	       avg(life_expectancy) as life_expectancy,
	       avg(protected_area) as protected_area,
	       avg(distance_to_hospital) as distance_to_hospital,
	       avg(distance_to_port) as distance_to_port,
	       avg(road_density) as road_density,
	       avg(households_with_fixed_phone) as households_with_fixed_phone,
	       avg(households_with_cell_phone) as households_with_cell_phone,
	       avg(voter_participation) as voter_participation,
	       avg(physicians_per_10000_persons) as physicians_per_10000_persons,
	       avg(nurse_midwife_per_10k) as nurse_midwife_per_10k,
	       avg(hbeds_per_10000_persons) as hbeds_per_10000_persons,
		   4 as resolution
    from ndpba_data_h3_in
    group by 1;