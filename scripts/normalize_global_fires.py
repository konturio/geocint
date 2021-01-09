import pandas as pd
import sys
import datetime
import hashlib


def create_empty_if_not_exists(df, column):
    if column not in df:
        df[column] = ""


def create_md5_hash_column(df):
    return df.apply(lambda x: hashlib.md5((''.join(map(str, tuple(x)))).encode("utf-8")).hexdigest(), axis=1)


csv_path = sys.argv[1]
out_path = csv_path.replace('.csv', '_proc.csv')

chunksize = 10000

for chunk_ind, df in enumerate(pd.read_csv(csv_path, dtype={'acq_time': 'str'}, chunksize=chunksize)):
    df['hash'] = create_md5_hash_column(df)

    acq_date_with_acq_time_ = df['acq_date'] + ":" + df["acq_time"]
    df['acq_datetime'] = acq_date_with_acq_time_.apply(lambda t: str(datetime.datetime.strptime(t, '%Y-%m-%d:%H%M')))

    create_empty_if_not_exists(df, 'brightness')
    create_empty_if_not_exists(df, 'bright_ti4')
    create_empty_if_not_exists(df, 'bright_t31')
    create_empty_if_not_exists(df, 'bright_ti5')

    df = df[['latitude', 'longitude', 'brightness', 'bright_ti4', 'scan',
             'track', 'satellite', 'confidence', 'version', 'bright_t31',
             'bright_ti5', 'frp', 'daynight', 'acq_datetime', 'hash']]

    if chunk_ind == 0:
        df.to_csv(out_path, index=False)
    else:
        df.to_csv(out_path, index=False, mode='a', header=False)
