drop table if exists foursquare_os_places_h3;
create table foursquare_os_places_h3 as (
    select h3_lat_lng_to_cell(ST_SetSrid(ST_Point(longitude, latitude), 4326)::point, 8) as h3,
           count(*)                                                                      as foursquare_os_places_count,
           count(*) filter (where '4bf58dd8d48988d1e0931735' = any(fsq_category_ids))    as coffee_shops_fsq_count,
           count(*) filter (where '5283c7b4e4b094cb91ec88d7' = any(fsq_category_ids))    as kebab_restaurants_fsq_count,
           count(*) filter (where '4d4b7105d754a06375d81259' = any(fsq_category_ids))    as business_and_professional_services_fsq_count,
           count(*) filter (where '63be6904847c3692a84b9bb5' = any(fsq_category_ids))    as dining_and_drinking_fsq_count,
           count(*) filter (where '4d4b7105d754a06378d81259' = any(fsq_category_ids))    as retail_fsq_count,
           count(*) filter (where '63be6904847c3692a84b9b9a' = any(fsq_category_ids))    as community_and_government_fsq_count,
           count(*) filter (where '4d4b7105d754a06379d81259' = any(fsq_category_ids))    as travel_and_transportation_fsq_count,
           count(*) filter (where '4d4b7105d754a06377d81259' = any(fsq_category_ids))    as landmarks_and_outdoors_fsq_count,
           count(*) filter (where '63be6904847c3692a84b9bb9' = any(fsq_category_ids))    as health_and_medicine_fsq_count,
           count(*) filter (where '4d4b7104d754a06370d81259' = any(fsq_category_ids))    as arts_and_entertainment_fsq_count,
           count(*) filter (where '4f4528bc4b90abdf24c9de85' = any(fsq_category_ids))    as sports_and_recreation_fsq_count,
           count(*) filter (where '4d4b7105d754a06373d81259' = any(fsq_category_ids))    as events_fsq_count,
           8::integer                                                                    as resolution
    from foursquare_os_places
    group by 1
);

call generate_overviews('foursquare_os_places_h3', '{foursquare_os_places_count, coffee_shops_fsq_count, kebab_restaurants_fsq_count, business_and_professional_services_fsq_count, dining_and_drinking_fsq_count, retail_fsq_count, community_and_government_fsq_count, travel_and_transportation_fsq_count, landmarks_and_outdoors_fsq_count, health_and_medicine_fsq_count, arts_and_entertainment_fsq_count, sports_and_recreation_fsq_count, events_fsq_count}'::text[], '{sum,sum,sum,sum,sum,sum,sum,sum,sum,sum,sum,sum,sum}'::text[], 8);
