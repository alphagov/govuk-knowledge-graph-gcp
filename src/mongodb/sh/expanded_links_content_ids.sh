FILE_NAME=expanded_links_content_ids

query_mongo \
  collection=expanded_links_content_ids \
  fields=link_type,from_content_id,to_content_id \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
