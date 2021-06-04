#!/usr/bin/env bash

cd /home/gis/geocint/data/osm_buildings_drp/
rm -f osm_buildings_*.gpkg
rm -f osm_buildings_*.gpkg.gz

ogr2ogr -lco OVERWRITE=YES -f GPKG osm_buildings_new_york.gpkg PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_new_york' -lco "SPATIAL_INDEX=NO" -nln osm_buildings
ogr2ogr -append -update -f GPKG osm_buildings_new_york.gpkg PG:'dbname=gis' -sql 'select id, "name", geom from osm_boundary_new_york' -lco "SPATIAL_INDEX=NO" -nln osm_boundary

ogr2ogr -lco OVERWRITE=YES -f GPKG osm_buildings_new_orleans.gpkg PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_new_orleans' -lco "SPATIAL_INDEX=NO" -nln osm_buildings
ogr2ogr -append -update -f GPKG osm_buildings_new_orleans.gpkg PG:'dbname=gis' -sql 'select id, "name", geom from osm_boundary_new_orleans' -lco "SPATIAL_INDEX=NO" -nln osm_boundary

ogr2ogr -lco OVERWRITE=YES -f GPKG osm_buildings_los_angeles.gpkg PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_los_angeles' -lco "SPATIAL_INDEX=NO" -nln osm_buildings
ogr2ogr -append -update -f GPKG osm_buildings_los_angeles.gpkg PG:'dbname=gis' -sql 'select id, "name", geom from osm_boundary_los_angeles' -lco "SPATIAL_INDEX=NO" -nln osm_boundary

ogr2ogr -lco OVERWRITE=YES -f GPKG osm_buildings_mexico_city.gpkg PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_mexico_city' -lco "SPATIAL_INDEX=NO" -nln osm_buildings
ogr2ogr -append -update -f GPKG osm_buildings_mexico_city.gpkg PG:'dbname=gis' -sql 'select id, "name", geom from osm_boundary_mexico_city' -lco "SPATIAL_INDEX=NO" -nln osm_boundary

ogr2ogr -lco OVERWRITE=YES -f GPKG osm_buildings_corpus_christi.gpkg PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_corpus_christi' -lco "SPATIAL_INDEX=NO" -nln osm_buildings
ogr2ogr -append -update -f GPKG osm_buildings_corpus_christi.gpkg PG:'dbname=gis' -sql 'select id, "name", geom from osm_boundary_corpus_christi' -lco "SPATIAL_INDEX=NO" -nln osm_boundary

ogr2ogr -lco OVERWRITE=YES -f GPKG osm_buildings_atlantic_city.gpkg PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_atlantic_city' -lco "SPATIAL_INDEX=NO" -nln osm_buildings
ogr2ogr -append -update -f GPKG osm_buildings_atlantic_city.gpkg PG:'dbname=gis' -sql 'select id, "name", geom from osm_boundary_atlantic_city' -lco "SPATIAL_INDEX=NO" -nln osm_boundary

ogr2ogr -lco OVERWRITE=YES -f GPKG osm_buildings_lake_charles.gpkg PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_lake_charles' -lco "SPATIAL_INDEX=NO" -nln osm_buildings
ogr2ogr -append -update -f GPKG osm_buildings_lake_charles.gpkg PG:'dbname=gis' -sql 'select id, "name", geom from osm_boundary_lake_charles' -lco "SPATIAL_INDEX=NO" -nln osm_boundary

ogr2ogr -lco OVERWRITE=YES -f GPKG osm_buildings_apalachicola.gpkg PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_apalachicola' -lco "SPATIAL_INDEX=NO" -nln osm_buildings
ogr2ogr -append -update -f GPKG osm_buildings_apalachicola.gpkg PG:'dbname=gis' -sql 'select id, "name", geom from osm_boundary_apalachicola' -lco "SPATIAL_INDEX=NO" -nln osm_boundary

ogr2ogr -lco OVERWRITE=YES -f GPKG osm_buildings_panama_city.gpkg PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_panama_city' -lco "SPATIAL_INDEX=NO" -nln osm_buildings
ogr2ogr -append -update -f GPKG osm_buildings_panama_city.gpkg PG:'dbname=gis' -sql 'select id, "name", geom from osm_boundary_panama_city' -lco "SPATIAL_INDEX=NO" -nln osm_boundary

ogr2ogr -lco OVERWRITE=YES -f GPKG osm_buildings_rome.gpkg PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_rome' -lco "SPATIAL_INDEX=NO" -nln osm_buildings
ogr2ogr -append -update -f GPKG osm_buildings_rome.gpkg PG:'dbname=gis' -sql 'select id, "name", geom from osm_boundary_rome' -lco "SPATIAL_INDEX=NO" -nln osm_boundary

ogr2ogr -lco OVERWRITE=YES -f GPKG osm_buildings_paris.gpkg PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_paris' -lco "SPATIAL_INDEX=NO" -nln osm_buildings
ogr2ogr -append -update -f GPKG osm_buildings_paris.gpkg PG:'dbname=gis' -sql 'select id, "name", geom from osm_boundary_paris' -lco "SPATIAL_INDEX=NO" -nln osm_boundary

ogr2ogr -lco OVERWRITE=YES -f GPKG osm_buildings_london.gpkg PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_london' -lco "SPATIAL_INDEX=NO" -nln osm_buildings
ogr2ogr -append -update -f GPKG osm_buildings_london.gpkg PG:'dbname=gis' -sql 'select id, "name", geom from osm_boundary_london' -lco "SPATIAL_INDEX=NO" -nln osm_boundary

ogr2ogr -lco OVERWRITE=YES -f GPKG osm_buildings_manila.gpkg PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_manila' -lco "SPATIAL_INDEX=NO" -nln osm_buildings
ogr2ogr -append -update -f GPKG osm_buildings_manila.gpkg PG:'dbname=gis' -sql 'select id, "name", geom from osm_boundary_manila' -lco "SPATIAL_INDEX=NO" -nln osm_boundary

ogr2ogr -lco OVERWRITE=YES -f GPKG osm_buildings_christchurch.gpkg PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_christchurch' -lco "SPATIAL_INDEX=NO" -nln osm_buildings
ogr2ogr -append -update -f GPKG osm_buildings_christchurch.gpkg PG:'dbname=gis' -sql 'select id, "name", geom from osm_boundary_christchurch' -lco "SPATIAL_INDEX=NO" -nln osm_boundary

ogr2ogr -lco OVERWRITE=YES -f GPKG osm_buildings_sydney.gpkg PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_sydney' -lco "SPATIAL_INDEX=NO" -nln osm_buildings
ogr2ogr -append -update -f GPKG osm_buildings_sydney.gpkg PG:'dbname=gis' -sql 'select id, "name", geom from osm_boundary_sydney' -lco "SPATIAL_INDEX=NO" -nln osm_boundary

ogr2ogr -lco OVERWRITE=YES -f GPKG osm_buildings_johannesburg.gpkg PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_johannesburg' -lco "SPATIAL_INDEX=NO" -nln osm_buildings
ogr2ogr -append -update -f GPKG osm_buildings_johannesburg.gpkg PG:'dbname=gis' -sql 'select id, "name", geom from osm_boundary_johannesburg' -lco "SPATIAL_INDEX=NO" -nln osm_boundary

ogr2ogr -lco OVERWRITE=YES -f GPKG osm_buildings_casablanca.gpkg PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_casablanca' -lco "SPATIAL_INDEX=NO" -nln osm_buildings
ogr2ogr -append -update -f GPKG osm_buildings_casablanca.gpkg PG:'dbname=gis' -sql 'select id, "name", geom from osm_boundary_casablanca' -lco "SPATIAL_INDEX=NO" -nln osm_boundary

ogr2ogr -lco OVERWRITE=YES -f GPKG osm_buildings_riad.gpkg PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_riad' -lco "SPATIAL_INDEX=NO" -nln osm_buildings
ogr2ogr -append -update -f GPKG osm_buildings_riad.gpkg PG:'dbname=gis' -sql 'select id, "name", geom from osm_boundary_riad' -lco "SPATIAL_INDEX=NO" -nln osm_boundary

ogr2ogr -lco OVERWRITE=YES -f GPKG osm_buildings_lagos.gpkg PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_lagos' -lco "SPATIAL_INDEX=NO" -nln osm_buildings
ogr2ogr -append -update -f GPKG osm_buildings_lagos.gpkg PG:'dbname=gis' -sql 'select id, "name", geom from osm_boundary_lagos' -lco "SPATIAL_INDEX=NO" -nln osm_boundary

ogr2ogr -lco OVERWRITE=YES -f GPKG osm_buildings_accra.gpkg PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_accra' -lco "SPATIAL_INDEX=NO" -nln osm_buildings
ogr2ogr -append -update -f GPKG osm_buildings_accra.gpkg PG:'dbname=gis' -sql 'select id, "name", geom from osm_boundary_accra' -lco "SPATIAL_INDEX=NO" -nln osm_boundary

ogr2ogr -lco OVERWRITE=YES -f GPKG osm_buildings_santo_domingo.gpkg PG:'dbname=gis' -sql 'select building, street, hno, levels, height, use, "name", geom from osm_buildings_santo_domingo' -lco "SPATIAL_INDEX=NO" -nln osm_buildings
ogr2ogr -append -update -f GPKG osm_buildings_santo_domingo.gpkg PG:'dbname=gis' -sql 'select id, "name", geom from osm_boundary_santo_domingo' -lco "SPATIAL_INDEX=NO" -nln osm_boundary

pigz osm_buildings_*.gpkg
