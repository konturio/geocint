-- Collect multiple GADM dataset levels together
drop table if exists gadm_boundaries;
create table gadm_boundaries as
select
       (row_number() over())::int id,           -- Add unique id column
       gid_0::text,                             -- Level_0 GADM id
       gid_1,                                   -- Level_1 GADM id
       gid_2,                                   -- Level_2 GADM id
       gid_3,                                   -- Level_3 GADM id
       case
                when gadm_level = 0 then gid_0
                when gadm_level = 1 then gid_1
                when gadm_level = 2 then gid_2
                when gadm_level = 3 then gid_3
       end gid,                                 -- Feature's lowest level gid
       case
                when gadm_level = 1 then gid_0
                when gadm_level = 2 then gid_1
                when gadm_level = 3 then gid_2
       end parent_gid,                           -- Feature's lowest level parent gid
       gadm_level,
       hasc::text,
       name::text,
       geom::geometry(geometry)
from (
         select gid_0       gid_0,
                null::text  gid_1,
                null::text  gid_2,
                null::text  gid_3,
                0::smallint gadm_level,
                null::text  hasc,                -- GADM level_0 doesn't have HASC codes
                name_0      "name",
                geom
         from gadm_level_0
         union all
         select gid_0       gid,
                gid_1       gid_1,
                null::text  gid_2,
                null::text  gid_3,
                1::smallint gadm_level,
                hasc_1      hasc,
                name_1      "name",
                geom
         from gadm_level_1
         union all
         select gid_0       gid,
                gid_1       gid_1,
                gid_2       gid_2,
                null::text  gid_3,
                2::smallint gadm_level,
                hasc_2      hasc,
                name_2      "name",
                geom
         from gadm_level_2
         union all
         select gid_0       gid,
                gid_1       gid_1,
                gid_2       gid_2,
                gid_3       gid_3,
                3::smallint gadm_level,
                hasc_3      hasc,
                name_3      "name",
                geom
         from gadm_level_3
     ) a;

-- Create indexes
create index on gadm_boundaries (gid);
create index on gadm_boundaries (parent_gid);
create index on gadm_boundaries using gist (geom);


-- Create deduplicated copy of GADM dataset
drop table if exists gadm_deduplicated;
create table gadm_deduplicated as
select *
from gadm_boundaries
where parent_gid is null
        or parent_gid not in (
                -- Find duplicated features in GADM:
                select g1.gid
                from gadm_boundaries      g1
                left join gadm_boundaries g2
                        on g1.gid = g2.parent_gid
                where g1.gadm_level < 3
                group by g1.gid
                having count(g2.*) = 1
        );
create index on gadm_deduplicated using gist(geom);


-- Drop temporary tables
drop table if exists gadm_level_0;
drop table if exists gadm_level_1;
drop table if exists gadm_level_2;
drop table if exists gadm_level_3;