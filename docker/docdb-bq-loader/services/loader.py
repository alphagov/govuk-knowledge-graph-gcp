"""
Configuration Loader Utility (loader.py)

This module provides helper functions to load and prepare the application
configuration required by the data ingestion pipeline.

Functions:
    1. load_config() : Reads the configuration file, creates the application
        configuration object, and returns both the parsed configuration and the
        raw configuration values.

"""

import json
import os
from models.config import AppConfig, BackupConfig

# =========================================================
# 1.LOAD CONFIGURATION
# =========================================================

def load_config():
    CONFIG_FILE = os.getenv("CONFIG_PATH", "config/development/config.json")

    with open(CONFIG_FILE, "r", encoding="utf-8") as f:
        raw = json.load(f)

    backup_cfg = raw.get("backup")

    config = AppConfig(
        project_id=raw["project_id"],
        bucket_name=raw["bucket_name"],
        dataset_id=raw["dataset_id"],
        collection_name=raw["collection_name"],
        table_name=raw.get("table_name"),
        dataset_location=raw.get("dataset_location", "europe-west2"),
        object_name=raw.get("object_name"),
        backup=BackupConfig(**backup_cfg) if backup_cfg else None,
    )

    return config, raw
