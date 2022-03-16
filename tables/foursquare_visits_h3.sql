drop table if exists foursquare_visits_h3;
create table foursquare_visits_h3 as (
    select h3_r8    as h3,
           count(*) as foursquare_visits_count,
           8        as resolution
    from foursquare_visits
    group by 1
);