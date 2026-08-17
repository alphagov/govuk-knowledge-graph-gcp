"""
Parquet Cleaning Service (parquet_cleaner.py)

Purpose:
This module cleans Parquet files using configurable rules and uploads the
processed files back to Google Cloud Storage while preserving the original
folder structure.

Execution Flow:
1. Validate whether cleaning rules are configured.
2. Create a unique temporary workspace for processing.
3. Clean any existing temporary files from previous executions.
4. Process each Parquet file from the input list.
5. Apply configured data cleaning rules such as type casting and null
   value replacement.
6. Write cleaned Parquet files locally.
7. Upload cleaned files to the target GCS location.
8. Remove temporary processing files.
9. Return the list of cleaned file paths.
"""

import os
import shutil
import uuid
import pyarrow as pa
import pyarrow.parquet as pq
import pyarrow.compute as pc
import gcsfs
import logging

logger = logging.getLogger(__name__)

# =================================================
# 1.0 VALIDATE CLEANING RULES
# =================================================
def clean_parquet_files(
    storage_client,
    bucket_name,
    parquet_blobs,
    source_root,
    target_root,
    temp_dir,
    cleaning_rules
):
    """
    Cleans Parquet files using dynamic rules and preserves folder structure.

    Returns:
        list[str]: Uploaded GCS object paths
    """

    # ------------------------------------------------
    # 1.1 NO CLEANING RULES
    # ------------------------------------------------
    if not cleaning_rules:
        logger.info(
            "No cleaning rules specified. Skipping parquet cleaning. files=%s",
            len(parquet_blobs)
        )
        return [b.name for b in parquet_blobs]

    # ------------------------------------------------
    # 2.0 UNIQUE TEMP DIRECTORY (CLOUD RUN SAFE)
    # ------------------------------------------------
    temp_dir = f"{temp_dir}_{uuid.uuid4().hex}"
    logger.info("Using temp directory: %s", temp_dir)

    # ------------------------------------------------
    # 3.0 CLEAN EXISTING TEMPORARY FILES
    # ------------------------------------------------
    try:
        if os.path.exists(temp_dir):
            logger.info("Cleaning existing temp directory: %s", temp_dir)
            shutil.rmtree(temp_dir)
    except Exception:
        logger.exception("Failed to clean temp directory: %s", temp_dir)
        raise

    os.makedirs(temp_dir, exist_ok=True)

    bucket = storage_client.bucket(bucket_name)
    # Ensure a unique instance so closing the session at the end doesn't break other tasks
    fs = gcsfs.GCSFileSystem(skip_instance_cache=True)

    cleaned_paths = []

    cast_to_string_cols = set(cleaning_rules.get("cast_to_string", []))
    cast_to_double_cols = set(cleaning_rules.get("cast_to_double", []))

    replace_rules = cleaning_rules.get("replace_null_strings", {})
    replace_cols = set(replace_rules.get("columns", []))
    replace_values = replace_rules.get("values", []) or []

    PROGRESS_INTERVAL = 100

    # ------------------------------------------------
    # 4.0 INITIALISE PARQUET CLEANING JOB
    # ------------------------------------------------
    logger.info(
        "Starting parquet cleaning job. files=%s target=%s",
        len(parquet_blobs),
        target_root
    )

    # ------------------------------------------------
    # 4.1 PROCESS PARQUET FILES
    # ------------------------------------------------
    for i, blob in enumerate(parquet_blobs, start=1):

        try:
            gcs_path = f"{bucket_name}/{blob.name}"

            # ------------------------------------------------
            # PROGRESS LOG (NO FLOODING)
            # ------------------------------------------------
            if i % PROGRESS_INTERVAL == 0:
                logger.info(
                    "Parquet cleaning progress: %s/%s",
                    i,
                    len(parquet_blobs)
                )

            # ------------------------------------------------
            # 4.2 PRESERVE SOURCE FOLDER STRUCTURE
            # ------------------------------------------------
            relative_path = blob.name.replace(source_root, "", 1).lstrip("/")
            if not relative_path:
                relative_path = os.path.basename(blob.name)

            local_path = os.path.join(temp_dir, relative_path)
            os.makedirs(os.path.dirname(local_path), exist_ok=True)

            # ------------------------------------------------
            # 4.3 READ PARQUET FILE
            # ------------------------------------------------
            with fs.open(gcs_path, "rb") as f:
                table = pq.read_table(f)
            #table = pq.read_table(gcs_path, filesystem=fs)

            new_columns = []

            for col_name in table.column_names:

                col = table.column(col_name).combine_chunks()

                if col_name in cast_to_string_cols:
                    col = col.cast(pa.string())

                elif col_name in cast_to_double_cols:
                    col = col.cast(pa.float64())

                # ------------------------------------------------
                # 4.4 NULL REPLACEMENT LOGIC
                # ------------------------------------------------
                if col_name in replace_cols and replace_values:

                    casted = col.cast(pa.string())

                    mask = None

                    for val in replace_values:
                        m = pc.equal(casted, val)
                        m = pc.fill_null(m, False)

                        mask = m if mask is None else pc.or_(mask, m)

                    null_array = pa.array([None] * len(col), type=col.type)

                    col = pc.replace_with_mask(
                        col,
                        mask,
                        null_array
                    )

                new_columns.append(col)

            # ------------------------------------------------
            # 5.0 BUILD CLEANED TABLE
            # ------------------------------------------------
            cleaned_table = pa.table(
                new_columns,
                names=table.column_names
            )

            # ------------------------------------------------
            # 6.0 WRITE LOCAL FILE
            # ------------------------------------------------
            pq.write_table(cleaned_table, local_path)

            # ------------------------------------------------
            # 7.0 UPLOAD TO GCS
            # ------------------------------------------------
            dest_blob_name = f"{target_root.rstrip('/')}/{relative_path}"
            dest_blob = bucket.blob(dest_blob_name)
            dest_blob.upload_from_filename(local_path)

            cleaned_paths.append(dest_blob_name)

        except Exception:
            logger.exception(
                "Failed processing parquet file: gs://%s/%s",
                bucket_name,
                blob.name
            )
            raise

    # ------------------------------------------------
    # 8.0 FINAL CLEANUP
    # ------------------------------------------------
    try:
        shutil.rmtree(temp_dir, ignore_errors=True)
        logger.info("Cleaned temp directory: %s", temp_dir)
    except Exception:
        logger.exception("Failed final temp directory cleanup: %s", temp_dir)

    # ------------------------------------------------
    # 9.0 SUMMARY
    # ------------------------------------------------
    logger.info(
        "Parquet cleaning completed. input=%s output=%s",
        len(parquet_blobs),
        len(cleaned_paths)
    )

    # Defensively close the underlying TCP connection pool
    try:
        if fs and hasattr(fs, "session") and fs.session:
            gcsfs.GCSFileSystem.close_session(fs.loop, fs.session)
            logger.info("Successfully closed GCSFileSystem session.")
    except Exception as e:
        logger.warning("Failed to close GCSFileSystem session cleanly: %s", e)

    return cleaned_paths
