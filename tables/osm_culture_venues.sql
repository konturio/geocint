drop table if exists osm_culture_venues;
create table osm_culture_venues as (
    select  osm_type,
            osm_id,
            geog::geometry as geom,
            case
                when (tags ? 'historic' and tags ->> 'historic' is not null)
                     or tags ->> 'amenity' = 'museum'
                     or tags ->> 'building' in ('museum','castle')
                     or tags ->> 'tourism' = 'museum'
                    then 'osm_historical_sites_and_museums' 
                when tags ->> 'tourism' in ('artwork','gallery')
                     or tags ->> 'amenity' in ('exhibition_centre','arts_centre')
                    then 'osm_art_venues'
                when tags ->> 'amenity' in ('theatre','cinema','brothel','casino',
                                            'fountain','gambling','love_hotel',
                                            'music_venue','nightclub','planetarium',
                                            'public_bookcase','library','stripclub',
                                            'swingerclub','dive_center','public_bath',
                                            'bbq','sports_centre')
                    then 'osm_entertainment_venues'
                when tags ->> 'amenity' in ('community_centre','conference_centre',
                                            'events_venue','exhibition_centre',
                                            'social_centre','stage','townhall',
                                            'internet_cafe','place_of_mourning',
                                            'social_facility','training')
                    then 'osm_cultural_and_comunity_centers'
            end as type,
            tags ->> 'name' as name,
            tags
    from osm o
    where (tags ? 'historic' and tags ->> 'historic' is not null)
          or tags ->> 'amenity' = 'museum'
          or tags ->> 'building' in ('museum','castle')
          or tags ->> 'tourism' = 'museum'
          or tags ->> 'tourism' in ('artwork','gallery')
          or tags ->> 'amenity' in ('exhibition_centre','arts_centre')
          or tags ->> 'amenity' in ('theatre','cinema','brothel','casino',
                                            'fountain','gambling','love_hotel',
                                            'music_venue','nightclub','planetarium',
                                            'public_bookcase','library','stripclub',
                                            'swingerclub','dive_center','public_bath',
                                            'bbq','sports_centre')
          or tags ->> 'amenity' in ('community_centre','conference_centre',
                                            'events_venue','exhibition_centre',
                                            'social_centre','stage','townhall',
                                            'internet_cafe','place_of_mourning',
                                            'social_facility','training')

    order by _ST_SortableHash(geog::geometry)
);
