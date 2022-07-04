import argparse
import logging
import os
import uuid

from hdx.facades.keyword_arguments import facade
from hdx.utilities.easy_logging import setup_logging

from hdxloader.dataset import DatasetType
from hdxloader.loader import create_datasets_for_all_hdx_countries, Loader, SCRIPT_NAME


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
    modes_parsers = [parser_create, parser_load]

    for sub_parser in modes_parsers:
        sub_parser.add_argument(
            '-t', '--dataset-type',
            choices=list(DatasetType),
            help='Specify a type of dataset you want to work with.',
            required=True,
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


def create_datasets(
        dataset_type: DatasetType,
        owner: str,
        no_dry_run: bool = False,
        **_kwargs
):
    new_datasets = create_datasets_for_all_hdx_countries(
        dataset_type,
        owner,
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
