# Cloud Run HTTP service to call APIs without memory limits

From a GCP workflow, call this function instead of directly sending GET requests to an API. The API response will be stored in a Cloud Storage bucket, rather than be returned to the workflow. Workflows have very limited memory (512KB for all variables put together, in April 2025), so a large response would cause the workflow to fail hard.

## Inputs

* `url` The endpoint of the API.
* `params` Three parameters to identify a Cloud Storage object to store the API's response: `project_id`, `bucket_name` and `object_name`. If the API request requires any headers, such as for authentication via Basic Auth, include them as a parameter called `headers`, formatted as a string of `key1: value1\r\nkey2: value2`. Any other parameters will be included in the call to the API, e.g. `page`, `page_size`.

## Outputs

An HTTP response, coded 200 for a success, or 500 for a failure. If there isn't enough information available in the response, then check the logs.

## Not a Cloud Run Function

This is a Cloud Run service, not a Cloud Run function. Cloud Run functions are supposedly easier to use than Cloud Run services, but experience shows that Terraform doesn't deal well with them.

## Goals

* DO fetch arbitrary API responses and store them in a bucket, without running out of memory. A Workflow might run out of memory.
* DON'T orchestrate the fetching of API responses, for fear of running out of time. A Workflow won't run out of time.

## Tests

Not intended to be run automatically, because the real API is called, and real data is uploaded into a bucket.

We use RSpec and a [GitHub
Action](https://github.com/alphagov/govuk-knowledge-graph-gcp/actions/workflows/ruby-lint-and-test.yml),
and `functions_framework`, which is Google's standard framework for testing
BigQuery remote functions.

```sh
cd docker/http-to-bucket
export PROJECT_ID="govuk-knowledge-graph-dev"
rspec
```

There is only one test, which tests the end-to-end function, by interacting with the real API, and uploading real data into a bucket. Delete the data manually, or allow it to expire.
