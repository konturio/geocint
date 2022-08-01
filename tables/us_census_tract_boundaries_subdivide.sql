-- Create subdivided geometry of us_census_tracts_boundaries
drop table if exists us_census_tract_boundaries_subdivide;
create table us_census_tract_boundaries_subdivide as (
    select affgeoid,
           ST_Subdivide(geom, 50) as geom
    from us_census_tract_boundaries
);

create index on us_census_tract_boundaries_subdivide using gist(geom);