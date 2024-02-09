-- Table of things on GOV.UK, and the type of thing that they are
TRUNCATE TABLE search.thing;
INSERT INTO search.thing
SELECT 'Person' AS type, title AS name
FROM graph.person
UNION ALL
SELECT 'Organisation' AS type, title AS name
FROM graph.organisation
UNION ALL
SELECT 'Role' AS type, title AS name
FROM graph.role
UNION ALL
SELECT
    'Taxon' AS type,
    /*
    Title is preferred to internal name because it is typically of better
    quality; internal name should be used if title is not unique / repeated.
    */
    CASE WHEN
        COUNT(taxon.title) OVER (PARTITION BY taxon.title) = 1 THEN taxon.title
        ELSE COALESCE(taxon.internal_name, taxon.title)
    END AS name
FROM graph.taxon
UNION ALL
SELECT 'Transaction' AS type, title AS name
FROM graph.page
WHERE document_type = 'transaction' AND
/* Exclude "alpha" (depcrecated) taxons */
phase != "alpha"
UNION ALL
SELECT DISTINCT 'AbbreviationText' AS type, abbreviation_text AS name
FROM content.abbreviations
UNION ALL
SELECT DISTINCT 'AbbreviationTitle' AS type, abbreviation_title AS name
FROM content.abbreviations
