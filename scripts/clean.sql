drop table if exists z8_grid;
drop table if exists z_grid;
drop table if exists osm_quality_bivariate_tiles;

drop table if exists insights_api_indicators_list_test;
drop table if exists insights_api_indicators_list_prod;
drop table if exists insights_api_indicators_list_dev;

create table if not exists insights_api_indicators_list_test(j jsonb);
create table if not exists insights_api_indicators_list_dev(j jsonb);
create table if not exists insights_api_indicators_list_prod(j jsonb);