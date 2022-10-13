FILE_NAME=withdrawn_at

query_mongo \
  fields=url,withdrawn_notice.withdrawn_at \
  query='{ "withdrawn_notice.withdrawn_at": { "$exists": true } }' \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
