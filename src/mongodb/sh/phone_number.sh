FILE_NAME=phone_number

mongoexport \
  -d content_store \
  -c phone_number \
  --type=csv \
  --fields "url,title,number,textphone,international_phone,fax,description,open_hours,best_time_to_call" \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
