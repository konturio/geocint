#!/usr/bin/env python3
import sys
from hashlib import md5
import pandas as pd

COLUMNS = 'latitude', 'longitude', 'brightness', 'bright_ti4', 'scan', 'track', 'satellite', 'instrument', \
          'confidence', 'version', 'bright_t31', 'bright_ti5', 'frp', 'daynight', 'acq_datetime',
CHUNK_SIZE = 10000


def main(filename):
    with_header = True
    with pd.read_csv(filename, dtype=str, chunksize=CHUNK_SIZE) as reader:
        for chunk in reader:
            # Combine date and time
            chunk['acq_datetime'] = pd.to_datetime(chunk['acq_date'] + ' ' + chunk['acq_time'], format='%Y-%m-%d %H%M')
            # Remove extra columns, add missing columns and reorder columns
            chunk = chunk.reindex(columns=COLUMNS, fill_value="")

            # Get only the first character of "satellite" because updates contain only abbreviation
            chunk['satellite'] = chunk['satellite'].str[0]

            # Calculate hash
            chunk['hash'] = chunk.apply(lambda x: md5(''.join(map(str, tuple(x))).encode("utf-8")).hexdigest(), axis=1)

            sys.stdout.write(chunk.to_csv(index=False, header=with_header))
            with_header = False


if __name__ == "__main__":
    main(sys.argv[1])
