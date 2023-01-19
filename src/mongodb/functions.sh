#! /bin/bash
PROJECT_ID="govuk-knowledge-graph"

# Extract datasets of nodes, attributes and edges from the MongoDB content store
# database.

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

# Wrapper around sed to replace single backslash with double backslashes,
# because Neo4j interprets a single backslash as an escape character.
double_backslashes () {
  sed 's/\\/\\\\/g'
}

# Compress and upload to cloud bucket
#
# Usage:
# command_that_emits_text | upload file_name=myfile
#
# The suffix ".csv.gz" is automatically appended to the file name.
#
# Single backslashes are doubled, because Neo4j interprets a single backslash as
# an escape character.
upload () {
  local file_name # reset in case they are defined globally
  local "${@}"
  double_backslashes \
  | gzip -c \
  | gcloud storage cp - "gs://${PROJECT_ID}-data-processed/content-store/${file_name}.csv.gz" --quiet
}

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
    --quiet=true \
    --replace \
    --source_format="CSV" \
    --allow_quoted_newlines \
    --skip_leading_rows=1 \
    "content.${file_name}" \
    "gs://${PROJECT_ID}-data-processed/content-store/${file_name}.csv.gz"
}

# Wrapper around mongoexport to preset --db=content_store and --type=csv
#
# The `collection=` parameter is optional.  Its default is `content_items`.
#
# The `query=` parameter is optional.
#
# Usage:
#
# query_mongo \
#   collection=my_collection \
#   fields=col1,col2
#
# query_mongo \
#   collection=my_collection \
#   fields=col1,col2 \
#   query='{ "my_field": { "$exists": true } }'
query_mongo () {
  local type collection fields query # reset in case they are defined globally
  local "${@}"
  mongoexport \
    --quiet \
    --db=content_store \
    --type=${type:-csv} \
    --collection=${collection:-content_items} \
    --fields=${fields} \
    --query="${query}"
}

# Wrappers around python scripts
#
# Use of these scripts requres type=json to be specified in the query_mongo
# command.
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
