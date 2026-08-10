"""
File Recovery Service (recovery.py)

Purpose:
This module recovers failed ingestion files by moving them from the error
location back to the landing location for reprocessing in recovery mode.

Execution Flow:
1. Identify files available in the error location.
2. Filter files belonging to the configured feed.
3. Copy eligible files back to the landing location.
4. Delete the original files from the error location.
5. Return the list of recovered files for further processing.
6. Log recovery progress and failures.
"""

import logging

logger = logging.getLogger(__name__)

def recover_files(
    storage_client,
    bucket_name,
    error_root,
    source_root,
    path_contains,
    move_path,
):
    """
    Recover failed ingestion files from error location back to landing location.

    Files matching the feed are copied from:
        error_root

    back to:
        source_root

    The original error files are deleted after successful copy.

    Returns:
        List of recovered target bucket Blob objects
    """

    logger.info(
        "Recovery started. Moving files from error '%s' back to landing '%s'",
        error_root,
        source_root,
    )

    # =================================================
    # 1. INITIALISE RECOVERY PROCESS
    # =================================================
    bucket = storage_client.bucket(bucket_name)

    # Ensure prefixes have trailing slash
    error_prefix = (
        error_root
        if error_root.endswith("/")
        else f"{error_root}/"
    )

    source_prefix = (
        source_root
        if source_root.endswith("/")
        else f"{source_root}/"
    )

    # =================================================
    # 2. DISCOVER FILES FROM ERROR LOCATION
    # =================================================
    error_blobs = list(
        storage_client.list_blobs(
            bucket_name,
            prefix=error_prefix
        )
    )

    logger.info(
        "Total files found in error location: %d",
        len(error_blobs)
    )

    # =================================================
    # 3. FILTER FILES FOR CURRENT FEED
    # =================================================
    recovery_blobs = [
        blob
        for blob in error_blobs
        if (
            (
                path_contains in blob.name
                and blob.name.endswith(".parquet")
            )
            or move_path in blob.name
            or blob.name.endswith(".json")
        )
    ]

    logger.info(
        "Files eligible for recovery: %d",
        len(recovery_blobs)
    )

    recovered_blobs = []

    for blob in recovery_blobs:

        try:

            relative_path = blob.name[len(error_prefix):]

            new_name = (
                f"{source_prefix}{relative_path}"
            )

            logger.info(
                "Recovering file: %s -> %s",
                blob.name,
                new_name,
            )

            # ================================================================
            # 4. COPY FILES TO LANDING LOCATION & REMOVE FROM ERROR LOCATION
            # ================================================================
            new_blob = bucket.copy_blob(
                blob,
                bucket,
                new_name,
            )

            # Delete error copy
            blob.delete()

            recovered_blobs.append(new_blob)

        except Exception as e:

            logger.exception(
                "Failed recovering blob %s",
                blob.name,
            )

            raise Exception(
                f"Recovery failed for {blob.name}: {e}"
            )


    logger.info(
        "Recovery completed. Files recovered: %d",
        len(recovered_blobs)
    )

    # =================================================
    # 5. RETURN RECOVERY SUMMARY
    # =================================================
    return recovered_blobs
