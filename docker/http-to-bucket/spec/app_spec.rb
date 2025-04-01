require "rspec"
require "functions_framework/testing"
require "base64"
require "google/cloud/secret_manager"

project_id = ENV['PROJECT_ID']
if !project_id
  puts "Please set an environment variable PROJECT_ID. For example:"
  puts "  export PROJECT_ID=govuk-knowledge-graph-dev"
  puts "Aborting."
  return
end

## Fetch secrets to authorise the API request
survey_id  = "smart-survey-api-survey-id"
api_secret_id  = "smart-survey-api-secret"
api_token_id  = "smart-survey-api-token"
version_id = "latest"

client = Google::Cloud::SecretManager.secret_manager_service

survey_id_name = client.secret_version_path(
  project:        project_id,
  secret:         survey_id,
  secret_version: version_id
)
api_token_name = client.secret_version_path(
  project:        project_id,
  secret:         api_token_id,
  secret_version: version_id
)
api_secret_name = client.secret_version_path(
  project:        project_id,
  secret:         api_secret_id,
  secret_version: version_id
)

survey_id = client.access_secret_version(name: survey_id_name).payload.data
api_token = client.access_secret_version(name: api_token_name).payload.data
api_secret = client.access_secret_version(name: api_secret_name).payload.data

endpoint_url = "https://api.smartsurvey.io/v1/surveys/#{survey_id}/responses"

auth_str = Base64.strict_encode64("#{api_token}:#{api_secret}")
headers = "Authorization: Basic #{auth_str}"

# Set some query parameters
params = {
  # Used within GcP to direct the API call its response
  "endpoint_url" => endpoint_url,
  "headers" => headers,
  "project_id" => project_id,
  "bucket_name" => "#{project_id}-smart-survey",
  "object_name" => "rspec-test",
  # External API query parameters
  "since" => 1744502400,
  "until" => 1744588799,
  "page" => 1,
  "page_size" => 100,
}

# Submit an http request, return an http response, with the body parsed into an
# array of JSON objects.
#
# @param body [array] of arrays, one array per call to the function, where each
# array has elements corresponding to the arguments of the function
# html_to_text().
def request(url, params = {})
  request = make_get_request url

  params.each do |key, value|
    request.update_param(key, value)
  end

  response = call_http "http_to_bucket", request
  response
end

describe "http_to_bucket() function" do
  include FunctionsFramework::Testing

  it "Uploads the API response to a bucket" do
    load_temporary "app.rb" do
      response = request("", params)
      puts response.body
      expect(response.status).to eq(200)
      expect(response.headers).to include(
        { "Content-Type" => "application/text" },
      )
      expect(response.body).to eq(["Success"])
    end
  end
end
