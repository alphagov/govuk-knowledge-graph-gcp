"""
Google Cloud Storage Service (gcs_service.py)

This module provides helper methods for working with Google Cloud Storage (GCS)
as part of the data ingestion pipeline.

Functions:
1. download_file() : Downloads a file from GCS to local temporary storage.
2. get_bucket() : Returns the Google Cloud Storage client.
3. bucket() : Returns a specific GCS bucket.
4. find_latest_backup() : Finds the most recent backup file that matches the
  configured prefix and filename pattern.

"""

import re
from google.cloud import storage
from utils.logging import get_logger
from services.exceptions import JobFailure

logger = get_logger(__name__)


class GCSService:

    def __init__(self, project_id: str):
        self.client = storage.Client(project=project_id)

    # =========================================================
    # 1. Downloads a file from GCS to local temporary storage
    # =========================================================

    def download_file(self, bucket_name: str, object_name: str, local_path: str):
        bucket = self.client.bucket(bucket_name)
        blob = bucket.blob(object_name)

        logger.info("Downloading gs://%s/%s", bucket_name, object_name)
        blob.download_to_filename(str(local_path))

    # =========================================================
    # 2. Returns the Google Cloud Storage client
    # =========================================================

    def get_bucket(self) -> storage.Client:
        """
        Returns the raw GCS Client instance.
        """
        return self.client

    # =========================================================
    # 3. Returns a specific GCS bucket
    # =========================================================

    def bucket(self, bucket_name: str) -> storage.Bucket:
        """
        Returns a specific GCS bucket instance.
        """
        return self.client.bucket(bucket_name)


    # =========================================================
    # 4. Finds the most recent backup file that matches 
    # the configured prefix and filename pattern
    # =========================================================

    def find_latest_backup(self, bucket_name: str, backup_cfg) -> str:
        """
        Returns latest backup matching config rules.
        """
        bucket = self.client.bucket(bucket_name)

        # Retrieve list of blobs matching prefix
        blobs = bucket.list_blobs(prefix=backup_cfg.prefix)

        pattern = re.compile(backup_cfg.match_regex)

        # Filter candidates based on the regex pattern
        candidates = [
            b for b in blobs
            if pattern.match(b.name)
        ]

        if not candidates:
            # Raising JobFailure if no matching backup is found
            raise JobFailure(
                f"No matching backup found in GCS bucket '{bucket_name}' "
                f"with prefix '{backup_cfg.prefix}' and pattern '{backup_cfg.match_regex}'"
            )

        # Find the most recently updated backup file
        latest = max(
            candidates,
            key=lambda b: b.updated
        )

        logger.info(
            "Selected latest backup: %s (Updated: %s)",
            latest.name,
            latest.updated
        )

        return latest.name
