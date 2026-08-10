"""
File Movement Utilities (file_archiver.py)

Purpose:
This module manages file movement within Google Cloud Storage. It supports
moving processed files to archive locations and failed files to error
locations.

Execution Flow:
1. Validate source file paths before moving files.
2. Build destination paths while maintaining the original folder structure.
3. Copy files to the target location.
4. Delete the original files after a successful copy.
5. Handle missing files caused by parallel processing safely.
6. Provide summary logging of moved and skipped files.
7. Support archive and error file movement through reusable functions.
"""

import logging
from google.api_core.exceptions import NotFound

logger = logging.getLogger(__name__)

# =================================================
# Move Files To Target Location
# =================================================
def move_files(
    storage_client,
    bucket_name,
    blobs,
    source_root,
    target_root
):
    bucket = storage_client.bucket(bucket_name)
    moved_count = 0
    skipped_count = 0

    logger.info("Starting file move operation")

    for blob in blobs:
        # Check if the blob is in the expected source path
        if source_root not in blob.name:
            skipped_count += 1
            continue

        # Extract relative path to reconstruct the destination
        relative_path = blob.name.split(source_root, 1)[1]
        
        # Ensure destination path is formatted correctly
        destination_blob_name = f"{target_root.rstrip('/')}/{relative_path.lstrip('/')}"

        # Try to copy and delete the blob safely
        try:
            # Copy the blob to the new location
            bucket.copy_blob(
                blob,
                bucket,
                destination_blob_name
            )

            # Delete the original blob
            blob.delete()
            
            moved_count += 1
        except NotFound:
            # If another parallel task already archived/deleted this file, skip it safely
            logger.warning(
                "Blob %s was not found on the server. It may have already been archived by another task.", 
                blob.name
            )
            skipped_count += 1
        except Exception as e:
            logger.error("Failed to move blob %s: %s", blob.name, e)
            raise

    # Print the final summary instead of individual file paths
    if skipped_count > 0:
        logger.info("File move completed. Moved=%s, Skipped=%s (already archived/deleted or invalid path)", moved_count, skipped_count)
    else:
        logger.info("Archive complete. Moved=%s files", moved_count)

# =================================================
#  Mover Files to Archive Location
# =================================================

def archive_files(
    storage_client,
    bucket_name,
    blobs,
    source_root,
    archive_root
):
    logger.info("Archiving files to %s", archive_root)

    move_files(
        storage_client=storage_client,
        bucket_name=bucket_name,
        blobs=blobs,
        source_root=source_root,
        target_root=archive_root
    )

# =================================================
#  Mover Files to Error Location
# =================================================

def move_to_error(
    storage_client,
    bucket_name,
    blobs,
    source_root,
    error_root
):
    logger.info("Moving failed files to error path: %s", error_root)
    
    move_files(
        storage_client=storage_client,
        bucket_name=bucket_name,
        blobs=blobs,
        source_root=source_root,
        target_root=error_root
    )
