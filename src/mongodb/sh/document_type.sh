# document_type
query_mongo \
  fields=url,document_type \
  query='{ "document_type": { "$exists": true } }' \
| upload file_name=document_type
