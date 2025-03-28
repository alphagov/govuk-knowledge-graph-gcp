# Decision record: Consume the Smart Survey API

## Context

Page on GOV.UK link to a feedback survey that is hosted by Smart Survey. Responses to the survey are only available via the Smart Survey API, not by direct access to a database. There is a need for the survey responses to be available in BigQuery. Batch updates would suffice; streaming updates are not required.

Please refer to the API documentation:

* [Overview](https://docs.smartsurvey.io/docs/getting-started)
* [Endpoint: `get-responses`](https://docs.smartsurvey.io/v1/reference/get-responses)

### 1. Workflow to BigQuery via a bucket (chosen)

Schedule a nightly Workflow to:

1. Fetch survey responses from the previous day
2. Write them to a bucket object with a random name.
3. Run a BigQuery job (a query), to fetch the responses directly from the bucket, via a "temporary external table", transform them, and append them to a permanent table.
4. Configure bucket objects to be automatically deleted after 24 hours.

Allow the job to be executed ad hoc to fetch responses from a given day, for the sake of backfilling.

## Consequences

### Positive consequences

* Cheap to run (see "Running costs" below)
* Easy to maintain (no programming language or its dependencies)

#### Running costs

The running costs of the workflow will probably be a few pence per day. It is priced per step that is executed.

Each API would cost five steps, because of the way that Workflows implement for-loops and try-retry-except blocks.

1. Begin a for-loop iteration
2. Enter a "try-retry-except" block
3. Begin a "try"
4. Call the Smart Survey API (an "external" step)
5. Send the API response to a bucket (an "internal" step)

On one recent day there were 50k survey responses. Responses can be fetched in batches of 100, so there would be 50k/100 = 500 API calls. Each call would cost 4 internal steps and 1 external step, so 500*4 = 2000 internal steps and 500 external steps. The price of 1000 internal steps is \$0.01. The price of 1000 external steps is \$0.025. The total cost would be 2*\$0.01 + 0.5*\$0.025 = \$0.0325 per day, plus a trivial amount for steps that initialise the API calls, and process the accumulated API responses.

### Negative consequences

None yet known. Please suggest any.

## Alternatives that were considered

### 1. Workflow to BigQuery directly

The only way to load data directly into BigQuery from a workflow is by using `googleapis.bigquery.v2.tabledata.insertAll`, which puts records into a streaming buffer, where they remain for an unpredictable amount of time. This makes it difficult to guarantee that subsequent steps would operate on all the new data. Records can usually be read immediately, while still in the buffer, but this is not guaranteed. Records that remain in the buffer cannot be deleted.

Some unsatisfactory workarounds:

1. Wait an arbitrary time before using the BigQuery table, and hope that the buffer had emptied by then.
1. Poll the streaming buffer until it is empty, before using the BigQuery table. This risks the polling function timing out.
1. Accumulate data into the table daily, and always check the entire table for new records to be processed. This would get increasingly expensive and slow.
1. Only delete records from the table that have been processed into downstream tables. Deletions fail when records remain in the buffer, so this workaround only moves the problem elsewhere.

### 2. Workflow to BigQuery via a bucket and a `bq load` job

This was previously done with data from other sources, and was reliable and easily maintained. The `bq load` step is redundant, however, given that data can be queried directly from the bucket. There is no need for these records to be in a permanent table in their raw form.

### 3. Cloud Run/Function

Feedback-as-a-Service currently uses a Cloud Run Function to fetch data the Smart Survey API. It seems wasteful to develop and maintain everything that that requires (infra, script, dependencies, dependabot), when a workflow could do the same job.

## Workflow-in-progress

This is a partial implementation of the proposed Workflow.

```yaml
- init:
    assign:
      - project_id: ${sys.get_env("GOOGLE_CLOUD_PROJECT_ID")}
      - token_secret_id: "SMART_SURVEY_API_TOKEN"
      - key_secret_id: "SMART_SURVEY_API_SECRET"
      - api_endpoint: "secret?"
      - completed: 1 # 0=Partial, 1=Completed, 2=Both
      - page_size: 1 # Defaults to 10, max is 100. The number of records is not guaranteed to be the number specified as visibility rules may filter out items.
      - sort_by: "date_started"
      - filter_id: 0
      - include_labels: true
        # TODO: default "since" and "until" to yesterday
      - since: 1742947200
      - until: 1743033599

- fetch_token:
    call: googleapis.secretmanager.v1.projects.secrets.versions.accessString
    args:
      secret_id: ${token_secret_id}
      project_id: ${project_id}
    result: str_token

- fetch_key:
    call: googleapis.secretmanager.v1.projects.secrets.versions.accessString
    args:
      secret_id: ${key_secret_id}
    result: str_key

- build_headers:
    assign:
      - auth_str: ${str_token + ":" + str_key}
      - auth_str_base64: ${"Basic " + base64.encode(text.encode(auth_str, "UTF-8"))}

# Call the API solely for the header that says how many results there will be.
- first_call:
    try:
      call: http.get
      args:
        url: ${api_endpoint}
        query:
          since: ${since}
          until: ${until}
          filter_id: ${filter_id}
          completed: ${completed}
          page: 1
          page_size: 0
          sort_by: ${sort_by}
          include_labels: ${include_labels}
        headers:
          "Authorization": ${auth_str_base64}
      result: api_response
    # Retry on 429 (Too Many Requests), 502 (Bad Gateway), 503 (Service
    # unavailable), and 504 (Gateway Timeout), as well as on any
    # ConnectionError, ConnectionFailedError and TimeoutError. Maximum retries
    # (excluding first try): 5 Initial backoff 1 second, maximum backoff 1
    # minute, multiplier 1.25.
    retry: ${http.default_retry}

# Calculate how many pages of page_size would fetch all the results.
- calculate_page_range:
    assign:
    - pagination_total: ${int(api_response.headers["X-Ss-Pagination-Total"])}
    - max_page: ${pagination_total // page_size + 1}

# Iteratively fetch each page of results and send to BigQuery
- iterative_calls:
    for:
        value: page
        range: ${[1, max_page]}
        steps:

          - iterative_call:
              try:
                call: http.get
                args:
                  url: ${api_endpoint}
                  query:
                    since: ${since}
                    until: ${until}
                    filter_id: ${filter_id}
                    completed: ${completed}
                    page: ${page}
                    page_size: ${page_size}
                    sort_by: ${sort_by}
                    include_labels: ${include_labels}
                  headers:
                    "Authorization": ${auth_str_base64}
                result: api_response
              # Retry on 429 (Too Many Requests), 502 (Bad Gateway), 503 (Service
              # unavailable), and 504 (Gateway Timeout), as well as on any
              # ConnectionError, ConnectionFailedError and TimeoutError. Maximum retries
              # (excluding first try): 5 Initial backoff 1 second, maximum backoff 1
              # minute, multiplier 1.25.
              retry: ${http.default_retry}
        # TODO: Append the API response to a bucket object

# TODO: Query the bucket object from BigQuery, reshape it, and append it to a table.

# Finish
- return_something:
    return: "Finished"
```
