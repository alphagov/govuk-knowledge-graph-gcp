#!/bin/bash

# Run both neo4j and scripts that interact with the database

# turn on bash's job control
set -m

# Start neo4j as a daemon
neo4j start

# Wait for neo4j to start
sleep 5

# Import data from a bucket

# Download the files to the local Neo4j import directory, because Neo4j can't
# import from a pipe.
gsutil -m cp -rv \
  gs://govuk-knowledge-graph-data-processed/content-store/\* \
  /var/lib/neo4j/import

# Decompress all those files (the semicolon is escaped for the shell, but might
# not need to be escaped within a script).
find /var/lib/neo4j/import -name "*.csv.gz" -exec gunzip {} \;

# Query the content store into intermediate datasets
gsutil cat \
  gs://govuk-knowledge-graph-repository/src/neo4j/load_content_store_data.cypher \
  | cypher-shell

# Stay alive
sleep infinity
