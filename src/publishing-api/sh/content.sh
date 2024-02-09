FILE_NAME=role_content

# The govspeak content of every role.
# As well as being uploaded, this is written to a file to be used by other
# scripts.
query_postgres_json \
  file=sql/content.sql \
| convert_govspeak_to_html input_col=govspeak id_cols=url,govspeak \
| gzip -c \
> data/role_content.csv.gz