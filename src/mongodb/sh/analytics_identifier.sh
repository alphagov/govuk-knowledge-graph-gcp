# analytics_identifier
query_mongo \
  fields=url,analytics_identifier \
  query='{ "analytics_identifier": { "$exists": true, "$ne": null } }' \
| upload file_name=analytics_identifier
