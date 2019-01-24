copy (
  select
    row_to_json(fc)
  from
    (
      select
        'FeatureCollection'         as type,
        array_to_json(array_agg(f)) as features
      from
        (
          select
            'Feature'                     as type,
            ST_AsGeoJSON(geom, 6) :: json as geometry,
            (
              select
                json_strip_nulls(row_to_json(t))
              from
                (
                  select
                    name,
                    type
                ) t
            )                             as properties
          from
            (
              select
                ST_Transform(point, 4326) as geom,
                tags -> 'name'            as name,
                'hospital'                as type
              from
                osm
              where
                tags @> 'amenity=>hospital'
                and tags ? 'name'
              union all
              select
                ST_Transform(point, 4326) as geom,
                tags -> 'name'            as name,
                'aerodrome'               as type
              from
                osm
              where
                tags @> 'aeroway=>aerodrome'
                and tags ? 'name'
              union all
              select
                ST_Transform(point, 4326) as geom,
                tags -> 'name'            as name,
                'seaport'                 as type
              from
                osm
              where
                tags @> 'landuse=>port'
                and tags ? 'name'
              union all
              select
                ST_Transform(point, 4326) as geom,
                tags -> 'name'            as name,
                'seaport'                 as type
              from
                osm
              where
                tags @> 'landuse=>industrial, industrial=>port'
                and tags ? 'name'
              union all
              select
                ST_Transform(point, 4326) as geom,
                tags -> 'name'            as name,
                'nuclear_plant'           as type
              from
                osm
              where
                tags @> 'generator:source=>nuclear'
              order by 1
            ) osm_eventbrief_poi
        ) as f
    ) as fc
  ) to stdout;