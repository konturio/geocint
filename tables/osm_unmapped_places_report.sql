drop table if exists osm_unmapped_places_report_in;
create table osm_unmapped_places_report_in as (
    select row_number() over() id,
           ST_PointOnSurface(ST_Transform(geom, 4326)) as geom,
           null::text                                  as hasc,
           null::text                                  as country,
           population                                  as population,
           view_count                                  as view_count,
           h3                                          as h3,

            -- Generate link for JOSM remote desktop:
           'hrefIcon_[Edit in JOSM](http://127.0.0.1:8111/load_and_zoom?' ||
           'left=' || ST_XMin(envelope) || '&right=' || ST_XMax(envelope) ||
           '&top=' || ST_YMax(envelope) || '&bottom=' || ST_YMin(envelope) || ')' as place
    from stat_h3, ST_Envelope(ST_Transform(geom, 4326)) as envelope
    where population > 1
      and view_count > 1000
      and count = 0
    order by floor(log10(population / area_km2)) desc,
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