import logging
import os

import functions_framework
import google.auth
from flask import jsonify
from google.cloud import dlp_v2

# Initialize logger
logger = logging.getLogger(__name__)

# Automatically discover current Project ID
_, default_project_id = google.auth.default()
PROJECT_ID = os.environ.get("PROJECT_ID", default_project_id)

dlp_client = dlp_v2.DlpServiceClient()

INFO_TYPES = [
    {"name": "DATE_OF_BIRTH"},
    {"name": "EMAIL_ADDRESS"},
    {"name": "PASSPORT"},
    {"name": "PERSON_NAME"},
    {"name": "PHONE_NUMBER"},
    {"name": "STREET_ADDRESS"},
    {"name": "UK_NATIONAL_INSURANCE_NUMBER"},
    {"name": "UK_PASSPORT"},
    {"name": "CREDIT_CARD_NUMBER"},
    {"name": "IBAN_CODE"},
    {"name": "IP_ADDRESS"},
    {"name": "MEDICAL_TERM"},
    {"name": "VEHICLE_IDENTIFICATION_NUMBER"},
    {"name": "SCOTLAND_COMMUNITY_HEALTH_INDEX_NUMBER"},
    {"name": "UK_DRIVERS_LICENSE_NUMBER"},
    {"name": "UK_NATIONAL_HEALTH_SERVICE_NUMBER"},
    {"name": "UK_TAXPAYER_REFERENCE"},
    {"name": "SWIFT_CODE"},
]

INSPECT_CONFIG = {
    "info_types": INFO_TYPES,
    "min_likelihood": dlp_v2.Likelihood.LIKELY,
}

DEIDENTIFY_CONFIG = {
    "info_type_transformations": {
        "transformations": [
            {
                "primitive_transformation": {
                    "replace_with_info_type_config": {}
                }
            }
        ]
    }
}


@functions_framework.http
def deidentify_handler(request):
    try:
        req_body = request.get_json(silent=True)
        if not req_body or "calls" not in req_body:
            return jsonify({"errorMessage": "Invalid BigQuery payload"}), 400

        calls = req_body.get("calls", [])

        # Flatten input: each call is a list of args, e.g. ["some string"]
        non_empty_indices = []
        dlp_rows = []

        # Prepare 1D list of replies matching calls length
        replies = []
        for idx, call in enumerate(calls):
            # Extract scalar value from the inner list [val]
            val = call[0] if (isinstance(call, list) and len(call) > 0) else call
            replies.append(val)

            if val and isinstance(val, str) and val.strip():
                non_empty_indices.append(idx)
                dlp_rows.append({"values": [{"string_value": val}]})

        # Call DLP API only if there are non-empty text strings
        if dlp_rows:
            table_item = {
                "table": {
                    "headers": [{"name": "text"}],
                    "rows": dlp_rows,
                }
            }

            dlp_request = {
                "parent": f"projects/{PROJECT_ID}",
                "deidentify_config": DEIDENTIFY_CONFIG,
                "inspect_config": INSPECT_CONFIG,
                "item": table_item,
            }

            dlp_response = dlp_client.deidentify_content(request=dlp_request)

            # Map the de-identified string back into the 1D replies list
            for orig_idx, result_row in zip(
                non_empty_indices, dlp_response.item.table.rows
            ):
                replies[orig_idx] = result_row.values[0].string_value

        # Return 1D array of strings: {"replies": ["masked_text_1", "masked_text_2", ...]}
        return jsonify({"replies": replies})

    except Exception:
        # 1. Log the traceback securely to GCP Logging using the defined logger and .exception()
        logger.exception("Error occurred during DLP de-identification.")

        # 2. Return a generic message to the client
        return (
            jsonify({
                "errorMessage": (
                    "An internal server error occurred while processing "
                    "the de-identification request."
                )
            }),
            500,
        )
