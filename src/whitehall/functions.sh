#! /bin/bash
set -e

dataset_name="whitehall"

# Export a table from an SQL dump file, upload to storage and import into BigQuery
export_editions_to_bigquery () {
  local table_name="editions"
  local csv_name="/data/mysql/table_${table_name}"

  mysql -u root ${dataset_name} -e "SELECT id,created_at,updated_at,document_id,state,type,major_change_published_at,first_published_at,force_published,public_timestamp,scheduled_publication,access_limited,opening_at,closing_at,political,primary_locale,auth_bypass_id,government_id
                                    INTO OUTFILE '${csv_name}'
                                    FIELDS ESCAPED BY ''
                                    TERMINATED BY ','
                                    ENCLOSED BY '\"'
                                    LINES TERMINATED BY '\n'
                                    FROM editions;"

  upload_to_bq $table_name $csv_name
}

export_assets_to_bigquery () {
  local table_name="assets"
  local csv_name="/data/mysql/table_${table_name}"

   mysql -u root ${dataset_name} -e "SELECT id,asset_manager_id,variant,created_at,updated_at,assetable_type,assetable_id,REPLACE(filename,'\"','\"\"') as filename
                                     INTO OUTFILE '${csv_name}'
                                     FIELDS ESCAPED BY ''
                                     TERMINATED BY ','
                                     ENCLOSED BY '\"'
                                     LINES TERMINATED BY '\n'
                                     FROM assets;"

  upload_to_bq $table_name $csv_name
}

export_attachment_data_to_bigquery () {
  local table_name="attachment_data"
  local csv_name="/data/mysql/table_${table_name}"

   mysql -u root ${dataset_name} -e "SELECT id,REPLACE(carrierwave_file,'\"','\"\"') as carrierwave_file,REPLACE(content_type,'\"','\"\"') as content_type,file_size,number_of_pages,created_at,updated_at,replaced_by_id
                                     INTO OUTFILE '${csv_name}'
                                     FIELDS ESCAPED BY ''
                                     TERMINATED BY ','
                                     ENCLOSED BY '\"'
                                     LINES TERMINATED BY '\n'
                                     FROM attachment_data;"

  upload_to_bq $table_name $csv_name
}

export_attachments_to_bigquery() {
  local table_name="attachments"
  local csv_name="/data/mysql/table_${table_name}"

   mysql -u root ${dataset_name} -e "SELECT id,created_at,updated_at,REPLACE(title,'\"','\"\"') as title,attachment_data_id,attachable_id,attachable_type,type,slug,locale,content_id,deleted
                                     INTO OUTFILE '${csv_name}'
                                     FIELDS ESCAPED BY ''
                                     TERMINATED BY ','
                                     ENCLOSED BY '\"'
                                     LINES TERMINATED BY '\n'
                                     FROM attachments;"

  upload_to_bq $table_name $csv_name
}


upload_to_bq () {
  local table_name=$1
  local csv_name=$2
  local schema_name="schema_${table_name}"

  # Download the existing schema
    bq show \
      --schema=true \
      --format=json \
      "${dataset_name}.${table_name}" \
      > $schema_name

  # Load data into the the table, using the "write disposition", which is
  # equivalent to WRITE_TRUNCATE in SQL. It empties the table and wipes its
  # schema, before inserting new rows. This is done within a transaction. We
  # preserve the schema by downloading it first with `bq show`, and then using
  # it as an argument to `bq load`.
    bq load \
      --source_format="CSV" \
      --field_delimiter="," \
      --null_marker="NULL" \
      --allow_quoted_newlines \
      --replace=true \
      --schema="${schema_name}" \
      "${dataset_name}.${table_name}" \
      "${csv_name}"
}