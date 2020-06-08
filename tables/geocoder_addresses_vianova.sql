drop table if exists vianova_geocoded_addresses;

create OR REPLACE function addr_processing(s text) returns text as
$$
begin
    return trim(ltrim(replace(replace(lower(s), 'rr.', ''), 'rruga', ''), 'rr'));
end;
$$
    LANGUAGE plpgsql;


create table vianova_geocoded_addresses as (
    select distinct (
                        addr_processing(address_field)) as address_valid,
                    patient_id
    from kosovo_covid_vianova
    where address_field is not null
      and lower(address_field) not in ('test')
      and length(address_field) > 3
);

set pg_trgm.similarity_threshold = 0.1;

drop table if exists osm_addr_preproc;
create temporary table osm_addr_preproc as
    (
        select osm_id,
               geom,
               lower(o.street || ' ' || o.hno || ' ' || o.city) as addr_concat -- other templates for addresses
        from osm_addresses_kosovo o
    );

drop table if exists osm_addr_dists;
create temporary table osm_addr_dists as
    (
        select similarity(address_valid, o.addr_concat) as sim,
               va.address_valid,
               va.patient_id,
               o.osm_id,
               o.addr_concat,
               o.geom
        from vianova_geocoded_addresses as va
                 join osm_addr_preproc as o
                      on va.address_valid % o.addr_concat
        order by sim desc
    );

drop table if exists osm_addr_dists_grouped;
create temporary table osm_addr_dists_grouped as
    (
        select max(sim) as sim, address_valid, patient_id
        from osm_addr_dists
        group by address_valid, patient_id
    );

drop table if exists geocoded_vianova;
create table geocoded_vianova as (
    select v.sim, v.address_valid, v.patient_id, o.osm_id, o.addr_concat, o.geom
    from osm_addr_dists_grouped as v
             join osm_addr_dists as o
                  on o.address_valid = v.address_valid and o.sim = v.sim
    order by v.sim desc);

drop table if exists kosovo_covid_geocoded;
create table kosovo_covid_geocoded as (select k.patient_id,
                                              contact_id,
                                              covid_status,
                                              current_status,
                                              confirmed_date,
                                              negative_date,
                                              hospitalized_date,
                                              birth_year,
                                              contact,
                                              profession,
                                              birth_year_2,
                                              has_cardiovascular,
                                              has_diabetes,
                                              has_breathing_disease,
                                              has_cancer,
                                              has_fever,
                                              has_fever_days,
                                              has_breathing_problems,
                                              has_breathing_problems_days,
                                              has_cough,
                                              has_cough_days,
                                              possible_contact,
                                              alert_level,
                                              latitude,
                                              longitude,
                                              address,
                                              address_field,
                                              address_valid,
                                              addr_concat,
                                              osm_id,
                                              v.geom as valid_geom --k.geom as invalid_geom
                                       from kosovo_vianova_copy as k
                                                join geocoded_vianova as v
                                                     on v.patient_id = k.patient_id);
