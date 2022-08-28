# public_updated_at
query_mongo \
  fields=url,public_updated_at \
  query='{ "public_updated_at": { "$exists": true } }' \
| upload file_name=public_updated_at
