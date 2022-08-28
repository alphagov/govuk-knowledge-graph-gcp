# publishing_app
query_mongo \
  fields=url,publishing_app \
  query='{ "publishing_app": { "$exists": true } }' \
| upload file_name=publishing_app
