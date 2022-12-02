FILE_NAME=body_lines

query_mongo \
  type=json \
  collection=body \
  fields=url,html \
| extract_lines_from_html \
  input_col=html \
  id_cols=url \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
