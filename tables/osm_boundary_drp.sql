alter table drp_regions
    add column if not exists geom geometry;

update drp_regions r
set geom = ST_ConvexHull(b.geom)
from osm_admin_boundaries b
where r.osm_id = b.osm_id;

-- force check on null geometry not to be null
update drp_regions r
set geom = ST_ConvexHull(b.geog::geometry)
from osm b
where b.tags ? 'admin_level'
  and b.tags @> '{"boundary":"administrative"}'
  and ST_Dimension(b.geog::geometry) = 2
  and not (tags ->> 'name' is null and tags @> '{"admin_level":"2"}')
  and r.geom is null
  and r.osm_id = b.osm_id;

create index if not exists drp_regions_geom_idx on drp_regions using gist(geom);