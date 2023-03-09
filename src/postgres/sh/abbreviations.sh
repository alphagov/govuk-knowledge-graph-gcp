FILE_NAME=role_abbreviations

zcat data/role_content.csv.gz \
| extract_abbreviations_from_html \
  input_col=html \
  id_cols=url \
| count_distinct escape_cols=abbreviation_title \
| upload file_name=$FILE_NAME

send_to_bigquery file_name=$FILE_NAME
