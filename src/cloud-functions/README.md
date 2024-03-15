# Cloud functions

The functions in this directory are used as BigQuery remote functions.  Various SQL queries call these functions.

BigQuery remote functions can be implemented as Cloud Functions or Cloud Run services.  The difference is that Cloud Functions don't support arbitrary system dependencies, whereas Cloud Run hosts any Docker image.  The functions in this directory don't require system dependencies.

## [`govspeak-to-html`](./govspeak-to-html)

Use the [govspeak](https://github.com/alphagov/govspeak) Ruby gem to render govspeak to HTML.

## [`parse-html`](./parse-html)

Extract various things out of the HTML representation of GOV.UK content, especially plain text and hyperlinks.
