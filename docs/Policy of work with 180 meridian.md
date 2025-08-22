# Policy of work with 180 meridian

Field: Content

### **Variants of the solution (geometry storing):**
* keep invalid coordinates (< -180 or > 180):
  * (-) not all libraries are ready for it;
* save geometry "as is":
  * (-) geometry is "inverted" when displayed on a map;
* cut all geometry along 180th meridian:
  * (-) need to customize displaying on front.
* Backend**, how to store geometry:

We need to process external data and if geometry crosses antimeridian create as output 2 geometries cut by 180th.

How to process it:

1. detect if geometry is crossing antimeridian using code from this article <https://towardsdatascience.com/around-the-world-in-80-lines-crossing-the-antimeridian-with-python-and-shapely-c87c9b6e1513>:
   * before using this algorithm need to check if (we have coordinates < -90 AND > 90) AND (coordinates with both positive and negative signs are present);
   * if the modulo difference between neighboring meridians greater than 180 → geometry cross 180th;
2. cut geometry (if needed) along 180th meridian;
3. fix all coordinates that  < -180 or > 180 (+360 or -360);
4. make geometry valid (library???);

|     |     |     |
| --- | --- | --- |
|  | Input geometry | Processing |
| 1 | y coordinates < -180 and/or > 180 | as a result, there are not y coordinates that are < -180 or > 180 geometry need to be cut by 180th |
| 2 | usual y coordinates > -180 and < 180 (**not** cut along the meridian) | geometry need to be cut by 180th |
| 3 | usual y coordinates > -180 and < 180 (cut along the meridian) | no actions required |
* Backend, Frontend**

How to zoom to the geometry:
* if we zoom to bbox "as is" we see smth like that

![image.png](https://kontur.fibery.io/api/files/f0543350-f129-48a8-a37a-76e25a2f5fe1#width=1338&height=656 "")
* default zoom behavior:
  * bbox - need to investigate
  * central point and zoom level:
    * central point = center of full bbox;
      * How to calculate bbox:
        * as for usual geometry;
        * if we need to request info inside bbox - do it based on cut geometry (to faster request);
        * we need to be aware of multipolygons that do not cross antimeridian but have "parts" on opposite sides of the meridian.
    * zoom level:
      * <https://docs.microsoft.com/en-us/azure/azure-maps/zoom-levels-and-tile-grid?tabs=csharp>
      * <https://groups.google.com/g/mapsforge-dev/c/MChsbAK1vl4?pli=1> 
        * dx = width of bbox projected to zoom_level 0 / tile_size (should\
          result in range 0..1)\
          zoom_x = floor(-log(4)\*log(dx) + screen_width/tile_size)\
          new_zoom = min(zoom_x,zoom_y)
    * *do not use "zoom to bbox" expression*

### **Frontend**, how to show geometry:
* there are different requests for border and for fill(background);

* if we need to show geometries border, we need to request border separately, without fill(background) and without a line that crosses antimeridian;
* if we need to show geometries fill(background), we need to request fill(background) separately, without border;
* our backend needs to be able to process different requests to the border and to fill(background);
* frontend needs to know what kind of request need to send.

![image.png](https://kontur.fibery.io/api/files/85c12bcc-aa24-44ea-b479-3607dd07dd6f#width=615&height=400 "")**Frontend**, draw tools:
* lines (divide by 3 parts);
* polygons;
