#!/usr/bin/python3

import sys

import pandas as pd

csv_path = sys.argv[1]
df = pd.read_csv(csv_path)
df = df.melt(
    id_vars=['Province/State', 'Country/Region', 'Lat', 'Long'],
    var_name='date',
    value_name='value',
)
df['date'] = pd.to_datetime(df.date)
df.to_csv(
    csv_path.replace('/in/', '/mid/')[:-4] + '_normalized.csv',
    index=False,
    header=True,
)
