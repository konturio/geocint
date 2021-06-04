drop table if exists basemap_mvts;
create table basemap_mvts (
    tile_z integer not null,
    tile_x integer not null,
    tile_y integer not null,
    mvt bytea
);

alter table basemap_mvts add constraint pkey primary key (tile_z, tile_x, tile_y);
