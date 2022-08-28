# phase (e.g. "live")
query_mongo \
  fields=url,phase \
  query='{ "phase": { "$exists": true } }' \
| upload file_name=phase
