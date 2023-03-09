FILE_NAME=parts_abbreviations

query_mongo \
  type=json \
  collection=parts \
  fields=url,base_path,part_index,html \
| extract_abbreviations_from_html \
  input_col=html \
  id_cols=url,base_path,part_index \
| count_distinct escape_cols=abbreviation_title \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
