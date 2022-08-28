# step_by_step content; individual lines of text
query_mongo \
  collection=step_by_step_content \
  fields=url,html \
| extract_lines_from_html \
  input_col=html \
  id_cols=url \
| upload file_name=step_by_step_lines
