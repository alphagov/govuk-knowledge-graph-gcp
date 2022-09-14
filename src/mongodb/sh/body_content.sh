# body_content content
query_mongo \
  type=json \
  collection=body_content \
  fields=url,html \
| extract_text_from_html \
  input_col=html \
  id_cols=url,html \
| upload file_name=body_content
