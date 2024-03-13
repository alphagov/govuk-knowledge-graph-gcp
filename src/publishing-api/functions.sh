#! /bin/bash

# Export a table, upload to storage and import into BigQuery
#
# Usage:
# query_bigquery table_name=name_of_table_in_postgres
export_to_bigquery () {
  local table_name # reset in case they are defined globally
  local "${@}"

  file_name="table_${table_name}"
  dataset_name="publishing_api"

  # We have to use uncompressed CSV for the largest table, so we might as well
  # use it for the others too.
  # BigQuery can't deal with compressed CSVs larger than 4GB.  The largest table
  # is 19GB when compressed.
  # Alternatively we could use Parquet (via DuckDB) but BigQuery can't cope with
  # values larger than 10MiB in any particular column, and the largest page has
  # 11302027 bytes (>10MiB) in the `details` column.
  # /hmrc-internal-manuals/customs-authorisation-and-approval/caa08030
  # https://webarchive.nationalarchives.gov.uk/ukgwa/20211120003440/https://www.gov.uk/hmrc-internal-manuals/customs-authorisation-and-approval/caa08030
  # The DuckDB max_line_size parameter defaults to 2 MiB, which would eliminate
  # those rows before they break BigQuery, but DuckDB stops with an error
  # instead of ignoring those lines.
  # The command gcloud bq load has options for ignoring bad lines, but they
  # don't work for parquet.
  # Finally, BigQuery does in fact seem to allow values larger than 10MiB, as
  # long as they come from uncompressed CSV files.  So that's what we use.
  # What a palaver.  "Big" Query, huh.
  psql \
		--username=postgres \
		--dbname=publishing_api_production \
    --command="\copy ${table_name} TO STDOUT WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');" \
  | gcloud storage cp \
    - \
    "gs://${PROJECT_ID}-data-processed/publishing-api/${file_name}.csv" \
    --gzip-in-flight-all

  # Empty the table
  bq query --use_legacy_sql=false "TRUNCATE TABLE ${dataset_name}.${table_name}"

  # Use nosynchronous_mode to avoid waiting for BQ to complete one job before
  # initiating another.
  bq load \
    --source_format="CSV" \
    --allow_quoted_newlines \
    --skip_leading_rows=1 \
    --noreplace \
    --nosynchronous_mode \
    "${dataset_name}.${table_name}" \
    "gs://${PROJECT_ID}-data-processed/publishing-api/${file_name}.csv"
}
