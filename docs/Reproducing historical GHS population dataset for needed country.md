# Reproducing historical GHS population dataset for needed country

Field: Content

### How to reuse this code:
* create a new temporary branch:

```
cd geocint
git checkout master && git pull
git checkout -b 99999-historical-population-dataset-united-states
```
* check if there is a new version of the GHS population, if so - add a link to geocint/static_data/ghsl/list-of-urls
* change the end goal (for example, to extract United States - the top level hash code is "US") according to the example below - replace the top level hash code of India with the top level hash code of the desired country):

```
from

data/out/ghsl_output/export_gpkg: db/table/export_ghsl_h3_dither | data/out/ghsl_IN ## Exports gpkg for India, hasc equal IN from tables
	seq 1975 5 2020 | parallel "ogr2ogr -overwrite -f GPKG kontur_historical_population_density_for_{}_IN_20230623.gpkg PG:'dbname=gis' -sql 'select distinct a.h3, a.population, a.geom from ghs_pop_e{}_globe_r2022a_54009_100_v1_0_h3_dither as a, kontur_boundaries as b where b.osm_id =2088990 and ST_Intersects(a.geom,b.geom)' -nln kontur_historical_population_density_for_{}_IN_20230623 -lco OVERWRITE=yes"
	touch $@

to
	
	data/out/ghsl_output/export_gpkg: db/table/export_ghsl_h3_dither | data/out/ghsl_US ## Exports gpkg for India, hasc equal US from tables
	seq 1975 5 2020 | parallel "ogr2ogr -overwrite -f GPKG kontur_historical_population_density_for_{}_US_20230623.gpkg PG:'dbname=gis' -sql 'select distinct a.h3, a.population, a.geom from ghs_pop_e{}_globe_r2022a_54009_100_v1_0_h3_dither as a, kontur_boundaries as b where b.osm_id =2088990 and ST_Intersects(a.geom,b.geom)' -nln kontur_historical_population_density_for_{}_US_20230623 -lco OVERWRITE=yes"
	touch $@
```
* go to geocint server and run this part of pipeline from geocint forlder:

```
cd geocint-kontur

-- switch to your new branch
git pull && git checkout 99999-historical-population-dataset-united-states

-- go out and copy changed files to ~/geocint forled
cd ~/
cp geocint-kontur/Makefile geocint/Makefile
cp geocint-kontur/functions/ghs_pop_dither.sql geocint/functions/ghs_pop_dither.sql
cp geocint-kontur/static_data/ghsl/list-of-urls geocint/static_data/ghsl/list-of-urls

-- go to ~/geocint forder and run needed part of pipeline
cd ~/geocint
profile_make -j -k data/out/ghsl_output/export_gpkg
```
* wait until pipeline will finished
* copy your data from ***/home/gis/geocint/data/out/*** folder:

```
cd /home/gis/geocint/data/out/ 

-- zip all geopackages
zip GHS_historical_population_US.zip *.gpkg

-- check filesize after zipping
ls -lh

-- load zip file to aws
aws s3 cp GHS_historical_population_US.zip s3://geodata-eu-central-1-kontur-public/kontur_datasets/GHS_historical_population_US.zip --acl public-read --profile geocint_pipeline_sender

your link example - https://geodata-eu-central-1-kontur-public.s3.eu-central-1.amazonaws.com/kontur_datasets/GHS_historical_population_US.zip

-- clean folder
rm *.gpkg && rm *.zip
	
```
* clean database:

```
cd ~/geocint
ls data/mid/ghsl/*.tif | parallel 'psql -c "drop table if exists {/.};"'
ls data/mid/ghsl/*.tif | parallel 'psql -c "drop table if exists {/.}_h3;"'
ls data/mid/ghsl/*.tif | parallel 'psql -c "drop table if exists {/.}_h3_dither;"'
```
