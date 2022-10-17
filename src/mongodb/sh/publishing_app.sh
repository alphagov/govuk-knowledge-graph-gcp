FILE_NAME=publishing_app

query_mongo \
  fields=url,publishing_app \
  query='{ "publishing_app": { "$exists": true } }' \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
