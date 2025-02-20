# BigQuery Remote Function to render Govspeak to HTML

A BigQuery remote function to use the [govspeak](https://github.com/alphagov/govspeak) Ruby gem to render govspeak to HTML.  It's easier to extract subsets of content from the HTML representation than from govspeak, because there are better parsers available, such as nokogiri.

Most GOV.UK content is composed in govspeak.  It isn't necessarily rendered to HTML until the Publishing API sends it to the Content API, and the HTML representation usually isn't stored in the Publishing API database.

## BigQuery Remote Functions

BigQuery supports various kinds of custom function, depending on whether it can
be implemented in

* pure SQL
* or a programming language that is supported by Cloud Functions v2, and that
  doesn't have any particular system requirements
* or a fully customised system, in Docker, hosted in Cloud Run.

We can't do this in pure SQL. We can do it in Ruby without any system
dependencies, but there are
[difficulties](https://github.com/alphagov/govuk-knowledge-graph-gcp/issues/749)
terraforming Cloud Functions. so we implement this in Cloud Run.

## Tests

https://github.com/alphagov/govuk-knowledge-graph-gcp/issues/732.
