# parts (just the nodes)
query_mongo \
  collection=parts_content \
  fields=url,base_path,slug,part_index,part_title \
| upload file_name=parts
