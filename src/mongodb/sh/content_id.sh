FILE_NAME=content_id

query_mongo \
  fields=url,content_id \
  query='{ "content_id": { "$exists": true, "$ne": null } }' \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
