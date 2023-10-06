#!/bin/bash

mongoexport \
  --quiet \
  --db=content_store \
  --type=csv \
  --collection=content_items \
  --fields=_id \
> data/url.csv
