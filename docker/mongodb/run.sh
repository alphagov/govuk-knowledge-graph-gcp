#!/bin/bash

# Run both mongod and scripts that interact with the database
# https://docs.docker.com/config/containers/multi-service_container/

# turn on bash's job control
set -m

# Start mongo and put it in the background
mongod &

# Wait for mongo to start
sleep 5

# Restore the content_store from its backup .bson file in GCP Storage

# https://stackoverflow.com/questions/6575221
gsutil cat gs://govuk-knowledge-graph-content-store/mongo.tar.gz \
  | tar xzvO var/lib/mongodb/backup/mongodump/content_store_production/content_items.bson \
  | mongorestore -v --db=content_store --collection=content_items -

# Query the content store into intermediate datasets
gsutil cat gs://govuk-knowledge-graph-repository/src/mongodb/prepare-content-store.js \
  | bash

# Download from the content store and intermediate datasets, upload to storage
gsutil cat gs://govuk-knowledge-graph-repository/src/mongodb/extract-from-mongodb.sh \
  | bash

# Stop this instance
# https://stackoverflow.com/a/41232669
gcloud compute instances stop mongodb --quiet --zone=europe-west2-a

# In case the instance is still running, bring the background process back into
# the foreground and leave it there
fg %1
