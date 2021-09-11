create function http_get(url text, pass_codes integer[] default null) returns text
    parallel safe
    cost 10000
    language plpython3u
as
$$
from urllib.request import urlopen
from urllib.error import HTTPError
try:
    return urlopen(url).read().decode('utf-8')
except HTTPError as e:
    if e.code not in pass_codes:
        raise
$$;

