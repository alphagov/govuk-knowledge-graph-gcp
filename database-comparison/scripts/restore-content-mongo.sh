#!/bin/bash

date
tar xzvO  \
  -f ./database-backups/mongo-api_2023-10-05T00_16_01-content_store_production.gz \
  content_store_production/content_items.bson \
| mongorestore -v --db=content_store --collection=content_items -
date
