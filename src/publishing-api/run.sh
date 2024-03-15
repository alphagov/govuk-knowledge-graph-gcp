#!/bin/bash

# Obtain the latest state of the repository
gcloud storage cp -r "gs://${PROJECT_ID}-repository/*" .

# turn on bash's job control
set -m

# Fetch the Publishing API database backup file from GCP Storage
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
# Export a variable so that the Makefile can use it
export FILE_PATH="/data/$OBJECT"

# https://stackoverflow.com/questions/6575221
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

# pg_dump each table into a file, upload it to BigQuery, and delete the file.
#
# Use a Makefile to do this in parallel.
#
# Two cores are sufficient, because the editions table takes longer than all the
# other tables together.
cd src/publishing-api
make

# Stop this instance
# https://stackoverflow.com/a/41232669
gcloud compute instances delete publishing-api --quiet --zone=$ZONE
