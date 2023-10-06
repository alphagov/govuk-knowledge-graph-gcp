-- Import the URLs (base paths) from each database
CREATE OR REPLACE TABLE url_content_mongo AS
SELECT * FROM read_csv(
  'data/all-urls-content-mongo.csv',
  header=true,
  auto_detect=true
)
;

CREATE OR REPLACE TABLE url_content_postgres AS
SELECT * FROM read_csv(
  'data/all-urls-content-postgres.csv',
  header=true,
  auto_detect=true
)
;

CREATE OR REPLACE TABLE url_publishing_postgres AS
SELECT * FROM read_csv(
  'data/all-urls-publishing.csv',
  header=true,
  auto_detect=true
)
;

-- Table every base_path from all three tables, and TRUE/NULL for their presence
-- in each table.
CREATE OR REPLACE TABLE register AS
WITH all_base_paths AS (
  SELECT base_path, 'publishing' AS database FROM url_publishing_postgres
  UNION ALL
  SELECT base_path, 'content_postgres' AS database FROM url_content_postgres
  UNION ALL
  SELECT _id AS base_path, 'content_mongo' AS database FROM url_content_mongo
)
PIVOT all_base_paths
ON database
USING FIRST(TRUE)
GROUP BY base_path
;

-- Export the register to a CSV file
COPY (select * from register) TO 'data/register-of-all-urls.csv' (HEADER);
