#!/bin/bash

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
cp src/publishing-api/postgresql.conf.write-optimised src/publishing-api/postgresql.conf
docker-entrypoint.sh postgres -c config_file=src/publishing-api/postgresql.conf &

# Wait for postgres to start
sleep 5

# Restore the Publishing API database from its backup file in GCP Storage

# Construct the file's URL
BUCKET=$(
  gcloud compute instances describe publishing-api \
    --project $PROJECT_ID \
    --zone $ZONE \
    --format="value(metadata.items.object_bucket)"
)
OBJECT=$(
gcloud compute instances describe publishing-api \
  --project $PROJECT_ID \
  --zone $ZONE \
  --format="value(metadata.items.object_name)"
)
OBJECT_URL="gs://$BUCKET/$OBJECT"
FILE_PATH="data/$OBJECT"

# https://stackoverflow.com/questions/6575221
date
gcloud storage cp "$OBJECT_URL" "$FILE_PATH"

# Check that the file size is larger than an arbitrary size of 2GiB.
# Typically they are about 27GiB.
# On 2023-03-03 the database backup files had a problem and were only a few
# megabytes.
minimumsize=2147483648
actualsize=$(wc -c <"$FILE_PATH")
if [ $actualsize -le $minimumsize ]; then
  # Turn this instance off and exit.  The data that is currrently in BigQuery
  # will remain there.
  gcloud compute instances delete publishing-api --quiet --zone=$ZONE
  exit 1
fi

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
cp src/publishing-api/postgresql.conf.safe src/publishing-api/postgresql.conf
psql -U postgres -c "SELECT pg_reload_conf();"

# 1. Export each table to compressed CSV and upload to a bucket
# 2. Import each file from the bucket into BigQuery
cd src/publishing-api
make

# Stop this instance
# https://stackoverflow.com/a/41232669
gcloud compute instances delete publishing-api --quiet --zone=$ZONE
