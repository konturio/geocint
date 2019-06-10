create table hrsl_population_boundary as (select ST_Subdivide(ST_Transform(geog::geometry,3857)) as geom, tags->>'name' as name, tags->>'ISO3166-1:alpha3' as iso from osm where tags @> '{"admin_level":"2", "boundary":"administrative"}' and osm_type='relation' and (tags ->> 'ISO3166-1:alpha3') in( 'PHL', 'IDN', 'KHM', 'THA', 'LKA', 'ARG',  'HTI', 'GTM', 'MEX'));

