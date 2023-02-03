FILE_NAME=redirects

query_mongo \
  collection=redirects \
  fields=from_url,to_url,to_url_bare \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
