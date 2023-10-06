#!/bin/bash

# The most recent edition of each document, as long as it has a base_path (url)
psql \
  --username=postgres \
  --dbname=publishing_api_production \
  --csv \
  --file=queries/latest-edition.sql
