import dataclasses


@dataclasses.dataclass
class EventsServers:
    api: str
    auth: str


STAGES = {
    'dev': EventsServers(
        api='https://dev-event-api.k8s-01.konturlabs.com/events/v1',
        auth='https://dev-keycloak.k8s-01.konturlabs.com/realms/dev/protocol/openid-connect/token',
    ),
    'test': EventsServers(
        api='https://test-event-api.k8s-01.konturlabs.com/events/v1',
        auth='https://test-keycloak.k8s-01.konturlabs.com/realms/test/protocol/openid-connect/token',
    ),
    'prod': EventsServers(
        api='https://prod-event-api.k8s-01.konturlabs.com/events/v1',
        auth='https://keycloak01.kontur.io/realms/kontur/protocol/openid-connect/token',
    ),
}
