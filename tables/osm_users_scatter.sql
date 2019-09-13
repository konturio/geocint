drop table if exists osm_users_hex_in;
create table osm_users_hex_in as (
    select *
    from osm_user_count_grid_h3
    where resolution = 7
    order by h3, count desc, osm_user
);
create index osm_users_hex_in_h3_osm_user on osm_users_hex_in (h3, osm_user);
create index osm_users_hex_in_osm_user_count_h3 on osm_users_hex_in (osm_user, count desc, h3);

drop table if exists osm_users_hex_out;
create table osm_users_hex_out
(
    h3       h3index,
    osm_user text
);

do
$$
    declare
        cur_user text;
        cur_hex  h3index;
    begin
        for cur_user in (select osm_user from osm_user_object_count where count > 20 order by max_count desc, hex_count)
            loop
                cur_hex = (select h3 from osm_users_hex_in where osm_user = cur_user order by count desc limit 1);
                if cur_hex is not null then
                    insert into osm_users_hex_out (
                                                      h3, osm_user
                    )
                    values
                    (
                        cur_hex, cur_user
                    );
                    delete from osm_users_hex_in where h3 = cur_hex;
                    delete from osm_users_hex_in using h3_k_ring(cur_hex, 3) r where h3 = r and osm_user = cur_user;
                    --raise notice '%s %s', cur_hex, cur_user;
                end if;
            end loop;
    end;
$$;

drop table if exists osm_users_hex;
create table osm_users_hex as (
    select a.*,
           hex.area / 1000000.0 as area_km2,
           hex.geom             as geom
    from osm_users_hex_out a
             join ST_HexagonFromH3(h3) hex on true
);

drop index osm_users_hex_in_osm_user_count_h3;
vacuum full osm_users_hex_in;
vacuum analyse osm_users_hex_in;
create index osm_users_hex_in_count_h3_osm_user_idx on osm_users_hex_in (count desc, h3, osm_user);
cluster osm_users_hex_in using osm_users_hex_in_count_h3_osm_user_idx;
drop index osm_users_hex_in_count_h3_osm_user_idx;
vacuum osm_users_hex_in;
do
$$
    declare
        cur_rec record;
        counter integer;
    begin
        counter = 0;
        for cur_rec in (select h3, osm_user, ctid from osm_users_hex_in order by count desc, h3)
        loop
            if not exists(select from osm_users_hex_in where ctid = cur_rec.ctid) then
  --              raise notice '%s %s', cur_rec.osm_user, cur_rec.h3;
                continue ;
            end if;
            counter = counter + 1;
            if counter % 10000 = 0 then
                raise warning '%s of %s', counter, (select count(*) from osm_users_hex_in);
                --exit;
            end if;
--             select h3, osm_user into cur_rec from osm_users_hex_in order by count desc, h3 limit 1;
--             if cur_rec is null then
--                 exit;
--             end if;
            insert into osm_users_hex_out (
                                              h3, osm_user
            )
            values
            (
                cur_rec.h3, cur_rec.osm_user
            );
            delete from osm_users_hex_in where h3 = cur_rec.h3;
            delete
            from osm_users_hex_in using h3_k_ring(cur_rec.h3, 3) r
            where h3 = r
              and osm_user = cur_rec.osm_user;
            --raise notice '%s %s', cur_rec.osm_user, cur_rec.h3;
        end loop;
    end;
$$;





drop table if exists osm_users_hex;
create table osm_users_hex as (
    select a.*,
           hex.area / 1000000.0 as area_km2,
           hex.geom             as geom
    from osm_users_hex_out a
             join ST_HexagonFromH3(h3) hex on true
    order by geom
);