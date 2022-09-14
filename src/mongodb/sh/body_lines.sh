# body content; individual lines of text
query_mongo \
  type=json \
  collection=body \
  fields=url,html \
| extract_lines_from_html \
  input_col=html \
  id_cols=url \
| upload file_name=body_lines
