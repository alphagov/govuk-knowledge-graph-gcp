#!/bin/bash

psql \
  --username=postgres \
  --dbname=content_store_test_deleteme \
  --csv \
  --command="SELECT base_path from content_items;" \
> data/url-content.csv
