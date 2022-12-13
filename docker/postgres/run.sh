#!/bin/bash
PROJECT_ID="govuk-knowledge-graph-dev"

# Increase the amount of shared memory available.
# This requires the containe to run in privileged mode.
# It prevents a postgres error
# "could not resize shared memory segment: No space left on device"
mount -o remount,size=8G /dev/shm

# Run both postgres and scripts that interact with the database

# Obtain the latest state of the repository
gcloud storage cp -r "gs://${PROJECT_ID}-repository/*" .

# turn on bash's job control
set -m

# Start postgres in the background.  The docker-entrypoint.sh script is on the
# path, and handles users and permissions
# https://stackoverflow.com/a/48880635/937932
cp src/postgres/postgresql.conf.write-optimised src/postgres/postgresql.conf
docker-entrypoint.sh postgres -c config_file=src/postgres/postgresql.conf &

# Wait for postgres to start
sleep 5

# Restore the Publishing API database from its backup .bson file in GCP Storage

# Construct the file's URL
BUCKET=$(
  gcloud compute instances describe postgres \
    --project $PROJECT_ID \
    --zone europe-west2-b \
    --format="value(metadata.items.object_bucket)"
)
OBJECT=$(
gcloud compute instances describe postgres \
  --project $PROJECT_ID \
  --zone europe-west2-b \
  --format="value(metadata.items.object_name)"
)
OBJECT_URL="gs://$BUCKET/$OBJECT"
FILE_PATH="data/$OBJECT"

# https://stackoverflow.com/questions/6575221
date
gcloud storage cp "$OBJECT_URL" "$FILE_PATH"
date
pg_restore \
  -U postgres \
  --verbose \
  --create \
  --clean \
  --dbname=postgres \
  --no-owner \
  --jobs=2 \
  "$FILE_PATH"
date
rm "$FILE_PATH"

# Restart postgres with a less-crashable configuration
cp src/postgres/postgresql.conf.safe src/postgres/postgresql.conf
psql -U postgres -c "SELECT pg_reload_conf();"

# 1. Query the content store into intermediate datasets
# 2. Download from the content store and intermediate datasets
# 3. Upload to storage
cd src/postgres
make

# Stop this instance
# https://stackoverflow.com/a/41232669
gcloud compute instances delete postgres --quiet --zone=europe-west2-b

# In case the instance is still running, bring the background process back into
# the foreground and leave it there
fg %1
