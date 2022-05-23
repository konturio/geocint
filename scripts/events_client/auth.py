import configparser
import dataclasses
import os
import requests

from events_client.servers import STAGES
from events_client.types import StageT

EVENTAPI_USERNAME_VAR = 'EVENTAPI_USERNAME'
EVENTAPI_PASSWORD_VAR = 'EVENTAPI_PASSWORD'


@dataclasses.dataclass
class Credentials:
    username: str
    password: str


def get_token_from_credentials(
        credentials: Credentials,
        stage: StageT
) -> str:
    auth_data = {
        'client_id': 'kontur_platform',
        'username': credentials.username,
        'password': credentials.password,
        'grant_type': 'password',
    }
    headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
    }
    response = requests.post(
        url=STAGES[stage].auth,
        data=auth_data,
        headers=headers,
    )
    assert response.status_code == 200

    response_json = response.json()
    assert 'access_token' in response_json

    return response_json['access_token']


def get_token_from_env(
        stage: StageT
) -> str:
    assert EVENTAPI_USERNAME_VAR in os.environ, \
        'Missing {} in environment'.format(EVENTAPI_USERNAME_VAR)
    assert EVENTAPI_PASSWORD_VAR in os.environ, \
        'Missing {} in environment'.format(EVENTAPI_PASSWORD_VAR)
    username, password = os.environ[EVENTAPI_USERNAME_VAR], os.environ[EVENTAPI_PASSWORD_VAR]
    return get_token_from_credentials(
        Credentials(username, password), stage,
    )


def get_token_from_file(
        filepath: str,
        stage: StageT,
) -> str:
    assert os.path.exists(filepath), 'Missing auth-config file: {}'.format(filepath)
    config = configparser.ConfigParser()
    config.read(filepath)
    assert 'username' in config
    assert 'password' in config
    return get_token_from_credentials(
        Credentials(config['userbane'], config['password']), stage,
    )
