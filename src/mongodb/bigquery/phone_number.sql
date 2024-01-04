  -- Phone numbers from contact documents and general page content, detected by
  -- GovNer (entities) and libphonenumber, and standardised by libphonenumber.
TRUNCATE TABLE
  graph.phone_number;
INSERT INTO
  graph.phone_number
WITH
  -- Phone numbers from contact documents.
  contacts AS (
  SELECT
    content_phone_number.url,
    extracted_numbers.text AS original_number,
    extracted_numbers.number AS standardised_number
  FROM
    `content.phone_number` AS content_phone_number,
    UNNEST(`functions.extract_phone_numbers`(number)) AS extracted_numbers ),
  -- Only those entities that are phone numbers, to avoid unnecessary calls to the
  -- libphonenumber function, which is slow.
  phone_entities AS (
  SELECT
    DISTINCT url,
    name AS number,
  FROM
    `cpto-content-metadata.named_entities.named_entities_all`
  WHERE
    type = "PHONE" ),
  -- Phone numbers in page content, detected by GovNer (entities).
  entities AS (
  SELECT
    phone_entities.url,
    phone_entities.number AS original_number,
    extracted_numbers.number AS standardised_number
  FROM
    phone_entities,
    UNNEST(`functions.extract_phone_numbers`(number)) AS extracted_numbers ),
  -- Unique lines of page content, to avoid unnecessary calls to the
  -- libphonenumber function, which is slow.
  lines AS (
  SELECT
    DISTINCT url,
    line
  FROM
    `content.lines` ),
  -- Phone numbers in page content, detected by libphonenumber
  content AS (
  SELECT
    lines.url,
    extracted_numbers.text AS original_number,
    extracted_numbers.number AS standardised_number
  FROM
    lines,
    UNNEST(`functions.extract_phone_numbers`(line)) AS extracted_numbers ),
  -- Combine them all and remove duplicates.
  combined AS (
  SELECT
    *
  FROM
    contacts
  UNION ALL
  SELECT
    *
  FROM
    entities
  UNION ALL
  SELECT
    *
  FROM
    content )
SELECT
  DISTINCT url,
  original_number,
  standardised_number
FROM
  combined;
