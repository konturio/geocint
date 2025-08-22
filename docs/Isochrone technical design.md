# Isochrone technical design

The goal of the project is transforming user input given as a set of geospatial coordinates into the set of isochrones that represents ETA from initial coordinates to various places on the map. The result should be represented as [Mapbox vector tiles](https://docs.mapbox.com/vector-tiles/specification/ "https://docs.mapbox.com/vector-tiles/specification/") available via REST-like endpoint.

## Getting initial data

Initial data set includes:
* OpenStreetMap (OSM) - data in a XML-based format that describes vector data used in a cartographic map
* Set of *points of interest* (POI) obtained from user input

OSM data should be analyzed against provided POI. In order to do that OSM data should be converted into a graph.

![Isochrone DFD.png](/api/file/1f7841b0-5063-11e9-a09a-f74a62fe341b "Isochrone DFD.png")

### Importing graph from OpenStreetMap

OpenStreetMap offers [several](https://wiki.openstreetmap.org/wiki/Downloading_data "https://wiki.openstreetmap.org/wiki/Downloading_data") [options](https://wiki.openstreetmap.org/wiki/Databases_and_data_access_APIs "https://wiki.openstreetmap.org/wiki/Databases_and_data_access_APIs") when it takes to importing data from them:
* [planet.osm](https://wiki.openstreetmap.org/wiki/Planet.osm "https://wiki.openstreetmap.org/wiki/Planet.osm") - entire database in a single archive. It updates weekly and weights about 75 GB
* Data extracts - several [providers ](https://wiki.openstreetmap.org/wiki/Processed_data_providers "https://wiki.openstreetmap.org/wiki/Processed_data_providers")(such as [geofabrik](http://download.geofabrik.de/ "http://download.geofabrik.de/")) offer an opportunity to download a database for chosen region
* [XAPI](https://wiki.openstreetmap.org/wiki/Xapi "https://wiki.openstreetmap.org/wiki/Xapi") - OSM Extended API is optimized for read-only operations and allows exporting DB for a bounding box limiting its content to 10 mil of objects (less than a third of California approx).
* [Overpass API](https://wiki.openstreetmap.org/wiki/Overpass_API "https://wiki.openstreetmap.org/wiki/Overpass_API") - a read-only API that serves up custom selected parts of the OSM map data. It is optimized for data consumers that need a few elements within a glimpse or up to roughly 10 million elements in some minutes, both selected by search criteria like e.g. location, type of objects, tag properties, proximity, or combinations of them. It acts as a database backend for [various services](https://wiki.openstreetmap.org/wiki/Overpass_API/Applications "Overpass API/Applications").
* [OSMaxx ](https://wiki.openstreetmap.org/wiki/OSMaxx "https://wiki.openstreetmap.org/wiki/OSMaxx")- OSM data preprocessor that offers preconfigured excepts as well as custome ones with conversion to a chosen format

OpenStreetMap data contains *nodes*, *ways* and *relations* each of which may have arbitrary tags assigned. We are interested in ways that associated with a [highway](https://wiki.openstreetmap.org/wiki/Key:highway "https://wiki.openstreetmap.org/wiki/Key:highway") tag and allow pedestrian.
* How do we import data from OpenStreetMap?**

We can work with raw OSM data using [osm4j](https://github.com/topobyte/osm4j "https://github.com/topobyte/osm4j") (supports JTS). This way we don’t have to convert initial data.

We can leverage [OSM lab’s](https://github.com/osmlab "https://github.com/osmlab") tools:
* [Atlas](https://github.com/osmlab/atlas "https://github.com/osmlab/atlas") - allows representing OSM data in-memory
* [Atlas-generator](https://github.com/osmlab/atlas-generator "https://github.com/osmlab/atlas-generator") - Spark Job that generates [Atlas](https://github.com/osmlab/atlas) shards from OSM pbf shards (in case we have to scale)

We can import OSM data into Neo4j simplified graph using [this approach](https://github.com/mihairaulea/atlas "https://github.com/mihairaulea/atlas") as described [here](https://medium.com/neo4j/how-i-put-the-world-map-in-a-graph-422b651780e9 "https://medium.com/neo4j/how-i-put-the-world-map-in-a-graph-422b651780e9").

— [[Darafei Praliaskouski#@aeb4a10c-3b70-11e9-be77-04d77e8d50cb/afbdd3a0-3b70-11e9-be77-04d77e8d50cb]] \
<https://osmcode.org/osmium-tool/> is an universal converter from OSM data format into OGC-like representation.

<https://github.com/mapbox/osrm-isochrone> as example of fast-but-incorrect isochrone implementation.
* How do we transform OSM data to travel times and edge costs?**

We need a thing called “speed profile“. One available set is part of OSRM routing engine:

<https://github.com/Project-OSRM/osrm-backend/tree/master/profiles>

Another good method is in Valhalla:

<https://github.com/valhalla/valhalla>

<https://www.mapzen.com/blog/low-stress-bike-routing/>

For walking a naive “travel 5 km/h on edges that can be travelled” can be enough for prototype.
* How do we import data from OpenStreetMap faster?**

We can import it partially. We can aggregate (map/reduce) the data before importing in another node (preprocessor). We can distribute the task.

We can do minutely updates**.** Working example <http://live.openstreetmap.fr/>.

We can use [osmupdate](https://wiki.openstreetmap.org/wiki/Osmupdate "https://wiki.openstreetmap.org/wiki/Osmupdate") or [Osmosis](https://wiki.openstreetmap.org/wiki/Osmosis "https://wiki.openstreetmap.org/wiki/Osmosis") for that.

### Getting user input

MapBox supports `LngLat` like values. It can be `Array`,  `String` or `Object`.

```
var v1 = new mapboxgl.LngLat(-122.420679, 37.772537);
var v2 = [-122.420679, 37.772537];
var v3 = {lon: -122.420679, lat: 37.772537};
```

Also supported [**MercatorCoordinate**](https://docs.mapbox.com/mapbox-gl-js/api/#mercatorcoordinate)**.** A MercatorCoordinate object represents a projected three dimensional position.

## Calculating isochrones

### Building shortest path tree

In order to calculate the [shortest path tree](https://en.wikipedia.org/wiki/Shortest-path_tree "https://en.wikipedia.org/wiki/Shortest-path_tree") we need a graph (edge weight is travel time) and set of POI. We should calculate a [shortest path tree](https://en.wikipedia.org/wiki/Shortest-path_tree "https://en.wikipedia.org/wiki/Shortest-path_tree") for every POI. Then we merge all the trees into a single one. Every node in the resulting tree will contain ETA from the closest of POI.

There are several options of an algorithm to build a shortest path tree:
* [Johnson’s algorithm](https://en.wikipedia.org/wiki/Johnson%27s_algorithm "https://en.wikipedia.org/wiki/Johnson%27s_algorithm")
* [Repeated Dijkstra’s algorithm](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm "https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm") (using [Fibonacci heap](https://en.wikipedia.org/wiki/Fibonacci_heap "https://en.wikipedia.org/wiki/Fibonacci_heap"))
* [Floyd–Warshall algorithm (for every pair of nodes especially if initial graph is dense)](https://en.wikipedia.org/wiki/Floyd%E2%80%93Warshall_algorithm "https://en.wikipedia.org/wiki/Floyd%E2%80%93Warshall_algorithm")

In order to parallel the computation the initial graph may be split into several smaller sub graphs which are clusters based on the [minimum spanning tree](https://en.wikipedia.org/wiki/Minimum_spanning_tree "https://en.wikipedia.org/wiki/Minimum_spanning_tree").

### Interpolation between nodes

In order to build continuous isochrone it is necessary to interpolate ETA value between nodes.

——
* how do we measure performance?
  * 4 minutes for calculation may be slow, how do we go faster?
    * GPU graph tools, what is available?
  * can we exchange calculation time to the memory usage?

As an option to exchange calculation time for the memory usage, we can pre-calculate tensor field for the OSM graph.

## Complexity evaluation

In order to evaluate amount of data we will need to tackle, consider a couple of average cities with good OSM coverage.

Minsk <http://www.overpass-api.de/api/xapi?*[bbox=27.4,53.83,27.7,53.98]> (\~110 MiB) 39 seconds

|     |     |     |     |
| --- | --- | --- | --- |
|  | Nodes | Ways | Relations |
| Total | 846 743 | 163 378 | 2 852 |
| Pedestrian | 393 726 (46% of total) | 78 830 (48% of total) | Not measured |

Tel-Aviv <http://www.overpass-api.de/api/xapi?*[bbox=34.6,31.8,35.05,32.25]> (\~200 MiB) 1:23 or 7 seconds from the local file

|     |     |     |     |
| --- | --- | --- | --- |
|  | Nodes | Ways | Relations |
| Total | 1 718 823 | 272 110 | 1 492 |
| Pedestrian | 591 790 (34% of total) | 78 734 (28% of total) | Not measured |

No more than 50% of raw OSM data will be interesting for the purpose of our solution. We will have to deal with raw graphs of 500 000 nodes. Raw solution with true ETA for a single node of such a graph would take 2 MiB approx. In order to calculate a full solution for a 500k graph in 24 hours giving that a single solution takes 1 minute on a single CPU, we would have to split the task between \~350 CPUs.

It would take 288 GiB to save true ETA for every possible pair of nodes in Minsk. 10% simplified graph would take 233 GiB (\~20% reduction). We can save true ETA for every pair of nodes from a graph of 70k nodes using 10 GiB.

## Presentation of result
* How to notify FE that tiles are ready?**

We have 4 options:
* Refetching by timeout
* Long poll
* WebSockets
* HTTP2 server push

Refetching it fits best because we have a relatively short time in which we need to poll the server. After we got “ready” response, polling stop.

WebSockets it that case look like overkill
* Can mapbox gl invalidate tile by cache expiration?**

<https://github.com/mapbox/mapbox-gl-js/issues/2633> \
Just to recap, the current state of this ticket is that we recognize the value of an explicit tile cache invalidation API for cases where you have some external way of knowing that some or all tiles are outdated. The current mechanism of removing and re-adding the source should work but is a cumbersome way to accomplish a re-load. The cache *is* supposed to respect HTTP max-age headers.

## Further development
* What else can we calculate apart from isochrones?**
* Given topology of the roads, how likely that a street will be crowded (betweenness centrality)?
* How many cars can pass between two points(max flow)?
* What is the minimum number of roads that can disconnect 2 cities(min cut)?
* How do we change restrictions?**

We will support updates from OpenStreetMap so user will be able to create obstacles right in OpenStreetMap using available tools.

Implementing our own routing engine enables us to change rules that evaluate which objects are considered obstacles.
* How do we count people depending on time of the day?**
