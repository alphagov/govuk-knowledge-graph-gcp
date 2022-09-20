#!/bin/bash

# Run both postgres and scripts that interact with the database

# turn on bash's job control
set -m

# Start postgres in the background.  The docker-entrypoint.sh script is on the
# path, and handles users and permissions
# https://stackoverflow.com/a/48880635/937932
docker-entrypoint.sh postgres &

# Wait for postgres to start
sleep 5

# Restore the Publishing API database from its backup .bson file in GCP Storage

# Construct the file's URL
OBJECT=$(
gcloud compute instances describe postgres \
  --project govuk-knowledge-graph \
  --zone europe-west2-a \
  --format="value[separator=\"/\"](metadata.items.object_bucket, metadata.items.object_name)"
)
OBJECT_URL="gs://$OBJECT"

# https://stackoverflow.com/questions/6575221
gsutil cat "$OBJECT_URL" \
  | tar xzvO content_store_production/content_items.bson \
  | pg_restore -v --db=content_store --collection=content_items -

# Obtain the latest state of the repository
gsutil -m cp -r gs://govuk-knowledge-graph-repository/\* .

# 1. Query the content store into intermediate datasets
# 2. Download from the content store and intermediate datasets
# 3. Upload to storage
cd src/postgres
make

# Stay alive (for dev)
sleep infinity

# Stop this instance
# https://stackoverflow.com/a/41232669
gcloud compute instances delete postgres --quiet --zone=europe-west2-a

# In case the instance is still running, bring the background process back into
# the foreground and leave it there
fg %1
