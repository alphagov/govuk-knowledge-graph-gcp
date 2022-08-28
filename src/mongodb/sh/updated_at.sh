# updated_at
query_mongo \
  fields=url,updated_at \
  query='{ "updated_at": { "$exists": true } }' \
| upload file_name=updated_at
