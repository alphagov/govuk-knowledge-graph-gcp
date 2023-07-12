FILE_NAME=schema_name

query_mongo \
  fields=url,schema_name \
  query='{ "schema_name": { "$exists": true } }' \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
