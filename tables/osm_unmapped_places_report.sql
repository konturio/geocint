drop table if exists osm_unmapped_places_report;
create table osm_unmapped_places_report as (
    select row_number() over() id,
           population,
           view_count,

            -- Generate link for JOSM remote desktop:
           'hrefIcon_[Edit in JOSM](http://localhost:8111/load_and_zoom?' ||
           'left=' || ST_XMin(envelope) || '&right=' || ST_XMax(envelope) ||
           '&top=' || ST_YMax(envelope) || '&bottom=' || ST_YMin(envelope) || ')'   as "Place bounding box"
    from stat_h3, ST_Envelope(ST_Transform(geom, 4326)) as envelope
    where population > 1
      and view_count > 1000
      and count = 0
    order by floor(log10(population / area_km2)) desc,
             view_count desc
);

-- Update timestamp in reports table (for further export to reports API JSON):
update osm_reports_list
set last_updated = (select meta->'data'->'timestamp'->>'last' as updated from osm_meta)
where id = 'osm_unmapped_places_report';
