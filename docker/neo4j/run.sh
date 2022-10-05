#!/bin/bash

# Generate certificates needed for HTTPS/BOLT connections"
# https://medium.com/neo4j/getting-certificates-for-neo4j-with-letsencrypt-a8d05c415bbd
su - root
certbot certonly \
  --agree-tos \
  --email data-products@digital.cabinet-office.gov.uk \
  -n \
  --nginx \
  -d govgraph.dev
chgrp -R neo4j /etc/letsencrypt/*
chmod -R g+rx /etc/letsencrypt/*
cd /var/lib/neo4j/certificates
mkdir bolt cluster https
export DOMAIN=govgraph.dev
for certsource in bolt cluster https ; do
  ln -s /etc/letsencrypt/live/$DOMAIN/fullchain.pem $certsource/neo4j.cert
  ln -s /etc/letsencrypt/live/$DOMAIN/privkey.pem $certsource/neo4j.key
  mkdir $certsource/trusted
  ln -s /etc/letsencrypt/live/$DOMAIN/fullchain.pem $certsource/trusted/neo4j.cert ;
done
chgrp -R neo4j *
chmod -R g+rx *
exit

# Run both neo4j and scripts that interact with the database

# turn on bash's job control
set -m

# Start neo4j as a daemon
neo4j start

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
until cypher-shell "RETURN true;" | grep -Fq "true"; do
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
