FILE_NAME=organisation_govuk_status

query_mongo \
  collection=organisation_govuk_status \
  fields=url,status,updated_at,organisation_url \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
