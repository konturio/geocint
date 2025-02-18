-- collect cod pcodes on different levels to single table
drop table if exists cod_pcodes_general;
create table cod_pcodes_general as (
    select *
    from (select adm0_pcode                                 as pcode,
               0::integer                                   as level,
               jsonb_build_object('adm0_pcode', adm0_pcode) as hierarchy,
               ST_Collect(geom)                             as geom
        from cod_pcodes_0_level
        group by adm0_pcode
        union all
        select nullif(trim(adm1_pcode), '')                 as pcode,
               1::integer                                   as level,
               jsonb_build_object('adm0_pcode', adm0_pcode,
                                  'adm1_pcode', adm1_pcode) as hierarchy,
               ST_Collect(geom)                             as geom
        from cod_pcodes_1_level
        group by adm0_pcode, adm1_pcode
        union all
        select nullif(trim(adm2_pcode), '')                 as pcode,
               2::integer                                   as level,
               jsonb_build_object('adm0_pcode', adm0_pcode,
                                  'adm1_pcode', adm1_pcode,
                                  'adm2_pcode', adm2_pcode) as hierarchy,
               ST_Collect(geom)                             as geom
        from cod_pcodes_2_level
        group by adm0_pcode, adm1_pcode, adm2_pcode
        union all
        select nullif(trim(adm3_pcode), '')                 as pcode,
               3::integer                                   as level,
               jsonb_build_object('adm0_pcode', adm0_pcode,
                                  'adm1_pcode', adm1_pcode,
                                  'adm2_pcode', adm2_pcode,
                                  'adm3_pcode', adm3_pcode) as hierarchy,
               ST_Collect(geom)                             as geom
        from cod_pcodes_3_level
        group by adm0_pcode, adm1_pcode, adm2_pcode, adm3_pcode
        union all
        select nullif(trim(adm4_pcode), '')                 as pcode,
               4::integer                                   as level,
               jsonb_build_object('adm0_pcode', adm0_pcode,
                                  'adm1_pcode', adm1_pcode,
                                  'adm2_pcode', adm2_pcode,
                                  'adm3_pcode', adm3_pcode,
                                  'adm4_pcode', adm4_pcode) as hierarchy,
               ST_Collect(geom)                             as geom
        from cod_pcodes_4_level
        group by adm0_pcode, adm1_pcode, adm2_pcode, adm3_pcode, adm4_pcode) a
    order by level, pcode
);

create index on cod_pcodes_general using gist(geom);
create index on cod_pcodes_general using btree(pcode);