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
          and u.year = 2020
        order by 1)
    select un.code,
           un.country,
           un.year                            "un_year",
           un.pop                             "un_population",
           k.population                       "kontur_population",
           diff_pop,
           diff_pop / (un.pop + k.population) "index"
    from un,
         kontur_boundaries k,
         abs(un.pop - k.population) "diff_pop",
         ST_Area(geom::geography) "area"
    where k.gadm_level = 0
      and un.code = k.tags ->> 'ISO3166-1:alpha3'
      and area > 5161293.2 -- average hexagon area at 7 resolution
    order by index desc
);