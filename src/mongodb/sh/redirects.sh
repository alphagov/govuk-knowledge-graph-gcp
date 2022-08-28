query_mongo \
  collection=redirects \
  fields=from,to \
| upload file_name=redirects
