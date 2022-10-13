FILE_NAME=first_published_at

query_mongo \
  fields=url,first_published_at \
  query='{ "first_published_at": { "$exists": true } }' \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
