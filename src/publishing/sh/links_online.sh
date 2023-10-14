FILE_NAME=links_online

# Links that are being used by the website.
query_postgres \
  file=sql/links_online.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
