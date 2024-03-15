# `govspeak-to-html` Cloud Function

A BigQuery remote function to use the [govspeak](https://github.com/alphagov/govspeak) Ruby gem to render govspeak to HTML.  It's easier to extract subsets of content from the HTML representation than from govspeak, because there are better parsers available, such as nokogiri.

Most GOV.UK content is composed in govspeak.  It isn't necessarily rendered to HTML until the Publishing API sends it to the Content API, and the HTML representation usually isn't stored in the Publishing API database.
