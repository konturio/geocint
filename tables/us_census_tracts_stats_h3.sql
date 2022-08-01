-- Calculate values per hexagons
drop table if exists us_census_tracts_stats_h3_in;
create table us_census_tracts_stats_h3_in as (
    select h3                                                      as h3,
           pop_under_5_total * (x.population / u.population)       as pop_under_5_total,
           pop_over_65_total * (x.population / u.population)       as pop_over_65_total,
           poverty_families_total * (x.population / u.population)  as poverty_families_total,
           pop_disability_total * (x.population / u.population)    as pop_disability_total,
           pop_not_well_eng_speak * (x.population / u.population)  as pop_not_well_eng_speak,
           pop_without_car * (x.population / u.population)         as pop_without_car,
           8::int                                                  as resolution,
           x.population                                            as hex_population
    from us_census_tracts_stats u,
         us_census_tracts_population_h3_r8 x
    where x.affgeoid = u.id_tract
    group by 1, 2, 3, 4, 5, 6, 7, 9
);

drop table if exists us_census_tracts_stats_h3_mid;
create table us_census_tracts_stats_h3_mid (
    like us_census_tracts_stats_h3_in
);

do
$$
    declare
        row                         record;
        -- variables for temporary data
        temp_pop_under_5_total      float;
        temp_pop_over_65_total      float;
        temp_poverty_families_total float;
        temp_pop_disability_total   float;
        temp_pop_not_well_eng_speak float;
        temp_pop_without_car        float;
        -- variables for output
        out_pop_under_5_total       float;
        out_pop_over_65_total       float;
        out_poverty_families_total  float;
        out_pop_disability_total    float;
        out_pop_not_well_eng_speak  float;
        out_pop_without_car         float;
    begin
        temp_pop_under_5_total = 0;
        temp_pop_over_65_total = 0;
        temp_poverty_families_total = 0;
        temp_pop_disability_total = 0;
        temp_pop_not_well_eng_speak = 0;
        temp_pop_without_car   = 0;

        --Sort by date and h3 from old to new and read row per row
        for row in ( select * from us_census_tracts_stats_h3_in order by h3) loop

            -- Increase sum of groups with new values cases
            temp_pop_under_5_total = temp_pop_under_5_total + coalesce(row.pop_under_5_total, 0);
            temp_pop_over_65_total = temp_pop_over_65_total + coalesce(row.pop_over_65_total, 0);
            temp_poverty_families_total = temp_poverty_families_total + coalesce(row.poverty_families_total, 0);
            temp_pop_disability_total = temp_pop_disability_total + coalesce(row.pop_disability_total, 0);
            temp_pop_not_well_eng_speak = temp_pop_not_well_eng_speak + coalesce(row.pop_not_well_eng_speak, 0);
            temp_pop_without_car = temp_pop_without_car + coalesce(row.pop_without_car, 0);

            --Check if this hex is actually populated
            if row.hex_population > 0 then
                           
                
                -- Check case when sum old and young population more than total population which is 1
                if temp_pop_over_65_total > 0 
                   and temp_pop_under_5_total > 0 
                   and temp_pop_over_65_total + temp_pop_under_5_total > row.hex_population  
                   and row.hex_population = 1 
                then
                   -- Set under 5 to 0 because single human in hex couldn't be kids under 5 years
                   out_pop_under_5_total = 0;

                   --Check if single people in hex is human over 65 years
                   if temp_pop_over_65_total >= 1
                   then 
                       out_pop_over_65_total = 1;
                   else
                       out_pop_over_65_total = 0;
                   end if;


                
                -- Check case when sum old and young population more than total population which more than 1
                elsif temp_pop_over_65_total > 0 
                   and temp_pop_under_5_total > 0 
                   and temp_pop_over_65_total + temp_pop_under_5_total > row.hex_population  
                   and row.hex_population > 1 
                then
                   -- floor - rounded up any positive or negative decimal value as smaller than the argument
                   -- Set young pop to 0.5 of total population and old as remainder
                   -- also check if 0.5 of hex_population no more than actual temp_pop_under_5_total 
                   -- we need this and next check to avoid negative number of peoples in hexs
                   out_pop_under_5_total = least(floor(temp_pop_under_5_total), floor(0.5 * row.hex_population));

                   -- also check if diff between hex_population and out_pop_under_5_total no more than actual temp_pop_over65_total 
                   out_pop_over_65_total = least(floor(temp_pop_over_65_total),floor(row.hex_population - out_pop_under_5_total));  

                else
                   -- For this and some next cases: if under 5 sum less then hexagon population - get under 5 sum
                   -- if under 5 sum more then hexagon population - get hexagon population as under 5 sun
                   out_pop_under_5_total = least(floor(temp_pop_under_5_total), floor(row.pop_under_5_total));
                   out_pop_over_65_total = least(floor(temp_pop_over_65_total), floor(row.pop_over_65_total));

                end if;
                
                if row.pop_disability_total is not null
                then
                    -- temp_pop_disability_total should be more than 1 or equal to move fractional part to 1
                    -- we use hex_population - 2 because all peoples in hex couldn't be disability
                    if (temp_pop_disability_total - row.pop_disability_total) >= 1 
                       --and temp_pop_disability_total < (row.hex_population - 2)
                    then
                        out_pop_disability_total = 1 + least(floor(temp_pop_disability_total), floor(row.pop_disability_total));
                    else
                        out_pop_disability_total = least(floor(temp_pop_disability_total), floor(row.pop_disability_total));
                    end if;
                else
                    out_pop_disability_total = least(floor(temp_pop_disability_total), floor(row.pop_disability_total));
                end if;

                if row.pop_not_well_eng_speak is not null
                then
                    -- temp_pop_not_well_eng_speak should be more than 1 or equal to move fractional part to 1
                    -- we use hex_population - 1 because total number not_well_speak peoples couldn't be more than total population
                    if (temp_pop_not_well_eng_speak - row.pop_not_well_eng_speak) >= 1 
                       --and temp_pop_not_well_eng_speak < (row.hex_population - 1)
                    then
                        out_pop_not_well_eng_speak = 1 + least(floor(temp_pop_not_well_eng_speak), floor(row.pop_not_well_eng_speak));
                    else
                        out_pop_not_well_eng_speak = least(floor(temp_pop_not_well_eng_speak), floor(row.pop_not_well_eng_speak));
                    end if;
                else
                    out_pop_not_well_eng_speak = least(floor(temp_pop_not_well_eng_speak), floor(row.pop_not_well_eng_speak));
                end if;

                if row.pop_without_car is not null
                then
                    -- temp_pop_without_car should be more than 1 or equal to move fractional part to 1
                    -- we use hex_population - 1 because total number peoples without car couldn't be more than total population
                    if (temp_pop_without_car - row.pop_without_car) >= 1 
                    -- and temp_pop_without_car < (row.hex_population - 1)
                    then
                        out_pop_without_car = 1 + least(floor(temp_pop_without_car), floor(row.pop_without_car));
                    else
                        out_pop_without_car = least(floor(temp_pop_without_car), floor(row.pop_without_car));
                    end if;
                else
                    out_pop_without_car = least(floor(temp_pop_without_car), floor(row.pop_without_car));
                end if;    

                -- divide by average 2020 USA family size
                out_poverty_families_total = least(floor(temp_poverty_families_total), floor(row.hex_population / 2.58));

                insert into us_census_tracts_stats_h3_mid (h3, 
                                                           resolution, 
                                                           hex_population,
                                                           pop_under_5_total, 
                                                           pop_over_65_total,
                                                           poverty_families_total, 
                                                           pop_disability_total, 
                                                           pop_not_well_eng_speak, 
                                                           pop_without_car)

                values (row.h3,
                        row.resolution,
                        row.hex_population,
                        out_pop_under_5_total,
                        out_pop_over_65_total,
                        out_poverty_families_total,
                        out_pop_disability_total,
                        out_pop_not_well_eng_speak,
                        out_pop_without_car);
                
                --raise info 'Insert checkpoint %' counter::text;

                -- For this and some next cases: If there is more population than we need, move difference to next hex
                temp_pop_under_5_total = temp_pop_under_5_total - out_pop_under_5_total;
                temp_pop_over_65_total = temp_pop_over_65_total - out_pop_over_65_total;                
                temp_pop_disability_total = temp_pop_disability_total - out_pop_disability_total;
                temp_pop_not_well_eng_speak = temp_pop_not_well_eng_speak - out_pop_not_well_eng_speak;
                temp_pop_without_car = temp_pop_without_car - out_pop_without_car;

                -- If there is some part of poverty_families, which we don't use because of floor rounding
                -- move this part to next hex
                -- f.ex. floor(31.5) - we will use 31 as poverty_families and move 0.5 to next hex 
                temp_poverty_families_total = temp_poverty_families_total - out_poverty_families_total;

            end if;
        end loop;
    end;
$$;

drop table if exists us_census_tracts_stats_h3;
create table us_census_tracts_stats_h3 as (
    select h3, 
           pop_under_5_total, 
           pop_over_65_total,
           poverty_families_total, 
           pop_disability_total, 
           pop_not_well_eng_speak, 
           pop_without_car, 
           resolution 
    from us_census_tracts_stats_h3_mid
);

-- Remove temporary tables
drop table if exists us_census_tracts_stats_h3_in;
drop table if exists us_census_tracts_stats_h3_mid;