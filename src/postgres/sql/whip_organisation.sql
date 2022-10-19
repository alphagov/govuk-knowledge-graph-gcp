SELECT
  url,
  details::json#>>'{whip_organisation,label}' AS whip_organisation
FROM roles
WHERE details::json#>>'{whip_organisation,label}'  IS NOT NULL
;
