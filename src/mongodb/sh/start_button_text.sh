FILE_NAME=start_button_text

mongoexport \
  -d content_store \
  -c content_items \
  --type=csv \
  --fields "url,details.start_button_text" \
  -q '{ "document_type": "transaction", "details.start_button_text": { "$exists": true } }' \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
