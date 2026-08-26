
CREATE TABLE `{project_id}.monitoring.file_ingestion_audit` (
    audit_id STRING NOT NULL,
    audit_stage STRING,
    bq_dataset STRING NOT NULL,
    bq_table STRING NOT NULL,
    file_type STRING,
    file_path STRING NOT NULL,
    status STRING NOT NULL,
    file_count INT64,
    inserted_rows INT64,
    error_message STRING,
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    end_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY _PARTITIONDATE
OPTIONS (
    partition_expiration_days = 30
);