#! /bin/bash

# Export a table from a pg_dump file, upload to storage and import into BigQuery
#
# Usage:
# query_bigquery backup_name=name_of_db_backup_file table_name=name_of_table_in_postgres
export_to_bigquery () {
  # reset variables in case they are defined globally
  local backup_name
  local table_name
  local "${@}"

  # Export data to the SSD, which is mapped to /data
  tsv_name="/data/table_${table_name}"
  dataset_name="support_api"

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

  # Dump the table
  #
  # pg_restore emits SQL statements, which can be trimmed to resemble
  # tab-separated values. Lines up to and including a COPY
  # statement are discarded. Following lines are retained until a line that has
  # only a backslash and a full stop.  That line and following lines are
  # discarded. Lines that are retained are modified to unescape escaped
  # backslashes, i.e. replace \\ with \.
  pg_restore \
    -U postgres \
    --no-owner \
    --data-only \
    --file=- \
    --table=$table_name \
    $backup_name \
    | sed -e '1,/^COPY/d' \
    | sed -e 's/\\\\/\\/g' \
    | sed -e '/^\\\./Q' \
    > $tsv_name

  # Empty the table
  bq query --use_legacy_sql=false "TRUNCATE TABLE ${dataset_name}.${table_name}"

  bq load \
    --source_format="CSV" \
    --field_delimiter="\t" \
    --null_marker="\\N" \
    --quote="" \
    --skip_leading_rows=1 \
    --noreplace \
    "${dataset_name}.${table_name}" \
    "${tsv_name}"
}
