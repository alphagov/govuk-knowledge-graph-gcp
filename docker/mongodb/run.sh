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

# https://stackoverflow.com/questions/6575221
gsutil cat gs://govuk-knowledge-graph-content-store/mongo.tar.gz \
  | tar xzvO var/lib/mongodb/backup/mongodump/content_store_production/content_items.bson \
  | mongorestore -v --db=content_store --collection=content_items -

# Obtain the latest state of the repository
gsutil -m cp -r gs://govuk-knowledge-graph-repository/\* .

# 1. Query the content store into intermediate datasets
# 2. Download from the content store and intermediate datasets
# 3. Upload to storage
cd src/mongodb
make

# # Stop this instance
# # https://stackoverflow.com/a/41232669
# gcloud compute instances delete mongodb --quiet --zone=europe-west2-a

# # In case the instance is still running, bring the background process back into
# # the foreground and leave it there
# fg %1
