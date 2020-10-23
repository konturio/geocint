import pandas as pd
import sys
import datetime

paths = sys.stdin.read().split('\n')

for csv_path in paths:
    if csv_path:
        df = pd.read_csv(csv_path, dtype={'acq_time': 'str'})
        df['acq_datetime'] = df['acq_date'] + ":" + df["acq_time"]
        df['acq_datetime'] = df['acq_datetime'].apply(lambda t: str(datetime.datetime.strptime(t, '%Y-%m-%d:%H%M')))
        df.drop(['acq_date', 'acq_time'], axis=1, inplace=True)
        df.to_csv(csv_path.replace('.csv', '_proc.csv'), index=False)