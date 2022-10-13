FILE_NAME=updated_at

query_mongo \
  fields=url,updated_at \
  query='{ "updated_at": { "$exists": true } }' \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
