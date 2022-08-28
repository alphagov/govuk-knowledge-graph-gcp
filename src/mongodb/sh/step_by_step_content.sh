# step_by_step content
query_mongo \
  collection=step_by_step_content \
  fields=url,html \
| extract_text_from_html \
  input_col=html \
  id_cols=url,html \
| upload file_name=step_by_step_content
