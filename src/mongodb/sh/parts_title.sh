FILE_NAME=parts_title

query_mongo \
  collection=parts_content \
  fields=url,title \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
