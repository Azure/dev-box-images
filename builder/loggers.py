# ------------------------------------
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# ------------------------------------

import logging
import os
from datetime import datetime, timezone
from pathlib import Path

timestamp = datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')

# indicates if the script is running in the docker container
in_builder = os.environ.get('ACI_IMAGE_BUILDER', False)

repo = Path('/mnt/repo') if in_builder else Path(__file__).resolve().parent.parent
storage = Path('/mnt/storage') if in_builder else repo / '.local' / 'storage'

log_file = storage / f'log_{timestamp}.txt'


def getLogger(name, level=logging.DEBUG):
    logger = logging.getLogger(name)
    logger.setLevel(level=level)

    formatter = logging.Formatter('{asctime} [{name:^8}] {levelname:<8}: {message}', datefmt='%m/%d/%Y %I:%M:%S %p', style='{',)

    ch = logging.StreamHandler()
    ch.setLevel(level=level)
    ch.setFormatter(formatter)

    logger.addHandler(ch)

    if in_builder and os.path.isdir(storage):
        fh = logging.FileHandler(log_file)
        fh.setLevel(level=level)
        fh.setFormatter(formatter)

        logger.addHandler(fh)

    return logger
