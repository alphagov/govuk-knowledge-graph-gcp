FILE_NAME=locale

query_mongo \
  fields=url,locale \
  query='{ "locale": { "$exists": true } }' \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
