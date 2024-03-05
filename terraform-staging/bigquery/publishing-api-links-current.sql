-- The links table includes ones to documents or editions that are no longer
-- public. Those links shouldn't be made public.
TRUNCATE TABLE public.publishing_api_links_current;
INSERT INTO public.publishing_api_links_current
SELECT
  sources.id AS source_edition_id,
  targets.id AS target_edition_id,
  links.link_type AS type,
  links.position
FROM publishing_api.links
INNER JOIN public.publishing_api_editions_current AS sources
  ON (sources.id = links.edition_id)
INNER JOIN public.publishing_api_editions_current AS targets
  ON (targets.content_id = links.target_content_id)
UNION ALL
SELECT
  sources.id AS source_edition_id,
  targets.id AS target_edition_id,
  links.link_type AS type,
  links.position
FROM publishing_api.link_sets
  -- The link_sets table has the content_id of the source document.
  -- The links table has the content_id of the target document.
INNER JOIN publishing_api.links
  ON (links.link_set_id = link_sets.id)
INNER JOIN public.publishing_api_editions_current AS sources
  ON (sources.content_id = link_sets.content_id)
INNER JOIN public.publishing_api_editions_current AS targets
ON (targets.content_id = links.target_content_id)
