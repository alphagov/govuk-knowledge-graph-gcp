#!/bin/bash

# Increase the amount of shared memory available.
# This requires the container to run in privileged mode.
# It prevents a postgres error
# "could not resize shared memory segment: No space left on device"
mount -o remount,size=8G /dev/shm

# Run both postgres and scripts that interact with the database

# Obtain the latest state of the repository
echo "fetch repo"
gcloud storage cp -r "gs://${PROJECT_ID}-repository/*" .

# turn on bash's job control
set -m

# Start postgres in the background.  The docker-entrypoint.sh script is on the
# path, and handles users and permissions
# https://stackoverflow.com/a/48880635/937932
cp src/content-api/postgresql.conf.write-optimised src/content-api/postgresql.conf
docker-entrypoint.sh postgres -c config_file=src/content-api/postgresql.conf &

# Wait for postgres to start
sleep 5

# Restore the Content API database from its backup file in GCP Storage

# Construct the file's URL
BUCKET=$(
  gcloud compute instances describe content-api \
    --project $PROJECT_ID \
    --zone $ZONE \
    --format="value(metadata.items.object_bucket)"
)
OBJECT=$(
gcloud compute instances describe content-api \
  --project $PROJECT_ID \
  --zone $ZONE \
  --format="value(metadata.items.object_name)"
)
OBJECT_URL="gs://$BUCKET/$OBJECT"
FILE_PATH="data/$OBJECT"

# https://stackoverflow.com/questions/6575221
date
echo "fetch database"
gcloud storage cp "$OBJECT_URL" "$FILE_PATH"

# Check that the file size is larger than an arbitrary size of 1GiB.
# Typically they are nearly 3GiB.
# On 2023-03-03 the database backup files had a problem and were only a few
# megabytes.
minimumsize=1073741824
actualsize=$(wc -c <"$FILE_PATH")
if [ $actualsize -le $minimumsize ]; then
  # Turn this instance off and exit.  The data that is currrently in BigQuery
  # will remain there.
  gcloud compute instances delete content-api --quiet --zone=$ZONE
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
cp src/content-api/postgresql.conf.safe src/content-api/postgresql.conf
psql -U postgres -c "SELECT pg_reload_conf();"

date
# Export the content_items table as CSV, to be loaded into BigQuery.
#
# Compression can cause trouble with big files or big columns. See
# /src/publishing-api/functions.sh. But this file is small, with small columns.
QUERY="\copy content_items TO STDOUT WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');"
DEST="gs://${PROJECT_ID}-data-processed/content-api/content_items.csv.gz"
psql \
  --username=postgres \
  --dbname=content_store_production \
  --command="${QUERY}" \
  | gcloud storage cp - "${DEST}" \
    --gzip-in-flight-all
date

# Remove the data that is currently in BigQuery
bq --project_id "${PROJECT_ID}" query \
  --use_legacy_sql=false \
  "TRUNCATE TABLE content_api.content_items"

# Load the new data into BigQuery
date
bq --project_id "${PROJECT_ID}" load \
  --source_format="CSV" \
  --allow_quoted_newlines \
  --skip_leading_rows=1 \
  --noreplace \
  --nosynchronous_mode \
  "content_api.content_items" \
  "gs://${PROJECT_ID}-data-processed/content-api/content_items.csv.gz"
date

# Stop this instance
# https://stackoverflow.com/a/41232669
gcloud compute instances delete content-api --quiet --zone=$ZONE
