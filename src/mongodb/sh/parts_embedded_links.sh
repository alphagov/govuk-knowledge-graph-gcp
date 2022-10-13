FILE_NAME=parts_embedded_links

query_mongo \
  type=json \
  collection=parts_content \
  fields=url,base_path,part_index,html \
| extract_hyperlinks_from_html \
  input_col=html \
  id_cols=url,base_path,part_index \
| count_distinct escape_cols=link_text \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
