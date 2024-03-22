drop table if exists bivariate_indicators_prod;
create table bivariate_indicators_prod 
(
    param_id   text,
    param_label text,
    copyrights json,
    direction json,
    is_base boolean not null default false,
    description text,
    coverage text,
    update_frequency text,
    is_public boolean,
    application json,
    unit_id text
);

alter table bivariate_indicators
    set (parallel_workers = 32);

insert into bivariate_indicators_prod 
        select * 
        from bivariate_indicators 
        where param_id in (select indicator from prod_indicators_list);

-- set indicator is_base to become denominators
update bivariate_indicators_prod
set is_base = true
where param_id in ('population', 'area_km2', 'one'); -- experiment with disabling three base indicators/denominators
-- where param_id in ('population', 'total_building_count', 'area_km2', 'populated_area_km2', 'one', 'total_road_length');

--- this is an ugly hack to enable Parallel Seq Scan on bivariate_indicators
-- Postgres parallel seq scan works on page level, so we can't really get it to run more workers than there are
-- pages in source table, so we make sure that the pages are filled in as sparsely as possible.
alter table bivariate_indicators_prod set (fillfactor = 10);
alter table bivariate_indicators_prod add column baloon text;
alter table bivariate_indicators_prod alter column baloon set storage external;
alter table bivariate_indicators_prod alter column copyrights set storage external;
update bivariate_indicators_prod set baloon = repeat(' ', 3000);
vacuum full bivariate_indicators_prod;
alter table bivariate_indicators_prod drop column baloon;