FILE_NAME=description

query_mongo \
  collection=description \
  fields=url,description \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
