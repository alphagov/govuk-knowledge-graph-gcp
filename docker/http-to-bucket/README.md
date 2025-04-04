# Cloud Run HTTP service to call APIs without memory limits

From a GCP workflow, call this function instead of directly sending GET requests to an API. The API response will be stored in a Cloud Storage bucket, rather than be returned to the workflow, because a large response might cause the workflow to fail hard by overwhelming its very limited memory (512KB for variables in April 2025).

## Inputs

* `url` The endpoint of the API
* `params` Three parameters to identify a Cloud Storage object to store the API's response: `project_id`, `bucket_name` and `object_name`. Any other parameters will be used when calling the API, e.g. `page`, `page_size`.
* `headers` Will be used when calling the API, such as for authentication via Basic Auth.

## Outputs

* `code` The HTTP response code, such as `200` for a success.
* `headers` The HTTP response headers.
* `body` The media URL of the Cloud Storage object that was created/overwritten, if successful. If unsuccessful, then the body of the HTTP response, describing the error.

## Not a Cloud Run Function

This is a Cloud Run service, not a Cloud Run function. Cloud Run functions are supposedly easier to use than Cloud Run services, but experience shows that Terraform doesn't deal well with them.

## Goals

* DO fetch arbitrary API responses and store them in a bucket, without running out of memory. A Workflow might run out of memory.
* DON'T orchestrate the fetching of API responses, for fear of running out of time. A Workflow won't run out of time.

## Tests

We use RSpec and a [GitHub
Action](https://github.com/alphagov/govuk-knowledge-graph-gcp/actions/workflows/ruby-lint-and-test.yml),
and `functions_framework`, which is Google's standard framework for testing
BigQuery remote functions.

```sh
cd docker/http-to-bucket
rspec
```
