FILE_NAME=role_content

zcat data/role_content.csv.gz \
| extract_text_from_html \
  input_col=html \
  id_cols=url,govspeak,html \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
