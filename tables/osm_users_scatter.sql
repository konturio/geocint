drop table if exists osm_users_hex_in;
create table osm_users_hex_in as (
    select *
    from osm_user_count_grid_h3
    order by h3, count desc, osm_user
);
create index osm_users_hex_in_h3_osm_user on osm_users_hex_in (h3, osm_user);
create index osm_users_hex_in_osm_user_count_h3 on osm_users_hex_in (osm_user, count desc, h3);

drop table if exists osm_users_hex_out;
create table osm_users_hex_out
(
    h3 h3index, osm_user text, resolution integer, count bigint, hours bigint
);

do
$$
    declare
        z integer;
        cur_user text;
        cur_hex  record;
    begin
        for z in (select distinct resolution from osm_users_hex_in)
            loop
                for cur_user in (
                    select osm_user from osm_user_object_count where count > 20 and resolution = z order by max_hours desc, hex_count
                )
                    loop
                        select h3, resolution, count, hours
                        into cur_hex
                        from osm_users_hex_in
                        where osm_user = cur_user and resolution = z
                        order by hours desc
                        limit 1;
                        if cur_hex is not null then
                            insert into osm_users_hex_out (h3, osm_user, resolution, count, hours)
                            values (cur_hex.h3, cur_user, cur_hex.resolution, cur_hex.count, cur_hex.hours);
                            delete from osm_users_hex_in where h3 = cur_hex.h3 and resolution = z;
                            delete from osm_users_hex_in using h3_k_ring(cur_hex.h3, 3) r
                                where h3 = r and osm_user = cur_user and resolution = z;
                            --raise notice '%s %s', cur_hex, cur_user;
                        end if;
                    end loop;
            end loop;
    end;
$$;

drop index osm_users_hex_in_osm_user_count_h3;
vacuum full osm_users_hex_in;
vacuum analyse osm_users_hex_in;
create index osm_users_hex_in_count_h3_osm_user_idx on osm_users_hex_in (count desc, h3, osm_user);
cluster osm_users_hex_in using osm_users_hex_in_count_h3_osm_user_idx;
--drop index osm_users_hex_in_count_h3_osm_user_idx;
vacuum osm_users_hex_in;

create or replace procedure trim_osm_users_h3()
    language plpgsql
as
$$
declare
    cur_rec   record;
    counter   integer;
    total_rec integer;
    last_seen timestamptz;
begin
    counter = 0;
    total_rec = (
        select count(*)
        from osm_users_hex_in
    );
    last_seen = clock_timestamp();
-- This whole loop is a trick.
-- We could have pulled this row in a loop like "cur_rec = select * from .... order by ... limit 1" with an index lookup.
-- That would work for an app but not in batch process: in batch process we have no spot to reorganize/vacuum table between loop iterations, and deleted entries are still in table and rechecked internally. So this index-order-by keeps removing head of the table and looks for first not-deleted entry on each iteration, which is slow.
-- Instead we do it other way: take snapshot of table and loop on it, using "for rec in (select...)". That removes rechecking that removed head of the table is actually removed, but we still have another problem: it's a snapshot, so rows we deleted from the queue "in the future" are still getting returned.
-- Luckily you can quickly check if a row is not deleted outside of snapshot, by selecting it by ctid. It's going to be a TID scan that goes to the page on disk directly and rechecks that it's still visible to new transaction.
-- This construction hinges on the fact that ctid's aren't going to change from old snapshot to new recheck transaction. However, from time to time we need to shrink the table, to save on the rechecks in the future.
-- That's why this all is wrapped into PROCEDURE - procedures can exist outside of transactions and perform maintenance operations, unlike functions.
-- Best would be to VACUUM FULL the table, just to shift values into holes. But for some reason it's not allowed in procedures. (that's a thing to report as a bug in postgres)
-- CLUSTER, which is internally same as VACUUM FULL with a sort by index, is luckily allowed.
-- CLUSTER renumbers all physical identifiers, so the loop has to be restarted and CLUSTER has to be performed outside of it.
    while true
        loop

            for cur_rec in (
                select h3, osm_user, ctid, resolution, count, hours from osm_users_hex_in order by hours desc, h3 limit 100000
            )
                loop
                    if not exists(select from osm_users_hex_in where ctid = cur_rec.ctid) then
                        continue;
                    end if;
                    counter = counter + 1;
                    if counter % 10000 = 0 then
                        raise warning '% %% - % of % (% per block, % left)', 100.0 * counter / total_rec, counter, total_rec, clock_timestamp() - last_seen, (clock_timestamp() - last_seen) * (total_rec - counter) / 10000;
                        last_seen = clock_timestamp();
                        commit;
                    end if;
                    insert into osm_users_hex_out (h3, osm_user, resolution, count, hours)
                    values (cur_rec.h3, cur_rec.osm_user, cur_rec.resolution, cur_rec.count, cur_rec.hours);
                    delete from osm_users_hex_in where h3 = cur_rec.h3;
                    delete
                    from osm_users_hex_in using h3_k_ring(cur_rec.h3, 3) r
                    where h3 = r
                      and osm_user = cur_rec.osm_user;
                    --raise notice '%s %s', cur_rec.osm_user, cur_rec.h3;
                end loop;

            raise warning 'clustering...';
            cluster osm_users_hex_in;
            raise warning 'clustered in %', clock_timestamp() - last_seen;
            last_seen = clock_timestamp();
            total_rec = (
                            select count(*)
                            from osm_users_hex_in
                        ) + counter;
            if total_rec = counter then exit;
            end if;
        end loop;
end;
$$;
call trim_osm_users_h3();

drop table if exists osm_users_hex;
create table osm_users_hex as (
    select a.*,
           hex.area / 1000000.0 as area_km2,
           hex.geom             as geom
    from osm_users_hex_out a
             join ST_HexagonFromH3(h3) hex on true
    order by geom
);