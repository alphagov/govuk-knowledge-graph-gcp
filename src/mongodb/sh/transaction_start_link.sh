# Transaction start button link
mongoexport \
  -d content_store \
  -c transaction_start_link \
  --type=csv \
  --fields "url,link_url,link_url_bare" \
| upload file_name=transaction_start_link
