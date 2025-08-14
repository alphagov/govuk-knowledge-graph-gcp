# Cloud Run HTTP service to call APIs without memory limits

From a GCP workflow, call this function instead of directly sending GET requests to an API. The API response will be stored in a Cloud Storage bucket, rather than be returned to the workflow. Workflows have very limited memory (512KB for all variables put together, in April 2025), so a large response would cause the workflow to fail hard.

## Inputs

* `endpoint_url` The endpoint of the API.
* `headers` (optional) string, e.g. `key1: value1\r\nkey2: value2`. Used in the API call. Can be used to authenticate with the API endpint via Basic Auth.
* `project_id` of the bucket to store the API's response. Not used in the API call.
* `bucket_name` to store the API's response. Not used in the API call.
* `object_name` to store the API's response. Not used in the API call.
* `jmespath` (optional) assuming that the API responds with JSON, this JMESPath command will be applied to it before it sent to the Cloud Storage bucket. Not used in the API call.
* any other parameters will be used in the API call, e.g. `page`, `page_size`.

### Authenticating to an API endpoint external to GCP

Use the `headers`, according to the API's documentation.

### Authenticating to a GCP REST API endpoint

1. Grant permission to a service account to use the API endpoint.
2. Fetch an access token for that service account.
3. Send the access token in the `headers`.

The example below uses the service account of the workflow itself to call the BigQuery REST API.

```yaml
main:
  steps:
    - init:
        assign:
          - service_account_email: ${text.split(sys.get_env("GOOGLE_CLOUD_SERVICE_ACCOUNT_NAME"), "/")[3]}
          - scopes:
              - "https://www.googleapis.com/auth/cloud-platform"
              - "https://www.googleapis.com/auth/bigquery"
          - bucket_name: some-bucket
          - workflow_execution_id: ${sys.get_env("GOOGLE_CLOUD_WORKFLOW_EXECUTION_ID")}
          - project_id: ${sys.get_env("GOOGLE_CLOUD_PROJECT_ID")}
    - generate_token:
        call: http.post
        args:
          url: ${"https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/" + service_account_email + ":generateAccessToken"}
          auth:
            type: OAuth2
          body:
            scope: ${scopes}
        result: token_response
    - build_bearer_token_header:
        assign:
          - bearer_token: '${"Authorization: Bearer " + token_response.body.accessToken}'
    - call_an_api_endpoint:
        try:
          call: http.get
          args:
            url: https://http-to-bucket-7zajlqdj6q-nw.a.run.app
            query:
              endpoint_url: "https://storage.googleapis.com/storage/v1/b?project=some-project"
              headers: "${bearer_token}"
              project: "some-project"
              project_id: "some-project"
              bucket_name: "some-bucket"
              object_name: ${workflow_execution_id}
            auth:
                type: OIDC
          result: api_response
        # Retry on 429 (Too Many Requests), 502 (Bad Gateway), 503 (Service
        # unavailable), and 504 (Gateway Timeout), as well as on any
        # ConnectionError, ConnectionFailedError and TimeoutError. Maximum retries
        # (excluding first try): 5 Initial backoff 1 second, maximum backoff 1
        # minute, multiplier 1.25.
        retry: ${http.default_retry}
```

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
