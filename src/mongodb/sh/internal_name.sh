FILE_NAME=internal_name

query_mongo \
  fields=url,details.internal_name \
  query='{ "details.internal_name": { "$exists": true } }' \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
