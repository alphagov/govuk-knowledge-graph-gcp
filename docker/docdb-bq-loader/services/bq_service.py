"""
BigQuery Service (bq_service.py)

This module provides helper methods for managing BigQuery datasets, tables,
schemas, and data loads used by the data ingestion pipeline.

Functions:
    1. ensure_dataset() : Creates the target dataset if it does not already exist.
    2. sync_schema() : Creates or updates the BigQuery table schema based on the
        fields discovered in the source data while preserving existing table
        properties where possible.
    3. load_from_gcs() : Loads JSON data from Google Cloud Storage (GCS) into
        the target BigQuery table.

"""

from google.cloud import bigquery
from google.cloud.exceptions import NotFound
from utils.logging import get_logger

logger = get_logger(__name__)


class BigQueryService:

    def __init__(self, project_id: str):
        self.client = bigquery.Client(project=project_id)

    # =========================================================
    # 1. Creates the target dataset if it does not already exist
    # =========================================================


    def ensure_dataset(self, dataset_id: str, location: str):
        dataset_ref = self.client.dataset(dataset_id)

        try:
            self.client.get_dataset(dataset_ref)
        except Exception:
            dataset = bigquery.Dataset(dataset_ref)
            dataset.location = location
            self.client.create_dataset(dataset)
            logger.info("Created dataset %s", dataset_id)

    # =========================================================
    # 2. Creates or updates the BigQuery table schema
    # =========================================================

    def sync_schema(self, dataset_id, table_name, source_fields, array_fields):
        """
        Reconciles the target table's schema against what was discovered
        in the source data, preserving REPEATED array columns instead of
        flattening everything to scalar STRING.

        - source_fields: every field name seen across all documents.
        - array_fields: subset of source_fields that were seen as a list
          on at least one document this run.

        Rules:
        - Existing columns are kept as-is UNLESS they need to become
          REPEATED (because array_fields or the column's own existing
          mode says so) and currently aren't — or they're RECORD/STRUCT,
          which this pipeline doesn't model; those get coerced to
          REPEATED/NULLABLE STRING as appropriate.
        - Any existing REPEATED column stays REPEATED even if this run's
          data doesn't happen to contain an array for it, so historical
          rows/queries relying on UNNEST keep working.
        - New fields not yet in the table are appended: REPEATED STRING
          if discovered as an array, NULLABLE STRING otherwise.
        - The table is only dropped/recreated if an existing column's
          resolved mode or type actually differs from what's stored —
          not as a blanket rebuild. Safe here because the pipeline
          always does a full WRITE_TRUNCATE_DATA load right after.
        - If a recreate is needed, the old table's partitioning,
          clustering, and options (friendly name, description, labels)
          are captured beforehand and reapplied to the new table, so
          they are never silently dropped.

        Returns (schema, repeated_field_names) where repeated_field_names
        is a lowercase set the caller uses to decide, per field, whether
        to wrap scalar values into single-element arrays before writing.
        """
        table_ref = self.client.dataset(dataset_id).table(table_name)

        try:
            table = self.client.get_table(table_ref)
        except NotFound:
            table = None

        final_fields = []
        seen = set()
        existing_by_name = {}

        if table:
            existing_by_name = {f.name.lower(): f for f in table.schema}
            for f in table.schema:
                key = f.name.lower()
                seen.add(key)
                should_be_repeated = key in array_fields or f.mode == "REPEATED"
                if f.field_type in ("RECORD", "STRUCT") or (should_be_repeated and f.mode != "REPEATED"):
                    final_fields.append(
                        bigquery.SchemaField(
                            f.name, "STRING",
                            mode="REPEATED" if should_be_repeated else "NULLABLE"
                        )
                    )
                else:
                    final_fields.append(f)

        for name in sorted(source_fields):
            key = name.lower()
            if key in seen:
                continue
            mode = "REPEATED" if key in array_fields else "NULLABLE"
            final_fields.append(bigquery.SchemaField(name, "STRING", mode=mode))
            seen.add(key)

        repeated_field_names = {f.name.lower() for f in final_fields if f.mode == "REPEATED"}

        needs_recreate = False
        if table:
            for nf in final_fields:
                old = existing_by_name.get(nf.name.lower())
                if old is not None and (old.mode != nf.mode or old.field_type != nf.field_type):
                    needs_recreate = True
                    break

        if table and needs_recreate:
            logger.warning(
                "Recreating table %s.%s — one or more column modes/types changed. "
                "Preserving partitioning, clustering, and table options.",
                dataset_id, table_name
            )

            time_partitioning = table.time_partitioning
            range_partitioning = table.range_partitioning
            clustering_fields = table.clustering_fields
            friendly_name = table.friendly_name
            description = table.description
            labels = table.labels

            self.client.delete_table(table_ref)

            new_table = bigquery.Table(table_ref, schema=final_fields)
            new_table.time_partitioning = time_partitioning
            new_table.range_partitioning = range_partitioning
            new_table.clustering_fields = clustering_fields
            new_table.friendly_name = friendly_name
            new_table.description = description
            new_table.labels = labels

            table = self.client.create_table(new_table)
            logger.info("Recreated table %s.%s with %d columns", dataset_id, table_name, len(final_fields))

        elif table is None:
            new_table = bigquery.Table(table_ref, schema=final_fields)
            table = self.client.create_table(new_table)
            logger.info("Created table %s.%s with %d columns", dataset_id, table_name, len(final_fields))

        elif len(final_fields) > len(table.schema):
            added = [f.name for f in final_fields if f.name.lower() not in existing_by_name]
            logger.info(
                "Adding %d new column(s) to %s.%s: %s",
                len(added), dataset_id, table_name, added
            )
            table.schema = final_fields
            table = self.client.update_table(table, ["schema"])

        return table.schema, repeated_field_names

    # =========================================================
    # 3. Loads JSON data from GCS to the target BigQuery table
    # =========================================================

    def load_from_gcs(self, dataset_id, table_name, uri, schema):
        table_ref = self.client.dataset(dataset_id).table(table_name)

        job_config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
            write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE_DATA,
            schema=schema,
            autodetect=False,
            ignore_unknown_values=False,
        )

        job = self.client.load_table_from_uri(uri, table_ref, job_config=job_config)
        job.result()

        logger.info("Loaded %s.%s", dataset_id, table_name)
