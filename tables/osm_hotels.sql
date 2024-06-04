drop table if exists osm_hotels;
create table osm_hotels as (
    select  osm_type,
            osm_id,
            geog::geometry as geom,
            tags ->> 'stars' as stars,
            case
                -- when it usual number
                when tags ->> 'stars' ~ '^[0-9]*\.?[0-9]+$'
                    then (tags ->> 'stars')::float
                -- when it looks like 3s or 3S
                when tags ->> 'stars' ~ '^[0-9][sS]$'
                    then left(tags ->> 'stars', 1)::float + 0.5
                when tags ->> 'stars' ~ '^[A-H]{1}$'
                    then 
                        case
                            when tags ->> 'stars' = 'A'
                                then 5::float
                            when tags ->> 'stars' = 'B'
                                then 4::float
                            when tags ->> 'stars' = 'C'
                                then 3::float
                            when tags ->> 'stars' = 'D'
                                then 2::float
                            when tags ->> 'stars' = 'E'
                                then 1::float
                        end
                when tags ->> 'stars' ~ '^\*+$'
                    then length(tags ->> 'stars')::float
                -- when it's two numbers separated by commas
                when tags ->> 'stars' ~ '^[0-9],[0-9]$'
                    then max_of_array(string_to_array(tags ->> 'stars',',')::int[])::float
                -- when it's two numbers separated by semicolon
                when tags ->> 'stars' ~ '^[0-9];[0-9]$'
                    then max_of_array(string_to_array(tags ->> 'stars',';')::int[])::float
                -- when it's two numbers separated by dash
                when tags ->> 'stars' ~ '^[0-9]-[0-9]$'
                    then max_of_array(string_to_array(tags ->> 'stars','-')::int[])::float
                -- when it's two numbers separated by dash
                when tags ->> 'stars' ~ '^[0-9]/[0-9]$'
                    then max_of_array(string_to_array(tags ->> 'stars','/')::int[])::float
                -- anything started from number and doesn't match previous cases
                when tags ->> 'stars' ~ '^[0-9]{1}[^0-9sS.,;\-*]'
                    then left(tags ->> 'stars', 1)::float
            end as assesment,
            parse_integer(tags ->> 'rooms') as rooms,
            parse_integer(tags ->> 'beds') as beds,
            tags ->> 'operator' as operator,
            tags
    from osm o
    where tags @> '{"amenity":"love_hotel"}' 
          or tags ->> 'tourism' in ('guest_house','hotel','hostel','motel')
    order by _ST_SortableHash(geog::geometry)
);

create index on osm_hotels using brin (geom);