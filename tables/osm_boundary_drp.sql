alter table drp_regions
    add column if not exists geom geometry;

update drp_regions r
set geom = ST_ConvexHull(b.geom)
from osm_admin_boundaries b
where r.osm_id = b.osm_id;

create index if not exists drp_regions_geom_idx on drp_regions using gist(geom);

-- notice: manually check if there is no ST_Equals geometry in osm table with smaller osm_id than in drp_regions.csv
-- if drp_regions.geom is null