# BigQuery Remote Function to embed text

A function to parse a short string of text passed in by BigQuery, and return an
embedding, in the form that BigQuery expects (JSON).

Strings up to a paragraph in length are suitable.

## BigQuery Remote Functions

BigQuery supports various kinds of custom function, depending on whether it can
be implemented in

* pure SQL
* or a programming language that is supported by Cloud Functions v2, and that
  doesn't have any particular system requirements
* or a fully customised system, in Docker, hosted in Cloud Run.

We need a fully customised system, because we need either access to the internet
to download the language model, or we need a local copy of the model (which
can't be installed by a language package manager). Hence we use the third
option, which is a Docker container hosted by Cloud Run.

## Why Python?

Because Ruby (GOV.UK's preferred language) isn't supported by Hugging Face
transformers, or by anything much.  The only alternatives are Python and NodeJS.
NodeJS is only partially supported by Hugging Face, and there are only a couple
of NodeJS repositories in GOV.UK, whereas Python is used by all of data.gov.uk
and many data science repositories.

## Tests

We use pytest and a [GitHub
Action](https://github.com/alphagov/govuk-knowledge-graph-gcp/actions/workflows/ruby-lint-and-test.yml).

```sh
cd docker/parse-html
# Set up a python environment
pytest
```

## Alternatives

We tried implementing this within the `parse_html()` function, but it seemed to
be impossible to build the docker container correctly.  It's also useful to have
a separate function, so that we can embed a semantic search query without
pretending to parse a whole chunk of HTML.
