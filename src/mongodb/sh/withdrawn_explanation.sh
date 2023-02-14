FILE_NAME=withdrawn_explanation

query_mongo \
  type=json \
  collection=withdrawn_explanation \
  fields=url,html \
| extract_text_from_html \
  input_col=html \
  id_cols=url,html \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
