FILE_NAME=withdrawn_explanation

query_mongo \
  fields=url,withdrawn_notice.explanation \
  query='{ "withdrawn_notice.explanation": { "$exists": true } }' \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
