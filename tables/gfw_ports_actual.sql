set timezone to 'UTC';

drop table if exists gfw_ports_actual;
create table gfw_ports_actual as (
    select port_id,
           port_name,
           st_centroid(st_collect(geom)) as geom
    from gfw_events
    where type = 'port_visit' and port_id is not null
    group by 1,2
);
create index on gfw_ports_actual using gist(geom);
