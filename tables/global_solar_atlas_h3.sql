drop table if exists global_solar_atlas_h3;

create table global_solar_atlas_h3 as (
    select
        ghi.*,
        gti.gsa_gti,
        pvout.gsa_pvout
    from
        global_solar_atlas_ghi_h3_r8 AS ghi
    full join global_solar_atlas_gti_h3_r8 AS gti using (h3)
    full join global_solar_atlas_pvout_h3_r8 AS pvout using (h3)
);