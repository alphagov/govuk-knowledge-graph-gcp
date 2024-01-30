#!/bin/bash
# Run both mongod and scripts that interact with the database
# https://docs.docker.com/config/containers/multi-service_container/

# turn on bash's job control
set -m

# Start mongo and put it in the background
mongod --nojournal &

# Wait for mongo to start
sleep 5

# Restore the Publisher app database from its backup .bson file in GCP Storage

# Construct the file's URL
OBJECT=$(
gcloud compute instances describe publisher \
  --project $PROJECT_ID \
  --zone $ZONE \
  --format="value[separator=\"/\"](metadata.items.object_bucket, metadata.items.object_name)"
)
OBJECT_URL="gs://$OBJECT"

gcloud storage cat "${OBJECT_URL}" \
  | gunzip -c \
  | mongorestore --archive --nsInclude=govuk_content_production.editions

# Obtain the latest state of the repository
gcloud storage cp -r gs://$PROJECT_ID-repository/\* .

# Prepare to export some data to BigQuery
cd src/publisher

DATABASE=govuk_content_production
QUERY=query.js
OUTPUT_COLLECTION=output
FILE=editions
OBJECT="gs://${PROJECT_ID}-data-processed/publisher/${FILE}.csv.gz"
DATASET=publisher
TABLE="${DATASET}.${FILE}"

# Create a dataset in mongodb of relevant metadata about relevant editions of
# documents.
mongo ${DATABASE} ${QUERY}

# 1. Export that dataset
# 2. Upload it to a cloud bucket
mongoexport \
  --quiet \
  --db=govuk_content_production \
  --type=csv \
  --collection="${OUTPUT_COLLECTION}" \
  --fields=url,updated_at,version_number,state,major_change \
  | gcloud storage cp - "${OBJECT}" --quiet --gzip-in-flight-all

# Upload the dataset from the cloud bucket to a BigQuery table
bq load \
  --quiet=true \
  --replace \
  --source_format="CSV" \
  --allow_quoted_newlines \
  --skip_leading_rows=1 \
  "${TABLE}" \
  "${OBJECT}"

# Stop this instance
# https://stackoverflow.com/a/41232669
gcloud compute instances delete publisher --quiet --zone=$ZONE
