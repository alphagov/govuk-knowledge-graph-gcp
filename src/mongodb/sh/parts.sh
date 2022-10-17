FILE_NAME=parts

query_mongo \
  collection=parts_content \
  fields=url,base_path,slug,part_index,part_title \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
