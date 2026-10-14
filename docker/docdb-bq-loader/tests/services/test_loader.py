import json
from unittest.mock import MagicMock, patch

import pytest

from services.loader import load_config


@pytest.fixture
def valid_raw_config():
    """Provides a valid full raw configuration dictionary."""
    return {
        "project_id": "my-gcp-project",
        "bucket_name": "my-bucket",
        "dataset_id": "my_dataset",
        "collection_name": "my_collection",
        "table_name": "my_table",
        "dataset_location": "us-central1",
        "object_name": "data.json",
        "backup": {
            "enabled": True,
            "retention_days": 30,
        },
    }


@patch("services.loader.BackupConfig")
@patch("services.loader.AppConfig")
def test_load_config_success_with_custom_path(
    mock_app_config, mock_backup_config, tmp_path, monkeypatch, valid_raw_config
):
    """Tests loading a complete configuration file using CONFIG_PATH."""
    config_file = tmp_path / "custom_config.json"
    config_file.write_text(json.dumps(valid_raw_config), encoding="utf-8")

    monkeypatch.setenv("CONFIG_PATH", str(config_file))

    mock_backup_instance = MagicMock()
    mock_backup_config.return_value = mock_backup_instance

    mock_app_instance = MagicMock()
    mock_app_config.return_value = mock_app_instance

    config, raw = load_config()

    assert raw == valid_raw_config
    assert config == mock_app_instance

    mock_backup_config.assert_called_once_with(enabled=True, retention_days=30)
    mock_app_config.assert_called_once_with(
        project_id="my-gcp-project",
        bucket_name="my-bucket",
        dataset_id="my_dataset",
        collection_name="my_collection",
        table_name="my_table",
        dataset_location="us-central1",
        object_name="data.json",
        backup=mock_backup_instance,
    )


@patch("services.loader.BackupConfig")
@patch("services.loader.AppConfig")
def test_load_config_defaults_and_no_backup(
    mock_app_config, mock_backup_config, tmp_path, monkeypatch, valid_raw_config
):
    """Tests fallback to default dataset location and handling missing backup config."""
    del valid_raw_config["backup"]
    del valid_raw_config["dataset_location"]

    config_file = tmp_path / "config.json"
    config_file.write_text(json.dumps(valid_raw_config), encoding="utf-8")

    monkeypatch.setenv("CONFIG_PATH", str(config_file))

    load_config()

    # BackupConfig should not be instantiated when backup key is missing
    mock_backup_config.assert_not_called()

    # Default dataset_location should fall back to 'europe-west2'
    mock_app_config.assert_called_once_with(
        project_id="my-gcp-project",
        bucket_name="my-bucket",
        dataset_id="my_dataset",
        collection_name="my_collection",
        table_name="my_table",
        dataset_location="europe-west2",
        object_name="data.json",
        backup=None,
    )


def test_load_config_file_not_found(tmp_path, monkeypatch):
    """Tests that FileNotFoundError is raised when the file does not exist."""
    non_existent_file = tmp_path / "missing.json"
    monkeypatch.setenv("CONFIG_PATH", str(non_existent_file))

    with pytest.raises(FileNotFoundError):
        load_config()


def test_load_config_missing_required_key(tmp_path, monkeypatch):
    """Tests that KeyError is raised when a required key like project_id is missing."""
    incomplete_config = {"bucket_name": "my-bucket"}

    config_file = tmp_path / "incomplete.json"
    config_file.write_text(json.dumps(incomplete_config), encoding="utf-8")

    monkeypatch.setenv("CONFIG_PATH", str(config_file))

    with pytest.raises(KeyError):
        load_config()
