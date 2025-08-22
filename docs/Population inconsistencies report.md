# Population inconsistencies report

As part of Disaster Ninja reporting, we created a [population inconsistencies report](https://test-apps-ninja02.konturlabs.com/active/reports "https://test-apps-ninja02.konturlabs.com/active/reports"). In this report we compare data from the Kontur population dataset with data in OpenStreetMap. We then analyse the inconsistencies and try to correct them. The most popular reasons for inconsistencies are administrative boundary hierarchy discrepancies and false information in the "population" tag. Do not forget to include the census date, if known.\
\
Here you will find instructions on how to process the population inconsistencies report. Follow the flowchart and you'll get it right. Below you will find estimate time of each actions.

### Work with Population inconsistencies

1. Open [JOSM](https://josm.openstreetmap.de/ "https://josm.openstreetmap.de/") on your computer, enable [remote control](https://josm.openstreetmap.de/wiki/Help/Preferences/RemoteControl "https://josm.openstreetmap.de/wiki/Help/Preferences/RemoteControl") in the settings
2. Open the [report itself](https://test-apps-ninja02.konturlabs.com/active/reports/osm_population_inconsistencies "https://test-apps-ninja02.konturlabs.com/active/reports/osm_population_inconsistencies"). Choose and open parent boundary clicking on it's name (parent boundaries are located above the delimiter line and child sub boundaries below).
3. Check if values [admin_level](https://wiki.openstreetmap.org/wiki/Key:admin_level "https://wiki.openstreetmap.org/wiki/Key:admin_level") matches this [article](https://wiki.openstreetmap.org/wiki/Tag:boundary%3Dadministrative#10_admin_level_values_for_specific_countries "https://wiki.openstreetmap.org/wiki/Tag:boundary%3Dadministrative#10_admin_level_values_for_specific_countries"). If there are inconsistencies, correct them.
4. Check [population](https://wiki.openstreetmap.org/wiki/Key:population "https://wiki.openstreetmap.org/wiki/Key:population") for the chosen area in wikipedia or in other sources. If you are using wikipedia to find a source, try opening articles in different languages. For example, articles in German will often be relevant for South America and French for Africa.
5. Compare tag "population" with the population in sources. If the values differ, verify the source is reliable, then correct the tag in area.
6. If the population tag in the open parent area matches the number in the source, open inner areas in the report.
7. Check each inner region against the source and correct tags.
8. Send the [changeset](https://wiki.openstreetmap.org/wiki/Changeset "https://wiki.openstreetmap.org/wiki/Changeset") to osm, don't forget to specify the hashtag *#Kontur* in comments.

![Снимок экрана 2021-11-18 в 13.07.37.png](https://kontur.fibery.io/api/files/cb43c9fa-2691-4404-b8aa-654ea75e722b#align=%3Aalignment%2Fblock-left&width=949&height=1234 "")Link on document:

1. Block schema: <https://miro.com/welcomeonboard/VHppZGE3bEV2bmhVS2t5N296Zk9lZ2NhaUJnbVEzNVJVWmtMeVAyemNSbERzTmdPckE4Y20wMFVMcXpQS0kxMnwzMDc0NDU3MzUwNDczMzUzODgz?invite_link_id=243751969912> 
2. Population inconsistencies. This report indicates potential errors in OpenStreetMap population key values: [https://test-apps-ninja02.konturlabs.com/active/reports/osm_population_inconsistencies](https://test-apps-ninja02.konturlabs.com/active/reports/osm_population_inconsistencies "https://test-apps-ninja02.konturlabs.com/active/reports/osm_population_inconsistencies")
3. Countries using admin_level 3–10 [https://wiki.openstreetmap.org/wiki/Tag:boundary%3Dadministrative#10_admin_level_values_for_specific_countries](https://wiki.openstreetmap.org/wiki/Tag:boundary%3Dadministrative#10_admin_level_values_for_specific_countries "https://wiki.openstreetmap.org/wiki/Tag:boundary%3Dadministrative#10_admin_level_values_for_specific_countries")

Estimating the lead time for the various operations:

|     |     |     |     |
| --- | --- | --- | --- |
| Operation | Best case time,  min | Most likely time, min | Worst case time, min |
| Open JOSM on your computer, enable remote control in the settings | \- | \- | \- |
| Choose and open parent boundaries by clicking [here](  https://test-apps-ninja02.konturlabs.com/active/reports/osm_population_inconsistencies "  https://test-apps-ninja02.konturlabs.com/active/reports/osm_population_inconsistencies") | 0.5 | 0.5 | 0.5 |
| Check if values admin_level matches this [article]( https://wiki.openstreetmap.org/wiki/Tag:boundary%3Dadministrative#10_admin_level_values_for_specific_countries " https://wiki.openstreetmap.org/wiki/Tag:boundary%3Dadministrative#10_admin_level_values_for_specific_countries"). If there are inconsistencies, correct them. | 1 | 2 | 5 |
| Check population chosen area in wikipedia or in other sources | 1 | 3 | 7 |
| Compare tag "population" with the population in sources. If the values differ, verify the source is reliable, then correct the tag in area. | 1 | 2 | 5 |
| If the population tag in the open parent area matches the number in the source, open inner areas in the report. | 1 | 3 | 7 |
| Check each inner region against the source and correct tags. | 2 | 5 | 10 |
| Send the changeset to osm, don't forget to specify the hashtag "#Kontur" in comments.  | 0.5 | 0.5 | 0.5 |
| Sum | 7 | 16 | 35 |

### Non-standard cases

Below we look at the non-standard cases you can encounter and the instructions for dealing with them.

1. No data about population. Absolutely.

In this case, open the history of that polygon, and see in which changeset the population data appeared. Follow the changeset and contact its author to ask him about population data source (changeset comments is the best place for it). If the author does not respond within a week, remove the population tag from the changeset.

2. Data in sources inconsistent.

Give preference to more recent data. If this is difficult, write to Slack in the #gis channel - perhaps someone has already encountered this dataset.

3. Local mappers are against bringing the admin_level tag into line with the [wiki-osm](https://wiki.openstreetmap.org/wiki/Main_Page "https://wiki.openstreetmap.org/wiki/Main_Page").

Before fixing admin_level, study the [table](https://wiki.openstreetmap.org/wiki/Tag:boundary%3Dadministrative#10_admin_level_values_for_specific_countries "https://wiki.openstreetmap.org/wiki/Tag:boundary%3Dadministrative#10_admin_level_values_for_specific_countries") carefully and use it. If someone has deleted your edits, ask them why they did so, and attach your arguments, referring to the wiki osm. If you have not received a reply within two working days, return your changes. If another member of the community reverses your edits again, write to the [DWG](https://wiki.osmfoundation.org/wiki/Data_Working_Group "https://wiki.osmfoundation.org/wiki/Data_Working_Group") detailing the situation.

Feel free to add other unusual cases here.
