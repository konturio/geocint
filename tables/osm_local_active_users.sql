drop table if exists osm_local_active_users;

-- Calculate median user edits location, weighted by hours invested, in 3D space
-- Users that edit on different sides of globe naturally go inside, and we can filter them by distance to surface
create table osm_local_active_users as
select
    osm_user,
    ST_Transform(
        ST_GeometricMedian(
            ST_Transform(
                    ST_Collect(
                    ST_SetSRID(
                        ST_MakePoint(
                            ST_X(h3::geometry),
                            ST_Y(h3::geometry),
                            0,
                            hours
                            ),
                        ST_SRID(h3::geometry))
                    ) filter ( where hours > 2 ),
                    4978
                )
            ),
        3857
        )
        as geom,
    null::geography as geog,
    sum(hours) as hours,
    max(hours) as max_hours
from
    osm_user_count_grid_h3
where
    resolution = 8
group by osm_user;
-- if user ever edited one cell, not active - drop
delete from osm_local_active_users where hours = max_hours;
-- if user never edited something 4 times, they're not active
delete from osm_local_active_users where max_hours < 3;
-- users who invested less than 35 hours in last 2 years are not active
delete from osm_local_active_users where hours < 35;
-- users who are 10km and more below surface aren't local anywhere
delete from osm_local_active_users where ST_Z(geom) < -10000;
delete from osm_local_active_users where ST_IsEmpty(geom) or geom is null;
update osm_local_active_users set geog = ST_Transform(ST_Force2D(geom),4326);
vacuum full osm_local_active_users;
create index on osm_local_active_users (osm_user);