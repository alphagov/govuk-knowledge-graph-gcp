"""
Application Configuration (config.py)

Purpose:
    Stores the configuration used by the application.

Classes:
    BackupConfig
        Settings for backup files.

    AppConfig
        Main application settings, including Google Cloud resources
        and optional backup configuration.
"""

from dataclasses import dataclass
from typing import Optional


@dataclass
class BackupConfig:
    prefix: str
    match_regex: str


@dataclass
class AppConfig:
    project_id: str
    bucket_name: str
    dataset_id: str
    collection_name: str
    table_name: Optional[str] = None
    dataset_location: str = "europe-west2"
    object_name: Optional[str] = None
    backup: Optional[BackupConfig] = None