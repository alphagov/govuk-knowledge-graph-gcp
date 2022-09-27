#! /bin/bash

# Extract datasets of nodes, attributes and edges from the PostgreSQL Publishing
# API database.

# Wrapper around psql.
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

# Wrapper around psql, for when emitting json
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
  | gcloud storage cp - "gs://govuk-knowledge-graph-data-processed/publishing-api/${file_name}.csv.gz"
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
# extract_lines_from_html
#   input_col=html \
#   id_cols=url \
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
      python3 ../../src/utils/extract_text_from_html.py \
      --input_col=${input_col} \
      --id_cols=${id_cols} \
  ;}
}
extract_lines_from_html () {
  local input_col id_cols # reset in case they are defined globally
  local "${@}"
  { echo $id_cols,line & \
    parallel \
      --pipe \
      --round-robin \
      --line-buffer \
      python3 ../../src/utils/extract_lines_from_html.py \
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
      python3 ../../src/utils/extract_hyperlinks_from_html.py \
      --input_col=${input_col} \
      --id_cols=${id_cols} \
  ;}
}
