# transaction department analytics profile
mongoexport \
  -d content_store \
  -c content_items \
  --type=csv \
  --fields "url,details.department_analytics_profile" \
  -q '{ "document_type": "transaction", "details.department_analytics_profile": { "$exists": true, "$ne": null, "$ne": "" } }' \
| upload file_name=department_analytics_profile
