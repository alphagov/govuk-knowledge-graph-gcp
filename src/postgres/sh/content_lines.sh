FILE_NAME=role_content_lines

zcat data/role_content.csv.gz \
| extract_lines_from_html \
  input_col=html \
  id_cols=url \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
