drop table if exists :table_name_h3;

create table :table_name_h3 tablespace evo4tb as (
    select h3,
           8 as resolution,
           :item_name
    from (
            select h3_lat_lng_to_cell(geom::point, 8) as h3,
            :aggr_func(val) as :item_name
             from (
                     select p.geom as geom,
                      case
                        when p.val > :threshold then :threshold
                        when p.val = 'NaN' then :threshold
                        when p.val is null then :threshold
                        when p.val = 0 then 1
                      else p.val
                      end val
                      from :table_name,
                           ST_PixelAsCentroids(rast) p
                      where (val != 'NaN')
                  ) z
            group by 1
         ) x
);

