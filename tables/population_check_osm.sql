drop table if exists population_check_osm;
create table population_check_osm as (
    select osm_id,
           name,
           coalesce(tags ->> 'name:en', tags ->> 'int_name') "name_en",
           tags ->> 'population:date'                        "pop_date",
           round(osm_pop)                                    "osm_pop",
           round(b.population)                               "kontur_pop",
           round(osm_pop - b.population)                     "diff_pop",
           abs(log(osm_pop) - log(b.population + 1))         "diff_log"     -- (b.population + 1) to prevent "2201E: cannot take logarithm of zero" when b.population = 0
    from kontur_boundaries b,
         parse_float(tags ->> 'population') osm_pop,
         ST_Area(geom::geography) "area"
    where osm_pop > 0
      and population is not null
      -- exclude boundaries with a small area (for example, the Vatican City)
      and area > 737327.6 -- average hexagon area at 8 resolution
    order by "diff_log" desc
);

-- Update timestamp in reports table (for further export to reports API JSON):
update osm_reports_list
set last_updated = (select meta->'data'->'timestamp'->>'last' as updated from osm_meta)
where id = 'population_tag_check';
