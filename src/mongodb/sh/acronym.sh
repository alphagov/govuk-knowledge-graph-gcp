FILE_NAME=acronym

query_mongo \
  fields=url,details.acronym \
  query='{ "details.acronym": { "$exists": true, "$ne": null, "$ne": "" } }' \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
