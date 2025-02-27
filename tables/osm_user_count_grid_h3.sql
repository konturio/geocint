drop table if exists osm_user_count_grid_h3;
create table osm_user_count_grid_h3 as (
    select h3, 
           osm_users,
           osm_users_array,
           resolution 
    from osm_object_count_grid_h3_r8
);

do
$$
    declare
        res integer;
    begin
        res = 8;
        while res > 0
            loop
                insert into osm_user_count_grid_h3 (resolution, h3, osm_users, osm_users_array)
                select (res - 1) as resolution,
                       h3_cell_to_parent(h3) as h3,
                       count(distinct osm_user) as osm_users,
                       array_agg(distinct osm_user) as osm_users_array
                from osm_user_count_grid_h3, unnest(osm_users_array) as osm_user
                where resolution = res
                group by 2;
                res = res - 1;
            end loop;
    end;
$$;
