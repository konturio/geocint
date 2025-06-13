from typing import Dict, List, Optional

# pylint: disable=too-many-positional-arguments

import requests

from events_client.servers import STAGES
from events_client.types import (BBoxT, EpisodeFilterT, EventSeverityT,
                                 EventTypeT, PageLimitT, SortOrderT, StageT)


class BadResponseCode(Exception):
    pass


class EventAPIClient:
    def __init__(
            self,
            token: str,
            stage: StageT = 'dev',
    ):
        self._stage = STAGES[stage]
        self._client = self._get_session(token)

    @staticmethod
    def _get_session(
            token: str,
    ) -> requests.Session:
        auth_header = {
            'accept': 'application/json',
            'Authorization': f'Bearer {token}',
        }
        session = requests.Session()
        session.headers.update(auth_header)
        return session

    def _get(self, *args, **kwargs):
        response = self._client.get(
            *args,
            timeout=120,
            **kwargs,
        )
        if not 200 <= response.status_code < 300:
            raise BadResponseCode(
                f'code: {response.status_code}\n'
                f'url: {response.url}\n'
                f'text: {getattr(response, "text")}'
            )
        return response

    def user_feeds(self) -> List[Dict[str, str]]:
        url = f'{self._stage.api}/user_feeds'
        response = self._get(url)
        if response.status_code == 200:
            return response.json()
        raise BadResponseCode(response.status_code)

    def observations(
            self,
            observation_id: str,
    ) -> str:
        url = f'{self._stage.api}/observations/{observation_id}'
        response = self._get(url)
        if response.status_code == 200:
            return response.json()
        raise BadResponseCode(response.status_code)

    def geojson_events(
            self,
            feed: str,
            types: Optional[List[EventTypeT]] = None,
            severities: Optional[List[EventSeverityT]] = None,
            after: Optional[str] = None,
            datetime: Optional[str] = None,
            bbox: Optional[BBoxT] = None,
            limit: Optional[PageLimitT] = None,
            sort_order: SortOrderT = 'ASC',
            episode_filter_type: EpisodeFilterT = 'ANY',
    ):
        url = f'{self._stage.api}/geojson/events'
        params = {
            'feed': feed,
            'types': types,
            'severities': severities,
            'after': after,
            'datetime': datetime,
            'bbox': bbox,
            'limit': limit,
            'sortOrder': sort_order,
            'episodeFilterType': episode_filter_type,
        }
        response = self._get(url, params=params)
        if response.status_code == 200:
            return response.json()
        if response.status_code == 204:
            return {}
        raise BadResponseCode(response.status_code)

    def event(
            self,
            feed: str,
            event_id: str,
            version: Optional[int] = None,
    ):
        url = f'{self._stage.api}/event'
        params = {
            'feed': feed,
            'version': version,
            'eventId': event_id,
        }
        response = self._get(url, params=params)
        if response.status_code == 200:
            return response.json()
        raise BadResponseCode(response.status_code)

    def v1(
            self,
            feed: str,
            types: Optional[List[EventTypeT]] = None,
            severities: Optional[List[EventSeverityT]] = None,
            after: Optional[str] = None,
            datetime: Optional[str] = None,
            bbox: Optional[BBoxT] = None,
            limit: Optional[PageLimitT] = None,
            sort_order: Optional[SortOrderT] = None,
            episode_filter_type: EpisodeFilterT = 'ANY',
    ):
        url = f'{self._stage.api}/'
        params = {
            'feed': feed,
            'types': types,
            'severities': severities,
            'after': after,
            'datetime': datetime,
            'bbox': bbox,
            'limit': limit,
            'sortOrder': sort_order,
            'episodeFilterType': episode_filter_type,
        }
        response = self._get(url, params=params)
        if response.status_code == 200:
            return response.json()
        if response.status_code == 204:
            return {}
        raise BadResponseCode(response.status_code)
