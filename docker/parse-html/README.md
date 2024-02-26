# BigQuery Remote Function to Parse HTML

A function to parse a string of HTML passed in by BigQuery, and return things
extracted from the HTML, in the form that BigQuery expects (JSON).

* `text`: plain text extracted from the HTML, as though rendered by a browser.
* `lines`: the plain text as an array of individual lines of text.
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

## Concurrency

The function must allow for simultaneous invocations, which would suggest
declaring a browser instance locally, and discarding it at the end of each
invocation.  But that would be incredibly slow, so it is declared globally, and
a filesystem lock is used as a mutex, to prevent multiple invocations changing
the browser state at the same time, and interfering with each other.  The
function is also specified in terraform as having
`max_instance_request_concurrency = 1`, which ought to prevent an instance being
sent more than one request at once.

A particular SQL query was found to be useful in debugging this. It is somewhat
magical, in that it seems to force BigQuery to call the function in such a way
that any possible interference occurs.  It is correct when the results of the
`text` column are `"foo"` and `"bar"` every time the query is run.

```sql
WITH
  dummy AS (
  SELECT
    'foo' AS html
  UNION ALL
  SELECT
    'bar' AS html
    ),
  extracted AS (
  SELECT
    html,
    functions.parse_html(html,
      '') AS extracted_content
  FROM
    dummy )
SELECT
  html,
  extracted_content, -- This makes the results chaotic
  extracted_content.text
FROM
  extracted
;
```

## How to add features

More things can be extracted from HTML by adding code to the `app.rb` script in
the function `parse_html()` beneath the comment `# TODO: extract other things
from the HTML`.

## Alternatives

We previously [implemented](https://github.com/alphagov/govuk-knowledge-graph-gcp/pull/292/commits/6b15dd683f14a84d6cad1e904715280d76a343db) this in a virtual machine, using w3m to parse the HTML, Python to call w3m, gnu-parallel to handle parallelisation, and a Makefile to coordinate everything.

This had the following disadvantages.

* Inaccessible to ad hoc tasks
* Complex to scale
* Difficult to test
* Relatively slow (several minutes to process the Content Store)
