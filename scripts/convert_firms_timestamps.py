import pandas as pd
import sys
import datetime

csv_path = sys.argv[1]
df = pd.read_csv(csv_path, dtype={'acq_time': 'str'})
df['acq_datetime'] = df['acq_date'] + ":" + df["acq_time"]
df['acq_datetime'] = df['acq_datetime'].apply(lambda t: str(datetime.datetime.strptime(t, '%Y-%m-%d:%H%M')))
df['type'] = df['acq_datetime']
df.drop(['acq_date', 'acq_time', 'type'], axis=1, inplace=True)
df.to_csv(csv_path.replace('.csv', '_proc.csv'), index=False)