FILE_NAME=body_abbreviations

query_mongo \
  type=json \
  collection=body \
  fields=url,html \
| extract_abbreviations_from_html \
  input_col=html \
  id_cols=url \
| count_distinct escape_cols=abbreviation_title \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
