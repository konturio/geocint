drop table if exists osm_hotels_in;
create table osm_hotels_in as (
    select  distinct on (osm_id, osm_type) osm_type,
            osm_id,
            geog::geometry as geom,
            tags ->> 'stars' as stars,
            parse_integer(tags ->> 'rooms') as rooms,
            parse_integer(tags ->> 'beds') as beds,
            tags ->> 'operator' as operator,
            tags
    from osm o
    -- index-friendly tag compares
    where tags @> '{"amenity":"love_hotel"}'
          or (tags ? 'tourism' and tags->>'tourism' in ('guest_house','hotel','hostel','motel'))
);

drop table if exists osm_hotels;
create table osm_hotels as (
    select  osm_type,
            osm_id,
            geom,
            case
                -- when it usual number
                when stars ~ '^[0-9]*\.?[0-9]+$'
                    then (stars)::float
                -- when it looks like 3s or 3S
                when stars ~ '^[0-9][sS]$'
                    then left(stars, 1)::float + 0.5
                -- when it's a letter code
                when stars ~ '^[A-H]{1}$'
                    then 
                        case
                            when stars = 'A'
                                then 5::float
                            when stars = 'B'
                                then 4::float
                            when stars = 'C'
                                then 3::float
                            when stars = 'D'
                                then 2::float
                            when stars = 'E'
                                then 1::float
                        end
                -- when it's a set of asterixes
                when stars ~ '^\*+$'
                    then length(stars)::float
                -- when it's numbers separated by commas
                when stars ~ '^[0-9,]*$'
                    then max_of_array(string_to_array(stars,',')::int[])::float
                -- when it's numbers separated by semicolon
                when stars ~ '^[0-9;]*$'
                    then max_of_array(string_to_array(stars,';')::int[])::float
                -- when it's numbers separated by dash
                when stars ~ '^[0-9-]*$'
                    then max_of_array(string_to_array(stars,'-')::int[])::float
                -- when it's numbers separated by slash
                when stars ~ '^[0-9/]*$'
                    then max_of_array(string_to_array(stars,'/')::int[])::float
                -- anything started from number and doesn't match previous cases
                when stars ~ '^[0-9]{1}[^0-9sS.,;\-*]'
                    then left(stars, 1)::float
            end as assesment,
            rooms,
            beds,
            operator,
            tags
    from osm_hotels_in
    order by 1,2,_ST_SortableHash(geom)
);

drop table if exists osm_hotels_in;