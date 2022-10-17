FILE_NAME=url

query_mongo \
  fields=url \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
