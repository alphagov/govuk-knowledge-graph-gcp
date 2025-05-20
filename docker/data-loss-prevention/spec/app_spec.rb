# gcloud auth application-default set-quota-project <project-name>

require "rspec"
require "functions_framework/testing"

ENV["PROJECT_ID"] = "govuk-knowledge-graph-dev"
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
}

def json_or_string(json_or_string)
  return JSON.parse(json_or_string)
rescue JSON::ParserError, TypeError => e
  return json_or_string
end

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
  response.body = json_or_string(response.body[0])["replies"]
  response
end

describe "data_loss_prevention() function" do
  include FunctionsFramework::Testing

  it "returns 400, given nil input" do
    load_temporary "app.rb" do
      response = request([[nil]])
      expect(response.status).to eq(400)
      expect(response.body[0]["error"]).to start_with("3:`deidentify_config` must be set.")
    end
  end

  it "returns 200 and no text, given nil input text" do
    load_temporary "app.rb" do
      response = request([[
        nil,
        inspect_config,
        deidentify_config
      ]])
      expect(response.status).to eq(200)
      expect(response.body[0]).nil?
    end
  end

  it "returns 200 and input text, given nil inspect_config" do
    load_temporary "app.rb" do
      response = request([[
        "foo",
        nil,
        deidentify_config
      ]])
      expect(response.status).to eq(200)
      expect(response.body[0]).to eq("foo")
    end
  end

  it "returns 400, given nil deidentify_config" do
    load_temporary "app.rb" do
      response = request([[
        "foo",
        inspect_config,
        nil
      ]])
      expect(response.status).to eq(400)
      expect(response.body[0]["error"]).to start_with("3:`deidentify_config` must be set.")
    end
  end

  it "returns 200 and empty string, given an empty string as input text" do
    load_temporary "app.rb" do
      response = request([[
        "",
        inspect_config,
        deidentify_config
      ]])
      expect(response.status).to eq(200)
      expect(response.body[0]).to eq("")
    end
  end

  it "returns 200 and whitespace input text, given whitespace input text" do
    load_temporary "app.rb" do
      response = request([[
        " ",
        inspect_config,
        deidentify_config
      ]])
      expect(response.status).to eq(200)
      expect(response.body[0]).to eq(" ")
    end
  end

  it "returns 200 and input text, given non-whitespace non-pii input text" do
    load_temporary "app.rb" do
      response = request([[
        "No personally identifiable information",
        inspect_config,
        deidentify_config
      ]])
      expect(response.status).to eq(200)
      expect(response.body[0]).to eq("No personally identifiable information")
    end
  end

  it "returns 200 and masked phone number, given a phone number in input text" do
    load_temporary "app.rb" do
      response = request([
        [
          "My phone number is 01234 567890.",
          inspect_config,
          deidentify_config
        ]
      ])
      expect(response.status).to eq(200)
      expect(response.body[0]).to eq("My phone number is [PHONE_NUMBER].")
    end
  end

  it "returns 200 and an error message for a given input row that has incorrect arguments" do
    load_temporary "app.rb" do
      response = request([[
        "foo",
        {
          "info_types": [
            {
              "name": "PHONE_NUMBER"
            }
          ],
          "include_quote": true
        },
        {
          "info_type_transformations": {
            "transformations": [
              {
                "info_types": [
                  {
                    "name": "PHONE_NUMBER"
                  },
                  {
                    "name": "EMAIL_ADDRESS" # Deliberate error: not included in inspect_config argument
                  }
                ],
                "primitive_transformation": {
                  "replace_with_info_type_config": {}
                }
              }
            ]
          }
        }
      ]])
      expect(response.status).to eq(400)
      expect(response.body[0]["error"]).to start_with("3:Info type \"EMAIL_ADDRESS\" was not included in InspectConfig.")
    end
  end
end
