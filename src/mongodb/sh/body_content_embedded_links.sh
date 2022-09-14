# body_content embedded hyperlinks
query_mongo \
  type=json \
  collection=body_content \
  fields=url,html \
| extract_hyperlinks_from_html \
  input_col=html \
  id_cols=url \
| count_distinct escape_cols=link_text \
| upload file_name=body_content_embedded_links
