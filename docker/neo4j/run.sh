#!/bin/bash
PROJECT_ID="govuk-knowledge-graph"
DOMAIN="35.246.18.75"

# Refresh certificates needed for HTTPS/BOLT connections"
# https://medium.com/neo4j/getting-certificates-for-neo4j-with-letsencrypt-a8d05c415bbd
cd /var/lib/neo4j/certificates
# Copy the most recent certificates from the bucket
gsutil -m rsync -J -r -d -C "gs://${PROJECT_ID}-ssl-certificates/letsencrypt" letsencrypt
# rsync doesn't copy empty directories, so make sure any empty ones do exist
mkdir -p letsencrypt/work-dir letsencrypt/logs-dir letsencrypt/config-dir
# Check that the certificates are still valid, otherwise renew them
certbot certonly \
  --agree-tos \
  --email data-products@digital.cabinet-office.gov.uk \
  -n \
  --nginx \
  -d $DOMAIN \
  --cert-path /var/lib/neo4j/certificates \
  --work-dir letsencrypt/work-dir \
  --logs-dir letsencrypt/logs-dir \
  --config-dir letsencrypt/config-dir
# In case the certificates were renewed, copy them back to the bucket
gsutil -m rsync -J -r -d -C letsencrypt "gs://${PROJECT_ID}-ssl-certificates/letsencrypt"
# Configure Neo4j to use the certificates
chgrp -R neo4j letsencrypt/*
chmod -R g+rx letsencrypt/*
mkdir bolt cluster https
for certsource in bolt cluster https ; do
  ln -s $PWD/letsencrypt/config-dir/live/$DOMAIN/fullchain.pem $certsource/neo4j.cert
  ln -s $PWD/letsencrypt/config-dir/live/$DOMAIN/privkey.pem $certsource/neo4j.key
  mkdir $certsource/trusted
  ln -s $PWD/letsencrypt/config-dir/live/$DOMAIN/fullchain.pem $certsource/trusted/neo4j.cert ;
done
# Finally make sure everything is readable to the database
chgrp -R neo4j *
chmod -R g+rx *

# Run both neo4j and scripts that interact with the database

# turn on bash's job control
set -m

# Start neo4j as a daemon
gosu neo4j:neo4j neo4j start

# Import data from a bucket

# Download the files to the local Neo4j import directory, because Neo4j can't
# import from a pipe.
gcloud storage cp --recursive \
  "gs://$PROJECT_ID-data-processed/content-store/*" \
  "/var/lib/neo4j/import"

gcloud storage cp \
  "gs://${PROJECT_ID}-data-processed/bigquery/content.csv.gz" \
  "gs://${PROJECT_ID}-data-processed/bigquery/embedded_links.csv.gz" \
  "/var/lib/neo4j/import"

gcloud storage cp --recursive \
  "gs://${PROJECT_ID}-data-processed/ga4/*" \
  "/var/lib/neo4j/import"

gcloud storage cp --recursive \
  "gs://${PROJECT_ID}-data-processed/publishing-api/*" \
  "/var/lib/neo4j/import"

gcloud storage cp --recursive \
  "gs://${PROJECT_ID}-data-processed/entities/*" \
  "/var/lib/neo4j/import"

# Decompress all those files (the semicolon is escaped for the shell, but might
# not need to be escaped within a script).
find /var/lib/neo4j/import -name "*.csv.gz" -exec gunzip {} \;

# Wait for neo4j to start
# Checking neo4j status doesn't work, because that says it's up before the
# server is ready.
until cypher-shell --address "neo4j+s://${DOMAIN}:7687" "RETURN true;" | grep -Fq "true"; do
  echo "Connecting to Neo4j"
  sleep 1;
done
neo4j status

# Ingest the Content Store data
gcloud storage cat \
  "gs://${PROJECT_ID}-repository/src/neo4j/load_content_store_data.cypher" \
  | cypher-shell --address "neo4j+s://${DOMAIN}:7687"

# Ingest the Publishing API data
gcloud storage cat \
  "gs://${PROJECT_ID}-repository/src/neo4j/load_publishing_api_data.cypher" \
  | cypher-shell --address "neo4j+s://${DOMAIN}:7687"

# Create the full-text indexes
gcloud storage cat \
  "gs://${PROJECT_ID}-repository/src/neo4j/index.cypher" \
  | cypher-shell --address "neo4j+s://${DOMAIN}:7687"

# Ingest entites from the NER (named-entity recognition) pipeline
gcloud storage cat \
  "gs://${PROJECT_ID}-repository/src/neo4j/load_entities.cypher" \
g | cypher-shell --address "neo4j+s://${DOMAIN}:7687"

# Stay alive
sleep infinity
