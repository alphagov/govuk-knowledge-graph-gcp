FILE_NAME=editions_online

# Editions that are being used by the website, either in the content store as
# documents in their own right, or as expanded links, or as search results.
query_postgres \
  file=sql/editions_online.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
