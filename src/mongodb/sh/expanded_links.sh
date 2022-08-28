# expanded links
query_mongo \
  collection=expanded_links \
  fields=link_type,from_url,to_url \
| upload file_name=expanded_links
