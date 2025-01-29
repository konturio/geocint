-- Drop the temporary foreign table after use
drop foreign table if exists temp_parquet_table;

create foreign table temp_parquet_table ( 
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
            ) server parquet_srv options (filename :'parquet_file');

insert into foursquare_os_places
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
                 from temp_parquet_table;

drop foreign table temp_parquet_table;
