#! /bin/bash

# Count the number of times that each distinct row of a CSV appears.
#
# This handles newlines in quoted columns.  You have to pass a comma-separated
# list of column names that could contain newlines.
#
# Input is via stdin.
#
# Usage:
# command_that_emits_csv | count_distinct escape_cols=col1,col2
#
# Where col1 and col2 are columns that might contain newlines.
#
# This depends on Python's CSV library to escape and unescape newline
# characters.
#
# Performance (speed and memory) should be okay.  The Python steps are
# parallelised, and only load a few lines at a time.  The unix steps are also
# efficient.
count_distinct () {
  local escape_cols    # reset first
  local "${@}"
  python3 ../../src/utils/toggle_escapes.py \
    --escape_cols=${escape_cols} \
  | ( \
    read -r; \
    printf "count,%s\n" "$REPLY"; \
    LC_ALL=C sort -S 100% \
    | LC_ALL=C uniq -c \
    | sed -E 's/(\s*)([[:digit:]]+)(\s+)/\2,/' \
  ) \
  | python3 ../../src/utils/toggle_escapes.py \
    --unescape_cols=${escape_cols}
}

# Extract datasets of nodes, attributes and edges from the PostgreSQL Publishing
# API database.

# Wrapper around psql to export the results of a query to CSV
#
# Usage:
#
# query_postgres \
#   file=path/to/file
query_postgres () {
  local file # reset in case they are defined globally
  local "${@}"
  psql \
		--username=postgres \
		--dbname=publishing_api_production \
		--csv \
    --file="${file}"
}

# Wrapper around psql to export the results of a query to JSON
#
# Usage:
#
# query_postgres_json \
#   file=path/to/file
query_postgres_json () {
  local file # reset in case they are defined globally
  local "${@}"
  psql \
		--username=postgres \
		--dbname=publishing_api_production \
		--tuples-only \
    --file="${file}"
}

# Wrapper around psql to export a whole table to CSV
#
# Usage:
#
# dump_table \
#   name=table_name
dump_table () {
  local name # reset in case they are defined globally
  local "${@}"
  psql \
		--username=postgres \
		--dbname=publishing_api_production \
    --command="\copy ${name} TO STDOUT WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');"
}

# Compress and upload to cloud bucket
#
# Usage:
# command_that_emits_text | upload file_name=myfile
#
# The suffix ".csv.gz" is automatically appended to the file name.
upload () {
  local file_name # reset in case they are defined globally
  local "${@}"
  gzip -c \
  | gcloud storage cp - "gs://${PROJECT_ID}-data-processed/publishing-api/${file_name}.csv.gz"
}
#
# Upload from cloud bucket to BigQuery table
#
# Usage:
# send_to_bigquery file_name=myfile
#
# The suffix ".csv.gz" is automatically appended to the file name.
send_to_bigquery () {
  local file_name # reset in case they are defined globally
  local "${@}"
  bq load \
    --replace \
    --source_format="CSV" \
    --allow_quoted_newlines \
    --skip_leading_rows=1 \
    "content.${file_name}" \
    "gs://${PROJECT_ID}-data-processed/publishing-api/${file_name}.csv.gz"
}

# Wrapper around a ruby script to convert govspeak to HTML
#
# Usage:
#
# convert_govspeak_to_html
#   input_col=govspeak \
#   id_cols=url,govspeak \
convert_govspeak_to_html () {
  local input_col id_cols # reset in case they are defined globally
  local "${@}"
  parallel \
    --pipe \
    --round-robin \
    --line-buffer \
    --no-run-if-empty \
    ruby ../../src/utils/convert_govspeak_to_html.rb \
    --input_col=${input_col} \
    --id_cols=${id_cols}
}

# Wrappers around python scripts
#
# The input to these functions must be lines of JSON.
#
# Usage:
#
# extract_text_from_html
#   input_col=html \
#   id_cols=url,html \
#
# extract_hyperlinks_from_html \
#   input_col=html \
#   id_cols=url \
#
# extract_abbreviations_from_html \
#   input_col=html \
#   id_cols=url \
extract_text_from_html () {
  local input_col id_cols # reset in case they are defined globally
  local "${@}"
  { echo $id_cols,text,text_without_blank_lines & \
    parallel \
      --pipe \
      --round-robin \
      --line-buffer \
      --keep-order \
      python3 ../../src/utils/extract_text_from_html.py \
      --input_col=${input_col} \
      --id_cols=${id_cols} \
  ;}
}
extract_hyperlinks_from_html () {
  local input_col id_cols # reset in case they are defined globally
  local "${@}"
  { echo $id_cols,link_url,link_url_bare,link_text & \
    parallel \
      --pipe \
      --round-robin \
      --line-buffer \
      --keep-order \
      python3 ../../src/utils/extract_hyperlinks_from_html.py \
      --input_col=${input_col} \
      --id_cols=${id_cols} \
  ;}
}
extract_abbreviations_from_html () {
  local input_col id_cols # reset in case they are defined globally
  local "${@}"
  { echo $id_cols,abbreviation_title,abbreviation_text & \
    parallel \
      --pipe \
      --round-robin \
      --line-buffer \
      --keep-order \
      python3 ../../src/utils/extract_abbreviations_from_html.py \
      --input_col=${input_col} \
      --id_cols=${id_cols} \
  ;}
}

# Execute an SQL file in BigQuery
#
# Usage:
# query_bigquery file_name=myfile.sql
query_bigquery () {
  local file_name # reset in case they are defined globally
  local "${@}"
  bq query \
    --use_legacy_sql=false \
    < "${file_name}"
}

# Export a table, upload to storage and import into BigQuery
#
# Usage:
# query_bigquery table_name=name_of_table_in_postgres
export_to_bigquery () {
  local table_name # reset in case they are defined globally
  local "${@}"

  file_name="table_${table_name}"
  dataset_name="publishing"

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
  dump_table \
    name=$table_name \
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