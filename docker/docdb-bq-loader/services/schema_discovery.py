"""
Schema Discovery Utility (schema_discovery.py)

This module contains helper functions to inspect source documents and identify
the fields and array structures required for creating the BigQuery schema.

Functions:
    1. discover_shapes() : Scans all documents in a MongoDB collection to identify
        available fields and fields containing list values.

"""

from utils.sanitizers import sanitize_document

# =========================================================
# 1. DISCOVER DOCUMENT FIELDS
# =========================================================

def discover_shapes(db, collection):
    """
    Checks all documents to find:
    - Every field that exists.
    - Which fields contain lists.

    This information is used to build the correct BigQuery schema
    before exporting any data.    
    """
    all_fields = set()
    array_fields = set()

    for doc in db[collection].find():
        clean = sanitize_document(doc)
        for key, value in clean.items():
            key_lower = key.lower()
            all_fields.add(key)
            if isinstance(value, list):
                array_fields.add(key_lower)

    return all_fields, array_fields
