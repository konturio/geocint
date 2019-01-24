-- TODO: Port Z interpolation to ST_ClosestPoint in PostGIS
create or replace function ST_ClosestPointWithZ(g1 geometry, g2 geometry)
  returns geometry
  language sql as
$$
select ST_LineInterpolatePoint(g1, ST_LineLocatePoint(g1, g2))
$$ immutable
   strict
   parallel safe;