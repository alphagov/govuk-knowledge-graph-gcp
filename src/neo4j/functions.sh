#! /bin/bash
PROJECT_ID="govuk-knowledge-graph"
DOMAIN="govgraph.dev"

# Wrapper around cypher-shell to preset export CSV files
#
# Usage:
#
# query_neo4j \
#   cypher="MATCH (n) RETURN n.url LIMIT 10;"
query_neo4j () {
  local cypher # reset in case they are defined globally
  local "${@}"
  cypher-shell \
    --address "neo4j+s://${DOMAIN}:7687" \
      --format plain \
      "${cypher}"
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
  | gcloud storage cp - "gs://${PROJECT_ID}-data-processed/neo4j/${file_name}.csv.gz" --quiet
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
    "gs://${PROJECT_ID}-data-processed/neo4j/${file_name}.csv.gz"
}
