# Extract datasets of nodes, attributes and edges from the MongoDB content store
# database.

# Count the number of times that each distinct row of a CSV appears.
#
# This handles newlines in quoted columns.  You have to pass a comma-separated
# list of column names that could contain newlines.
#
# Input is via stdin.
#
# Usage:
# command_that_emits_csv | count_distinct escape_cols=col1,col2
#
# Where col1 and col2 are columns that might contain newlines.
#
# This depends on Python's CSV library to escape and unescape newline
# characters.
#
# Performance (speed and memory) should be okay.  The Python steps are
# parallelised, and only load a few lines at a time.  The unix steps are also
# efficient.
count_distinct () {
  local escape_cols    # reset first
  local "${@}"
  python3 src/utils/toggle_escapes.py \
    --escape_cols=${escape_cols} \
  | ( \
    read -r; \
    printf "count,%s\n" "$REPLY"; \
    LC_ALL=C sort -S 100% \
    | LC_ALL=C uniq -c \
    | sed -E 's/(\s*)([[:digit:]]+)(\s+)/\2,/' \
  ) \
  | python3 src/utils/toggle_escapes.py \
    --unescape_cols=${escape_cols}
}

# Compress and upload to cloud bucket
#
# Usage:
# command_that_emits_text | upload file_name=myfile
#
# The suffix ".csv.gz" is automatically appended to the file name.
#
# The bucket path is taken from the environment variable
# KNOWLEDGE_GRAPH_BUCKET_PATH, suffixed with a slash.
upload () {
  local file_name # reset in case they are defined globally
  local "${@}"
  gzip -c \
  | gsutil cp - "gs://govuk-knowledge-graph-data-processed/content-store/${file_name}.csv.gz"
}

# Wrapper around mongoexport to preset --db=content_store and --type=csv
#
# The `collection=` parameter is optional.  Its default is `content_items`.
#
# The `query=` parameter is optional.
#
# Usage:
#
# query_mongo \
#   collection=my_collection \
#   fields=col1,col2
#
# query_mongo \
#   collection=my_collection \
#   fields=col1,col2 \
#   query='{ "my_field": { "$exists": true } }'
query_mongo () {
  local collection fields query # reset in case they are defined globally
  local "${@}"
  mongoexport \
    --db=content_store \
    --type=csv \
    --collection=${collection:-content_items} \
    --fields=${fields} \
    --query="${query}"
}

# Wrappers around python scripts
#
# Usage:
#
# extract_text_from_html
#   input_col=html \
#   id_cols=url,html \
#
# extract_lines_from_html
#   input_col=html \
#   id_cols=url \
#
# extract_hyperlinks_from_html \
#   input_col=html \
#   id_cols=url \
extract_text_from_html () {
  local input_col id_cols # reset in case they are defined globally
  local "${@}"
  python3 src/utils/extract_text_from_html.py \
    --input_col=${input_col} \
    --id_cols=${id_cols}
}
extract_lines_from_html () {
  local input_col id_cols # reset in case they are defined globally
  local "${@}"
  python3 src/utils/extract_lines_from_html.py \
    --input_col=${input_col} \
    --id_cols=${id_cols}
}
extract_hyperlinks_from_html () {
  local input_col id_cols # reset in case they are defined globally
  local "${@}"
  python3 src/utils/extract_hyperlinks_from_html.py \
    --input_col=${input_col} \
    --id_cols=${id_cols}
}

# base_path (just the nodes)
query_mongo \
  fields=url \
| upload file_name=url

# phase (e.g. "live")
query_mongo \
  fields=url,phase \
  query='{ "phase": { "$exists": true } }' \
| upload file_name=phase

# content_id
query_mongo \
  fields=url,content_id \
  query='{ "content_id": { "$exists": true } }' \
| upload file_name=content_id

# analytics_identifier
query_mongo \
  fields=url,analytics_identifier \
  query='{ "analytics_identifier": { "$exists": true, "$ne": null } }' \
| upload file_name=analytics_identifier

# parts (just the nodes)
query_mongo \
  collection=parts_content \
  fields=url,base_path,slug,part_index,part_title \
| upload file_name=parts

# document_type
query_mongo \
  fields=url,document_type \
  query='{ "document_type": { "$exists": true } }' \
| upload file_name=document_type

# locale
query_mongo \
  fields=url,locale \
  query='{ "locale": { "$exists": true } }' \
| upload file_name=locale

# publishing_app
query_mongo \
  fields=url,publishing_app \
  query='{ "publishing_app": { "$exists": true } }' \
| upload file_name=publishing_app

# updated_at
query_mongo \
  fields=url,updated_at \
  query='{ "updated_at": { "$exists": true } }' \
| upload file_name=updated_at

# public_updated_at
query_mongo \
  fields=url,public_updated_at \
  query='{ "public_updated_at": { "$exists": true } }' \
| upload file_name=public_updated_at

# first_published_at
query_mongo \
  fields=url,first_published_at \
  query='{ "first_published_at": { "$exists": true } }' \
| upload file_name=first_published_at

# withdrawn_notice.withdrawn_at
query_mongo \
  fields=url,withdrawn_notice.withdrawn_at \
  query='{ "withdrawn_notice.withdrawn_at": { "$exists": true } }' \
| upload file_name=withdrawn_at

# withdrawn_notice.explanation
query_mongo \
  fields=url,withdrawn_notice.explanation \
  query='{ "withdrawn_notice.explanation": { "$exists": true } }' \
| upload file_name=withdrawn_explanation

# title
query_mongo \
  collection=title \
  fields=url,title \
| upload file_name=title

# description
query_mongo \
  collection=description \
  fields=url,description \
| upload file_name=description

# step_by_step content
query_mongo \
  collection=step_by_step_content \
  fields=url,html \
| extract_text_from_html \
  input_col=html \
  id_cols=url,html \
| upload file_name=step_by_step_content

# step_by_step content; individual lines of text
query_mongo \
  collection=step_by_step_content \
  fields=url,html \
| extract_lines_from_html \
  input_col=html \
  id_cols=url \
| upload file_name=step_by_step_lines

# step_by_step embedded hyperlinks
query_mongo \
  collection=step_by_step_content \
  fields=url,html \
| extract_hyperlinks_from_html \
  input_col=html \
  id_cols=url \
| count_distinct escape_cols=link_text \
| upload file_name=step_by_step_embedded_links

# transaction department analytics profile
mongoexport \
  -d content_store \
  -c content_items \
  --type=csv \
  --fields "url,details.department_analytics_profile" \
  -q '{ "document_type": "transaction", "details.department_analytics_profile": { "$exists": true, "$ne": null, "$ne": "" } }' \
| gzip -c  \
| upload file_name=department_analytics_profile

# Transaction start button link
mongoexport \
  -d content_store \
  -c transaction_start_link \
  --type=csv \
  --fields "url,link_url,link_url_bare" \
| gzip -c  \
| upload file_name=transaction_start_link

# Transaction start button text
mongoexport \
  -d content_store \
  -c content_items \
  --type=csv \
  --fields "url,details.start_button_text" \
  -q '{ "document_type": "transaction", "details.start_button_text": { "$exists": true } }' \
| gzip -c  \
| upload file_name=start_button_text

# expanded links
query_mongo \
  collection=expanded_links \
  fields=link_type,from_url,to_url \
| upload file_name=expanded_links

# guide_and_travel_advice_parts content
query_mongo \
  collection=parts_content \
  fields=url,base_path,part_index,html \
| extract_text_from_html \
  input_col=html \
  id_cols=url,base_path,part_index,html \
| upload file_name=parts_content

# parts content; individual lines of text
query_mongo \
  collection=parts_content \
  fields=url,base_path,part_index,html \
| extract_lines_from_html \
  input_col=html \
  id_cols=url,base_path,part_index \
| upload file_name=parts_lines

# parts embedded hyperlinks
query_mongo \
  collection=parts_content \
  fields=url,base_path,part_index,html \
| extract_hyperlinks_from_html \
  input_col=html \
  id_cols=url,base_path,part_index \
| count_distinct escape_cols=link_text \
| upload file_name=parts_embedded_links

# transaction content
query_mongo \
  collection=transaction_content \
  fields=url,html \
| extract_text_from_html \
  input_col=html \
  id_cols=url,html \
| upload file_name=transaction_content

# transaction content; individual lines of text
query_mongo \
  collection=transaction_content \
  fields=url,html \
| extract_lines_from_html \
  input_col=html \
  id_cols=url \
| upload file_name=transaction_lines

# transaction embedded hyperlinks
query_mongo \
  collection=transaction_content \
  fields=url,html \
| extract_hyperlinks_from_html \
  input_col=html \
  id_cols=url \
| count_distinct escape_cols=link_text \
| upload file_name=transaction_embedded_links

# place content
query_mongo \
  collection=place_content \
  fields=url,html \
| extract_text_from_html \
  input_col=html \
  id_cols=url,html \
| upload file_name=place_content

# place content; individual lines of text
query_mongo \
  collection=place_content \
  fields=url,html \
| extract_lines_from_html \
  input_col=html \
  id_cols=url \
| upload file_name=place_lines

# place embedded hyperlinks
query_mongo \
  collection=place_content \
  fields=url,html \
| extract_hyperlinks_from_html \
  input_col=html \
  id_cols=url \
| count_distinct escape_cols=link_text \
| upload file_name=place_embedded_links

# body content
query_mongo \
  collection=body \
  fields=url,html \
| extract_text_from_html \
  input_col=html \
  id_cols=url,html \
| upload file_name=body

# body content; individual lines of text
query_mongo \
  collection=body \
  fields=url,html \
| extract_lines_from_html \
  input_col=html \
  id_cols=url \
| upload file_name=body_lines

# body embedded hyperlinks
query_mongo \
  collection=body \
  fields=url,html \
| extract_hyperlinks_from_html \
  input_col=html \
  id_cols=url \
| count_distinct escape_cols=link_text \
| upload file_name=body_embedded_links

# body_content content
query_mongo \
  collection=body_content \
  fields=url,html \
| extract_text_from_html \
  input_col=html \
  id_cols=url,html \
| upload file_name=body_content

# body_content content; individual lines of text
query_mongo \
  collection=body_content \
  fields=url,html \
| extract_lines_from_html \
  input_col=html \
  id_cols=url \
| upload file_name=body_content_lines

# body_content embedded hyperlinks
query_mongo \
  collection=body_content \
  fields=url,html \
| extract_hyperlinks_from_html \
  input_col=html \
  id_cols=url \
| count_distinct escape_cols=link_text \
| upload file_name=body_content_embedded_links
