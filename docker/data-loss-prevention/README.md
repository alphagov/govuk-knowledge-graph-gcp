# BigQuery Remote Function to call Cloud DLP (Data Loss Prevention)

1. A Cloud Run service remove/mask/whatever PII from a text string by calling Cloud DLP. This is designed to be used only from BigQuery, because it assumes that the request is an array of table rows.
2. A BigQuery remote function called `functions.data_loss_prevention()`, which wraps the Cloud Run service.
3. A BigQuery custom function called `functions.mask_pii()`, which wraps the  `functions.data_loss_prevention()` function. This function hardcodes an `inspect_config` and `deidentify_config` (which have been used for a few years for masking PII in feedback), and truncates the input string to the maximum number of bytes supported by the DLP API.

Users are expected to call `function.mask_pii()` most often. If a different `inspect_config` and `deidentify_config` are required, then `functions.data_loss_prevention()` can be called directly.

## BigQuery Remote Functions

BigQuery supports various kinds of custom function, depending on whether it can be implemented in

* pure SQL
* or a programming language that is supported by Cloud Functions v2, and that doesn't have any particular system requirements
* or a fully customised system, in Docker, hosted in Cloud Run.

We can't do this in pure SQL. We can do it in Ruby without any system dependencies, but there are [difficulties](https://github.com/alphagov/govuk-knowledge-graph-gcp/issues/749) terraforming Cloud Functions. so we implement this in Cloud Run.

## Pricing

https://cloud.google.com/sensitive-data-protection/pricing#content-methods-pricing

The DLP component is expected to cost less than $10 per year to process data from Smart Survey and the Support API, which are less than 3GB of data altogether.

## Alternatives

There's a [Dataflow template](https://cloud.google.com/dataflow/docs/guides/templates/provided/dlp-text-to-bigquery), but it doesn't handle the API's data size limit gracefully. It asks the user to choose a batch size (in rowsrather than bytes) and doesn't check that the byte limit is met. A [BigQuery Remote Function](https://cloud.google.com/sensitive-data-protection/docs/deidentify-bq-tutorial) in Cloud Run has the same problem.

## Example deidentify config

```
inspect_config = {
  "info_types": [
    { "name": "DATE_OF_BIRTH" },
    { "name": "EMAIL_ADDRESS" },
    { "name": "PASSPORT" },
    { "name": "PERSON_NAME" },
    { "name": "PHONE_NUMBER" },
    { "name": "STREET_ADDRESS" },
    { "name": "UK_NATIONAL_INSURANCE_NUMBER" },
    { "name": "UK_PASSPORT" },
    { "name": "CREDIT_CARD_NUMBER" },
    { "name": "IBAN_CODE" },
    { "name": "IP_ADDRESS" },
    { "name": "MEDICAL_TERM" },
    { "name": "VEHICLE_IDENTIFICATION_NUMBER" },
    { "name": "SCOTLAND_COMMUNITY_HEALTH_INDEX_NUMBER" },
    { "name": "UK_DRIVERS_LICENSE_NUMBER" },
    { "name": "UK_NATIONAL_HEALTH_SERVICE_NUMBER" },
    { "name": "UK_TAXPAYER_REFERENCE" },
    { "name": "SWIFT_CODE" }
  ],
  "include_quote": true
}

deidentify_config = {
  "info_type_transformations": {
    "transformations": [
      {
        "info_types": [
          { "name": "DATE_OF_BIRTH" },
          { "name": "EMAIL_ADDRESS" },
          { "name": "PASSPORT" },
          { "name": "PERSON_NAME" },
          { "name": "PHONE_NUMBER" },
          { "name": "STREET_ADDRESS" },
          { "name": "UK_NATIONAL_INSURANCE_NUMBER" },
          { "name": "UK_PASSPORT" },
          { "name": "CREDIT_CARD_NUMBER" },
          { "name": "IBAN_CODE" },
          { "name": "IP_ADDRESS" },
          { "name": "MEDICAL_TERM" },
          { "name": "VEHICLE_IDENTIFICATION_NUMBER" },
          { "name": "SCOTLAND_COMMUNITY_HEALTH_INDEX_NUMBER" },
          { "name": "UK_DRIVERS_LICENSE_NUMBER" },
          { "name": "UK_NATIONAL_HEALTH_SERVICE_NUMBER" },
          { "name": "UK_TAXPAYER_REFERENCE" },
          { "name": "SWIFT_CODE" }
        ],
        "primitive_transformation": {
          "replace_with_info_type_config": {}
        }
      }
    ]
  }
}
```
## Testing

```sh
# An ennvironment variable is required, to be whichever project the tests are being run in.
export PROJECT_ID=govuk-knowledge-graph-dev
cd docker/data-loss-prevention
rspec
```
