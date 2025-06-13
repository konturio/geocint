import logging
from typing import Set

# pylint: disable=too-many-nested-blocks,too-many-branches

# from hdx.data.organization import Organization
from hdxloader.loader import get_datasets_for_dataset_type
from hdxloader.dataset import DatasetType


# get list of unique available keys for selected datasets
def get_available_keys(dataset_type: DatasetType,
                       show_available_keys: bool,
                       show_full_metadata: bool,
                       keys_list: str) -> Set[str]:

    if dataset_type:
        datasets = get_datasets_for_dataset_type(dataset_type)

        # Show only keys without metadata
        if show_available_keys and not show_full_metadata:
            full_list_of_available_keys = []
            for i in datasets.values():
                full_list_of_available_keys = full_list_of_available_keys + list(i.keys())
            logging.info(set(full_list_of_available_keys))

        # Show full metadata or only needed key - value pairs
        elif show_full_metadata and not show_available_keys:
            if len(keys_list) > 0:
                selected_keys = keys_list.strip(',').split(',')
                if 'title' not in selected_keys:
                    selected_keys.append('title')
                if 'id' not in selected_keys:
                    selected_keys.append('id')

                for i in datasets.values():
                    out_metadata = {}
                    for k in i.keys():
                        if k in selected_keys:
                            out_metadata[k] = i[k]
                    logging.info(out_metadata)
            else:
                for i in datasets.values():
                    logging.info(i)
        else:
            logging.info(
                'select one of the available options: --show-available-keys, '
                '--show-full-metadata (full or with using --keys_list)'
            )
