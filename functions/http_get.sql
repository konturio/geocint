create function http_get(url text) returns text
    parallel safe
    cost 10000
    language plpython3u
as
$$
import urllib.request
return urllib.request.urlopen(url).read().decode('utf-8')
$$;

alter function http_get(text) owner to gis;

