#!/bin/bash
# Run both mongod and scripts that interact with the database
# https://docs.docker.com/config/containers/multi-service_container/

# turn on bash's job control
set -m

# Start mongo and put it in the background
mongod --nojournal &

# Wait for mongo to start
sleep 5

# Restore the content_store from its backup .bson file in GCP Storage

# Construct the file's URL
OBJECT=$(
gcloud compute instances describe mongodb \
  --project $PROJECT_ID \
  --zone $ZONE \
  --format="value[separator=\"/\"](metadata.items.object_bucket, metadata.items.object_name)"
)
OBJECT_URL="gs://$OBJECT"

# https://stackoverflow.com/questions/6575221
gcloud storage cat "$OBJECT_URL" \
  | tar xzvO content_store_production/content_items.bson \
  | mongorestore -v --db=content_store --collection=content_items -

# Obtain the latest state of the repository
gcloud storage cp -r gs://$PROJECT_ID-repository/\* .

# 1. Query the content store into intermediate datasets
# 2. Download from the content store and intermediate datasets
# 3. Upload to storage
cd src/mongodb
make

# Stop this instance
# https://stackoverflow.com/a/41232669
gcloud compute instances delete mongodb --quiet --zone=$ZONE

# In case the instance is still running, bring the background process back into
# the foreground and leave it there
fg %1
