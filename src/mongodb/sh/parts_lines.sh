# parts content; individual lines of text
query_mongo \
  collection=parts_content \
  fields=url,base_path,part_index,html \
| extract_lines_from_html \
  input_col=html \
  id_cols=url,base_path,part_index \
| upload file_name=parts_lines
