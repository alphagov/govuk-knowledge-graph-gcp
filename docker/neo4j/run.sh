#!/bin/bash

# Refresh certificates needed for HTTPS/BOLT connections"
# https://medium.com/neo4j/getting-certificates-for-neo4j-with-letsencrypt-a8d05c415bbd
cd /var/lib/neo4j/certificates
mkdir -p letsencrypt/work-dir letsencrypt/logs-dir letsencrypt/config-dir
certbot certonly \
  --agree-tos \
  --email data-products@digital.cabinet-office.gov.uk \
  -n \
  --nginx \
  -d govgraph.dev \
  --cert-path /var/lib/neo4j/certificates/cert.pem \
  --work-dir letsencrypt/work-dir \
  --logs-dir letsencrypt/logs-dir \
  --config-dir letsencrypt/config-dir
mkdir bolt cluster https
export DOMAIN=govgraph.dev
for certsource in bolt cluster https ; do
  ln -s $PWD/letsencrypt/config-dir/live/$DOMAIN/fullchain.pem $certsource/neo4j.cert
  ln -s $PWD/letsencrypt/config-dir/live/$DOMAIN/privkey.pem $certsource/neo4j.key
  mkdir $certsource/trusted
  ln -s $PWDletsencrypt/config-dir/live/$DOMAIN/fullchain.pem $certsource/trusted/neo4j.cert ;
done

# Run both neo4j and scripts that interact with the database

# turn on bash's job control
set -m

# Start neo4j as a daemon
exec gosu neo4j:neo4j neo4j start

# Import data from a bucket

# Download the files to the local Neo4j import directory, because Neo4j can't
# import from a pipe.
gcloud storage cp --recursive \
  gs://govuk-knowledge-graph-data-processed/content-store/\* \
  /var/lib/neo4j/import

gcloud storage cp --recursive \
  gs://govuk-knowledge-graph-data-processed/ga4/\* \
  /var/lib/neo4j/import

gcloud storage cp --recursive \
  gs://govuk-knowledge-graph-data-processed/publishing-api/\* \
  /var/lib/neo4j/import

# Decompress all those files (the semicolon is escaped for the shell, but might
# not need to be escaped within a script).
find /var/lib/neo4j/import -name "*.csv.gz" -exec gunzip {} \;

# Wait for neo4j to start
# Checking neo4j status doesn't work, because that says it's up before the
# server is ready.
until cypher-shell --address neo4j+s://govgraph.dev:7687 "RETURN true;" | grep -Fq "true"; do
  echo "Connecting to Neo4j"
  sleep 1;
done
neo4j status

# Ingest the Content Store data
gcloud storage cat \
  gs://govuk-knowledge-graph-repository/src/neo4j/load_content_store_data.cypher \
  | cypher-shell --address neo4j+s://govgraph.dev:7687

# Ingest the Publishing API data
gcloud storage cat \
  gs://govuk-knowledge-graph-repository/src/neo4j/load_content_store_data.cypher \
  | cypher-shell --address neo4j+s://govgraph.dev:7687

# Stay alive
sleep infinity
