-- Call a sequence of routines that process updated documents from the
-- Publishing API database.

-- Fetch new editions
CALL functions.publishing_api_editions_current();

-- Update the public table of unpublishings.
CALL functions.publishing_api_unpublishings_current();

-- Extract content markup, render GovSpeak to HTML when necessary, and then
-- extract plain text and various tags.
CALL functions.extract_content_from_editions();
