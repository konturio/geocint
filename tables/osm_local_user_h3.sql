drop table if exists osm_local_user_h3;

create table osm_local_user_h3 as
select osm_user, home_point, hex.h3, hex.resolution
from (select osm_user,
             ST_GeometricMedian(ST_Collect(
                     ST_SetSRID(
                             ST_MakePointM(st_x(ST_Centroid(geom::geometry)), st_y(ST_Centroid(geom::geometry)), hours),
                             st_srid(geom::geometry))
                 )) as home_point
      from osm_user_count_grid_h3
               join ST_HexagonFromH3(h3) hex on true
      where resolution = 8
      group by osm_user) as h,
     ST_H3Bucket(home_point) as hex
;

create index on osm_local_user_h3 (h3);
