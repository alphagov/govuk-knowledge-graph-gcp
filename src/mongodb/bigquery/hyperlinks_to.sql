-- Derive HYPERLINKS_TO relationships
-- coalesce() handles a handful of links that have malformed URLs, or empty link
-- text.
-- 1. Create table of relationships
-- 2. Create destination Page nodes that don't yet exist.
-- 3. Derive HYPERLINKS_TO relationships from expanded links

TRUNCATE TABLE graph.hyperlinks_to;

-- 1. Create table of relationships
INSERT INTO graph.hyperlinks_to
SELECT
  *
  EXCEPT (link_url_bare)
  REPLACE (
    COALESCE(link_url_bare, link_url, "") AS link_url,
    COALESCE(link_text, "") AS link_text
  )
FROM content.embedded_links
;

-- 2. Create destination Page nodes that don't yet exist.
INSERT INTO graph.page (url)
SELECT link_url AS url
FROM graph.hyperlinks_to
LEFT JOIN graph.page ON page.url = hyperlinks_to.link_url
WHERE page.url IS NULL
;

-- 3. Derive HYPERLINKS_TO relationships from expanded links
INSERT INTO graph.hyperlinks_to (count, url, link_url)
SELECT
  1 AS count,
  from_url AS url,
  to_url AS link_url
FROM content.expanded_links
WHERE expanded_links.link_type IN (
  'suggested_ordered_related_items',
  'ordered_related_items',
  'ordered_related_items_overrides'
)
;
