# Population tag check report

As part of the Disaster Ninja reports, we have created a "[population tag check](https://disaster.ninja/active/reports/population_tag_check "https://disaster.ninja/active/reports/population_tag_check")" report. In this report, we compare the OpenStreetMap and Kontur datasets. Find discrepancies between [Kontur Population](https://www.kontur.io/portfolio/population-dataset/) and [OpenStreetMap](https://wiki.openstreetmap.org/wiki/Key:population) data to see potential errors in OpenStreetMap population data. [Kontur Population](https://data.humdata.org/dataset/kontur-population-dataset) is a global population dataset generated based on various public data sources including OpenStreetMap. Inconsistencies in the values between Kontur data and OpenStreetMap population key on administrative division boundaries may indicate inaccuracies in OSM data or in Kontur algorithm. The main idea is to create a machine-readable table with OSM id and valid value for subsequent export

### Work with Population tag check report

   1\. Open JOSM on your computer, enable remote control in the settings

   2\. Open the “[population tag check](https://disaster.ninja/active/reports/population_tag_check "https://disaster.ninja/active/reports/population_tag_check")” report

   3\. Open the region of interest in JOSM

   4\. Turn on the satellite imagery layer, for example, Maxar.

   5\. Visually evaluate the number of buildings in the region and determine to which number of the two datasets it is closer.

   6\. By default, the population specified in the OpenStreetMap is considered correct.

   7\. If you saw a controversial point, for example, the population of the region is very different from both the OSM and the Kontur, find a suitable data source and specify the population size.

   8\. Work with the report is carried out in a [google table](https://docs.google.com/spreadsheets/d/1ULDBA1KPCRdwvc4Cu6BLm8da2khDDcKfbtc8Pgdqd0g/edit#gid=0 "https://docs.google.com/spreadsheets/d/1ULDBA1KPCRdwvc4Cu6BLm8da2khDDcKfbtc8Pgdqd0g/edit#gid=0"). Enter the number that seems correct to you based on the above In the "Valid population" column in the [table](https://docs.google.com/spreadsheets/d/1ULDBA1KPCRdwvc4Cu6BLm8da2khDDcKfbtc8Pgdqd0g/edit#gid=0 "https://docs.google.com/spreadsheets/d/1ULDBA1KPCRdwvc4Cu6BLm8da2khDDcKfbtc8Pgdqd0g/edit#gid=0")

   9\. After checking the region, mark in the "check" column.
