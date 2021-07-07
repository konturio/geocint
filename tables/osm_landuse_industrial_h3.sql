drop table if exists osm_landuse_industrial_h3_in;
create table osm_landuse_industrial_h3_in as
    (select distinct
            h3_polyfill(st_buffer(geom,0.0045), 8)     as h3,
            8::int                                            as resolution,
            1::int                                            as is_industrial
     --       h3_to_geo_boundary_geometry(h3_polyfill(geom, 8)) as h3_geom
     from osm_landuse_industrial);

-- generate overviews
do
$$
    declare
        res integer;
    begin
        res = 8;
        while res > 0
            loop
                insert into osm_landuse_industrial_h3 (h3, is_industrial, resolution)
                select h3_to_parent(h3) as h3, sum(is_industrial), (res - 1) as resolution
                from osm_landuse_industrial_h3
                where resolution = res
                group by 1;
                res = res - 1;
            end loop;
    end;
$$;