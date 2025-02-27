drop table if exists osm_unmapped_places_report_in;
create table osm_unmapped_places_report_in as (
    select row_number() over() id,
           ST_PointOnSurface(ST_Transform(p.geom, 4326)) as geom,
           null::text                                    as hasc,
           null::text                                    as country,
           p.population                                  as population,
           v.view_count                                  as view_count,
           v.h3                                          as h3,

            -- Generate link for JOSM remote desktop:
           'hrefIcon_[Edit in JOSM](http://localhost:8111/load_and_zoom?' ||
           'left=' || ST_XMin(envelope) || '&right=' || ST_XMax(envelope) ||
           '&top=' || ST_YMax(envelope) || '&bottom=' || ST_YMin(envelope) || ')' as place
    from
      tile_logs_h3 v
      join kontur_population_h3 p on (v.h3 = p.h3)
      left join osm_object_count_grid_h3 c on (v.h3 = c.h3),
      ST_Envelope(ST_Transform(p.geom, 4326)) as envelope
    where
      p.population > 1
      and v.view_count > 1000
      and c.count is null
    order by
      floor(log10(population / h3_cell_area(p.h3))) desc,
      view_count desc
);

update osm_unmapped_places_report_in o
    set country = h.name,
        hasc = h.hasc_wiki
    from hdx_boundaries h
    where ST_Intersects(h.geom, o.geom);

drop table if exists osm_unmapped_places_report;
create table osm_unmapped_places_report as (
    select distinct on (id)
           id,
           h3          as h3,
           country     as "Country",
           population,
           view_count,
           place       as "Place bounding box"           
    from osm_unmapped_places_report_in
    order by id, hasc
);

drop table if exists osm_unmapped_places_report_in;