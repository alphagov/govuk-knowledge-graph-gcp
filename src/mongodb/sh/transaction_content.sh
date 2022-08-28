# transaction content
query_mongo \
  collection=transaction_content \
  fields=url,html \
| extract_text_from_html \
  input_col=html \
  id_cols=url,html \
| upload file_name=transaction_content
