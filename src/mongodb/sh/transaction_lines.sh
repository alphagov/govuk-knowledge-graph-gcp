# transaction content; individual lines of text
query_mongo \
  collection=transaction_content \
  fields=url,html \
| extract_lines_from_html \
  input_col=html \
  id_cols=url \
| upload file_name=transaction_lines
