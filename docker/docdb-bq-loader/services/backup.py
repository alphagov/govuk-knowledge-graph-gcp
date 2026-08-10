"""
Backup Resolution Utility (backup.py)

This module contains helper functions to locate the MongoDB backup file
to be processed.

Functions:
- resolve_backup() : Returns the backup file specified in the configuration.
  If no file is provided, it finds the latest matching backup in Google
  Cloud Storage (GCS).

"""

from services.exceptions import JobFailure

def resolve_backup(config, gcs):
    if config.object_name:
        return config.object_name

    if not config.backup:
        raise JobFailure("Backup config not defined")

    return gcs.find_latest_backup(
        config.bucket_name,
        config.backup
    )
