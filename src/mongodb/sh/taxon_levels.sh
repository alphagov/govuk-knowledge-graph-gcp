# taxon levels, sorted by level and url
query_mongo \
  collection=taxon_levels \
  fields=level,url \
| (read -r; printf "%s\n" "$REPLY"; sort) \
| upload file_name=taxon_levels
