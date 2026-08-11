"""
Table Ingestion Processing Service (ingestion.py)

Purpose:
This module manages the end-to-end ingestion process for an individual
table. It handles file discovery, recovery processing, auditing, BigQuery
loading, transformation execution, file archiving, and error handling.

Execution Flow:
1. Initialise table configuration and processing variables.
2. Determine normal or recovery processing mode.
3. Discover or recover source files.
4. Insert raw load audit record.
5. Handle scenarios where no files are available.
6. Copy required files to the target bucket.
7. Optionally clean Parquet files.
8. Load Parquet data into the raw BigQuery table.
9. Insert DW audit record and execute transformation SQL.
10. Archive successfully processed files.
11. Update audit records and move files to error location if processing fails.
12. Remove temporary cleaned files during cleanup.
"""

import logging
from datetime import date
from utils.gcs_utils import list_blobs, derive_move_path, copy_blobs_to_bucket
from services.audit import insert_audit_record, update_audit_record
from services.bq_loader import load_parquet_to_bq, run_transform_sql
from services.parquet_cleaner import clean_parquet_files
from services.file_archiver import archive_files, move_to_error
from services.recovery import recover_files

logger = logging.getLogger(__name__)

def process_table(storage_client, bq_client, config, table_cfg, recovery_mode=False):

    project_id = config["project_id"]
    source_bucket_name = config["source_bucket_name"]
    target_bucket_name = config["target_bucket_name"]
    bucket_name = target_bucket_name

    source_root = config["source_root"]
    archive_root = config["archive_root"]
    error_root = config["error_root"]

    raw_dataset = table_cfg["raw_dataset"]
    dw_dataset = table_cfg["dw_dataset"]
    raw_table = table_cfg["raw_table"]
    dw_table = table_cfg["dw_table"]
    db_instance = table_cfg["db_instance"]

    run_date = date.today().isoformat()
    gcs_prefix = f"{source_root}{run_date}/{db_instance}"

    path_contains = table_cfg["path_contains"]
    raw_to_dw_sql = table_cfg["raw_to_target_bqload_sql"]

    partition_by = table_cfg.get("partition_by", {})
    clustering_fields = table_cfg.get("clustering_fields")

    audit_table_id = f"{project_id}.{config['audit_dataset']}.{config['audit_table']}"
    raw_table_id = f"{project_id}.{raw_dataset}.{raw_table}"
    dw_table_id = f"{project_id}.{dw_dataset}.{dw_table}"


    clean_parquet_flag = table_cfg.get("clean_parquet", "N")
    move_path = derive_move_path(path_contains)

    sql_params = {
        "project_id": project_id,
        "raw_dataset": raw_dataset,
        "dw_dataset": dw_dataset,
    }

    # =========================================================
    # 1. INITIALISE PROCESSING STATE
    # =========================================================
    raw_audit_id = None
    dw_audit_id = None

    inserted_rows = None
    dw_rows = None

    move_blobs = []
    blobs_to_load = []
    cleaned_blobs_to_delete = []

    raw_status = "processing"
    dw_status = None
    error_message = None

    try:
        # We need these lists of blobs in both normal and recovery mode
        target_copied_blobs = []
        parquet_blobs = []
        source_parquet_count = 0

        # =============================================================
        # 2. DETERMINE PROCESSING MODE
        # =============================================================
        if recovery_mode:
            # =========================================================
            # 2.1 RECOVERY MODE: RESTORE FILES FROM ERROR LOCATION
            # =========================================================
            target_copied_blobs = recover_files(
                storage_client=storage_client,
                bucket_name=bucket_name,
                error_root=error_root,
                source_root=source_root,
                path_contains=path_contains,
                move_path=move_path,
            )

            parquet_blobs = [
                b for b in target_copied_blobs
                if path_contains in b.name
                and b.name.endswith(".parquet")
            ]

            source_parquet_count = len(parquet_blobs)

        else:
            # =========================================================
            # 2.2 NORMAL MODE: DISCOVER FILES FROM SOURCE BUCKET
            # =========================================================
            all_source_blobs = list_blobs(storage_client, source_bucket_name, gcs_prefix)

            logger.info("Prefix = %s", gcs_prefix)
            logger.info("Total blobs found = %d", len(all_source_blobs))


            # Filter source blobs for ONLY the current feed BEFORE copying
            source_parquet_blobs = [
                b for b in all_source_blobs
                if path_contains in b.name and b.name.endswith(".parquet")
            ]

            source_move_blobs = [
                b for b in all_source_blobs
                if move_path in b.name or b.name.endswith(".json")
            ]

            source_parquet_count = len(source_parquet_blobs)

        # =========================================================
        # 3. INSERT RAWAUDIT RECORD
        # =========================================================
        raw_audit_id = insert_audit_record(
            bq_client=bq_client,
            audit_table_id=audit_table_id,
            audit_stage="raw_load_recovery" if recovery_mode else "raw_load",
            bq_dataset=raw_dataset,
            bq_table=raw_table,
            file_type="parquet",
            file_path=f"gs://{target_bucket_name}/{gcs_prefix}",
            status="processing",
            file_count=source_parquet_count,
        )

        # =========================================================
        # 4. HANDLE NO FILES CASE
        # =========================================================
        if source_parquet_count == 0:
            logger.info("No parquet files found for pattern '%s' (Recovery: %s) in %s", 
                        path_contains, recovery_mode, source_bucket_name if not recovery_mode else bucket_name)

            raw_status = "no_files"

            update_audit_record(
                bq_client=bq_client,
                audit_table_id=audit_table_id,
                audit_id=raw_audit_id,
                status=raw_status,
                inserted_rows=0,
                error_message="No parquet files found"
            )
            return

        # =================================================================
        # 5. COPY FILES FROM SOURCE TO TARGET BUCKET (SKIP IF RECOVERY)
        # =================================================================
        if not recovery_mode:
            # Combine and deduplicate to get the exact files that belong only to this specific table/feed
            blobs_to_copy = list({b.name: b for b in source_parquet_blobs + source_move_blobs}.values())

            logger.info(
                "Copying %d discovered files for feed '%s' from source '%s' to target '%s'",
                len(blobs_to_copy), path_contains, source_bucket_name, target_bucket_name
            )

            # Server-side copy ONLY the files belonging to this specific feed
            target_copied_blobs = copy_blobs_to_bucket(
                storage_client=storage_client,
                source_bucket_name=source_bucket_name,
                target_bucket_name=target_bucket_name,
                blobs=blobs_to_copy
            )

            # Filter the lists of blobs directly from the newly copied target bucket references
            parquet_blobs = [
                b for b in target_copied_blobs
                if path_contains in b.name and b.name.endswith(".parquet")
            ]

        # Regardless of recovery or normal mode, we now define the move/load variables on target_copied_blobs
        move_blobs = [
            b for b in target_copied_blobs
            if move_path in b.name or b.name.endswith(".json")
        ]

        blobs_to_load = [b.name for b in parquet_blobs]

        # =========================================================
        # 6. OPTIONAL PARQUET CLEANING
        # =========================================================
        if clean_parquet_flag.upper() == "Y":
            logger.info("Cleaning parquet files enabled")

            cleaned_prefix = f"fixed_parquet_data/{raw_table}/"
            temp_dir = "./temp_parquet_workspace"

            blobs_to_load = clean_parquet_files(
                storage_client=storage_client,
                bucket_name=bucket_name,
                parquet_blobs=parquet_blobs,
                source_root=source_root,
                target_root=cleaned_prefix,
                temp_dir=temp_dir,
                cleaning_rules=table_cfg.get("cleaning_rules", {}),
            )

            cleaned_blobs_to_delete = list(blobs_to_load)

        # =========================================================
        # 7. LOAD DATA INTO RAW BIGQUERY TABLE
        # =========================================================
        inserted_rows = load_parquet_to_bq(
            bq_client=bq_client,
            bucket_name=bucket_name,
            parquet_blobs=blobs_to_load,
            raw_table_id=raw_table_id,
            partition_by=partition_by,
            clustering_fields=clustering_fields,
            raw_to_target_bqload_sql=raw_to_dw_sql,
            sql_params=sql_params,
        )

        logger.info("RAW load completed: %s rows", inserted_rows)

        if not inserted_rows:
            raise Exception("RAW load inserted 0 rows")

        raw_status = "success"

        # update raw audit immediately after success
        update_audit_record(
            bq_client=bq_client,
            audit_table_id=audit_table_id,
            audit_id=raw_audit_id,
            status=raw_status,
            inserted_rows=inserted_rows,
            error_message=None
        )

        # =========================================================
        # 8. INSERT DW AUDIT RECORD & EXECUTE TRANSFORMATION SQL
        #    UPDATE DW AUDIT RECORD AFTER SUCCESS
        # =========================================================
        dw_audit_id = insert_audit_record(
            bq_client=bq_client,
            audit_table_id=audit_table_id,
            audit_stage="dw_load",
            bq_dataset=dw_dataset,
            bq_table=dw_table,
            file_type="sql",
            file_path=raw_to_dw_sql,
            status="processing",
        )

        dw_rows = run_transform_sql(bq_client, raw_to_dw_sql, sql_params,dw_table_id)

        logger.info("DW load completed: %s rows", dw_rows)

        dw_status = "success"

        update_audit_record(
            bq_client=bq_client,
            audit_table_id=audit_table_id,
            audit_id=dw_audit_id,
            status=dw_status,
            inserted_rows=dw_rows,
            error_message=None
        )

         
        # =========================================================
        # 9. ARCHIVE PROCESSED FILES (ON TARGET BUCKET)
        # =========================================================
        archive_files(
            storage_client=storage_client,
            bucket_name=bucket_name,
            blobs=move_blobs,
            source_root=source_root,
            archive_root=archive_root,
         )
        logger.info("--------- Finished table %s.%s ---------", raw_dataset, dw_table)
        return

        # =========================================================
        # 10. FAILURE RAW AUDIT UPDATES
        # =========================================================        

    except Exception as e:
        error_message = str(e)
        logger.exception("Pipeline failed for %s.%s", raw_dataset, dw_table)
        # mark raw audit failure if exists
        if raw_audit_id:
            try:
                    update_audit_record(
                        bq_client=bq_client,
                        audit_table_id=audit_table_id,
                        audit_id=raw_audit_id,
                        status="fail",
                        inserted_rows=inserted_rows,
                        error_message=error_message
                    )
            except Exception:
                    logger.exception("Failed updating raw audit")

        # =========================================================
        # 11. FAILURE DW AUDIT UPDATES
        # =========================================================        

        if dw_audit_id:
            try:
                update_audit_record(
                    bq_client=bq_client,
                    audit_table_id=audit_table_id,
                    audit_id=dw_audit_id,
                    status="fail",
                    inserted_rows=dw_rows,
                    error_message=error_message
                )
            except Exception:
                    logger.exception("Failed updating DW audit")

        # =========================================================
        # 12. MOVE FILES TO ERROR (ON TARGET BUCKET)
        # =========================================================        
        try:
            move_to_error(
                storage_client=storage_client,
                bucket_name=bucket_name,
                blobs=move_blobs,
                source_root=source_root,
                error_root=error_root,
            )
        except Exception:
            logger.exception("Failed moving files to error zone")


        raise

    finally:
        # =========================================================
        # 13. CLEANUP TEMP FILES ONLY (ON TARGET BUCKET)
        # =========================================================
        if cleaned_blobs_to_delete:
            bucket = storage_client.bucket(bucket_name)

            for blob_name in cleaned_blobs_to_delete:
                try:
                    bucket.blob(blob_name).delete()
                    logger.info("Deleted temporary cleaned file %s", blob_name)
                except Exception as e:
                    logger.warning("Failed deleting temporary file %s: %s",blob_name,e)
