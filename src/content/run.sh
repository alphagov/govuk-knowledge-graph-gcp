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
cp src/content/postgresql.conf.write-optimised src/content/postgresql.conf
docker-entrypoint.sh postgres -c config_file=src/content/postgresql.conf &

# Wait for postgres to start
sleep 5

# Restore the Content Store database from its backup .bson file in GCP Storage

# Construct the file's URL
BUCKET=$(
  gcloud compute instances describe content \
    --project $PROJECT_ID \
    --zone $ZONE \
    --format="value(metadata.items.object_bucket)"
)
OBJECT=$(
gcloud compute instances describe content \
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
# Typically they are nearly 2GiB.
# On 2023-03-03 the database backup files had a problem and were only a few
# megabytes.
minimumsize=1073741824
actualsize=$(wc -c <"$FILE_PATH")
if [ $actualsize -le $minimumsize ]; then
  # Turn this instance off and exit.  The data that is currrently in BigQuery
  # will remain there.
  gcloud compute instances delete content --quiet --zone=$ZONE
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
cp src/content/postgresql.conf.safe src/content/postgresql.conf
psql -U postgres -c "SELECT pg_reload_conf();"

# Export the content_items table as JSON, to be loaded into MongoDB
QUERY=$(cat <<-"END"
\copy (
  WITH export AS (
    SELECT
      base_path AS _id,
      id,
      base_path,
      content_id,
      title,
      description,
      document_type,
      content_purpose_document_supertype,
      content_purpose_subgroup,
      content_purpose_supergroup,
      email_document_supertype,
      government_document_supertype,
      navigation_document_supertype,
      search_user_need_document_supertype,
      user_journey_document_supertype,
      schema_name,
      locale,
      first_published_at,
      public_updated_at,
      publishing_scheduled_at,
      details,
      publishing_app,
      rendering_app,
      routes,
      redirects,
      expanded_links,
      access_limited,
      auth_bypass_ids,
      phase,
      analytics_identifier,
      payload_version,
      withdrawn_notice,
      publishing_request_id,
      created_at,
      updated_at
    FROM content_items
  )
  SELECT row_to_json(export)
  FROM export
) TO STDOUT;
END
)

DEST="gs://${PROJECT_ID}-data-processed/content-store/content_items.json.gz"

date
# COPY escapes backslashes with more backslashes, so unescape them with sed
psql \
  --username=postgres \
  --dbname=content_store_production \
  --tuples-only \
  --command="${QUERY}" \
  | sed -E 's/\\\\/\\/g' \
  | gzip -c \
  | gcloud storage cp - "${DEST}"
date

# Start a virtual machine to process the exported data
gcloud --project "${PROJECT_ID}" compute instances create mongodb \
    --source-instance-template="https://www.googleapis.com/compute/v1/projects/${PROJECT_ID}/global/instanceTemplates/mongodb" \
    --zone="${ZONE}"

date
# Export the content_items table as CSV, to be loaded into BigQuery.
#
# Compression can cause trouble with big files or big columns. See
# /src/publishing-api/functions.sh. But this file is small, with small columns.
QUERY="\copy content_items TO STDOUT WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');"
DEST="gs://${PROJECT_ID}-data-processed/content-store/content_items.csv.gz"
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
  "TRUNCATE TABLE content.content_items"

# Load the new data into BigQuery
date
bq --project_id "${PROJECT_ID}" load \
  --source_format="CSV" \
  --allow_quoted_newlines \
  --skip_leading_rows=1 \
  --noreplace \
  --nosynchronous_mode \
  "content.content_items" \
  "gs://${PROJECT_ID}-data-processed/content-store/content_items.csv.gz"
date

# Stop this instance
# https://stackoverflow.com/a/41232669
gcloud compute instances delete content --quiet --zone=$ZONE
