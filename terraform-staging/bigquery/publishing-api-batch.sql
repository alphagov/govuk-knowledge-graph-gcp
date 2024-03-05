-- Call a sequence of routines that process updated documents from the
-- Publishing API database.

-- Fetch new editions
CALL functions.publishing_api_editions_current();

-- Update the public table of links.
CALL functions.publishing_api_links_current();

-- Update the public table of unpublishings.
CALL functions.publishing_api_unpublishings_current();

-- Extract content markup, render GovSpeak to HTML when necessary, and then
-- extract plain text and various tags.
CALL functions.extract_content_from_editions();

-- Update the public table of phone numbers extracted from 'contact' documents.
CALL functions.contact_phone_numbers();

-- Update the public table of phone numbers extracted from content.
CALL functions.phone_numbers();

-- Update the public table of the taxonomy.
CALL functions.taxonomy();
