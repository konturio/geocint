import enum
import os


__here__ = os.path.dirname(os.path.abspath(__file__))

# Add new property to class DatasetType if you want to load a new kind of datasets to HDX


class DatasetType(str, enum.Enum):
    CountryAdministrativeDivisionWithAggregatedPopulation = 'country-boundaries'
    CountryPopulationDensityFor400mH3Hexagons = 'country-population'
    GlobalAdministrativeDivisionWithAggregatedPopulation = 'global-boundaries'
    GlobalPopulationDensityFor400mH3Hexagons = 'global-population'
    NoType = 'without-type'

    def __str__(self):
        return self.value


STATIC_CONFIG_FOR_DATASET = {
    DatasetType.CountryAdministrativeDivisionWithAggregatedPopulation:
        os.path.join(__here__, 'config', 'hdx_kontur_country_boundaries_static.yml'),
    DatasetType.CountryPopulationDensityFor400mH3Hexagons:
        os.path.join(__here__, 'config', 'hdx_kontur_country_population_static.yml'),
}


def format_dataset_data(dataset, **kwargs):
    for key, value in dataset.items():
        if isinstance(value, str):
            dataset[key] = value.format(**kwargs)
    return dataset
