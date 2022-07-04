import abc
import datetime
import logging
import os
import re
import subprocess as sp
import tarfile
import zipfile

from typing import Optional, Tuple, Union

from hdx.data.resource import Resource

from hdxloader.dataset import DatasetType


class Datasource(abc.ABC):
    def __init__(self, dataset_path: str):
        if tarfile.is_tarfile(dataset_path) or zipfile.is_zipfile(dataset_path):
            raise ValueError(
                f'Datasource {dataset_path} must be initialized for non-archived data.'
            )
        self._dataset_path = dataset_path

    @property
    def path(self) -> str:
        return self._dataset_path

    @abc.abstractmethod
    def convert_to_resource_and_upload(self) -> Resource:
        pass

    @classmethod
    @abc.abstractmethod
    def is_file_matching_by_regexp(cls, file_path: str) -> bool:
        pass


class CountryDatasource(Datasource, abc.ABC):
    FILENAMEREGEX = None
    ALPHA2REGEX = re.compile(r'[A-Z]{2}')

    def __init__(self, dataset_path: str):
        super().__init__(dataset_path)

        self._alpha2: Optional[str] = None
        self._date: Optional[datetime.date] = None
        self._extract_iso3_and_date_from_path()

        self._url: Optional[str] = None

    def __repr__(self):
        return f'CountryDatasource("{self._dataset_path}")'

    @classmethod
    def is_file_matching_by_regexp(cls, file_path: str) -> bool:
        return bool(cls.FILENAMEREGEX.match(file_path))

    @property
    def alpha2(self) -> str:
        return self._alpha2

    @alpha2.setter
    def alpha2(self, value: str):
        if not isinstance(value, str):
            raise TypeError(f'Unknown type for Alpha2 code: {type(value)}')
        if not self.ALPHA2REGEX.match(value):
            raise ValueError(f'Wrong Alpha2 code format: {value}')
        self._alpha2 = value

    @property
    def date(self) -> Optional[datetime.date]:
        return self._date

    @date.setter
    def date(self, value: Union[str, datetime.date]):
        if isinstance(value, str):
            try:
                date = datetime.datetime.strptime(value, '%Y%m%d').date()
            except ValueError as e:
                raise ValueError(f'{e}\nWrong format for date: {value}. Must match `YYYYMMDD`') \
                    from e
        else:
            date = value

        if not isinstance(date, datetime.date):
            raise TypeError(f'Wrong type for date: {type(date)}')

        self._date = date

    def _extract_iso3_and_date_from_path(self) -> Tuple[str, str]:
        filename = os.path.basename(self._dataset_path)
        match = self.FILENAMEREGEX.match(filename)
        assert match, f'Unable to parse ISO3 and date from file path: {filename}'

        self.date = match.group('date')
        self.alpha2 = match.group('alpha2')
        return match.group('date'), match.group('alpha2')

    def _generate_overview(self):
        pass

    def _pack_and_upload_to_s3(self):
        def _parse_direct_link_from_s3_url(url_: str) -> str:
            s3_regexp = re.compile(r'(s3://)?(?P<bucket>[^/]+)/(?P<key>.+)')
            match = s3_regexp.match(url_)
            assert match, f'Unparsable url: {url_}'
            return f"https://{match.group('bucket')}.s3.amazonaws.com/{match.group('key')}"

        self._url = None
        archive_path = self._dataset_path + '.gz'

        try:
            pigz_cmd = [
                'pigz',
                '-k', '--best',
                self._dataset_path,
            ]
            logging.debug(' '.join(pigz_cmd))
            sp.check_call(pigz_cmd)

            assert os.path.exists(archive_path), \
                f'Could not find archived dataset: {archive_path}'

            archive_name = os.path.basename(archive_path)

            s3_archive_uri = \
                f's3://geodata-eu-central-1-kontur-public/kontur_datasets/{archive_name}'
            s3_cmd = [
                'aws', 's3', 'cp',
                archive_path,
                s3_archive_uri,
                '--profile', 'geocint_pipeline_sender',
                '--acl', 'public-read',
            ]
            logging.debug(' '.join(s3_cmd))
            sp.check_call(s3_cmd)
            direct_link = _parse_direct_link_from_s3_url(s3_archive_uri)
            self._url = direct_link

        finally:
            if os.path.exists(archive_path):
                os.remove(archive_path)

        return self._url

    def convert_to_resource_and_upload(self) -> Resource:
        url = self._pack_and_upload_to_s3()
        resource = Resource({
            'description': f'Release {self.date}',
            'format': 'gpkg',
            'name': os.path.basename(self._dataset_path),
            'url': url,
        })

        return resource


class CountryPopulationDensityFor400mH3Hexagons(CountryDatasource):
    FILENAMEREGEX = re.compile(r'.*kontur_population_(?P<alpha2>[A-Z]{2})_(?P<date>\d{8})\.gpkg')

    def __repr__(self):
        return f'CountryPopulationDensityFor400mH3Hexagons("{self._dataset_path}")'


class CountryAdministrativeDivisionWithAggregatedPopulation(CountryDatasource):
    FILENAMEREGEX = re.compile(r'.*kontur_boundaries_(?P<alpha2>[A-Z]{2})_(?P<date>\d{8})\.gpkg')

    def __repr__(self):
        return f'CountryAdministrativeDivisionWithAggregatedPopulation("{self._dataset_path}")'


DATASETTYPE_TO_DATASOURCE = {
    DatasetType.CountryAdministrativeDivisionWithAggregatedPopulation:
        CountryAdministrativeDivisionWithAggregatedPopulation,
    DatasetType.CountryPopulationDensityFor400mH3Hexagons:
        CountryPopulationDensityFor400mH3Hexagons,
}
