-- Recreate the legacy graph.page table from the 'public' dataset

TRUNCATE TABLE graph.taxon;
INSERT INTO graph.taxon
SELECT
  'https://www.gov.uk/' || editions.content_id AS url,
  editions.title,
  JSON_VALUE(editions.details, "$.internal_name") AS internal_name,
  editions.description,
  editions.content_id,
  taxonomy.level
FROM
  public.taxonomy
INNER JOIN
  public.publishing_api_editions_current AS editions
ON
  editions.id = taxonomy.edition_id
;
