"""
BigQuery Load and Transformation Utilities (bq_loader.py)

Purpose:
This module loads Parquet files from Google Cloud Storage into BigQuery
and executes optional SQL transformations on the loaded data.

Execution Flow:
1. Load one or more Parquet files from Cloud Storage into a BigQuery raw table.
2. Execute transformation SQL script.
"""

from google.cloud import bigquery
import sys
import os
import logging

logger = logging.getLogger(__name__)

# =================================================
# 1. LOAD PARQUET TO BIGQUERY
# =================================================
def load_parquet_to_bq(
    bq_client,
    bucket_name,
    parquet_blobs,
    raw_table_id,
    partition_by=None,
    clustering_fields=None,
    raw_to_target_bqload_sql=None,
    sql_params=None
):

    # ------------------------------------------------
    # 1.1 Skip the BQ load if no files
    # ------------------------------------------------
    if not parquet_blobs:
        print(f"Parquet files not available, skipping load for {raw_table_id}", flush=True)
        return

    # ------------------------------------------------
    # 1.2 Build GCS URIs
    # ------------------------------------------------
    uris = [
        f"gs://{bucket_name}/{b}"
        for b in parquet_blobs
    ]

    logger.info("Preparing to load %s files into BigQuery",len(uris))

    # ------------------------------------------------
    # 1.3 Partitioning config
    # ------------------------------------------------
    time_partitioning = None
    if partition_by:
        time_partitioning = bigquery.TimePartitioning(
            type_=partition_by.get("type").upper(),
            field=partition_by.get("field")
        )

    # ------------------------------------------------
    # 1.4 Load job config
    # ------------------------------------------------
    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.PARQUET,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        time_partitioning=time_partitioning,
        clustering_fields=clustering_fields
    )

    logger.info("Loading into %s", raw_table_id)

    # ------------------------------------------------
    # 1.5 Execute BQ load
    # ------------------------------------------------
    load_job = bq_client.load_table_from_uri(
        uris,
        raw_table_id,
        job_config=job_config
    )

    try:
        load_job.result()
    except Exception:
        logger.exception("BigQuery Load Job failed for table: %s",raw_table_id)

        if load_job.error_result:
            logger.error("BigQuery Error Result: %s",load_job.error_result)

        if load_job.errors:
            logger.error("Detailed BigQuery Errors:")
            for err in load_job.errors:
                logger.error(
                    "Location=%s | Reason=%s | Message=%s",
                    err.get("location"),
                    err.get("reason"),
                    err.get("message")
                )
        raise

    # ------------------------------------------------
    # 1.6 Fetch loaded table row count
    # ------------------------------------------------
    destination_table = bq_client.get_table(raw_table_id)

    logger.info("Successfully loaded %s rows into %s",destination_table.num_rows,raw_table_id)

    return destination_table.num_rows

# =================================================
# 2. EXECUTE TRANSFORMATION SQL
# =================================================
def run_transform_sql(bq_client, sql_path, template_params=None, dw_table_id=None):
    """
    Execute a transform SQL file after BigQuery raw load completes.
    """
    if not sql_path:
        logger.info("Raw data load completed, transformation sql not available,skipping transformation step.")
        return

    if not os.path.exists(sql_path):
        raise FileNotFoundError(f"SQL file not found: {sql_path}")

    with open(sql_path, "r") as f:
        sql = f.read()

    if template_params:
        sql = sql.format(**template_params)

    logger.info("Executing transformation SQL:%s", sql_path)

    query_job = bq_client.query(sql)
    query_job.result()

    if dw_table_id:
        count_sql = f"""
        SELECT COUNT(*) AS cnt
        FROM `{dw_table_id}`
        """

        result = list(bq_client.query(count_sql).result())
        affected_rows = result[0].cnt
    else:
        affected_rows = query_job.num_dml_affected_rows or 0

    logger.info("Transformation SQL execution completed, rows affected: %s",affected_rows)

    return affected_rows
