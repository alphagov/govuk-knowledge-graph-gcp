# step_by_step embedded hyperlinks
query_mongo \
  collection=step_by_step_content \
  fields=url,html \
| extract_hyperlinks_from_html \
  input_col=html \
  id_cols=url \
| count_distinct escape_cols=link_text \
| upload file_name=step_by_step_embedded_links
