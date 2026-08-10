"""
Audit Logging Utilities (audit.py)

Purpose:
This module manages audit records for the ingestion pipeline by creating,
updating, and marking audit entries in the BigQuery audit table.

Execution Flow:
1. Insert a new audit record when a processing stage begins.
2. Update the audit record with the processing status, inserted row count,
   error message (if applicable), and end time.
3. Mark the audit record as failed using the helper function when an error
   occurs during processing.
"""

from google.cloud import bigquery
import uuid
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


# =================================================
# 1. INSERT AUDIT RECORD
# =================================================
def insert_audit_record(
    bq_client: bigquery.Client,
    audit_table_id: str,
    audit_stage: str,
    bq_dataset: str,
    bq_table: str,
    file_type: str = None,
    file_path: str = None,
    status: str = "processing",
    file_count: int = None
):
    """
    Inserts a new audit record and returns audit_id.
    """

    audit_id = str(uuid.uuid4())
    now = datetime.utcnow()

    query = """
    INSERT INTO `{audit_table_id}`
    (
        audit_id,
        audit_stage,
        bq_dataset,
        bq_table,
        file_type,
        file_path,
        status,
        file_count,
        inserted_rows,
        error_message,
        start_time,
        end_time
    )
    VALUES
    (
        @audit_id,
        @audit_stage,
        @bq_dataset,
        @bq_table,
        @file_type,
        @file_path,
        @status,
        @file_count,
        NULL,
        NULL,
        @start_time,
        NULL
    )
    """.format(audit_table_id=audit_table_id)

    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter("audit_id", "STRING", audit_id),
            bigquery.ScalarQueryParameter("audit_stage", "STRING", audit_stage),
            bigquery.ScalarQueryParameter("bq_dataset", "STRING", bq_dataset),
            bigquery.ScalarQueryParameter("bq_table", "STRING", bq_table),
            bigquery.ScalarQueryParameter("file_type", "STRING", file_type),
            bigquery.ScalarQueryParameter("file_path", "STRING", file_path),
            bigquery.ScalarQueryParameter("status", "STRING", status),
            bigquery.ScalarQueryParameter("file_count", "INT64", file_count),
            bigquery.ScalarQueryParameter("start_time", "TIMESTAMP", now),
        ]
    )

    job = bq_client.query(query, job_config=job_config)
    job.result()

    logger.info("Audit inserted: %s (%s)", audit_id, audit_stage)

    return audit_id


# =================================================
# 2. UPDATE AUDIT RECORD
# =================================================
def update_audit_record(
    bq_client: bigquery.Client,
    audit_table_id: str,
    audit_id: str,
    status: str,
    inserted_rows: int = None,
    error_message: str = None
):
    """
    Updates audit record safely.
    """

    now = datetime.utcnow()

    # normalize values
    inserted_rows = inserted_rows if inserted_rows is not None else 0
    error_message = error_message if error_message else None

    query = """
    UPDATE `{audit_table_id}`
    SET
        status = @status,
        inserted_rows = @inserted_rows,
        error_message = @error_message,
        end_time = @end_time
    WHERE audit_id = @audit_id
    """.format(audit_table_id=audit_table_id)

    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter("audit_id", "STRING", audit_id),
            bigquery.ScalarQueryParameter("status", "STRING", status),
            bigquery.ScalarQueryParameter("inserted_rows", "INT64", inserted_rows),
            bigquery.ScalarQueryParameter("error_message", "STRING", error_message),
            bigquery.ScalarQueryParameter("end_time", "TIMESTAMP", now),
        ]
    )

    job = bq_client.query(query, job_config=job_config)
    job.result()

    affected_rows = job.num_dml_affected_rows

    if affected_rows == 0:
        logger.warning("No audit row updated for audit_id=%s", audit_id)
    else:
        logger.info("Audit updated: %s [%s]", audit_id, status)

    return affected_rows


# =================================================
# 3. FAIL AUDIT HELPER
# =================================================
def fail_audit_record(
    bq_client: bigquery.Client,
    audit_table_id: str,
    audit_id: str,
    error_message: str
):
    """
    Standard failure wrapper.
    """

    return update_audit_record(
        bq_client=bq_client,
        audit_table_id=audit_table_id,
        audit_id=audit_id,
        status="failed",
        inserted_rows=0,
        error_message=error_message
    )
