# BigQuery Remote Function to call Cloud DLP (Data Loss Prevention)

A BigQuery remote function to remove/mask/whatever PII by calling Cloud DLP.  It automatically batches to meet the API's data size limit, so that the user doesn't have to.

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

## Pricing

https://cloud.google.com/sensitive-data-protection/pricing#content-methods-pricing

I think the DLP component will cost less than $10 per year, which is less than 3GB of data.

## Alternatives

There's a [Dataflow template](https://cloud.google.com/dataflow/docs/guides/templates/provided/dlp-text-to-bigquery), but it doesn't handle the API's data size limit gracefully. It asks the user to choose a batch size (in rowsrather than bytes) and doesn't check that the byte limit is met. A [BigQuery Remote Function](https://cloud.google.com/sensitive-data-protection/docs/deidentify-bq-tutorial) in Cloud Run has the same problem.

## Deidentify config

```
info_types = [
    "DATE_OF_BIRTH",
    "EMAIL_ADDRESS",
    "PASSPORT",
    "PERSON_NAME",
    "PHONE_NUMBER",
    "STREET_ADDRESS",
    "UK_NATIONAL_INSURANCE_NUMBER",
    "UK_PASSPORT",
    "CREDIT_CARD_NUMBER",
    "IBAN_CODE",
    "IP_ADDRESS",
    "MEDICAL_TERM",
    "VEHICLE_IDENTIFICATION_NUMBER",
    "SCOTLAND_COMMUNITY_HEALTH_INDEX_NUMBER",
    "UK_DRIVERS_LICENSE_NUMBER",
    "UK_NATIONAL_HEALTH_SERVICE_NUMBER",
    "UK_TAXPAYER_REFERENCE",
    "SWIFT_CODE",
]
```

```
def inspect_config(
    dlp_info_types: List,
    min_likelihood: str = "LIKELY",
    include_quote: bool = True,
    max_findings: int = 0,
) -> dict:
    """Create an inspection config to define inspection sensitivity."""
    print("Build DLP inspect config")
    return {
        "info_types": list(map(lambda info_type: {"name": info_type}, dlp_info_types)),
        "min_likelihood": min_likelihood,
        "include_quote": include_quote,
        "limits": {"max_findings_per_request": max_findings},
    }
```

```
def deidentify_config(dlp_info_types: List) -> dict:
    """Build a config specifying info types to be parsed by deidentify."""
    print("Build DLP deidentify config")
    deidentify_replace_transformations = []

    for info_type_name in dlp_info_types:
        deidentify_replace_transformations.append(
            {
                "info_types": [{"name": info_type_name}],
                "primitive_transformation": {
                    "replace_config": {
                        "new_value": {"string_value": f"[{info_type_name}]"}
                    }
                },
            }
        )

    return {
        "info_type_transformations": {
            "transformations": deidentify_replace_transformations
        }
    }
```

```
def remove_profanity(
    strip_whitespace: pd.Series, profanity_list_path: pathlib.Path
) -> pd.Series:
    """Remove profanity using profanity input file at a specified path."""
    print("Remove profanity")
    with open(profanity_list_path) as f:
        lines = f.readlines()
        lines = [line.strip() for line in lines]
    profanity.load_censor_words(lines)
    return strip_whitespace.apply(profanity.censor)

```

### A Ruby DLP request, including the deidentify_config

```ruby
{parent: "projects/govuk-knowledge-graph-dev/locations/europe-west2",
 deidentify_config: {info_type_transformations: {transformations: [{info_types: [{name: "PHONE_NUMBER"}], primitive_transformation: {replace_with_info_type_config: {}}}]}},
 inspect_config: {info_types: [{name: "PHONE_NUMBER"}], include_quote: true},
 item: {value: "my number is 01234567890"}}
```

```json
{
  "parent": "projects/govuk-knowledge-graph-dev/locations/europe-west2",
  "deidentify_config": {
    "info_type_transformations": {
      "transformations": [
        {
          "info_types": [
            {
              "name": "PHONE_NUMBER"
            }
          ],
          "primitive_transformation": {
            "replace_with_info_type_config": {}
          }
        }
      ]
    }
  },
  "inspect_config": {
    "info_types": [
      {
        "name": "PHONE_NUMBER"
      }
    ],
    "include_quote": true
  },
  "item": {
    "value": "my number is 01234567890"
  }
}
```
