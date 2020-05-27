drop table if exists osm_addresses_kosovo;

create table osm_addresses_kosovo as (
    select osm_type,
           osm_id,
           tags ->> 'municipality'     as municipality,
           tags ->> 'city'             as city,
           tags ->> 'town'             as town,
           tags ->> 'village'          as village,
           tags ->> 'suburb'           as suburb,
           tags ->> 'addr:street'      as street,
           tags ->> 'addr:housenumber' as hno,
           tags ->> 'name'             as name,
           geog::geometry              as geom
    from osm
    where tags ? 'addr:housenumber'
      and ST_DWithin(
            geog::geometry,
            (
                select geog::geometry
                from osm
                where tags @> '{"name:en":"Kosovo", "boundary":"administrative"}'
                  and osm_id = 2088990
                  and osm_type = 'relation'
            ),
            0
        )
);

select city, lower(city) <-> replace(lower(' Gjakove'), ' ', ''), geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select city, lower(city) <-> replace(lower('Pejë'), 'ë', 'e'), geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

select city, name, lower(city || '' || name) <-> lower('Ferizaj Bondsteel'), geom
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

select street, lower(street) <-> lower('15 shkurti'), geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;

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

select street,
       village,
       municipality,
       lower(street || ' ' || village || ' ' || municipality) <-> lower('Rruga Mustaf Qorri, Pemishtë Skenderaj'),
       geom
from osm_addresses_kosovo
order by 3, 2, 1
limit 10;
