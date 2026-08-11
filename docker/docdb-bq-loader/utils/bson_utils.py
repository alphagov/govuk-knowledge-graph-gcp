"""
BSON Data Sanitization Utility (bson_utils.py)

This module provides helper functions to convert MongoDB BSON data types into
JSON-compatible formats before processing and loading data into BigQuery.

Functions:
1. bson_to_json() : Converts MongoDB-specific data types such as ObjectId,
  datetime, Decimal128, Binary, DBRef, and other BSON objects into
  JSON-serializable values.

"""

import base64
from datetime import datetime, date
import uuid
from decimal import Decimal

# Import advanced BSON/PyMongo types safely to avoid serialization crashes
from bson import ObjectId
from bson.decimal128 import Decimal128
from bson.regex import Regex
from bson.dbref import DBRef
from bson.timestamp import Timestamp
from bson.min_key import MinKey
from bson.max_key import MaxKey

# =========================================================
# 1. Convert BSON to JSON-Compatible Formats
# =========================================================

def bson_to_json(value):
    # 1. ObjectId Conversion
    if isinstance(value, ObjectId):
        return str(value)

    # 2. Timezone-safe Datetime Handling
    if isinstance(value, datetime):
        # If naive (no timezone info), append "Z" because MongoDB datetimes are always UTC.
        if value.tzinfo is None:
            return value.isoformat() + "Z"
        return value.isoformat()

    # 3. Datetime Date Handling (must follow datetime check because datetime inherits from date)
    if isinstance(value, date):
        return value.isoformat()

    # 4. Decimals (BigQuery handles numeric strings flawlessly)
    if isinstance(value, Decimal128):
        return str(value.to_decimal())

    if isinstance(value, Decimal):
        return str(value)

    # 5. MongoDB Timestamps (convert to UTC datetime)
    if isinstance(value, Timestamp):
        return value.as_datetime().isoformat()

    # 6. MongoDB Regex
    if isinstance(value, Regex):
        return value.pattern

    # 7. MongoDB DBRefs (reconstruct to a standard JSON-serializable dict)
    if isinstance(value, DBRef):
        return {
            "$ref": value.collection,
            "$id": bson_to_json(value.id),
            "$db": value.database
        }

    # 8. Singletons (MinKey, MaxKey)
    if isinstance(value, (MinKey, MaxKey)):
        return str(value)

    # 9. Native UUID (Pymongo converts Binary Subtype 4 to UUID)
    if isinstance(value, uuid.UUID):
        return str(value)

    # 10. Binary Data (Base64 Encode)
    # PyMongo Binary inherits from bytes and is captured here. We add bytearray.
    if isinstance(value, (bytes, bytearray)):
        return base64.b64encode(value).decode("utf-8")

    # 11. Custom Collections / Sets (convert Sets to lists)
    if isinstance(value, set):
        return [bson_to_json(v) for v in value]

    # 12. Recursive traversals
    if isinstance(value, dict):
        return {k: bson_to_json(v) for k, v in value.items()}

    if isinstance(value, list):
        return [bson_to_json(v) for v in value]

    return value
