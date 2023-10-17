FILE_NAME=content_items

# The awk command wraps each line in {"item":<line>} to trick BigQuery into
# importing the whole line of JSON into a single JSON column, called "item".
mongoexport \
  --quiet \
  --db=content_store \
  --type=json \
  --collection=content_items \
| awk '{print "{\"item\":" $0 "}"}' \
| gzip -c \
| gcloud storage cp \
  - \
  "gs://${PROJECT_ID}-data-processed/content-store/content_items.json.gz" \
  --quiet

bq query --use_legacy_sql=false "TRUNCATE TABLE content.content_items"

bq load \
  --nosynchronous_mode \
  --noreplace \
  --source_format="NEWLINE_DELIMITED_JSON" \
  "content.content_items" \
  "gs://${PROJECT_ID}-data-processed/content-store/content_items.json.gz"
