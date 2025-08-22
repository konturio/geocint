# Population totals improvement

This document provides instructions on how to use the "Top 5 Difference Messages" from the geocint channel to improve Kontur population.


In the Slack channel you can find two different types of '**Top 5 difference messages**':

1\. Top 5 scaled boundaries with a population difference from OSM.

2\. Top 5 not scaled boundaries with a population difference from OSM.

Each message contains the top 5 boundaries from Kontur Boundaries with the largest absolute difference between population data from OSM and the actual Kontur Population totals.

To enhance the Kontur population data, please use the following script:

For 'Top 5 scaled boundaries with population differences from OSM':

1. Compare Kontur Population with the expected population. If the difference is significant (>\~1%), notify the data engineer.
2. Compare Kontur Population with OSM population. 
   1. If the difference is significant (>\~1.5%): 
      1. check the official census data and other possible sources by clicking the 'Open in Google' button. 
      2. compare it with Wikidata using the 'Open on Wikidata' button and the actual Kontur Population. 
      3. If the total in OSM appears incorrect:
         1. open the relation in JOSM using the 'Open in JOSM' button or use the OSM web client
         2. set a new population value for the object. 
      4. If the total in OSM looks correct - **notify the data engineer.**

For 'Top 5 not scaled boundaries with population differences from OSM':

1. Compare Kontur Population with OSM population. 
   1. If the difference is significant (>\~1.5%):
      1. check the official census data and other possible sources by clicking the 'Open in Google' button.
      2. compare it with Wikidata using the 'Open on Wikidata' button and the actual Kontur Population.
      3. \- If the total in OSM appears correct:
         1. find the OSM ID and OSM type of the object in OSM
         2. go to the Prescale Mastertable (use hyperlink "Prescale to OSM mastertable" at the end of the message)
         3. add this object to a new line on Sheet 1. 
         4. fill in all the fields and **notify the data engineer about the changes**. 
         6. wait until the next nightly build is finished to check the results."
      4. If the total in OSM appears incorrect:
         1. open the relation in JOSM using the 'Open in JOSM' button or use the OSM web client
         2. set a new population value for the object. 
