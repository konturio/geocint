#!/usr/bin/python

import sys
from osgeo import osr, ogr
from shapely import wkt, geometry
import h3
import geopandas as gpd
import rasterio
from rasterio.mask import mask
from shapely.geometry import mapping
import numpy as np

# Call Example
# python3 tiff_to_h3.py '/home/frolui/code/test/esa_data/raster1.tif' '/home/frolui/code/test/esa_data/raster_info.csv' 8 'True'
# use "True" to import wkt geometry of hexagons in csv, and ahother value to drop it

# Workflow body function
def Pipeline(rasterfile, out_csv, h3_level, geom_flag):

    # Open raster and set variables
    rast = rasterio.open(rasterfile, driver='GTiff')
    # Get spatial reference of input raster
    source_srs = int(rast.crs.to_authority()[1])
    # Set h3 level for hexagons, which will be create
    h3_level = int(h3_level)

    # Create buffer polygon from input raster bounding box, buffer width - average inradios of hexagon on actual h3_level
    buffer = GetHulfHexBuffer(CreatePoly(rast, source_srs), h3_level, source_srs)
    # Create shapely Polygon from buffer
    shapely_polygon_fig = wkt.loads(buffer.ExportToWkt())
    # Create list of hexagons
    hexs = h3.polyfill(geometry.mapping(shapely_polygon_fig), h3_level, geo_json_conformant = True)
    # Count number of pixels bu class for each hexagon from hexs list
    final = CountPixels(PrepareGeoDataFrame(hexs, source_srs), rast)

    # Export final geodataframe to out_csv file
    if geom_flag == 'True':
        final.to_csv(out_csv)
        print (str(rasterfile) + ' succesfully done')
    else:
        final.drop('geom',axis=1).to_csv(out_csv)
        print (str(rasterfile) + ' succesfully done')

# Create Bounding Box Polygon with Spatial Reference from SRID
def CreatePoly(rast, source_srs):
    geom = ogr.CreateGeometryFromWkt(geometry.box(*rast.bounds).wkt)
    
    # Create spatial reference from source raster
    # Get SRID from source raster. !!! Now work only with EPSG AUTHORITY
    out_srs = osr.SpatialReference()
    out_srs.ImportFromEPSG(source_srs)
    
    # Assign spatial reference to geometry
    geom.AssignSpatialReference(out_srs)
    return geom

# Create a hex radius buffer for geometry
def GetHulfHexBuffer(geom, h3_level, source_srs):
    # Source SRS
    source = osr.SpatialReference()
    source.ImportFromEPSG(source_srs)
    
    # Temporary SRS
    target = osr.SpatialReference()
    target.ImportFromEPSG(3857)
    
    # Create transformations
    transform_in = osr.CoordinateTransformation(source, target)
    transform_out = osr.CoordinateTransformation(target, source)
    
    # Transform to meter-based SRS
    geom.Transform(transform_in)  
    
    # Buffer distance is equal to inradius of average hex on the given level  
    bufferDistance = round(h3.edge_length(h3_level, 'm')*3**0.5/2)
    poly = geom.Buffer(bufferDistance)
    
    # Transform to source SRS
    poly.Transform(transform_out)
    
    return poly

# Prepare geodataframe
def PrepareGeoDataFrame(hexs, source_srs):
    # Create shapely Polygon geometry from h3 index
    polygonise = lambda hex_id: geometry.Polygon(
                                    h3.h3_to_geo_boundary(
                                        hex_id, geo_json=True)
                                        )
    # Load h3 index and polygons from list into geopandas.GeoSeries
    polys = gpd.GeoSeries(list(map(polygonise, hexs)), \
                                    index=hexs, \
                                    crs="EPSG:"+str(source_srs) \
                                   )
    # Create GeoDataFrame from GeoSeries
    gdf = gpd.GeoDataFrame(gpd.GeoSeries(polys))
    
    # Rename column with geometry
    gdf = gdf.rename({0: 'geom'}, axis='columns')
    
    # Add column for statistics
    gdf = gdf.assign(class_1=0).assign(class_2=0).assign(class_4=0).assign(class_5=0).assign(class_0=0)

    # Add column and calculate area
    gdf = gdf.assign(area=gdf['geom'].to_crs(3857).area/ 10**6)
    
    # Change index name
    gdf.index.names = ['h3']
    
    return gdf

# Iterate gpd and set values
def CountPixels(geodataframe, rast):
    # Iterate throw geodataframe

    for index in geodataframe.index:
        # extract the raster values values within the polygon 
        out_image, out_transform = mask(rast, [mapping(geodataframe.loc[index, 'geom'])], crop=True)
            
        # Set value
        geodataframe.loc[index, 'class_1'] = np.count_nonzero(out_image == 1)
        geodataframe.loc[index, 'class_2'] = np.count_nonzero(out_image == 2)
        geodataframe.loc[index, 'class_4'] = np.count_nonzero(out_image == 4)
        geodataframe.loc[index, 'class_5'] = np.count_nonzero(out_image == 5)
        geodataframe.loc[index, 'class_0'] = np.count_nonzero(out_image == 0)
    
    # Close raster
    rast.close()    
    return geodataframe


# Start point
if __name__ == "__main__":
	Pipeline(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
