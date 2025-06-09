drop table if exists bivariate_indicators;
create table bivariate_indicators
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
    unit_id text,
    emoji text,
    downscale text
);

alter table bivariate_indicators
    set (parallel_workers = 32);

-- rows are loaded from static_data/bivariate_indicators.csv via Makefile
