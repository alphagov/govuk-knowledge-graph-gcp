FILE_NAME=phase

query_mongo \
  fields=url,phase \
  query='{ "phase": { "$exists": true } }' \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
