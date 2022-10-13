FILE_NAME=transaction_start_link

mongoexport \
  -d content_store \
  -c transaction_start_link \
  --type=csv \
  --fields "url,link_url,link_url_bare" \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
