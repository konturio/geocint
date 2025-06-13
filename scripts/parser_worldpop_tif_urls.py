#!/usr/bin/python3

import re

import requests

IDS_URL = 'https://www.worldpop.org/ajax/geolisting/category?id=29&_=1621603565247'
PAGE_URL = 'https://www.worldpop.org/geodata/summary?id='
SITE = 'data.worldpop.org'


def get_ids():
    response_id = requests.get(IDS_URL, timeout=30)
    data = response_id.json()

    url_ids = [row['id'] for row in data if row['popyear'] == '2020']

    return url_ids


def get_urls(ids):
    image_urls = []
    for id_ in ids:
        url = PAGE_URL + id_
        a_html = requests.get(url, timeout=30).text
        for line in a_html.split('\n'):
            if SITE in line:
                found_urls = re.findall(r'href="(.*\.tif)', line)
                assert len(found_urls) == 1, \
                    f"HTML parsing error: expected len(found_urls)=1, " \
                    f"found {len(found_urls)} for id={id_}"
                image_urls.append(found_urls[0])

    return image_urls


def main():
    ids = get_ids()
    urls = get_urls(ids)
    print("\n".join(urls))


if __name__ == "__main__":
    main()
