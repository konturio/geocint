alter table water_polygons_vector drop constraint water_polygons_vector_pkey;
alter table water_polygons_vector alter COLUMN geom type geometry;

with complex_areas_to_subdivide as (
    delete from water_polygons_vector
    where ST_NPoints(geom) > 100
    returning gid, fid, geom
)
insert into water_polygons_vector (gid, fid, geom)
    select
        gid,fid, ST_Subdivide(geom, 100) as geom
    from complex_areas_to_subdivide
    order by 3;

vacuum full water_polygons_vector;
vacuum analyze water_polygons_vector;
