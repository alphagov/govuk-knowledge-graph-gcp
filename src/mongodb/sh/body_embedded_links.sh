# body embedded hyperlinks
query_mongo \
  type=json \
  collection=body \
  fields=url,html \
| extract_hyperlinks_from_html \
  input_col=html \
  id_cols=url \
| count_distinct escape_cols=link_text \
| upload file_name=body_embedded_links
