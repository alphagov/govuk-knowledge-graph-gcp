zcat data/role_content.csv.gz \
| extract_lines_from_html \
  input_col=html \
  id_cols=url \
| upload file_name=role_content_lines
