#!/usr/bin/env python3
from typing import AnyStr
import argparse
import asyncio
import aiohttp
import psycopg2
from psycopg2.extras import execute_values
from threading import Thread
import multiprocessing as mp
from time import sleep
from math import ceil

MAX_CONCURRENT = 100
PAGE_SIZE = 1000
PROCESSES = 4


async def fetch_table(session, semaphore, url):
    async with semaphore:
        async with session.get(url) as response:
            answer = await response.json()
            return answer


def process_answer(answer):
    points = (dest['location'] for dest in answer['destinations'])
    etas = answer['durations'][0]
    return tuple((*z[0], z[1]) for z in zip(points, etas) if z[1] is not None)


async def fetch_tables(urls, query_string):
    semaphore = asyncio.Semaphore(MAX_CONCURRENT)
    async with aiohttp.ClientSession() as session:
        completed = []
        for coro in asyncio.as_completed([fetch_table(session, semaphore, url + '?' + query_string) for url in urls]):
            completed.append(process_answer(await coro))
        return tuple(set().union(*completed))


def populate_queue(queue: mp.Queue, dsn: AnyStr, points_table: AnyStr):
    conn = psycopg2.connect(dsn)
    with conn.cursor() as curs:
        curs.execute(f"""
            select round(ST_X(tr), 6), round(ST_Y(tr), 6)
            from {points_table} t,
                 ST_Transform(t.geom, 4326) tr
        """)
        for item in curs:
            queue.put(item)


def build_isochrones(queue: mp.Queue,
                     dsn,
                     dst_points,
                     max_distance: float,
                     url_prefix: AnyStr,
                     osrm_max_table: int,
                     seconds: float,
                     output_table: AnyStr
                     ):
    conn = psycopg2.connect(dsn)
    conn.autocommit = True
    with conn.cursor() as curs:
        curs.execute('create temp table isochrone_points (geom geometry);')
    i = 0
    while True:
        # sleep(1)
        with conn.cursor() as curs:
            curs.execute('truncate pg_temp.isochrone_points;')
        if queue.empty():
            break
        x1, y1 = queue.get()
        i += 1
        url = f'{url_prefix}/{x1},{y1}'
        urls = [url]
        n_points = 1
        with conn.cursor() as curs:
            curs.execute(f"""
                select distinct round(ST_X(p2), 6), round(ST_Y(p2), 6)
                from ST_Transform(ST_SetSRID(ST_MakePoint(%(x1)s, %(y1)s), 4326), 3857) p1,
                    {dst_points} t,
                    ST_Transform(t.geom, 4326) p2
                where ST_DWithin(p1, t.geom, %(max_distance)s)
                """, {
                    "x1": x1,
                    "y1": y1,
                    "max_distance": max_distance,
            })
            for x2, y2 in curs:
                # Split urls by coordinates count < OSRM max_table_size
                if n_points == osrm_max_table:
                    n_points = 0
                    urls.append(url)
                urls[-1] += f';{x2},{y2}'
                n_points += 1
            points_eta = asyncio.run(fetch_tables(urls, 'sources=0&annotations=duration'))
            with conn.cursor() as curs:
                execute_values(curs,
                               'insert into pg_temp.isochrone_points (geom) values %s',
                               points_eta,
                               template='(ST_SetSRID(ST_MakePoint(%s, %s, %s), 4326))',
                               page_size=PAGE_SIZE
                               )
        with conn.cursor() as curs:
            curs.execute("""
                    select ST_Union(ch) geom
                    from (
                             select (ST_Dump(ST_DelaunayTriangles(ST_Collect(geom)))).geom
                             from pg_temp.isochrone_points
                             ) "d",
                         ST_ConvexHull(
                                 ST_LocateBetweenElevations(ST_Boundary(d.geom),
                                                            0,
                                                            %s)
                             ) ch;
                    """,
                         (seconds,)
                         )
            isochrone = (curs.fetchone() or [None, ])[0]
        if isochrone:
            with conn.cursor() as curs:
                curs.execute(f'insert into {output_table} (geom, x, y) values (%s, %s, %s)',
                             (isochrone, x1, y1,)
                             )
    with conn.cursor() as curs:
        curs.execute('drop table pg_temp.isochrone_points;')
    conn.close()


def main(dsn, osrm_url, osrm_max_table, seconds, avg_speed, src_points, dst_points, output_table):
    conn = psycopg2.connect(dsn)
    with conn.cursor() as curs:
        curs.execute('select to_regclass(%s)', (output_table,))
        if curs.fetchone()[0]:
            raise Exception(f'Table {output_table} already exists')
        curs.execute(f'create table {output_table} (x float, y float, geom geometry)')
    conn.commit()
    conn.close()

    # TODO: show progress
    max_distance = ceil(avg_speed * seconds)
    m = mp.Manager()
    queue = m.Queue()
    populate_thread = Thread(target=populate_queue, args=(queue, dsn, src_points))
    populate_thread.start()
    sleep(1)

    threads = []
    for _ in range(PROCESSES):
        threads.append(
            Thread(target=build_isochrones,
                   args=(queue, dsn, dst_points, max_distance, osrm_url, osrm_max_table, seconds, output_table,)))
        threads[-1].start()
    [thread.join() for thread in threads]

    populate_thread.join()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Calculate isochrones between 2 point tables", add_help=False)
    parser.add_argument('--help', help='show this help message and exit', action='help')

    database = parser.add_argument_group(title='PostgreSQL connection options')
    database.add_argument("-h", "--host", help="Server host")
    database.add_argument("-p", "--port", help="Server port")
    database.add_argument("-U", "--user", help="User name")
    database.add_argument("-W", "--password", help="Password")
    database.add_argument("-d", "--dbname", help="Database name to connect")

    osrm = parser.add_argument_group('OSRM options')
    osrm.add_argument('-u', '--url', help='OSRM router url', default='http://localhost:5000/table/v1/car')
    osrm.add_argument('-m', '--max-table-size', type=int, help='Max. locations supported in distance table query', default=100)

    isochrones = parser.add_argument_group('Isochrone build options')
    isochrones.add_argument('-t', '--time', help='', required=True, type=int)
    isochrones.add_argument('-s', '--avg-speed', help='', required=True, type=int)

    parser.add_argument("points_from", help='Points table for build isochrones from (SRID:3857)')
    parser.add_argument("points_to", help='Points table for build isochrones to (SRID:3857)')
    parser.add_argument("output_table", help='Output table (SRID:3857)')
    args = parser.parse_args()

    dsn = ' '.join(f'{arg.dest}={getattr(args, arg.dest)}' for arg in database._group_actions if
                   getattr(args, arg.dest) is not None)

    main(
        dsn=dsn,
        osrm_url=args.url.rstrip(),
        osrm_max_table=args.max_table_size,
        seconds=args.time,
        avg_speed=args.avg_speed,
        src_points=args.points_from,
        dst_points=args.points_to,
        output_table=args.output_table
    )
