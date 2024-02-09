TRUNCATE TABLE search.document_type;
INSERT INTO search.document_type
SELECT DISTINCT document_type.document_type
FROM content.document_type
