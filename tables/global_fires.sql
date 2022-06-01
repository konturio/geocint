set timezone to utc;

create table if not exists global_fires (like global_fires_in) tablespace evo4tb;

drop table if exists global_fires_new;
create table global_fires_new as (
    select *
    from global_fires
    where acq_datetime > now() - interval '13 months'
    union all
    select distinct on (n.hash) n.*
    from global_fires_in n
         left outer join global_fires gf
            on n.hash = gf.hash
    where gf.hash is null
      and n.acq_datetime > now() - interval '13 months'
    order by acq_datetime, hash
);
