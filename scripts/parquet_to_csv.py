#!/usr/bin/env python3
# transform parquet file to csv

import csv
import sys

import numpy as np
import pandas as pd


def to_pg_array(val):
    if isinstance(val, (list, np.ndarray)):
        return '{' + ','.join(str(v).replace('"', '\\"').replace('\\', '\\\\') for v in val) + '}'
    return val


if len(sys.argv) < 3:
    print(f"Usage: {sys.argv[0]} input.parquet output.csv [col1 col2 ...]")
    sys.exit(1)

input_file = sys.argv[1]
output_file = sys.argv[2]
columns = sys.argv[3:] if len(sys.argv) > 3 else None

df = pd.read_parquet(input_file, columns=columns)

for col in df.columns:
    if df[col].apply(lambda x: isinstance(x, (list, np.ndarray))).any():
        df[col] = df[col].apply(to_pg_array)

df.to_csv(
    output_file,
    index=False,
    sep=';',
    quoting=csv.QUOTE_NONE,
    escapechar='\\',
)

print(output_file)
