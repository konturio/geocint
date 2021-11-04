drop table if exists pf_maxtemp_h3;
create table pf_maxtemp_h3 as
    (select pf.h3,
            pf.resolution,
            days_maxtemp_over_32c_1c,
            days_mintemp_above_25c_1c,
            (days_maxtemp_over_32c_1c * population) as mandays_maxtemp_over_32c_1c,
            days_maxtemp_over_32c_2c,
            days_mintemp_above_25c_2c,
            days_maxwetbulb_over_32c_1c,
            days_maxwetbulb_over_32c_2c
     from pf_maxtemp_idw_h3 pf
              left join kontur_population_h3 kp on pf.h3 = kp.h3);
