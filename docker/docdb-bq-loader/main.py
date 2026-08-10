"""
Google Cloud Run Job Entry Point (main.py)

Purpose:
    This module serves as the entry point for the Cloud Run Job. It initiates
    the data ingestion process and handles controlled job failures.

Execution Flow:
    1. Cloud Run starts the container.
    2. The `ingest()` function from `services.ingest` executes the ingestion pipeline.
    3. If the pipeline completes successfully, the job exits normally.
    4. If a `JobFailure` is raised, the error is logged and re-raised so
       Cloud Run marks the execution as failed.
"""

from services.ingest import ingest
from services.exceptions import JobFailure
from utils.logging import get_logger

logger = get_logger(__name__)


# =========================================================
# Application Entry Point
# =========================================================

if __name__ == "__main__":
    try:
        ingest()
    except JobFailure as e:
        logger.error("Job failed: %s", e)
        raise
