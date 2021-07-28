import os
import json
import argparse

import pandas as pd


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-c", "--config_path", required=True,
                        help="Configuration JSON with header mapping data and selected headers from files.",
                        type=str),
    parser.add_argument("-o", "--out_path", required=True, help="Output path where file will be saved.", type=str)
    return parser.parse_args()


def process_dataframe(df, header_map):
    df = df.apply(lambda x: x.replace("-", ""))
    new_header = df.iloc[0]
    df = df[1:]
    df.columns = [header_map[h] for h in new_header.values]
    return df


def merge_dataframes(config_data: dict):
    df = None
    for filepath, header in config_data["header_code"].items():
        if not os.path.exists(filepath):
            raise ValueError(f"Filepath {filepath} does not exist!")
        else:
            cropped_df = pd.read_csv(filepath, usecols=header, low_memory=False)
            if df is None:
                df = cropped_df
            else:
                df = df.merge(cropped_df, on=["GEO_ID", "NAME"])

    return process_dataframe(df, config_data["header_map"])


if __name__ == "__main__":
    args = parse_args()
    with open(args.config_path, "r") as f:
        config_data = json.load(f)

    if args.config_path:
        print(f"Configuration file is: {args.config_path}")

    df = merge_dataframes(config_data)
    df.to_csv(args.out_path, index=False, sep=";")

    if args.out_path:
        print(f"Output file is saved: {args.out_path}")
