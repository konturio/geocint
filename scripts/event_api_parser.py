#!/usr/bin/python3

import argparse
import copy
import datetime
import dateutil.parser
import getpass
import json
import logging
import os
import sys

from typing import Any, Dict

from events_client.auth import EVENTAPI_USERNAME_VAR, EVENTAPI_PASSWORD_VAR, \
    Credentials, get_token_from_credentials
from events_client.client import EventAPIClient
from events_client.servers import STAGES


DEFAULT_WORK_DIR = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    'data',
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        'Parser for Event-API.'
    )
    auth_group = parser.add_argument_group(
        title='Authorization',
        description='Specify one of two ways of authorization or '
                    'left it blank and provide user/pass later'
    )
    auth_group.add_argument(
        '-e', '--env',
        action='store_true',
        help=f'Take credentials from environment variables: '
             f'{EVENTAPI_USERNAME_VAR} and {EVENTAPI_PASSWORD_VAR}',
    )
    auth_group.add_argument(
        '-u',
        required='-p' in sys.argv,
        help='Username',
        dest='username',
    )
    auth_group.add_argument(
        '-p',
        required='-u' in sys.argv,
        help='Password',
        dest='password',
    )

    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        '--feed',
        type=str,
        help='Feed to parse. You can run --list-feeds to select one from available.',
    )
    group.add_argument(
        '--list-feeds',
        action='store_true',
        help='Do not download anything, just print available feeds.'
    )

    parser.add_argument(
        '--stage',
        type=str,
        default='prod',
        choices=list(STAGES.keys()),
        help='Specify stage to parse'
    )

    parser.add_argument(
        '--work-dir',
        type=str,
        default=DEFAULT_WORK_DIR,
        help='Specify a path to store results to.'
    )
    return parser.parse_args()


def setup_logger() -> logging.Logger:

    logger = logging.getLogger('event-api-parser')
    if not logger.handlers:
        logger.setLevel(logging.DEBUG)
        ch = logging.StreamHandler()
        ch.setLevel(logging.DEBUG)
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        ch.setFormatter(formatter)
        logger.addHandler(ch)
    return logger


def get_credentials(cli_args: argparse.Namespace) -> Credentials:
    if cli_args.env:
        username = os.environ.get(EVENTAPI_USERNAME_VAR) or getpass.getpass('Username: ')
        password = os.environ.get(EVENTAPI_PASSWORD_VAR) or getpass.getpass('Password: ')
    else:
        username = cli_args.username or getpass.getpass('Username: ')
        password = cli_args.password or getpass.getpass('Password: ')
    return Credentials(username, password)


def parse_datetime_from_iso8601(datetime_string: str) -> datetime.datetime:
    return dateutil.parser.isoparse(datetime_string)


class FeedParser:
    logger = setup_logger()

    def __init__(
        self,
        credentials: Credentials,
        stage: str,
        work_dir: str = DEFAULT_WORK_DIR,
    ):
        self._work_dir = work_dir
        os.makedirs(self._work_dir, exist_ok=True)

        token = get_token_from_credentials(credentials, stage)
        self._client = EventAPIClient(token, stage)

    def _request_feeds(self):
        self.logger.debug('Sending request')
        data = self._client.user_feeds()
        return data

    def run(self):
        feeds_json = self._request_feeds()
        pretty_result = '\n' + '\n'.join(
            f'{feed_dict["feed"]}\t{feed_dict["description"]}'
            for feed_dict in feeds_json
        )
        self.logger.info(pretty_result)

        filepath = os.path.join(self._work_dir, 'feeds')
        self.logger.debug('Dumping data to: %s', filepath)
        tempfile = os.path.join(self._work_dir, '.tmp-events-feeds')

        with open(tempfile, 'w', encoding='utf-8') as f:
            json.dump(feeds_json, f, indent=2)
        os.rename(tempfile, filepath)


class EventParser:
    PARAMS = {
        'feed': None,
        'types': None,
        'severities': None,
        'limit': None,
        'sort_order': 'ASC',
        'episode_filter_type': 'ANY',
        'after': None,
    }
    logger = setup_logger()

    def __init__(
            self,
            credentials: Credentials,
            feed: str,
            stage: str,
            work_dir: str = DEFAULT_WORK_DIR,
    ):
        self._feed = feed
        self._limit = 1000
        self._after = None

        self._work_dir = os.path.join(work_dir, self._feed)
        self._artifact = os.path.join(self._work_dir, '.done')

        os.makedirs(self._work_dir, exist_ok=True)
        existing_geojsons = filter(
            lambda x: x.endswith('.geojson'),
            os.listdir(self._work_dir)
        )
        existing_geojsons_names = [
            os.path.splitext(_f)[0]
            for _f in existing_geojsons
        ]

        if existing_geojsons_names:
            self._after = max(existing_geojsons_names, key=parse_datetime_from_iso8601)
            self.logger.info('Starting from: %s', self._after)

        try:
            os.remove(self._artifact)
        except OSError:
            pass

        token = get_token_from_credentials(credentials, stage)
        self._client = EventAPIClient(token, stage)

    def _get_params(self) -> Dict[str, Any]:
        request_params = copy.copy(self.PARAMS)
        request_params['after'] = self._after
        request_params['feed'] = self._feed
        request_params['limit'] = self._limit
        return request_params

    def _request_events(self):
        self.logger.debug('Sending request')
        data = self._client.geojson_events(
            **self._get_params(),
        )
        if data:
            self.logger.debug('Parsing request')
            self._after = data['pageMetadata']['nextAfterValue']
            self.logger.debug('Next to be parsed is: %s', self._after)
        return data

    def _dump_events(
            self,
            events: Dict[str, Any],
    ):
        filename = f'{events["pageMetadata"]["nextAfterValue"]}.geojson'
        filepath = os.path.join(self._work_dir, filename)
        self.logger.debug('Dumping data to: %s', filepath)
        tempfile = os.path.join(self._work_dir, '.tmp-events')

        with open(tempfile, 'w', encoding='utf-8') as f:
            json.dump(events, f)
        os.rename(tempfile, filepath)

        return filepath

    def run(self):
        while True:
            events = self._request_events()
            if events:
                output_file = self._dump_events(events)
                self.logger.info('Data dumped to: %s', output_file)

            if not events or len(events['features']) < self._limit:
                self.logger.info('No more events until now. Done')
                with open(self._artifact, 'w', encoding='utf-8') as _:
                    pass
                break


def parse_feeds(
        credentials: Credentials,
        stage: str,
        work_dir: str,
):
    parser = FeedParser(
        credentials=credentials,
        stage=stage,
        work_dir=work_dir,
    )
    parser.run()


def parse_events(
        credentials: Credentials,
        feed: str,
        stage: str,
        work_dir: str,
):
    parser = EventParser(
        credentials=credentials,
        feed=feed,
        stage=stage,
        work_dir=work_dir,
    )
    parser.run()


def main():
    args = parse_args()
    credentials = get_credentials(args)

    if args.list_feeds:
        parse_feeds(
            credentials=credentials,
            stage=args.stage,
            work_dir=args.work_dir,
        )
    else:
        parse_events(
            credentials=credentials,
            feed=args.feed,
            stage=args.stage,
            work_dir=args.work_dir,
        )


if __name__ == '__main__':
    main()
