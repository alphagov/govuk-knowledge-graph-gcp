TRUNCATE TABLE search.link;
INSERT INTO search.link
SELECT
  embedded_links.link_url AS to_url,
  title_to.title AS to_title,
  ARRAY_AGG(STRUCT(
    embedded_links.url AS from_url,
    title_from.title AS from_title,
    embedded_links.link_text AS link_text
  )) AS links
FROM content.embedded_links
LEFT JOIN content.title AS title_from ON (title_from.url = embedded_links.url)
LEFT JOIN content.title AS title_to ON (title_to.url = link_url_bare)
GROUP BY
  embedded_links.link_url,
  title_to.title
;
