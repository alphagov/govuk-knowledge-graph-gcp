-- Call a sequence of routines that process updated documents from the
-- Publishing API database.

-- Fetch new editions
CALL functions.publishing_api_editions_current();

-- Extract content markup, and render GovSpeak to HTML when necessary.
CALL functions.extract_markup();
