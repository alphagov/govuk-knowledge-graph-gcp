FILE_NAME=document_type

query_mongo \
  fields=url,document_type \
  query='{ "document_type": { "$exists": true, "$ne": null } }' \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
