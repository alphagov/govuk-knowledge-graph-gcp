# BigQuery Remote Function to Parse HTML

A function to parse a string of HTML passed in by BigQuery, and return things
extracted from the HTML, in the form that BigQuery expects (JSON).

* `hyperlinks`: an array of objects that describe hyperlinks (their URL, a
  cleaned-up version of their URL, and the text that they display).
* `abbreviations`: an array of objects that describe abbreviations (the
  abbreviation, and the thing that is abbreviated).

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

## Goals

* Parse each HTML string only once, and extract several things from it. This
  lowers our BigQuery costs, which charge for the amount of data consumbed by
  each query, so if we parse the same HTML several times in different queries,
  then we are charged several times.
* Be available to BigQuery so that we can compose the entire data pipeline in
  SQL, where it is easier to test with frameworks such as DBT and SQLMesh.

## Tests

We use RSpec and a [GitHub
Action](https://github.com/alphagov/govuk-knowledge-graph-gcp/actions/workflows/ruby-lint-and-test.yml),
and `functions_framework`, which is Google's standard framework for testing
BigQuery remote functions.

```sh
cd docker/parse-html
rspec
```

## How to add features

More things can be extracted from HTML by adding code to the `app.rb` script in
the function `parse_html()` beneath the comment `# TODO: extract other things
from the HTML`.
