import pandas as pd
import sys

csv_path = sys.argv[1]
df = pd.read_csv(csv_path)
df = df.melt(id_vars=['UID','iso2','iso3','code3','FIPS','Admin2','Province_State','Country_Region','Lat','Long_','Combined_Key', 'Population'], var_name='date', value_name='value')
df['date'] = pd.to_datetime(df.date)
df.to_csv(csv_path.replace('.csv', '_normalized.csv'), index=False, header=True)

