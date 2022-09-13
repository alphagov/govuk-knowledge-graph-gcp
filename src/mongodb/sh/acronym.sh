# acronym
query_mongo \
  fields=url,details.acronym \
  query='{ "details.acronym": { "$exists": true, "$ne": null, "$ne": "" } }' \
| upload file_name=acronym
