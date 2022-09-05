# expanded links
query_mongo \
  collection=expanded_links \
  fields=link_type,from_url,to_url \
| upload file_name=expanded_links

# expanded links by content_id
query_mongo \
  collection=expanded_links_content_ids \
  fields=link_type,from_content_id,to_content_id \
| upload file_name=expanded_links_content_ids
