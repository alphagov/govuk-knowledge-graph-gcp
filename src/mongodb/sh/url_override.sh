FILE_NAME=url_override

query_mongo \
  collection=url_override \
  fields=url,url_override \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
