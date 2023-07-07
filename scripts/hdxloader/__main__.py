import argparse
import logging
import os
import uuid
import yaml

from hdx.facades.keyword_arguments import facade
from hdx.utilities.easy_logging import setup_logging
from hdx.data.dataset import Dataset

from hdxloader.dataset import DatasetType
from hdxloader.loader import create_datasets_for_all_hdx_countries, get_datasets_for_dataset_type, Loader, SCRIPT_NAME


USER_AGENT = 'Kontur HDX Loader'


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        'HDX Loader',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    sub_parsers = parser.add_subparsers(
        title="Modes",
        description="Choose what do you want to do.",
        dest="mode",
        required=True,
    )
    parent_parser = argparse.ArgumentParser(add_help=False)

    # Add special parser for "update" mode
    parser_update = sub_parsers.add_parser(
        "update",
        help="update dataset",
        parents=[parent_parser],
    )
    parser_update.add_argument(
        '-i', '--identifier',
        help='Specify a dataset identifier.',
        required=False,
        type=str,
    )
    parser_update.add_argument(
        '-u', '--update_with_file',
        help='Specify a dataset identifier.',
        required=False,
        type=str,
    )
    parser_update.add_argument(
        '-f', '--file_with_update',
        help='file with updated information',
        required=False,
        type=str,
    )
    parser_update.add_argument(
        '-n', '--tag_name',
        help='tag that should be updated',
        required=False,
        type=str,
    )
    parser_update.add_argument(
        '--tag_value',
        help='new tag value',
        required=False,
        type=str,
    )
    parser_update.add_argument(
        '--update_by_iso3',
        action='store_true',
        required=False,
        help='Update by file with iso3 values.',
    )
    parser_update.add_argument(
        '--iso3_file',
        help='Yaml file with key(iso3 lowercase code) - value(yaml key-value properties) configuration for update by matching iso3 codes)',
        required=False,
        type=str,
    )

    # Add special parser for "load" mode
    parser_load = sub_parsers.add_parser(
        "load",
        help="load resources",
        parents=[parent_parser],
    )
    parser_load.add_argument(
        '-d', '--data-directory',
        help='Specify a path with data to load.',
        required=True,
        type=str,
    )

    # Add special parser for "create" mode
    parser_create = sub_parsers.add_parser(
        "create",
        help="create datasets",
        parents=[parent_parser],
    )
    parser_create.add_argument(
        '-o', '--owner',
        help='Who is the owner of these datasets?',
        required=True,
        type=str,
    )
    parser_create.add_argument(
        '--create-from-hasc-code',
        action='store_true',
        required=False,
        help='Create datasets only for hascs from list.',
    )
    parser_create.add_argument(
        '--hasc-list',
        help='List of commaseparated hascs of new datasets, that should be created.',
        required=False,
        type=str,
    )
    parser_create.add_argument(
        '--create-private',
        action='store_true',
        required=False,
        help='New datasets will be private by default.',
    )

    modes_parsers = [parser_create, parser_load, parser_update]

    # Add general arguments to all modes
    for sub_parser in modes_parsers:
        sub_parser.add_argument(
            '-t', '--dataset-type',
            choices=list(DatasetType),
            default=DatasetType('without-type'),
            help='Specify a type of dataset you want to work with.',
            required=False,
            type=DatasetType,
        )
        auth_group = sub_parser.add_argument_group(
            title='Authorization',
        )
        auth_group.add_argument(
            '-k', '--key',
            default='',
            type=str,
            required=False,
            help=f'HDX API key. '
                 f'Visit https://data.humdata.org/user/{os.getlogin()}/api-tokens to get one. '
                 f'Omit it to use key from $HDX_KEY environment variable '
                 f'(env available: {get_hdx_key_from_env() is not None}).',
        )
        auth_group.add_argument(
            '-s', '--hdx-site',
            choices=['stage', 'prod'],
            default='stage',
            type=str,
            required=True,
            help='Set HDX site. Use `stage` for testing. '
                 'Notice that HDX keys are different for different sites'
        )
        misc_group = sub_parser.add_argument_group(
            title='Misc',
        )
        misc_group.add_argument(
            '-v', '--verbose',
            action='store_true',
            required=False,
            help='Run in verbose mode.',
        )
        misc_group.add_argument(
            '--no-dry-run',
            action='store_true',
            required=False,
            help='Do actual work.',
        )

    return parser.parse_args()

# get hdx key from environmental variable if -k, --key options will be omit
def get_hdx_key_from_env():
    return os.environ.get('HDX_KEY', None)

def load(
        data_directory: str,
        dataset_type: DatasetType,
        no_dry_run: bool = False,
        **_kwargs
):
    loader = Loader(dataset_type, data_directory)
    for filename in os.listdir(data_directory):
        datasource_path = os.path.join(data_directory, filename)
        if not loader.datasource_class.is_file_matching_by_regexp(datasource_path):
            continue
        resource = loader.datasource_class(datasource_path)
        loader.add_datasource(resource)

    if no_dry_run:
        loader.upload(skip_validation=False)


# create set of empty datasets
def create_datasets(
        dataset_type: DatasetType,
        owner: str,
        no_dry_run: bool = False,
        create_from_hasc_code: bool = False,
        hasc_list: str = '',
        create_private: bool = False,
        **_kwargs
):
    new_datasets = create_datasets_for_all_hdx_countries(
        dataset_type,
        owner,
        create_from_hasc_code,
        hasc_list,
        create_private,
    )
    unique_id = str(uuid.uuid4())
    if no_dry_run:
        for dataset in new_datasets:
            dataset.create_in_hdx(
                remove_additional_resources=False,
                hxl_update=False,
                updated_by_script=SCRIPT_NAME,
                batch=unique_id,
                allow_no_resources=True,
            )
    else:
        for dataset in new_datasets:
            logging.info(dataset)

# upfate existed datasets
def update_dataset(
        dataset_type: DatasetType,
        dataset_identifier: str,
        update_with_file: str,
        file_with_update: str = '',
        updated_tag: str = '',
        updated_tag_value: str = '',
        iso3_file: str = '',
        update_by_iso3: bool = False,
        no_dry_run: bool = False,
        **_kwargs
):
    # if True - do actual work, else - do nothing
    if no_dry_run:        

        datasets_for_update = []

        # If true - update all <dataset_type> datasets
        if dataset_type.value != 'without-type':
            datasets = get_datasets_for_dataset_type(dataset_type)            
            datasets_for_update = [datasets[_id] for _id in datasets.keys()]  

            assert len(datasets_for_update) > 0, \
                'The number of datasets to update must be greater than 0.'

        elif dataset_identifier:
            # get dataset by identifier
            datasets_for_update = [Dataset.read_from_hdx(dataset_identifier),]  

            assert datasets_for_update != [None], \
                'Request dataset by the dataset identifier returned None.'
        else:
            print('No right conditions provided, please set correct dataset_type or dataset_identifier')


        # if true - update datasets by iso3 code, else - update from yaml/json/command line attribute
        if update_by_iso3:

            assert iso3_file, \
                'You use update by iso3 option but missed iso3_file argument.'
            
            # read yaml file with key(iso3 lowercase code) - value(yaml key-value properties) configuration for update by matching iso3 codes
            with open(iso3_file, "r") as file:
                iso3_values_dict = yaml.load(file, Loader=yaml.FullLoader)            
            
            # updated_datasets = []
            keys = iso3_values_dict.keys()
            print(keys)

            # update by matching iso3 codes
            for i in datasets_for_update:
                if i['groups'][0]['name'] in keys:
                    # dataset['groups'][0]['name'] - name of group is an iso3 lowercase code
                    i.update(iso3_values_dict[i['groups'][0]['name']])
                    i.update_in_hdx()

        else:
            # update local version of dataset by one of several options
            if update_with_file in ('json','yml','yaml','no_file'):
                if update_with_file == 'json':
                    for i in datasets_for_update:
                        i.update_from_json(file_with_update)
                elif update_with_file in ['yml','yaml']:
                    for i in datasets_for_update:
                        i.update_from_yaml(file_with_update)
                elif update_with_file == 'no_file':
                    for i in datasets_for_update:
                        i.update({updated_tag : updated_tag_value})
                # update dataset metadata on hdx server
                for i in datasets_for_update:
                    i.update_in_hdx()
            else:
                print('Wrong value of --update-with-file attribute')


def main():
    args = parse_args()
    setup_logging(
        console_log_level='DEBUG' if args.verbose or not args.no_dry_run else 'INFO',
        log_file=None,
    )

    if args.mode == 'load':
        facade(
            load,
            data_directory=os.path.abspath(args.data_directory),
            dataset_type=args.dataset_type,
            no_dry_run=args.no_dry_run,
            hdx_site=args.hdx_site,
            user_agent=USER_AGENT,
            hdx_read_only=False,
            hdx_key=args.key or get_hdx_key_from_env(),
        )
    elif args.mode == 'create':
        facade(
            create_datasets,
            dataset_type=args.dataset_type,
            owner=args.owner,
            hasc_list=args.hasc_list,
            no_dry_run=args.no_dry_run,
            create_from_hasc_code=args.create_from_hasc_code,
            create_private=args.create_private,
            hdx_site=args.hdx_site,
            user_agent=USER_AGENT,
            hdx_read_only=False,
            hdx_key=args.key or get_hdx_key_from_env(),
        )
    elif args.mode == 'update':
        facade(
            update_dataset,
            dataset_type=args.dataset_type,
            dataset_identifier=args.identifier,
            update_with_file=args.update_with_file,
            file_with_update=args.file_with_update,
            updated_tag=args.tag_name,
            updated_tag_value=args.tag_value,
            update_by_iso3=args.update_by_iso3,
            iso3_file=args.iso3_file,
            no_dry_run=args.no_dry_run,
            hdx_site=args.hdx_site,
            user_agent=USER_AGENT,
            hdx_read_only=False,
            hdx_key=args.key or get_hdx_key_from_env(),
        )
    else:
        raise RuntimeError


if __name__ == '__main__':
    main()
