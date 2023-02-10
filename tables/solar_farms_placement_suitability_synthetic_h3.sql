drop table if exists solar_farms_placement_suitability_synthetic_h3;

-- indicators
with gsa_ghi as (select gsa.h3         as h3,
                        gsa.resolution as resolution,
                        case
                            when gsa.gsa_ghi < 2 then 0
                            when gsa.gsa_ghi > 6 then 1
                            else ((gsa.gsa_ghi - 2) / (6 - 2))
                            end           ghi
                 from global_solar_atlas_h3 gsa),

     slope as (select gebco.h3 as                                                     h3,
                      case
                          when gebco.avg_slope_gebco_2022 < 0 then 1
                          when gebco.avg_slope_gebco_2022 > 4 then 0
                          else (1 - ((gebco.avg_slope_gebco_2022 - 0) / (4 - 0))) end slope
               from gebco_2022_h3 gebco),

     powerlines_prox as (select prox_tab.h3 as                                                               h3,
                                case
                                    when prox_tab.powerlines_proximity_m < 100 then 1
                                    when prox_tab.powerlines_proximity_m > 15000 then 0
                                    else (1 - ((prox_tab.powerlines_proximity_m - 100) / (15000 - 100))) end powl_prox
                         from proximities_h3 prox_tab),

     powersubstations_prox as (select prox_tab.h3 as                                                                  h3,
                                      case
                                          when prox_tab.power_substations_proximity_m < 100 then 1
                                          when prox_tab.power_substations_proximity_m > 50000 then 0
                                          else (1 -
                                                ((prox_tab.power_substations_proximity_m - 100) / (50000 - 100))) end pwstat_prox
                               from proximities_h3 prox_tab),


-- constraints

     constraint_temperatures as (select wc.h3 as       h3,
                                        case
                                            when wc.worldclim_max_temperature > 45 then 0
                                            when wc.worldclim_min_temperature < -30 then 0
                                            else 1 end constraint_temperatures
                                 from worldclim_temperatures_h3 wc),

     constraint_ghi as (select gsa.h3 as      h3,
                               case
                                   when gsa.gsa_ghi < 2 then 0
                                   else 1 end constraint_ghi
                        from global_solar_atlas_h3 gsa),

     constraint_slope as (select gebco.h3 as    h3,
                                 case
                                     when gebco.avg_slope_gebco_2022 > 5 then 0
                                     else 1 end constraint_slope
                          from gebco_2022_h3 gebco),

     constraint_popprox as (select prox_tab.h3 as h3,
                                   case
                                       when prox_tab.populated_areas_proximity_m < 500 then 0
                                       when prox_tab.populated_areas_proximity_m > 50000 then 0
                                       else 1 end constraint_popprox
                            from proximities_h3 prox_tab),

     constraint_powerlines as (select prox_tab.h3 as h3,
                                      case
                                          when prox_tab.powerlines_proximity_m > 15000 then 0
                                          else 1 end      constraint_powerlines
                               from proximities_h3 prox_tab),

     constraint_powersubstations as (select prox_tab.h3 as h3,
                                            case
                                                when prox_tab.power_substations_proximity_m > 50000 then 0
                                                else 1 end        constraint_powersubstations
                                     from proximities_h3 prox_tab)

     select gsa_ghi.h3                                                                as h3,
       gsa_ghi.resolution                                                        as resolution,
       (gsa_ghi.ghi * 0.55 + slope.slope * 0.12 + powerlines_prox.powl_prox * 0.2 + powersubstations_prox.pwstat_prox*0.13)*constraint_temperatures.constraint_temperatures*constraint_ghi.constraint_ghi*constraint_slope.constraint_slope*constraint_popprox.constraint_popprox*constraint_powerlines.constraint_powerlines*constraint_powersubstations.constraint_powersubstations as solar_farms_placement_suitability
into solar_farms_placement_suitability_synthetic_h3
from gsa_ghi
         inner join slope on gsa_ghi.h3 = slope.h3
         inner join powerlines_prox on gsa_ghi.h3 = powerlines_prox.h3
         inner join powersubstations_prox on gsa_ghi.h3 = powersubstations_prox.h3
         inner join constraint_temperatures on gsa_ghi.h3 = constraint_temperatures.h3
         inner join constraint_ghi on gsa_ghi.h3 = constraint_ghi.h3
         inner join constraint_slope on gsa_ghi.h3 = constraint_slope.h3
         inner join constraint_popprox on gsa_ghi.h3 = constraint_popprox.h3
         inner join constraint_powerlines on gsa_ghi.h3 = constraint_powerlines.h3
         inner join constraint_powersubstations on gsa_ghi.h3 = constraint_powersubstations.h3

where resolution = 8;

-- delete 0 values for better overviews (simplest approach)
delete from solar_farms_placement_suitability_synthetic_h3 where solar_farms_placement_suitability = 0;