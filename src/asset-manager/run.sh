#!/bin/bash
# Run both mongod and scripts that interact with the database
# https://docs.docker.com/config/containers/multi-service_container/

# turn on bash's job control
set -mex

# Start mongo and put it in the background
mongod --fork --syslog

# Wait for mongo to start
sleep 5

# Restore the Asset Manager app database from its backup .bson file in GCP Storage

# Construct the file's URL
OBJECT=$(
gcloud compute instances describe asset-manager \
  --project $PROJECT_ID \
  --zone $ZONE \
  --format="value[separator=\"/\"](metadata.items.object_bucket, metadata.items.object_name)"
)
OBJECT_URL="gs://$OBJECT"

gcloud storage cat "${OBJECT_URL}" \
  | gunzip -c \
  | mongorestore --archive --nsInclude=govuk_assets_production.assets

# Obtain the latest state of the repository
gcloud storage cp -r gs://$PROJECT_ID-repository/\* .

# Prepare to export some data to BigQuery
cd src/asset-manager

DATABASE=govuk_assets_production
QUERY=query.js
OUTPUT_COLLECTION=output
FILE=assets
OBJECT="gs://${PROJECT_ID}-data-processed/asset-manager/${FILE}.csv.gz"
DATASET=asset_manager
TABLE="${DATASET}.${FILE}"

# Create a collection in mongodb of relevant assets.
mongosh ${DATABASE} ${QUERY}

# 1. Export that dataset
# 2. Upload it to a cloud bucket
# TODO add filename_history access_limited access_limited_organisation_ids
mongoexport \
  --quiet \
  --db=govuk_assets_production \
  --type=csv \
  --collection="${OUTPUT_COLLECTION}" \
  --fields=_id,created_at,updated_at,replacement_id,state,uuid,draft,redirect_url,last_modified,size,content_type,parent_document_url,deleted_at,file,_type,legacy_url_path \
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
 gcloud compute instances delete asset-manager --quiet --zone=$ZONE
