-- join by iso3
drop table if exists idmc_country_2023_h3_in;
create table idmc_country_2023_h3_in as (
    select b.code, 
           b.hasc, 
           a.name, 
           coalesce(a.conflict_stock_displacement + a.disaster_stock_displacement, 
           	        a.conflict_stock_displacement, 
           	        a.disaster_stock_displacement) as total_stock_displacement,
           a.conflict_internal_displacements,
           a.disaster_internal_displacements
    from idmc_country_2023 a 
         join hdx_locations_with_wikicodes b 
         on lower(a.iso3)=b.code
);

call transform_hasc_to_h3_percent_of_population('idmc_country_2023_h3_in', 
	                      'idmc_country_2023_h3', 
	                      'hasc', 
	                      '{total_stock_displacement,conflict_internal_displacements,disaster_internal_displacements}'::text[], 8);

-- insert data for Abyei area (disputed area between two Sudans, that doesn't have an official hasc code)
insert into idmc_country_2023_h3 
	select distinct on (h3) h3_polygon_to_cells(ST_Subdivide(ST_Transform(ST_Buffer(ST_Transform(b.geom, 3857), 500), 4326)), 8) as h3,
	                    (a.conflict_stock_displacement + a.disaster_stock_displacement)::float / b.population::float * 100::float as total_stock_displacements,
	                    a.conflict_internal_displacements::float / b.population::float * 100::float as conflict_internal_displacements,
	                    a.disaster_internal_displacements::float / b.population::float * 100::float as disaster_internal_displacements, 
	                    8 as resolution
    from idmc_country_2023 a, kontur_boundaries b
    where a.iso3 = 'AB9' and b.osm_id = 13501064;

drop table if exists idmc_country_2023_h3_in;

call generate_overviews('idmc_country_2023_h3', '{total_stock_displacement,conflict_internal_displacements,disaster_internal_displacements}'::text[], '{max,max,max}'::text[], 8);

vacuum full idmc_country_2023_h3;

create index on idmc_country_2023_h3 using btree(h3);
