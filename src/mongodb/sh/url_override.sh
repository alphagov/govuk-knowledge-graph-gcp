# Taxon url_override
query_mongo \
  collection=url_override \
  fields=url,url_override \
| upload file_name=url_override
