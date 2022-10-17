FILE_NAME=redirects

query_mongo \
  collection=redirects \
  fields=from,to \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
