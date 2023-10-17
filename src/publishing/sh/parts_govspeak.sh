FILE_NAME=parts_govspeak

# Editions that are being used by the website, either in the govspeak store as
# documents in their own right, or as expanded links, or as search results.
query_postgres \
  file=sql/parts_govspeak.sql \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
