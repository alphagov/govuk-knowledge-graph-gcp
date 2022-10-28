FILE_NAME=role_embedded_links

zcat data/role_content.csv.gz \
| extract_hyperlinks_from_html \
  input_col=html \
  id_cols=url \
| count_distinct escape_cols=link_text \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
