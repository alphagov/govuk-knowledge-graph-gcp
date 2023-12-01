#!/bin/bash
# Run both mongod and scripts that interact with the database
# https://docs.docker.com/config/containers/multi-service_container/

# turn on bash's job control
set -m

# Start mongo and put it in the background
mongod --nojournal &

# Wait for mongo to start
sleep 5

# Load the content_store data from the JSON file in GCP Storage, which is put
# there by the 'content' virtual machine that exports it from the Postgres
# version of the content store.
#
# The reason why we don't query the postgres version of the content store
# directly, is because it didn't exist when we wrote all these queries.  Then in
# October 2023 GOV.UK ported the content store from MongoDB to postgres.
# Instead of rewriting all the queries as SQL, we export the whole table from
# postgres, as JSON, then load it into MongoDB, where we can use the original
# queries.
gcloud storage cat gs://$PROJECT_ID-data-processed/content-store/content_items.json.gz \
  | gunzip -c \
  | mongoimport --db=content_store --collection=content_items --quiet

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
