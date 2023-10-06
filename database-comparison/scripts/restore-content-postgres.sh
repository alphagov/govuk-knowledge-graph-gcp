#!/bin/bash

date
pg_restore \
  --verbose \
  --create \
  --clean \
  --no-owner \
  --jobs=2 \
  --dbname postgres \
  --format=c \
  ./database-backups/2023-10-05T000705Z-content_store_test_deleteme.gz
date
