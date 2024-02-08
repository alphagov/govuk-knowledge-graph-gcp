SELECT
  CONCAT('https://www.gov.uk/', link_sets.content_id  ) AS organisation_url,
  CONCAT('https://www.gov.uk/', links.target_content_id ) AS role_url
FROM links
INNER JOIN link_sets ON link_sets.id = links.link_set_id
WHERE links.link_type = 'ordered_roles'
;
