# Basemap specification

## Basemap specification
* Basemap** is a map service consisting of tiles of different zooms and sizes and based on OpenStreetMap data. 

We are developing Basemap for different projects like Disaster Ninja, Unfolded Studio, Basemap for Logistics*.* Each of it had its own properties and needs. We can see all kinds of basemap here: <https://geocint.kontur.io/basemap/index.html>, <https://zigzag.kontur.io/live/>, [https://sonic.kontur.io/](https://zigzag.kontur.io/) 

### Basemap peculiar properties and differences

|     |     |     |     |
| --- | --- | --- | --- |
|  | **Disaster Ninja** | **Foursquare studio** | **Logistics** |
| Link to resource | <https://disaster.ninja/live> | <https://studio.unfolded.ai/map/ae15f0e7-179f-4cb5-a621-32cea9e9458a> | not developed yet |
| Type of map | background | background | foreground |
| Technical requirements | daily update cycle built from latest OSM  | load time - less than 150 ms at least monthly update cycle built from "stable" OSM (daylight) | daily update cycle |
| Purpose of usage | to be a background for hegaxons layers of Disaster Ninja | to use map for displaying data over it |  |
| Main properties | To use only black and white colours Simplicity and lightness  Land is more important than water | Two divided coloured styles - white/day and blue/night To avoid congestion Not too bright colours | Coloured map Houses, housenumbers, all the roads should be seen Clarity and detail Big zooms are more important |
| References | [https://api.mapbox.com/styles/v1/akiyamka](https://api.mapbox.com/styles/v1/akiyamka/cjushbakm094j1fryd5dn0x4q.html?title=view&access_token=pk.eyJ1IjoiYWtpeWFta2EiLCJhIjoiY2p3aG4zY2Y2MDFyNjQ2bjZ1bTNldjQyOCJ9.uM8bC4cSVnYETymmoonsEg&zoomwheel=true&fresh=true#0.26/0/121.9) | [maps.me](http://maps.me), <https://studio.unfolded.ai/map/ae15f0e7-179f-4cb5-a621-32cea9e9458a> | [maps.me](http://maps.me), <https://studio.unfolded.ai/map/ae15f0e7-179f-4cb5-a621-32cea9e9458a> |
| Zooms | 0-9 | 0-14 | 0-14 |
| Detalization | 0-9 | 0-14 | 0-18 |
| Location of file with style | geocint / basemap / styles / [**ninja.mapcss**](https://gitlab.com/kontur-private/platform/geocint/-/blob/master/basemap/styles/ninja.mapcss "https://gitlab.com/kontur-private/platform/geocint/-/blob/master/basemap/styles/ninja.mapcss") | geocint / basemap / styles / [mapsme_mod](https://gitlab.com/kontur-private/platform/geocint/-/tree/master/basemap/styles/mapsme_mod "https://gitlab.com/kontur-private/platform/geocint/-/tree/master/basemap/styles/mapsme_mod") |  |
| Objects are placed | Land objects (coastline)  Water objects on land (rivers, lakes, reservours, channels) Administrative boundaries (8 levels) Roads (higways, primaries, secondaries, motorways, trunks) | Land use (water, agricultural lands, forests and parks, grassland, building)  Water objects on land (rivers, lakes, reservours, glaciers, channels, ponds) Administrative boundaries (8 levels) Roads (higways, primaries, secondaries, motorways, trunks), railways Houses | Land use (water, agricultural lands, forests and parks, grassland, building)  Water objects on land (rivers, lakes, reservours, glaciers, channels, ponds) Mountains, volcanoes Administrative boundaries (10 levels) Roads (higways, primaries, secondaries, motorways, trunks, footways, pedestrians), railways Houses |
| Names are placed | Countries States, regions and provincies Cities and capitals, towns, villages, hamlets Water objects: oceans, seas, gulfs, bays, straits | Countries States, regions and provincies, districts Cities and capitals, towns, villages, hamlets Water objects: oceans, seas, gulfs, bays, straits, glaciers, rivers, lakes, channels, reservours, swamps, ponds) Reservers, national parks, wildlife sanctuaries Streets, roads House numbers | Countries States, regions and provincies, districts Cities and capitals, towns, villages, hamlets Water objects: oceans, seas, gulfs, bays, straits, glaciers, rivers, lakes, channels, reservours, swamps, ponds) Mountains, volcanoes+height Reservers, national parks, wildlife sanctuaries Streets, roads House numbers Infrastructure objects |

