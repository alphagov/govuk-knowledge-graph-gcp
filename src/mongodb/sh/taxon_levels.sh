FILE_NAME=taxon_levels

query_mongo \
  collection=taxon_levels \
  fields=url,homepage_url,level \
| (read -r; printf "%s\n" "$REPLY"; sort) \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
