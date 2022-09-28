SELECT
  url,
  details::json#>>'{whip_organisation,label}' AS whip_organisation
FROM roles_details
WHERE details::json#>>'{whip_organisation,label}'  IS NOT NULL
;
