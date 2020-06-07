drop table if exists vianova_geocoded_addresses;

create OR REPLACE function addr_processing(s text) returns text as $$
    begin
    return trim(ltrim(replace(replace(lower(s), 'rr.', ''), 'rruga', ''), 'rr'));
    end;
    $$
    LANGUAGE plpgsql;

-- select addr_processing(address_field) from vianova_geocoded_addresses LIMIT 1000;

create table vianova_geocoded_addresses as (
    select distinct (
        addr_processing(address_field)) as address_field
    from kosovo_covid_vianova
    where address_field is not null and
          lower(address_field) not in ('test') and
          length(address_field) > 3
);

set pg_trgm.similarity_threshold = 0.1;

drop table if exists osm_addr_preproc;
create temporary table osm_addr_preproc as
    (
        select osm_id, lower(o.street || ' ' || o.hno) as addr_concat -- other templates for addresses
        from osm_addresses_kosovo o
    );

drop table if exists osm_addr_dists;
create temporary table osm_addr_dists as
    (
        select similarity(address_field, o.addr_concat) as sim, va.address_field, o.osm_id, o.addr_concat
        from vianova_geocoded_addresses as va
                 join osm_addr_preproc as o
                      on va.address_field % o.addr_concat
        order by sim desc
    );

drop table if exists osm_addr_dists_grouped;
create temporary table osm_addr_dists_grouped as
    (
        select max(sim) as sim, address_field
        from osm_addr_dists
        GROUP BY address_field
    );

select v.sim, v.address_field, o.osm_id, o.addr_concat
from osm_addr_dists_grouped as v
         join osm_addr_dists as o on o.address_field = v.address_field and o.sim = v.sim
order by v.sim desc;




alter table vianova_geocoded_addresses
    add column dist float;

alter table kosovo_covid_vianova
    add column addr_valid geometry;

update kosovo_vianova_copy
set addr_valid = osm_id
from osm_addresses_kosovo
where (
    select min(lower(city) <-> replace(lower('Pejë'), 'ë', 'e'))
          from osm_addresses_kosovo);

select city, lower(city) <-> replace(lower(' Gjakove'), ' ', ''), geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select city, lower(city) <-> replace(lower('Pejë'), 'ë', 'e'), geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select city, name, lower(city || '' || name) <-> lower('Ferizaj Bondsteel'), geom, osm_id
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select city, street, lower(city || ' ' || street) <-> lower('Prishtine Qender'), geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select city,
       street,
       hno,
       lower(city || ' ' || street || ' ' || hno) <-> replace(lower('Prizren Rr . Sefedin Lajqi 34/b'), 'Rr.', ''),
       geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select city,
       street,
       name,
       lower(city || ' ' || street || ' ' || name) <-> lower('Pristina. Lagja Qendresa, veternik'),
       geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select city, suburb, lower(city || ' ' || suburb) <-> lower('Prishtine Bregu i Diellit'), geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select municipality, lower(municipality) <-> lower('Zoqisht, Rahovec'), geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select municipality, village, lower(municipality || ' ' || village) <-> lower('Istog, Vrelle'), geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select municipality,
       village,
       street,
       lower(municipality || ' ' || village || ' ' || street) <->
       replace(lower('Vushtrri, Dobërllukë, Rr. SahitJaha'), 'Pr.', ''),
       geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select name, lower(name) <-> lower('Bill clinton'), geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select name, town, lower(name || ' ' || town) <-> lower('qafe culle pn shipitulle'), geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select name,
       village,
       municipality,
       lower(name || ' ' || village || ' ' || municipality) <-> lower('Makovc-Prishtine'),
       geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select name,
       street,
       city,
       lower(name || ' ' || street || ' ' || city) <-> lower('Ontex 1, Mehmet Gradica, Prishtina'),
       geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select name,
       street,
       city,
       lower(name || ' ' || street || ' ' || city) <-> lower('Ontex 1, Mehmet Gradica, Prishtina'),
       geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select street, city, lower(street || ' ' || city) <-> replace(lower('\"Filip Shiroka\", Peje'), '\"', ''), geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select min(lower(street) <-> lower('15 shkurti'))
from osm_addresses_kosovo;

select street, lower(street) <-> replace(lower('Rr. Muharrem Fejza'), 'Pr.', ''), geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select street,
       hno,
       city,
       lower(street || ' ' || hno || ' ' || city) <->
       replace(lower('Rr. Ganimete Tërbeshi 19/6, Prishtinë'), 'Rr.', ''),
       geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select street, hno, town, lower(street || ' ' || hno || ' ' || town) <-> lower('Mentor Dervishaj 41 Obiliq'), geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select street,
       hno,
       suburb,
       lower(street || ' ' || hno || ' ' || suburb) <->
       replace(lower('Rr.Rexhep Krasniqi nr 9 bl 1 Emshir'), 'Pr.', ''),
       geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select street,
       suburb,
       city,
       lower(street || ' ' || suburb || ' ' || city) <-> lower('Islam Bulliqi street, Dragodan, Pristina'),
       geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select street, town, lower(street || ' ' || town) <-> lower('Sami frasheri, shtime'), geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select suburb, city, lower(suburb || ' ' || city) <-> lower('Aktash Prishtine'), geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select street, village, lower(street || ' ' || village) <-> lower('Rud, Malisheve'), geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select suburb, lower(suburb) <-> lower('Bregu i diellit'), geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select town, lower(town) <-> lower('Fushe kosove'), geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select village,
       municipality,
       lower(village || ' ' || municipality) <-> replace(lower('Baje-Malisheve'), '-', ' '),
       geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select min(lower(street || ' ' || village || ' ' || municipality) <-> lower('Rruga Mustaf Qorri, Pemishtë Skenderaj'))
from osm_addresses_kosovo;
