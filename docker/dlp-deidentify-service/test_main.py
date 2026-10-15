from unittest.mock import MagicMock, patch

import pytest
from flask import Flask
from flask import request as flask_request

# 1. Mock google auth and DLP client globally BEFORE importing main
# This prevents actual API initialization which would fail without credentials
mock_dlp_client = MagicMock()

with patch("google.auth.default", return_value=(None, "test-project-id")), \
     patch("google.cloud.dlp_v2.DlpServiceClient", return_value=mock_dlp_client):
    import main


@pytest.fixture
def client():
    """Sets up a local Flask test client wrapper around the Cloud Function handler."""
    app = Flask(__name__)

    @app.route("/", methods=["POST"])
    def route_handler():
        # Pass Flask's request object directly to the HTTP handler
        return main.deidentify_handler(flask_request)

    app.testing = True
    return app.test_client()


def test_deidentify_handler_invalid_payload(client):
    """Test that an empty or malformed payload returns a 400 error."""
    response = client.post("/", json={})
    assert response.status_code == 400
    assert "Invalid BigQuery payload" in response.get_json()["errorMessage"]


def test_deidentify_handler_empty_calls(client):
    """Test that empty values are returned unmodified without calling the DLP API."""
    payload = {"calls": [[""], [None]]}
    response = client.post("/", json=payload)

    assert response.status_code == 200
    assert response.get_json() == {"replies": ["", None]}
    # Ensure DLP API was never called for empty rows
    mock_dlp_client.deidentify_content.assert_not_called()


def test_deidentify_handler_success(client):
    """Test successful de-identification with mocked DLP responses."""
    # Reset mock call history from previous tests
    mock_dlp_client.deidentify_content.reset_mock()

    # Mock the return structure of DLP's deidentify_content API
    mock_row = MagicMock()
    mock_row.values = [MagicMock(string_value="[PERSON_NAME]")]

    mock_response = MagicMock()
    mock_response.item.table.rows = [mock_row]
    mock_dlp_client.deidentify_content.return_value = mock_response

    # Execute the request
    payload = {"calls": [["John Doe"]]}
    response = client.post("/", json=payload)

    # Validate output
    assert response.status_code == 200
    assert response.get_json() == {"replies": ["[PERSON_NAME]"]}
    mock_dlp_client.deidentify_content.assert_called_once()
