"""
MongoDB Document Cleaner (sanitizers.py)

This script prepares MongoDB data so it can be safely saved into databases 
like BigQuery without causing errors. It does this by fixing inconsistent 
fields and removing empty (None) values.

Functions:
1. serialize_and_strip_nulls() : Converts special MongoDB data types into 
   standard, easy-to-read JSON. It also looks through the data and removes 
   any fields that are empty (None).

2. sanitize_document() : The main function used to clean a document. It first 
   fixes specific inconsistent fields (like making sure "access_limited" is 
   always a list) and then cleans up the rest of the document.
"""

from typing import Any, Dict, List
from .bson_utils import bson_to_json

# Normalizes legacy fields into arrays to prevent BigQuery schema type-mismatch crashes
SANITIZATION_RULES = {
    "access_limited": lambda v: [] if isinstance(v, bool) or v is None else v
}


def serialize_and_strip_nulls(obj: Any) -> Any:
    """
    Recursively converts BSON/custom types to JSON-friendly representations 
    and removes keys with None values in a single, high-performance pass.
    """
    # 1. Handle Dictionaries
    if isinstance(obj, dict):
        result = {}
        for k, v in obj.items():
            # First, resolve/serialize the value
            serialized_val = serialize_and_strip_nulls(v)
            # Skip keys whose resolved values are None
            if serialized_val is not None:
                result[k] = serialized_val
        return result

    # 2. Handle Lists (preserve elements, but clean nested items)
    if isinstance(obj, list):
        return [serialize_and_strip_nulls(v) for v in obj]

    # 3. Base Case: Convert BSON type using our utility
    return bson_to_json(obj)


def sanitize_document(doc: Dict[str, Any]) -> Dict[str, Any]:
    """
    Applies schema normalization rules and outputs a cleaned, 
    JSON-serializable dictionary with None values stripped.
    
    NOTE: Mutates the input document in-place for performance.
    """
    # Apply root-level schema normalization rules
    for field, fn in SANITIZATION_RULES.items():
        if field in doc:
            doc[field] = fn(doc[field])

    # Convert BSON types and strip out None values in one single pass
    return serialize_and_strip_nulls(doc)