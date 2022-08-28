# withdrawn_notice.explanation
query_mongo \
  fields=url,withdrawn_notice.explanation \
  query='{ "withdrawn_notice.explanation": { "$exists": true } }' \
| upload file_name=withdrawn_explanation
