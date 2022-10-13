FILE_NAME=transaction_embedded_links

query_mongo \
  type=json \
  collection=transaction_content \
  fields=url,html \
| extract_hyperlinks_from_html \
  input_col=html \
  id_cols=url \
| count_distinct escape_cols=link_text \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
