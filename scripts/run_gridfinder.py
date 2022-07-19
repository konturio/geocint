import dataclasses
import json
import os
import pathlib

from typing import Optional, Union, Tuple

import geopandas
import numpy as np
import pyproj
import rasterio
import sqlalchemy

import rasterio.features
import rasterio.mask

import gridfinder


@dataclasses.dataclass
class GFInputs:
    input_directory: pathlib.Path
    input_ntl_directory: pathlib.Path

    input_table_aoi: str
    input_table_roads: str
    roads_weight_column: str
    input_table_powerlines: str
    input_table_pop: str
    population_column_name: str

    output_directory: pathlib.Path
    output_directory_with_ntl_rasters: pathlib.Path
    output_raster_ntl_merged: pathlib.Path

    output_raster_targets: pathlib.Path
    output_raster_targets_without_empty_areas: pathlib.Path
    output_raster_roads: pathlib.Path

    output_raster_dist: pathlib.Path
    output_raster_guess: pathlib.Path
    output_raster_guess_skeletonized: pathlib.Path
    output_raster_guess_nulled: pathlib.Path

    output_table: str

    @staticmethod
    def create_default(input_directory: str, output_directory: str):
        input_directory_path = pathlib.Path(input_directory)
        output_directory_path = pathlib.Path(output_directory)
        assert input_directory_path.exists()
        assert output_directory_path.exists()

        input_ntl_directory = input_directory_path / 'ntl'
        assert input_ntl_directory.exists()

        input_table_aoi = 'public.gridfinder_input_aoi'
        input_table_roads = 'public.gridfinder_input_roads'
        roads_weight_column = 'weight'
        input_table_powerlines = 'public.gridfinder_input_powerlines'
        input_table_pop = 'public.pop_h3'
        population_column_name = 'pop'

        output_directory_with_ntl_rasters = output_directory_path / 'ntl_clipped'
        output_raster_ntl_merged = output_directory_path / 'ntl_merged.tif'
        output_raster_targets = output_directory_path / 'targets.tif'
        output_raster_targets_without_empty_areas = output_directory_path / 'targets_clean.tif'
        output_raster_roads = output_directory_path / 'roads.tif'

        output_raster_dist = output_directory_path / 'dist.tif'
        output_raster_guess = output_directory_path / 'guess.tif'
        output_raster_guess_skeletonized = output_directory_path / 'guess_skel.tif'
        output_raster_guess_nulled = output_directory_path / 'guess_nulled.tif'

        output_table = 'public.gridfinder_output'

        return GFInputs(
            input_directory=input_directory_path,
            input_ntl_directory=input_ntl_directory,
            input_table_aoi=input_table_aoi,
            input_table_roads=input_table_roads,
            roads_weight_column=roads_weight_column,
            input_table_powerlines=input_table_powerlines,
            input_table_pop=input_table_pop,
            population_column_name=population_column_name,
            output_directory=output_directory_path,
            output_directory_with_ntl_rasters=output_directory_with_ntl_rasters,
            output_raster_ntl_merged=output_raster_ntl_merged,
            output_raster_targets=output_raster_targets,
            output_raster_targets_without_empty_areas=output_raster_targets_without_empty_areas,
            output_raster_roads=output_raster_roads,
            output_raster_dist=output_raster_dist,
            output_raster_guess=output_raster_guess,
            output_raster_guess_skeletonized=output_raster_guess_skeletonized,
            output_raster_guess_nulled=output_raster_guess_nulled,
            output_table=output_table,
        )


@dataclasses.dataclass
class GFParams:
    percentile: float = 70  # percentile value to use when merging monthly NTL rasters
    ntl_threshold: float = 0.1  # threshold when converting filtered NTL to binary (probably shouldn't change)
    upsample_by: float = 2  # factor by which to upsample before processing roads (both dimensions are scaled by this)
    cutoff: float = 0.0  # cutoff to apply to output dist raster, values below this are considered grid


class GridFinderProxy:
    @staticmethod
    def merge_rasters(
            input_directory_with_rasters: pathlib.Path,
            percentile: float,
    ) -> Tuple[np.ndarray, rasterio.Affine]:
        return gridfinder.merge_rasters(
            input_directory_with_rasters,
            percentile=percentile,
        )

    @staticmethod
    def save_raster(
            path: pathlib.Path,
            raster: np.array,
            affine: rasterio.Affine,
            crs: Optional[Union[str, pyproj.Proj]] = None,
            nodata: int = 0,
    ):
        gridfinder.save_raster(path, raster, affine, crs, nodata)

    @staticmethod
    def prepare_ntl(
            ntl_in: pathlib.Path,
            aoi_in: str,
            ntl_filter: Optional[np.array] = None,
            threshold: Optional[float] = None,
            upsample_by: Optional[float] = None
    ) -> Tuple[np.array, rasterio.Affine]:
        aoi_dataset = read_table_as_dataset(aoi_in)
        return gridfinder.prepare_ntl(
            ntl_in=ntl_in,
            aoi_in=aoi_dataset,
            ntl_filter=ntl_filter,
            threshold=threshold,
            upsample_by=upsample_by,
        )

    @staticmethod
    def drop_zero_pop(
            targets_in: pathlib.Path,
            pop_in: str,
            population_column: str,
            aoi: str,
    ) -> np.ndarray:
        population_dataset = read_table_as_dataset(pop_in)
        population_dataset.query(f'{population_column} > 0', inplace=True)
        aoi_dataset = read_table_as_dataset(aoi)

        clipped, affine, crs = clip_raster(targets_in, aoi_dataset)
        clipped, affine, crs = clip_raster_dataset(clipped, population_dataset)
        return clipped

    @staticmethod
    def prepare_roads(
            roads_in: str,
            roads_weight_column: str,
            powerlines_in: str,
            aoi_in: str,
            ntl_in: pathlib.Path
    ) -> Tuple[np.array, rasterio.Affine]:
        ntl_rd = rasterio.open(ntl_in)
        shape = ntl_rd.read(1).shape
        affine = ntl_rd.transform

        aoi_dataset = read_table_as_dataset(aoi_in)
        roads_dataset = read_table_as_dataset(roads_in)
        roads_masked = roads_dataset.intersection(aoi_dataset)

        powerlines_dataset = read_table_as_dataset(powerlines_in)
        powerlines_masked = powerlines_dataset.intersection(aoi_dataset)

        powerlines_masked[roads_weight_column] = 0

        roads_masked.append(powerlines_masked)
        roads_masked = roads_masked[roads_masked[roads_weight_column != 1]]

        # sort by weight descending so that lower weight (bigger roads) are
        # processed last and overwrite higher weight roads
        roads_masked = roads_masked[roads_masked.columns]
        roads_masked.sort_values(by=roads_weight_column, ascending=False, inplace=True)

        roads_for_raster = [
            (row.geometry, row.weight) for _, row in roads_masked.iterrows()
        ]
        roads_raster = rasterio.features.rasterize(
            roads_for_raster,
            out_shape=shape,
            fill=1,
            default_value=0,
            all_touched=True,
            transform=affine,
        )

        return roads_raster, affine


def get_default_pg_conn():
    return f'postgresql://{os.getlogin()}@localhost:5432/gis'


def read_table_as_dataset(
        table: str,
        pg_conn_str: str = None,
) -> geopandas.GeoDataFrame:
    pg_conn_str = pg_conn_str or get_default_pg_conn()
    con = sqlalchemy.create_engine(pg_conn_str)
    sql = f'SELECT * FROM {table}'
    dataset = geopandas.read_postgis(sql, con)
    return dataset


def clip_raster_dataset(
        raster: np.array,
        boundary_dataset: geopandas.GeoDataFrame,
):
    if boundary_dataset.crs != raster.crs and boundary_dataset.crs != raster.crs.data:
        boundary_dataset = boundary_dataset.to_crs(crs=raster.crs)

    coords = [
        json.loads(boundary_dataset.to_json())["features"][0]["geometry"]
    ]

    # mask/clip the raster using rasterio.mask
    clipped, affine = rasterio.mask.mask(
        dataset=raster,
        shapes=coords,
        crop=True,
    )

    if len(clipped.shape) >= 3:
        clipped = clipped[0]

    return clipped, affine, raster.crs


def clip_raster(
        raster_path: pathlib.Path,
        boundary_dataset: geopandas.GeoDataFrame,
):
    raster = rasterio.open(raster_path.as_posix())
    return clip_raster_dataset(raster, boundary_dataset)


def clip_rasters(
        input_directory: pathlib.Path,
        output_directory: pathlib.Path,
        boundary_table: str,
        pg_conn_str: Optional[str] = None):
    boundary_dataset = read_table_as_dataset(boundary_table, pg_conn_str)

    for file_path in os.listdir(input_directory.as_posix()):
        if not file_path.endswith('.tif'):
            continue

        clipped, affine, _ = clip_raster(input_directory / file_path, boundary_dataset)
        gridfinder.save_raster(output_directory, clipped, affine)


def main():
    inputs = GFInputs.create_default(input_directory='data/in/gridfinder', output_directory='/data/out/gridfinder')
    params = GFParams()

    clip_rasters(
        inputs.input_ntl_directory,
        inputs.output_directory_with_ntl_rasters,
        inputs.input_table_aoi,
    )

    raster_merged, affine = GridFinderProxy.merge_rasters(
        inputs.output_directory_with_ntl_rasters,
        percentile=params.percentile,
    )
    GridFinderProxy.save_raster(
        path=inputs.output_raster_ntl_merged,
        raster=raster_merged,
        affine=affine,
    )
    ntl_filter = gridfinder.create_filter()

    ntl_thresh, affine = GridFinderProxy.prepare_ntl(
        ntl_in=inputs.output_raster_ntl_merged,
        aoi_in=inputs.input_table_aoi,
        ntl_filter=ntl_filter,
        threshold=params.ntl_threshold,
        upsample_by=params.upsample_by,
    )

    GridFinderProxy.save_raster(
        path=inputs.output_raster_targets,
        raster=ntl_thresh,
        affine=affine,
    )

    targets_clean = GridFinderProxy.drop_zero_pop(
        targets_in=inputs.output_raster_targets,
        pop_in=inputs.input_table_pop,
        population_column=inputs.population_column_name,
        aoi=inputs.input_table_aoi,
    )
    GridFinderProxy.save_raster(
        path=inputs.output_raster_targets,
        raster=targets_clean,
        affine=affine,
    )

    roads_raster, affine = GridFinderProxy.prepare_roads(
        roads_in=inputs.input_table_roads,
        roads_weight_column=inputs.roads_weight_column,
        powerlines_in=inputs.input_table_powerlines,
        aoi_in=inputs.input_table_aoi,
        ntl_in=inputs.output_raster_targets,
    )
    GridFinderProxy.save_raster(
        path=inputs.output_raster_roads,
        raster=roads_raster,
        affine=affine,
        nodata=-1,
    )

    targets, costs, start, affine = gridfinder.get_targets_costs(
        targets_in=inputs.output_raster_targets_without_empty_areas.as_posix(),
        costs_in=inputs.output_raster_roads.as_posix(),
    )

    dist = gridfinder.optimise(
        targets=targets,
        costs=costs,
        start=start,
        jupyter=False,
        animate=False,
        affine=affine,
    )
    GridFinderProxy.save_raster(
        path=inputs.output_raster_dist,
        raster=dist,
        affine=affine,
    )

    guess, affine = gridfinder.threshold(
        dists_in=inputs.output_raster_dist,
        cutoff=params.cutoff,
    )
    GridFinderProxy.save_raster(
        path=inputs.output_raster_guess,
        raster=guess,
        affine=affine,
    )
    guess_skel, affine = gridfinder.thin(inputs.output_raster_guess)
    GridFinderProxy.save_raster(
        path=inputs.output_raster_guess_skeletonized,
        raster=guess_skel,
        affine=affine,
    )

    guess_gdf = gridfinder.raster_to_lines(
        guess_skel_in=inputs.output_raster_guess_skeletonized,
    )
    guess_gdf.to_postgis(
        inputs.output_table,
        con=get_default_pg_conn(),
    )


if __name__ == '__main__':
    main()