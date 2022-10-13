FILE_NAME=expanded_links

query_mongo \
  collection=expanded_links \
  fields=link_type,from_url,to_url \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
