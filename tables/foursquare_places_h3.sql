drop table if exists foursquare_places_h3;
create table foursquare_places_h3 as (
    select h3_r8    as h3,
           count(*) as foursquare_places_count,
           8        as resolution
    from foursquare_places
    where h3_r8 is not null
    group by 1
);
