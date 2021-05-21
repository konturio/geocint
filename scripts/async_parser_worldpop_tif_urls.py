import requests
import re

import aiohttp
import asyncio

IDS_URL = 'https://www.worldpop.org/ajax/geolisting/category?id=29&_=1621603565247'
PAGE_URL = 'https://www.worldpop.org/geodata/summary?id='
SITE = 'data.worldpop.org'


def get_ids():
    response_id = requests.get(IDS_URL)
    data = response_id.json()

    url_ids = [row['id'] for row in data if row['popyear'] == '2020']

    return url_ids


def process_html(html):
    for line in html.split('\n'):
        if SITE in line:
            found_urls = re.findall('href="(.*\.tif)', line)
            assert len(
                found_urls) == 1, f'HTML parsing error: expected len(found_urls)=1, found {len(found_urls)} for id={id_}'
            return found_urls[0]


async def process_url(client, url):
    async with client.get(url) as response:
        html = await response.text()
        image_url = process_html(html)
    return image_url


async def get_urls(ids):
    async with aiohttp.ClientSession() as client:
        tasks = []
        for id_ in ids:
            url = PAGE_URL + id_
            tasks.append(process_url(client, url))
        image_urls = await asyncio.gather(*tasks)
    return image_urls


async def main():
    ids = get_ids()
    urls = await get_urls(ids)
    print("\n".join(urls))


if __name__ == "__main__":
    asyncio.run(main())
