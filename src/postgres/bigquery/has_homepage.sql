-- Link to home pages of roles that have base_paths
-- Assume that the graph.has_homepage table was already emptied of old data by
-- the mongodb data pipeline.
INSERT INTO graph.has_homepage
SELECT
  role_homepage_url.url,
  role_homepage_url.homepage_url
FROM content.role_homepage_url AS role_homepage_url
;
