# guide_and_travel_advice_parts content
query_mongo \
  collection=parts_content \
  fields=url,base_path,part_index,html \
| extract_text_from_html \
  input_col=html \
  id_cols=url,base_path,part_index,html \
| upload file_name=parts_content
