TRUNCATE TABLE public.mainstream_browse;
INSERT INTO public.mainstream_browse
WITH
browse_pages AS (
  SELECT *
  FROM `public.publishing_api_editions_current`
  WHERE schema_name = 'mainstream_browse_page'
),
links AS (
  SELECT *
  FROM `public.publishing_api_links_current`
  WHERE type IN ('top_level_browse_pages', 'second_level_browse_pages', 'mainstream_browse_pages')
),
editions AS (
  SELECT
    id,
    content_id
  FROM public.publishing_api_editions_current
  WHERE schema_name NOT IN ('gone', 'redirect')
),
root AS (
  SELECT
    id AS edition_id,
    '/browse' AS base_path,
    id AS parent_edition_id,
    '/browse' AS parent_base_path,
    1 AS level,
    [STRUCT(id AS edition_id, '/browse' AS base_path, 1 AS level)] AS ancestors
  FROM browse_pages
  WHERE base_path = '/browse'
),
top_level_browse_pages AS (
  SELECT
    links.target_edition_id AS edition_id,
    links.target_base_path AS base_path,
    root.edition_id AS parent_edition_id,
    root.base_path AS parent_base_path,
    2 AS level,
    ARRAY_CONCAT(
      root.ancestors,
      [STRUCT(
        links.target_edition_id AS edition_id,
        links.target_base_path AS target_base_path,
        2 AS level
      )]
    ) AS ancestors
  FROM links
  INNER JOIN root ON root.edition_id = links.source_edition_id
  INNER JOIN editions ON editions.id = links.target_edition_id
  WHERE links.type = 'top_level_browse_pages'
),
second_level_browse_pages AS (
  SELECT
    links.target_edition_id AS edition_id,
    links.target_base_path AS base_path,
    top_level_browse_pages.edition_id AS parent_edition_id,
    top_level_browse_pages.base_path AS parent_base_path,
    3 AS level,
    ARRAY_CONCAT(
      top_level_browse_pages.ancestors,
      [STRUCT(
        links.target_edition_id AS edition_id,
        links.target_base_path AS target_base_path,
        3 AS level
      )]
    ) AS ancestors
  FROM links
  INNER JOIN top_level_browse_pages ON top_level_browse_pages.edition_id = links.source_edition_id
  INNER JOIN editions ON editions.id = links.target_edition_id
  WHERE links.type = 'second_level_browse_pages'
),
leaves AS (
  SELECT
    links.source_edition_id AS edition_id,
    links.source_base_path AS base_path,
    second_level_browse_pages.edition_id AS parent_edition_id,
    second_level_browse_pages.base_path AS parent_base_path,
    4 AS level,
    second_level_browse_pages.ancestors
  FROM links
  INNER JOIN editions ON editions.id = links.source_edition_id
  INNER JOIN second_level_browse_pages ON second_level_browse_pages.edition_id = links.target_edition_id
  WHERE links.type = 'mainstream_browse_pages'
),
group_links AS (
  SELECT
    browse_pages.id AS source_edition_id,
    editions.id AS target_edition_id,
    group_index,
    JSON_VALUE(link_groups, "$.name") AS group_name,
    page_index
  FROM browse_pages
  INNER JOIN second_level_browse_pages ON second_level_browse_pages.edition_id = browse_pages.id
  CROSS JOIN UNNEST(JSON_QUERY_ARRAY(details, "$.groups")) AS link_groups WITH OFFSET AS group_index
  CROSS JOIN UNNEST(JSON_VALUE_ARRAY(link_groups, "$.content_ids")) AS group_content_ids WITH OFFSET AS page_index
  LEFT JOIN editions ON editions.content_id = group_content_ids
),
all_pages AS (
  SELECT * FROM root
  UNION ALL SELECT * FROM top_level_browse_pages
  UNION ALL SELECT * FROM second_level_browse_pages
  UNION ALL SELECT * FROM leaves
)
SELECT
  all_pages.*,
  group_links.group_index,
  group_links.group_name,
  group_links.page_index
FROM all_pages
LEFT JOIN group_links ON group_links.source_edition_id = all_pages.parent_edition_id AND group_links.target_edition_id = all_pages.edition_id
