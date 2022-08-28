# content_id
query_mongo \
  fields=url,content_id \
  query='{ "content_id": { "$exists": true } }' \
| upload file_name=content_id
