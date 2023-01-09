-- Derive external page nodes
DELETE graph.external_page WHERE TRUE;
INSERT INTO graph.external_page
SELECT url
FROM graph.page
WHERE left(url, 18) <> "https://www.gov.uk"
;
-- Remove external pages from the table of page nodes
DELETE graph.page
WHERE EXISTS (
  SELECT url
  FROM graph.external_page
  WHERE external_page.url = page.url
)
;
