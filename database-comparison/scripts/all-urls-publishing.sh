#!/bin/bash

psql \
  --username=postgres \
  --dbname=publishing_api_production \
  --csv \
  --command="SELECT base_path from editions_latest;" \
> data/url-publishing.csv
