# gcloud auth application-default set-quota-project <project-name>

require "rspec"
require "functions_framework/testing"

inspect_config = {
  "info_types": [
    {
      "name": "PHONE_NUMBER"
    }
  ],
  "include_quote": true
}

deidentify_config = {
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

# Submit an http request, return an http response, with the body parsed into an
# array of JSON objects.
#
# @param body [array] of arrays, one array per call to the function, where each
# array has elements corresponding to the arguments of the function
# html_to_text().
def request(calls)
  body = { "calls" => calls }
  url = ""
  headers = ["Content-Type: application/json"]
  body = body.to_json.to_s
  request = make_post_request url, body, headers
  response = call_http "data_loss_prevention", request
  response.body = JSON.parse(response.body[0])["replies"]
  response
end

describe "data_loss_prevention() function" do
  include FunctionsFramework::Testing

  it "returns 200 with nil input" do
    load_temporary "app.rb" do
      response = request([[nil]])
      expect(response.status).to eq(200)
    end
  end

  it "returns 200 with blank input" do
    load_temporary "app.rb" do
      response = request([[""]])
      expect(response.status).to eq(200)
    end
  end

  it "returns 200 with html input" do
    load_temporary "app.rb" do
      response = request([["<p>text</p>, "]])
      expect(response.status).to eq(200)
    end
  end

  it "Initialises profanities" do
    load_temporary "app.rb" do
      response = request([[
        "No profanity",
        inspect_config,
        deidentify_config,
        "govuk-knowledge-graph-staging",
        "govuk-knowledge-graph-staging-lib",
        "profane_words.txt"
      ]])
      expect(response.body[0]).to eq("No profanity")
    end
  end
end
