set timezone to 'UTC';

drop table if exists gfw_flag_popular_h3;
create table gfw_flag_popular_h3 as (
    select h3_lat_lng_to_cell(geom::point, 11) as h3,
           mode() within group (order by f.flag) as top_flag,
           count(*) as n_evts,
           11::integer as resolution
    from gfw_events e
    join gfw_vessel_flags f on f.id = e.vessel_id
    group by 1
);

