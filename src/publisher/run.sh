#!/bin/bash
# Run both mongod and scripts that interact with the database
# https://docs.docker.com/config/containers/multi-service_container/

# turn on bash's job control
set -m

# Start mongo and put it in the background
mongod --fork --syslog

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

make

# Stop this instance
# https://stackoverflow.com/a/41232669
gcloud compute instances delete publisher --quiet --zone=$ZONE
