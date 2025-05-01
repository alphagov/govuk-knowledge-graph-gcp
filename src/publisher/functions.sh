#! /bin/bash
set -e

# Export a table from an SQL dump file, upload to storage and import into BigQuery
export_query_to_bigquery () {
  local mongo_database="$1"
  local gcp_project_id="$2"
  local bq_dataset="$3"
  local bq_table="$4"
  local fields="$5"

  local query="${bq_table}.js"
  local collection="${bq_table}_output"
  local object="gs://${gcp_project_id}-data-processed/publisher/${bq_table}.csv.gz"
  local table="${bq_dataset}.${bq_table}"

  # Create a dataset in mongodb of relevant metadata about relevant editions of
  # documents.
  mongosh "${mongo_database}" "${query}"

  # Export that dataset
  # Upload it to a cloud bucket
  mongoexport \
    --quiet \
    --db="${mongo_database}" \
    --type=csv \
    --collection="${collection}" \
    --fields="${fields}" \
    | gcloud storage cp - "${object}" --quiet --gzip-in-flight-all

  # Upload the dataset from the cloud bucket to a BigQuery table
  bq --project_id "${gcp_project_id}" load \
    --quiet=true \
    --replace \
    --source_format="CSV" \
    --allow_quoted_newlines \
    --skip_leading_rows=1 \
    "${table}" \
    "${object}"
}
