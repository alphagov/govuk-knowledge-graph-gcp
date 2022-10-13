FILE_NAME=public_updated_at

query_mongo \
  fields=url,public_updated_at \
  query='{ "public_updated_at": { "$exists": true } }' \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
