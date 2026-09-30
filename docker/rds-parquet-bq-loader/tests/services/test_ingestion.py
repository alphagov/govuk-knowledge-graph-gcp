from unittest.mock import MagicMock, patch

import pytest

from services.ingestion import process_table

# =========================================================
# FIXTURES
# =========================================================

@pytest.fixture
def mock_clients():
    """Provides mocked GCS and BigQuery client objects."""
    return MagicMock(name="storage_client"), MagicMock(name="bq_client")


@pytest.fixture
def base_config():
    """Provides standard pipeline configuration."""
    return {
        "project_id": "test-project",
        "source_bucket_name": "src-bucket",
        "target_bucket_name": "tgt-bucket",
        "source_root": "inbound/",
        "archive_root": "archive/",
        "error_root": "error/",
        "audit_dataset": "audit_ds",
        "audit_table": "pipeline_audit",
    }


@pytest.fixture
def table_config():
    """Provides table-specific configuration."""
    return {
        "raw_dataset": "raw_ds",
        "dw_dataset": "dw_ds",
        "raw_table": "orders_raw",
        "dw_table": "orders_dw",
        "db_instance": "db01",
        "path_contains": "orders",
        "raw_to_target_bqload_sql": "SELECT * FROM raw_ds.orders_raw",
        "clean_parquet": "N",
    }


@pytest.fixture
def sample_blob():
    """Utility helper to mock GCS Blob objects."""
    def _create_blob(name):
        blob = MagicMock()
        blob.name = name
        return blob
    return _create_blob


# =========================================================
# TEST CASES
# =========================================================

@patch("services.ingestion.archive_files")
@patch("services.ingestion.run_transform_sql", return_value=100)
@patch("services.ingestion.load_parquet_to_bq", return_value=100)
@patch("services.ingestion.copy_blobs_to_bucket")
@patch("services.ingestion.list_blobs")
@patch("services.ingestion.update_audit_record")
@patch("services.ingestion.insert_audit_record", side_effect=["raw_123", "dw_456"])
@patch("services.ingestion.derive_move_path", return_value="orders_path")
def test_process_table_success_normal_mode(
    mock_derive_move,
    mock_insert_audit,
    mock_update_audit,
    mock_list_blobs,
    mock_copy_blobs,
    mock_load_bq,
    mock_transform_sql,
    mock_archive_files,
    mock_clients,
    base_config,
    table_config,
    sample_blob,
):
    storage_client, bq_client = mock_clients

    # Mock discovered blobs
    parquet_blob = sample_blob("inbound/2026-09-30/db01/orders_data.parquet")
    json_blob = sample_blob("inbound/2026-09-30/db01/orders_meta.json")
    
    mock_list_blobs.return_value = [parquet_blob, json_blob]
    mock_copy_blobs.return_value = [parquet_blob, json_blob]

    # Execute
    process_table(storage_client, bq_client, base_config, table_config, recovery_mode=False)

    # Verify audit tracking
    assert mock_insert_audit.call_count == 2
    mock_update_audit.assert_any_call(
        bq_client=bq_client,
        audit_table_id="test-project.audit_ds.pipeline_audit",
        audit_id="raw_123",
        status="success",
        inserted_rows=100,
        error_message=None,
    )

    # Verify core actions executed
    mock_copy_blobs.assert_called_once()
    mock_load_bq.assert_called_once()
    mock_transform_sql.assert_called_once()
    mock_archive_files.assert_called_once()


@patch("services.ingestion.update_audit_record")
@patch("services.ingestion.insert_audit_record", return_value="raw_123")
@patch("services.ingestion.list_blobs", return_value=[])
@patch("services.ingestion.derive_move_path", return_value="orders_path")
def test_process_table_no_files_found(
    mock_derive_move,
    mock_list_blobs,
    mock_insert_audit,
    mock_update_audit,
    mock_clients,
    base_config,
    table_config,
):
    storage_client, bq_client = mock_clients

    # Execute
    process_table(storage_client, bq_client, base_config, table_config, recovery_mode=False)

    # Audit should update to no_files and exit early
    mock_update_audit.assert_called_once_with(
        bq_client=bq_client,
        audit_table_id="test-project.audit_ds.pipeline_audit",
        audit_id="raw_123",
        status="no_files",
        inserted_rows=0,
        error_message="No parquet files found",
    )


@patch("services.ingestion.move_to_error")
@patch("services.ingestion.load_parquet_to_bq", side_effect=RuntimeError("BigQuery Connection Error"))
@patch("services.ingestion.copy_blobs_to_bucket")
@patch("services.ingestion.list_blobs")
@patch("services.ingestion.update_audit_record")
@patch("services.ingestion.insert_audit_record", return_value="raw_123")
@patch("services.ingestion.derive_move_path", return_value="orders_path")
def test_process_table_handles_failure(
    mock_derive_move,
    mock_insert_audit,
    mock_update_audit,
    mock_list_blobs,
    mock_copy_blobs,
    mock_load_bq,
    mock_move_error,
    mock_clients,
    base_config,
    table_config,
    sample_blob,
):
    storage_client, bq_client = mock_clients

    parquet_blob = sample_blob("inbound/2026-09-30/db01/orders_data.parquet")
    mock_list_blobs.return_value = [parquet_blob]
    mock_copy_blobs.return_value = [parquet_blob]

    # Verify exception bubbles up
    with pytest.raises(RuntimeError, match="BigQuery Connection Error"):
        process_table(storage_client, bq_client, base_config, table_config)

    # Verify failure audit update
    mock_update_audit.assert_called_with(
        bq_client=bq_client,
        audit_table_id="test-project.audit_ds.pipeline_audit",
        audit_id="raw_123",
        status="fail",
        inserted_rows=None,
        error_message="BigQuery Connection Error",
    )

    # Verify files moved to error directory
    mock_move_error.assert_called_once()


@patch("services.ingestion.archive_files")
@patch("services.ingestion.run_transform_sql", return_value=50)
@patch("services.ingestion.load_parquet_to_bq", return_value=50)
@patch("services.ingestion.recover_files")
@patch("services.ingestion.update_audit_record")
@patch("services.ingestion.insert_audit_record", side_effect=["raw_rec_123", "dw_rec_456"])
@patch("services.ingestion.derive_move_path", return_value="orders_path")
def test_process_table_recovery_mode(
    mock_derive_move,
    mock_insert_audit,
    mock_update_audit,
    mock_recover,
    mock_load_bq,
    mock_transform_sql,
    mock_archive_files,
    mock_clients,
    base_config,
    table_config,
    sample_blob,
):
    storage_client, bq_client = mock_clients

    recovered_blob = sample_blob("error/orders_data.parquet")
    mock_recover.return_value = [recovered_blob]

    process_table(storage_client, bq_client, base_config, table_config, recovery_mode=True)

    # Verify recover_files was called instead of list_blobs
    mock_recover.assert_called_once_with(
        storage_client=storage_client,
        bucket_name="tgt-bucket",
        error_root="error/",
        source_root="inbound/",
        path_contains="orders",
        move_path="orders_path",
    )

    # Verify raw load audit was logged with raw_load_recovery stage
    assert mock_insert_audit.call_args_list[0].kwargs["audit_stage"] == "raw_load_recovery"
