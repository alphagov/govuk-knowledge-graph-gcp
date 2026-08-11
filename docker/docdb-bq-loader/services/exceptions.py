"""
Pipeline Exceptions (exceptions.py)

This module defines custom exceptions used by the data ingestion pipeline.

Classes:
- JobFailure : Raised when a pipeline step fails and execution should stop.

"""

class JobFailure(Exception):
    """
    Custom exception raised when the pipeline job fails.
    Used to signal controlled failure in ETL pipeline execution.
    """
    pass
