FILE_NAME=department_analytics_profile

mongoexport \
  -d content_store \
  -c content_items \
  --type=csv \
  --fields "url,details.department_analytics_profile" \
  -q '{ "document_type": "transaction", "details.department_analytics_profile": { "$exists": true, "$ne": null, "$ne": "" } }' \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
