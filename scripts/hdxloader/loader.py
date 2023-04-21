import datetime
import logging
import uuid

from typing import Dict, Set, Union

from hdx.data.organization import Organization
from hdx.data.dataset import Dataset
from hdx.location.country import Country
from slugify import slugify

from hdxloader.dataset import (
    DatasetType, format_dataset_data,
    STATIC_CONFIG_FOR_DATASET,
)
from hdxloader.datasource import (
    CountryAdministrativeDivisionWithAggregatedPopulation,
    CountryPopulationDensityFor400mH3Hexagons,
    DATASETTYPE_TO_DATASOURCE,
    Datasource,
)

# TO DO
# Looks like we should move these variables to special configuration file
ORGANIZATION_NAME = 'kontur'
SCRIPT_NAME = 'HDX: Kontur Data Loader'


class Loader:
    def __init__(
            self,
            dataset_type: DatasetType,
            data_directory: str,
    ):
        self._dataset_type = dataset_type
        self._data_directory = data_directory

        self._datasets: Dict[str, Dataset] = get_datasets_for_dataset_type(self._dataset_type)
        self._datasources: Set[Datasource] = set()
        self._datasources_for_datasets: Dict[str, Datasource] = {}

        self._uuid: str = str(uuid.uuid4())

    @property
    def data_directory(self) -> str:
        return self._data_directory

    @property
    def datasource_class(self) -> type:
        return DATASETTYPE_TO_DATASOURCE[self._dataset_type]

    def add_datasource(self, datasource: Datasource):
        if self._dataset_type == DatasetType.CountryAdministrativeDivisionWithAggregatedPopulation:
            assert isinstance(datasource, CountryAdministrativeDivisionWithAggregatedPopulation)
            self._add_country_datasource(datasource)
        elif self._dataset_type == DatasetType.CountryPopulationDensityFor400mH3Hexagons:
            assert isinstance(datasource, CountryPopulationDensityFor400mH3Hexagons)
            self._add_country_datasource(datasource)

    def _add_country_datasource(
            self,
            datasource: Union[
                CountryAdministrativeDivisionWithAggregatedPopulation,
                CountryPopulationDensityFor400mH3Hexagons]
    ):
        datasource_country_info = Country.get_country_info_from_iso2(datasource.alpha2)
        datasource_country_iso3 = datasource_country_info['#country+code+v_iso3']

        matching_datasets = set()
        for dataset_id, dataset in self._datasets.items():
            dataset_iso3 = dataset['groups'][0]['id'] \
                if len(dataset['groups'][0]['id']) == 3 \
                else dataset['groups'][0]['name']
            if dataset_iso3.lower() == datasource_country_iso3.lower():
                matching_datasets.add(dataset_id)

        assert len(matching_datasets) == 1, \
            f'Must be one and the only one dataset found for {datasource}. ' \
            f'Found: {matching_datasets}'

        if matching_datasets:
            dataset_id = matching_datasets.pop()
            self._datasources_for_datasets[dataset_id] = datasource
            logging.debug('%r for dataset %s', datasource, dataset_id)

    def upload(self, skip_validation: bool = False):
        missing_datasets_ids = self._datasets.keys() - self._datasources_for_datasets.keys()
        missing_datasets = [self._datasets[_id] for _id in missing_datasets_ids]
        if missing_datasets:
            for dataset in missing_datasets:
                logging.error('Missing dataset: %s', dataset)

        assert skip_validation or not missing_datasets, 'Some datasets are missing'

        for dataset_id, datasource in self._datasources_for_datasets.items():
            dataset = self._datasets[dataset_id]
            resource = datasource.convert_to_resource_and_upload()
            dataset.add_update_resource(resource=resource)
            dataset.create_in_hdx(
                remove_additional_resources=False,
                hxl_update=False,
                updated_by_script=SCRIPT_NAME,
                batch=self._uuid,
            )

# TO DO
# expected tags for type should be moved to separate config file, to avoid errors in case, when tasg were changed by HDX
def get_datasets_for_dataset_type(dataset_type: DatasetType) -> Dict[str, Dataset]:
    def _is_dataset_ok_by_tags(
            dataset_: Dataset,
            dataset_type_: DatasetType,
    ) -> bool:
        expected_name_for_type = {
            DatasetType.CountryAdministrativeDivisionWithAggregatedPopulation: 'kontur-boundaries',
            DatasetType.CountryPopulationDensityFor400mH3Hexagons: 'kontur-population',
        }
        expected_tags_for_type = {
            DatasetType.CountryAdministrativeDivisionWithAggregatedPopulation: {
                'administrative divisions',
                'baseline population',
                'geodata',
            },
            DatasetType.CountryPopulationDensityFor400mH3Hexagons: {
                'baseline population',
                'distributions',
                'geodata',
            },
        }
        skip_global = dataset_type in {
            DatasetType.CountryAdministrativeDivisionWithAggregatedPopulation,
            DatasetType.CountryPopulationDensityFor400mH3Hexagons,
        }

        assert (dataset_type_ in expected_name_for_type and
                dataset_type_ in expected_tags_for_type), \
            f'I don\t know what to do with {dataset_type_}'

        if 'groups' not in dataset_ or not dataset_['groups']:
            return False
        if 'id' not in dataset_['groups'][0]:
            return False
        if 'tags' not in dataset_:
            return False
        if skip_global and dataset_['groups'][0]['id'] == 'world':
            return False

        dataset_tags = {_t['display_name'] for _t in dataset_['tags']}
        return expected_tags_for_type[dataset_type_] <= dataset_tags \
            and expected_name_for_type[dataset_type_] in dataset_['name']

    we_are = Organization.read_from_hdx(identifier=ORGANIZATION_NAME)
    our_datasets = we_are.get_datasets()

    return {
        _dataset['id']: _dataset
        for _dataset in our_datasets
        if _is_dataset_ok_by_tags(_dataset, dataset_type)
    }


def create_datasets_for_all_hdx_countries(
        dataset_type: DatasetType,
        owner: str
):
    we_are = Organization.read_from_hdx(identifier=ORGANIZATION_NAME)
    i_might_be = [
        _user
        for _user in we_are.get_users()
        if _user['name'] == owner
    ]
    assert i_might_be and len(i_might_be) == 1, f'No matching user found: {owner}'
    i_am = i_might_be[0]

    config_path = STATIC_CONFIG_FOR_DATASET[dataset_type]
    countries = Country.countriesdata()['countries']
    datasets = get_datasets_for_dataset_type(dataset_type)
    countries_with_dataset = {
        _dataset['groups'][0]['id'].upper()
        for _dataset in datasets.values()
    }

    countries_without_dataset = {
        _country_iso3: _country
        for _country_iso3, _country in countries.items()
        if _country_iso3 not in countries_with_dataset
    }

    new_datasets = []

    for country_iso3, country in countries_without_dataset.items():
        dataset = Dataset()
        location_name = country['#country+name+preferred']
        country_iso3 = country['#country+code+v_iso3']
        dataset.update_from_yaml(config_path)
        dataset.add_country_locations([country_iso3])
        format_dataset_data(
            dataset,
            country_name_lower=slugify(location_name.lower()),
            country_name_capitalized=location_name,
        )
        dataset.set_organization(we_are['id'])
        dataset.set_maintainer(i_am['id'])
        dataset.update({'dataset_date':datetime.datetime.now()})
        dataset.set_expected_update_frequency('-2')

        new_datasets.append(dataset)

    return new_datasets
