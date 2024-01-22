# BigQuery Remote Function to Parse HTML

A function to parse a string of HTML passed in by BigQuery, and return things
extracted from the HTML, in the form that BigQuery expects (JSON).

## BigQuery Remote Functions

BigQuery supports various kinds of custom function, depending on whether it can
be implemented in

* pure SQL
* or a programming language that is supported by Cloud Functions v2, and that
  doesn't have any particular system requirements
* or a fully customised system, in Docker, hosted in Cloud Run.

We need a fully customised system, because we use Selenium with Chromedriver to
parse the HTML, and those can't be installed as Ruby gems.  Hence we use the third option, which is a Docker container hosted by Cloud Run.

## Goals

* Parse each HTML string only once, and extract several things from it. This
  lowers our BigQuery costs, which charge for the amount of data consumbed by
  each query, so if we parse the same HTML several times in different queries,
  then we are charged several times.
* Extract plain text as it is rendered by a browser. This is why we use Selenium
  and Chromedriver, which is a real browser, rather than nokogiri or
  beautifulsoup. The main difference is the handling of newlines for `<h1>` and
  `<div>` elements, and literal newline characters.
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
from the HTML`. That function should be refactored, of course.

## Alternatives

We previously [implemented](https://github.com/alphagov/govuk-knowledge-graph-gcp/pull/292/commits/6b15dd683f14a84d6cad1e904715280d76a343db) this in a virtual machine, using w3m to parse the HTML, Python to call w3m, gnu-parallel to handle parallelisation, and a Makefile to coordinate everything.

This had the following disadvantages.

* Inaccessible to ad hoc tasks
* Complex to scale
* Difficult to test
* Relatively slow (several minutes to process the Content Store)
