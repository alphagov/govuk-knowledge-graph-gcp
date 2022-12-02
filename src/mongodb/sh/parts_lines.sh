FILE_NAME=parts_lines

query_mongo \
  type=json \
  collection=parts_content \
  fields=url,base_path,part_index,html \
| extract_lines_from_html \
  input_col=html \
  id_cols=url,base_path,part_index \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
