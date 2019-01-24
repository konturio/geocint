-- TODO: expose in PostGIS 3 (https://trac.osgeo.org/postgis/ticket/4198)
create or replace function public.st_triangulate2dz(geometry)
  returns geometry as
'$libdir/postgis-2.5',
'sfcgal_triangulate'
  language c
  immutable
  strict
  cost 100;