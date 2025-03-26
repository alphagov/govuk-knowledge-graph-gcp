#!/bin/bash

# Obtain the latest state of the repository
gcloud storage cp -r "gs://${PROJECT_ID}-repository/*" .

# turn on bash's job control
set -m

# Fetch the Whitehall database backup file from GCP Storage
BUCKET=$(
  gcloud compute instances describe whitehall \
    --project $PROJECT_ID \
    --zone $ZONE \
    --format="value(metadata.items.object_bucket)"
)
OBJECT=$(
gcloud compute instances describe whitehall \
  --project $PROJECT_ID \
  --zone $ZONE \
  --format="value(metadata.items.object_name)"
)
OBJECT_URL="gs://$BUCKET/$OBJECT"
export FILE_PATH="/root/$OBJECT"

gcloud storage cp "$OBJECT_URL" "$FILE_PATH"

# Check that the file size is larger than an arbitrary size of 2GiB.
# If it is not, then the file is likely corrupt and we should not proceed.
minimumsize=2147483648
actualsize=$(wc -c <"$FILE_PATH")
if [ $actualsize -le $minimumsize ]; then
  # Turn this instance off and exit.  The data that is currrently in BigQuery
  # will remain there.
  gcloud compute instances delete whitehall --quiet --zone=$ZONE
  exit 1
fi

cd src/whitehall

# Start the mysql service
mariadbd --user=mysql &

# Wait for mariadb to start
sleep 30

# Restore the dump to mariadb and export it to csv and then bigquery (via Makefile)
mysql -u root -e 'create database whitehall;'
gunzip < "$FILE_PATH" | mysql -u root whitehall
make

# Delete this instance
gcloud compute instances delete whitehall --quiet --zone=$ZONE
