drop table if exists isodist_ports_h3_distinct;
create table isodist_ports_h3_distinct as (
    select h3,
           min(distance) as distance,
           ST_SetSRID(geom,4326) as geom
    from isochrone_destinations_h3_r8
    where type = 'port'
    group by h3, geom
    order by h3
);
create index on isodist_ports_h3_distinct using gist (geom);

drop table if exists isodist_ports_h3;
create table isodist_ports_h3 as (
    select h3,
           8 as resolution,
           distance
    from isodist_ports_h3_distinct
);

call generate_overviews('isodist_ports_h3', '{distance}'::text[], '{min}'::text[], 8);
