drop table if exists osm_user_count_grid_h3;
create table osm_user_count_grid_h3 as (
    select resolution,
           h3,
           osm_user,
           count(*) as count,
           count(distinct hours) as hours
    from (
             select
                 resolution as resolution,
                 h3         as h3,
                 osm_user   as osm_user,
                 date_trunc('hour', ts) as hours
             from osm,
                  ST_H3Bucket(geog) as hex
             where ts > (select (meta -> 'data' -> 'timestamp' ->> 'last')::timestamptz
                          from osm_meta) - interval '2 years'
         ) z
    group by 1, 2, 3
);

delete from osm_user_count_grid_h3 
	where exists 
	(select 1 
	from users_deleted 
	where 
	osm_user_count_grid_h3.osm_user = users_deleted.osm_user);

-- clean up some known bots and import accounts from the low zoom maps.
delete from osm_user_count_grid_h3 where osm_user in ('NeisBot', 'b-jazz-bot', 'SomeoneElse_Revert', 'SherbetS_Import', 'Mateusz Konieczny - bot account', 'NorthCrab_upload', 'woodpeck_repair', 'kmpoppe (@ Mapillary Update)', 'autoAWS', '❤‍🔥import', 'latvia-bot', 'kapazao_import', 'cquest_bot', 'zluuzki_Import', 'PlayzinhoAgro-imports', 'wb_import', 'popball-import', 'Reitstoen_import', 'wheelmap_visitor', 'Serbian OSM Lint bot', 'asibwene_ImportAccount', 'William Mponeja_ImportAccount', 'Samwel Kyando_Import Account', 'NeemaAlphonce_ImportAccount', 'Abou kachongo jr_ImportAccount', 'HellenGaspar_ImportAccount' );

create index on osm_user_count_grid_h3 (h3);
