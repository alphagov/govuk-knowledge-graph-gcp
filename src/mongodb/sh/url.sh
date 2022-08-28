# base_path (just the nodes)
query_mongo \
  fields=url \
| upload file_name=url
