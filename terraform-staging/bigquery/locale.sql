TRUNCATE TABLE search.locale;
INSERT INTO search.locale
SELECT DISTINCT locale.locale
FROM content.locale
