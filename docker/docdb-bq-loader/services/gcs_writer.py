"""
GCS JSON Writer Utility (gcs_writer.py)

This module contains helper functions to export MongoDB documents to JSON
files stored in Google Cloud Storage (GCS).

Functions:
    1. write_to_gcs() : Reads documents from a MongoDB collection, formats them
        according to the BigQuery schema, and writes them as newline-delimited JSON
        records to GCS.

"""

import json
from services.bq_normalizer import normalize_for_bq
from utils.logging import get_logger
from utils.sanitizers import sanitize_document

logger = get_logger(__name__)

# =========================================================
# 1. Reads documents from a MongoDB collection, formats them
#    according to the BigQuery schema, and writes to GCS as
#    newline-delimited JSON records.
# =========================================================

def write_to_gcs(db, collection, bucket, blob_name, repeated_fields):
    """
    Writes all documents to a JSON file in GCS.
    Each document is formatted using the BigQuery schema decided earlier.
    """
    blob = bucket.blob(blob_name)
    count = 0

    with blob.open("w", encoding="utf-8") as f:
        for doc in db[collection].find():
            clean = normalize_for_bq(sanitize_document(doc), repeated_fields)
            f.write(json.dumps(clean) + "\n")
            count += 1

            if count % 1000000 == 0:
                logger.info("Processed %s docs", count)

    return count
