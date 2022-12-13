FILE_NAME=pagerank

# sed is used to remove spaces after column delimiters, which cause BigQuery to
# interpret decimals as strings, and therefore fail to import the data.
query_neo4j \
  cypher="MATCH (a:Page) RETURN a.url, a.pagerank;"  \
  | sed 's/, /,/g' \
  | upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
