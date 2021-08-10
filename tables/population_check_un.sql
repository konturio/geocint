drop table if exists population_check_un;
create table population_check_un as (
    with un as (
        select distinct i.iso3      "code",
                        u.name      "country",
                        u.year      "year",
                        u.pop_total "pop"
        from un_population u,
             iso_codes i
        where u.iso = i.iso_num
          and u.variant_id = 2
          and u.year = date_part('year', current_date) - 1
        order by 1)
    select un.code,
           un.country,
           un.year                       "un_year",
           un.pop                        "un_population",
           k.population                  "kontur_population",
           un.pop - k.population         "diff_pop",
           abs(log(un.pop) - log(population)) "diff_log"
    from un,
         kontur_boundaries k,
         ST_Area(geom::geography) "area"
    where k.gadm_level = 0
      and un.code = k.tags ->> 'ISO3166-1:alpha3'
      -- exclude boundaries with a small area (for example, the Vatican City)
      and area > 737327.6 -- average hexagon area at 8 resolution
    order by "diff_log" desc
);