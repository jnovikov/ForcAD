#!/usr/bin/env python3

import psycopg2
import redis
import sys
import time

from pathlib import Path

BASE_DIR = Path(__file__).absolute().resolve().parents[1]
sys.path.insert(0, str(BASE_DIR))

import storage

SCRIPTS_DIR = BASE_DIR / 'scripts'


def run():
    conn = storage.get_db_pool().getconn()
    curs = conn.cursor()

    create_query_path = SCRIPTS_DIR / 'drop_query.sql'
    create_query = create_query_path.read_text()
    # noinspection PyUnresolvedReferences
    try:
        curs.execute(create_query)
    except psycopg2.errors.UndefinedTable:
        pass
    else:
        conn.commit()
    finally:
        curs.close()

    while True:
        try:
            storage.get_redis_storage().flushall()
        except (
                redis.exceptions.ConnectionError,
                redis.exceptions.BusyLoadingError):
            print('[*] Redis isn\'t running, waiting...')
            time.sleep(5)
        else:
            break


if __name__ == '__main__':
    run()
