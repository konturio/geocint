from typing import Annotated, List, Literal, Tuple, Union

BBoxT = Annotated[
    Union[
        List[float],
        Tuple[float],
    ],
    4,
]

EpisodeFilterT = Literal[
    'ANY',
    'LATEST',
]

EventSeverityT = Literal[
    'EXTREME',
    'SEVERE',
    'MODERATE',
    'MINOR',
    'TERMINATION',
    'UNKNOWN',
]

EventTypeT = Literal[
    'FLOOD',
    'TSUNAMI',
    'WILDFIRE',
    'THERMAL_ANOMALY',
    'INDUSTRIAL_HEAT',
    'TORNADO',
    'WINTER_STORM',
    'EARTHQUAKE',
    'STORM',
    'CYCLONE',
    'DROUGHT',
    'VOLCANO',
    'SITUATION',
    'OTHER',
]

PageLimitT = int

SortOrderT = Literal[
    'ASC',
    'DSC',
]

StageT = Literal[
    'prod',
    'test',
    'dev',
]
