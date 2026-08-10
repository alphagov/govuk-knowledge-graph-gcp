"""
BigQuery Data Normalization Utility (bq_normalizer.py)

This module contains helper functions to format MongoDB documents so they
match the expected BigQuery schema before loading.

Functions:
    1. _to_bq_string() : Converts values to a BigQuery-compatible STRING format.
    2. normalize_for_bq() : Formats document fields to match the BigQuery schema,
        ensuring repeated fields are stored as arrays and all other values are
        converted to strings.
"""

import json

# =========================================================
# 1. Converts values to a BigQuery-compatible STRING format
# =========================================================

def _to_bq_string(value):
    """Converts a value into a BigQuery STRING format"""
    if value is None:
        return None
    if isinstance(value, (list, dict)):
        return json.dumps(value, default=str)
    if isinstance(value, str):
        return value
    return str(value)

# =========================================================
# 2. Formats document fields to match the BigQuery schema
# =========================================================

def normalize_for_bq(doc, repeated_fields):
    """
    Formats a document so it matches the BigQuery schema.

    - List fields are always saved as arrays.
    - Missing list fields become empty arrays.
    - Single values in list fields are wrapped into a list.
    - Other fields are converted into strings.
    """
    normalized = {}
    for key, value in doc.items():
        key_lower = key.lower()
        if key_lower in repeated_fields:
            if isinstance(value, list):
                items = value
            elif value is None:
                items = []
            else:
                items = [value]
            normalized[key] = [_to_bq_string(v) for v in items]
        else:
            normalized[key] = _to_bq_string(value)
    return normalized
