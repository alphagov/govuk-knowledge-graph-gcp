# body_content content; individual lines of text
query_mongo \
  type=json \
  collection=body_content \
  fields=url,html \
| extract_lines_from_html \
  input_col=html \
  id_cols=url \
| upload file_name=body_content_lines
