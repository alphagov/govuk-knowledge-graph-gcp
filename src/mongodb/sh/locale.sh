# locale
query_mongo \
  fields=url,locale \
  query='{ "locale": { "$exists": true } }' \
| upload file_name=locale
