USING PERIODIC COMMIT
LOAD CSV WITH HEADERS FROM 'file:///department_analytics_profile.csv' AS line
FIELDTERMINATOR ','
MATCH (p:Page { url: line.url })
SET p.departmentAnalyticsProfile = line.`details.department_analytics_profile`
;
