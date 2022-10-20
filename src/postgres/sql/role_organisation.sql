SELECT
  link_sets.content_id AS organisation_content_id,
  links.target_content_id AS role_content_id
FROM links
INNER JOIN link_sets ON link_sets.id = links.link_set_id
WHERE links.link_type = 'ordered_roles'
;
