---use more osm_local_active_users

drop table if exists osm_users_hex_in;
create table osm_users_hex_in as (select *
                                  from osm_user_count_grid_h3
                                  order by h3, count desc, osm_user);
create index osm_users_hex_in_h3_osm_user on osm_users_hex_in (h3, osm_user);
create index osm_users_hex_in_osm_user_resolution_hours on osm_users_hex_in (osm_user, resolution, hours desc);

drop table if exists osm_users_hex_out;
create table osm_users_hex_out
(
    h3         h3index,
    osm_user   text,
    resolution integer,
    count      bigint,
    hours      bigint
);

do
$$
    declare
        z        integer;
        cur_user record;
        cur_hex  record;
    begin
        for z in (select distinct resolution from osm_users_hex_in)
            loop
                for cur_user in (
                    select osm_user, geom
                    from osm_local_active_users
                    order by hours desc, ST_Z(geom) desc
                )
                    loop
                        select a.h3, a.resolution, a.count, a.hours
                        into cur_hex
                        from osm_users_hex_in a
                        where osm_user = cur_user.osm_user
                          and resolution = z
                        order by hours desc
                        limit 1;
                        if cur_hex is not null then
                            insert into osm_users_hex_out (h3, osm_user, resolution, count, hours)
                            values (cur_hex.h3, cur_user.osm_user, cur_hex.resolution, cur_hex.count, cur_hex.hours);
                            delete from osm_users_hex_in where h3 = cur_hex.h3;
                            delete
                            from osm_users_hex_in using h3_grid_disk(cur_hex.h3, 3) r
                            where h3 = r
                              and osm_user = cur_user.osm_user;
                            raise notice 'added % %', cur_user.osm_user, z;
                        end if;
                        raise notice 'finished % %', cur_user.osm_user, z;
                    end loop;
            end loop;
    end;
$$;

drop index osm_users_hex_in_osm_user_resolution_hours;

create index osm_users_hex_in_resolution_hours_h3 on osm_users_hex_in (resolution, hours desc, h3);
cluster osm_users_hex_in using osm_users_hex_in_resolution_hours_h3;
vacuum analyze osm_users_hex_in;

create or replace procedure trim_osm_users_h3()
    language plpgsql
as
$$
declare
    cur_rec      record;
    counter      integer;
    total_rec    integer;
    dead_rec     integer;
    last_seen    timestamptz;
    last_cluster timestamptz;
    cluster_time interval;
begin
    counter = 0;
    dead_rec = 0;
    last_cluster = clock_timestamp();
    cluster_time = '2 min';
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
                select h3, osm_user, ctid, resolution, count, hours
                from osm_users_hex_in
                order by resolution, hours desc, h3
                limit 500000
            )
                loop
                    if not exists(select from osm_users_hex_in where ctid = cur_rec.ctid) then
                        dead_rec = dead_rec + 1;
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
                    from osm_users_hex_in using h3_grid_disk(cur_rec.h3, 3) r
                    where h3 = r
                      and osm_user = cur_rec.osm_user;
                    --raise notice '%s %s', cur_rec.osm_user, cur_rec.h3;
                end loop;
            if dead_rec > 250000 and (clock_timestamp() - last_cluster > cluster_time) then
                dead_rec = 0;
                raise warning 'clustering...';
                last_cluster = clock_timestamp();
                cluster osm_users_hex_in;
                cluster_time = clock_timestamp() - last_cluster;
                last_cluster = clock_timestamp();
                raise warning 'clustered in %', cluster_time;
                last_seen = clock_timestamp();
            end if;
            total_rec = (
                            select count(*)
                            from osm_users_hex_in
                        ) + counter;
            if total_rec = counter then
                exit;
            end if;
        end loop;
end;
$$;
call trim_osm_users_h3();

drop table if exists osm_users_hex;
create table osm_users_hex as (
    select a.*,
           st_area(h3_cell_to_boundary_geometry(a.h3)::geography) / 1000000.0 as area_km2,
           st_transform(h3_cell_to_boundary_geometry(a.h3), 3857) as geom,
           false                as is_local
    from osm_users_hex_out a
    order by geom
);

create index on osm_users_hex using gist (resolution, geom);
create index on osm_users_hex using btree (osm_user);

update osm_users_hex ouh
set is_local = true
from osm_local_active_users olau
where ouh.osm_user = olau.osm_user
  and ST_Intersects(
        ST_Transform(ST_Buffer(olau.geog, 50000)::geometry, 3857),
        ouh.geom
    );
