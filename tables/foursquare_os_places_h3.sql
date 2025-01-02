drop table if exists foursquare_os_places_h3;
create table foursquare_os_places_h3 as (
    select 
        h3_lat_lng_to_cell(ST_SetSrid(ST_Point(longitude, latitude), 4326)::point, 8) as h3,
        count(*)                                                                      as foursquare_os_places_count,
        count(*) filter (where '4bf58dd8d48988d1e0931735' = any(fsq_category_ids))    as coffee_shops_fsq_count,
        count(*) filter (where '5283c7b4e4b094cb91ec88d7' = any(fsq_category_ids))    as kebab_restaurants_fsq_count,
        count(*) filter (
            where fsq_category_ids && array(
                select category_id from foursquare_os_places_categories where level1_category_id = '4d4b7105d754a06375d81259'
            ))                                                                        as business_and_professional_services_fsq_count,
        count(*) filter (
            where fsq_category_ids && array(
                select category_id from foursquare_os_places_categories where level1_category_id = '63be6904847c3692a84b9bb5'
            ))                                                                        as dining_and_drinking_fsq_count,
        count(*) filter (
            where fsq_category_ids && array(
                select category_id from foursquare_os_places_categories where level1_category_id = '4d4b7105d754a06378d81259'
            ))                                                                        as retail_fsq_count,
        count(*) filter (
            where fsq_category_ids && array(
                select category_id from foursquare_os_places_categories where level1_category_id = '63be6904847c3692a84b9b9a'
            ))                                                                        as community_and_government_fsq_count,
        count(*) filter (
            where fsq_category_ids && array(
                select category_id from foursquare_os_places_categories where level1_category_id = '4d4b7105d754a06379d81259'
            ))                                                                        as travel_and_transportation_fsq_count,
        count(*) filter (
            where fsq_category_ids && array(
                select category_id from foursquare_os_places_categories where level1_category_id = '4d4b7105d754a06377d81259'
            ))                                                                        as landmarks_and_outdoors_fsq_count,
        count(*) filter (
            where fsq_category_ids && array(
                select category_id from foursquare_os_places_categories where level1_category_id = '63be6904847c3692a84b9bb9'
            ))                                                                        as health_and_medicine_fsq_count,
        count(*) filter (
            where fsq_category_ids && array(
                select category_id from foursquare_os_places_categories where level1_category_id = '4d4b7104d754a06370d81259'
            ))                                                                        as arts_and_entertainment_fsq_count,
        count(*) filter (
            where fsq_category_ids && array(
                select category_id from foursquare_os_places_categories where level1_category_id = '4f4528bc4b90abdf24c9de85'
            ))                                                                        as sports_and_recreation_fsq_count,
        count(*) filter (
            where fsq_category_ids && array(
                select category_id from foursquare_os_places_categories where level1_category_id = '4d4b7105d754a06373d81259'
            ))                                                                        as events_fsq_count,
        8::integer                                                                    as resolution
    from foursquare_os_places
    where latitude is not null and longitude is not null
    group by 1
);

call generate_overviews('foursquare_os_places_h3', '{foursquare_os_places_count, coffee_shops_fsq_count, kebab_restaurants_fsq_count, business_and_professional_services_fsq_count, dining_and_drinking_fsq_count, retail_fsq_count, community_and_government_fsq_count, travel_and_transportation_fsq_count, landmarks_and_outdoors_fsq_count, health_and_medicine_fsq_count, arts_and_entertainment_fsq_count, sports_and_recreation_fsq_count, events_fsq_count}'::text[], '{sum,sum,sum,sum,sum,sum,sum,sum,sum,sum,sum,sum,sum}'::text[], 8);
