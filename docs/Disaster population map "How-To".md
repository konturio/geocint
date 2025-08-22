# Disaster population map "How-To"

# Prerequisites
* Tools and sources you need:**
* Event API / Disaster Ninja / other sources of disaster data
* HDX (Kontur Population, Kontur Boundaries)
* QGIS
* Blender + install the plugin <https://github.com/domlysz/BlenderGIS>
* Figma

Create a new folder in [Disaster Populations Maps](https://drive.google.com/drive/folders/1UOJOVwSvBRGqmnrQVICLInwZeFlAlugA?usp=share_link "https://drive.google.com/drive/folders/1UOJOVwSvBRGqmnrQVICLInwZeFlAlugA?usp=share_link") to store the materials for the map you're about to create. (specify the number of a map and event name, ex. `01-earthquake-turkey-syria`)

# Download data

### Event geometry

*Geometry must be in QGIS-accepted vector format: GeoJSON, KML, GeoPackage, shapefile, etc. will work.*

1. Find disaster from Event API. You can look for it and download it in Disaster Ninja
2. If the event is missing or geometry/event data doesn't fit your needs, please, report pain points and search for data in other sources:
   * original GDACS or PDC data
   * other specialized providers, like USGS, FEMA, etc.
3. Save the selected disaster geometry to [Disaster Populations Maps](https://drive.google.com/drive/folders/1UOJOVwSvBRGqmnrQVICLInwZeFlAlugA?usp=share_link "https://drive.google.com/drive/folders/1UOJOVwSvBRGqmnrQVICLInwZeFlAlugA?usp=share_link") corresponding folder.

### Kontur Population and Boundaries datasets
* Download the global Kontur Boundaries dataset from HDX
* Download the Kontur Population dataset from HDX:
  * Global dataset - preferable if you already have it downloaded (400m resolution, for now, is the best one)
  * Datasets of only affected countries - may be a faster and more lightweight version

### Learning data

For learning purposes, you can use the same data as the one used in the video:
* Global Kontur Boundaries dataset - <https://data.humdata.org/dataset/kontur-boundaries>
* Global Kontur Population dataset (3 km resolution) - <https://data.humdata.org/dataset/kontur-population-dataset-3km>
* GDACS earthquake geometry (attached) - `1357372_1487096_9_shakemap.kml`

### Blender template

Please take one of the ready Blender project templates from [Disaster Populations Maps](https://drive.google.com/drive/folders/1UOJOVwSvBRGqmnrQVICLInwZeFlAlugA?usp=share_link "https://drive.google.com/drive/folders/1UOJOVwSvBRGqmnrQVICLInwZeFlAlugA?usp=share_link") (it has a camera, materials, etc setup)

# Process data using QGIS and Blender

<video src="/api/files/94e3bd66-85c7-4fc4-b313-b19d7907f57f" type="video/mp4" width="1920" height="1016"></video>

*A skipped step may be needed if the geometry is too detailed and the image doesn't look good.*
* *After importing geometries, merge points in every imported shape*
  * *Select a 3D object in the Collection panel → Go to edit mode → `Points` → `Select All` → `Mesh` → `Merge` → `By Distance` (0.0001m)*
  * *Repeat for all 3D Objects*

Add the layers saved from QGIS and rendered image from Blender to [Disaster Populations Maps](https://drive.google.com/drive/folders/1UOJOVwSvBRGqmnrQVICLInwZeFlAlugA?usp=share_link "https://drive.google.com/drive/folders/1UOJOVwSvBRGqmnrQVICLInwZeFlAlugA?usp=share_link") corresponding folder.

# Finish the image in Figma

1. Copy the latest Figma page as a template [Figma →](https://www.figma.com/file/kCkUKY1hWyJR5OZqLhWeOH/Twitter-posts?node-id=1490%3A1136&t=OFrVjbLtmEaA1jWC-1 "https://www.figma.com/file/kCkUKY1hWyJR5OZqLhWeOH/Twitter-posts?node-id=1490%3A1136&t=OFrVjbLtmEaA1jWC-1")
   1. Right mouse click on the page name in the Layers panel → Duplicate page
   2. Rename duplicated page by double click on its name
2. Paste new rendered image from Blender instead of the old one
3. Add a title, legend, copyrights, labels, and callouts using elements from the template composition
4. Export image from Figma\
   Select main frame → Export section in right sidebar → Export
5. Save the Final Image to [Disaster Populations Maps](https://drive.google.com/drive/folders/1UOJOVwSvBRGqmnrQVICLInwZeFlAlugA?usp=share_link "https://drive.google.com/drive/folders/1UOJOVwSvBRGqmnrQVICLInwZeFlAlugA?usp=share_link") corresponding folder.
