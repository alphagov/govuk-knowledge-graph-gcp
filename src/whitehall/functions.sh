#! /bin/bash
set -e

# Export a table from an SQL dump file, upload to storage and import into BigQuery
#
# Usage:
# export_to_bigquery backup_name=name_of_db_backup_file table_name=name_of_table_in_mysql
export_to_bigquery () {
  # reset variables in case they are defined globally
  local backup_name
  local table_name
  local "${@}"

  csv_name="/data/mysql/table_${table_name}"

  schema_name="schema_${table_name}"
  dataset_name="whitehall"

  mysql -u root ${dataset_name} -e "SELECT id,created_at,updated_at,document_id,state,type,major_change_published_at,first_published_at,force_published,public_timestamp,scheduled_publication,access_limited,opening_at,closing_at,political,primary_locale,auth_bypass_id,government_id
                              INTO OUTFILE '${csv_name}'
                              FIELDS TERMINATED BY ','
                              ENCLOSED BY '\"'
                              LINES TERMINATED BY '\n'
                              FROM editions;"

  # Download the existing schema
  bq show \
    --schema=true \
    --format=json \
    "${dataset_name}.${table_name}" \
    > $schema_name

  # Load data into the the table, using the "write disposition", which is
  # equivalent to WRITE_TRUNCATE in SQL. It empties the table and wipes its
  # schema, before inserting new rows. This is done within a transaction. We
  # preserve the schema by downloading it first with `bq show`, and then using
  # it as an argument to `bq load`.
  bq load \
    --source_format="CSV" \
    --field_delimiter="," \
    --null_marker="\\N" \
    --quote="\"" \
    --replace=true \
    --schema="${schema_name}" \
    "${dataset_name}.${table_name}" \
    "${csv_name}"
}
