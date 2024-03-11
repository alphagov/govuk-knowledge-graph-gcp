-- Recreate the legacy graph.is_tagged_to table from the 'public' dataset

TRUNCATE TABLE graph.is_tagged_to;
INSERT INTO graph.is_tagged_to
SELECT
  "https://www.gov.uk/" || sources.content_id AS url,
  "https://www.gov.uk/" || targets.content_id AS taxon_url
FROM public.taxonomy
INNER JOIN public.publishing_api_links_current AS links ON (links.target_edition_id = taxonomy.edition_id)
INNER JOIN public.publishing_api_editions_current AS sources ON (sources.id = links.source_edition_id)
INNER JOIN public.publishing_api_editions_current AS targets ON (targets.id = links.target_edition_id)
WHERE links.type = 'taxons'
;
