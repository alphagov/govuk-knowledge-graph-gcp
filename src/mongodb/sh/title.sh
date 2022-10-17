FILE_NAME=title

query_mongo \
  collection=title \
  fields=url,title \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
