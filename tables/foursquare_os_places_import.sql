-- create server for parquet foreign data wrapper
create server if not exists parquet_srv foreign data wrapper parquet_fdw options (public 'true');

drop table if exists foursquare_os_places;
create table foursquare_os_places (
    fsq_place_id text,
    name text,
    latitude double precision,
    longitude double precision,
    address text,
    locality text,
    region text,
    postcode text,
    admin_region text,
    post_town text,
    po_box text,
    country text,
    date_created text,
    date_refreshed text,
    date_closed text,
    tel text,
    website text,
    email text,
    facebook_id bigint,
    instagram text,
    twitter text,
    fsq_category_ids text[],
    fsq_category_labels text[],
    geom bytea
);

-- upload files with points to database
do $$
declare
    file_name text;
begin
    -- Get the list of all files in the directory
    for file_name in
        select fls from (select pg_ls_dir('/home/gis/test/fsqr') as fls) as f
        where fls like 'places-%.zstd.parquet'
    loop

        -- Debug: Show which file is being processed
        raise notice 'Processing file: %', file_name;

        -- Drop the temporary foreign table after use
        execute 'drop foreign table if exists temp_parquet_table;';

        -- Dynamically create a temporary foreign table for each file
        execute format(
            'create foreign table temp_parquet_table ( 
                fsq_place_id text,
                name text,
                latitude double precision,
                longitude double precision,
                address text,
                locality text,
                region text,
                postcode text,
                admin_region text,
                post_town text,
                po_box text,
                country text,
                date_created text,
                date_refreshed text,
                date_closed text,
                tel text,
                website text,
                email text,
                facebook_id bigint,
                instagram text,
                twitter text,
                fsq_category_ids text[],
                fsq_category_labels text[],
                geom bytea,
                bbox jsonb
            ) server parquet_srv options (filename ''/home/gis/test/fsqr/%s'');',
            file_name
        );

        execute 'insert into foursquare_os_places
                 select
                     fsq_place_id,
                     name,
                     latitude,
                     longitude,
                     address,
                     locality,
                     region,
                     postcode,
                     admin_region,
                     post_town,
                     po_box,
                     country,
                     date_created,
                     date_refreshed,
                     date_closed,
                     tel,
                     website,
                     email,
                     facebook_id,
                     instagram,
                     twitter,
                     fsq_category_ids,
                     fsq_category_labels,
                     geom
                 from temp_parquet_table;';

        -- Drop the temporary foreign table after use
        execute 'drop foreign table temp_parquet_table;';

         -- Debug: Notify about completion for the file
        raise notice 'File % processed successfully.', file_name;
    end loop;
end $$;

create index on foursquare_os_places using gin(fsq_category_ids);

-- upload file with categories
drop foreign table if exists temp_parquet_table;
create foreign table temp_parquet_table ( 
    category_id text,
    category_level int,
    category_name text,
    category_label text,
    level1_category_id text,
    level1_category_name text,
    level2_category_id text,
    level2_category_name text,
    level3_category_id text,
    level3_category_name text,
    level4_category_id text,
    level4_category_name text,
    level5_category_id text,
    level5_category_name text,
    level6_category_id text,
    level6_category_name text
) server parquet_srv options (filename '/home/gis/test/fsqr/categories.zstd.parquet');

drop table if exists foursquare_os_places_categories;
create table foursquare_os_places_categories as (
    select * from temp_parquet_table
);

drop foreign table if exists temp_parquet_table;
