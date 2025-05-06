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
}
# require "google/cloud/dlp/v2"
# dlp = ::Google::Cloud::Dlp::V2::DlpService::Client.new
# # text = "No profanity"
# text = "My phone number is 07757532536"
# config = {
#   "parent": "projects/govuk-knowledge-graph-dev/locations/europe-west2",
#   "inspect_config": inspect_config,
#   "deidentify_config": deidentify_config,
#   "item": {
#     "value": text
#   }
# }
# response = dlp.deidentify_content config
# response

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
  # response.body = json_or_string(response.body[0])["replies"]
  response
end

describe "data_loss_prevention() function" do
  include FunctionsFramework::Testing

#   it "returns 200 and empty object with nil input" do
#     load_temporary "app.rb" do
#       response = request([[nil]])
#       expect(response.status).to eq(200)
#       expect(response.body[0]).to eq({})
#     end
#   end

#   it "returns 200 and non-empty object with nil input text" do
#     load_temporary "app.rb" do
#       response = request([[
#         nil,
#         inspect_config,
#         deidentify_config
#       ]])
#       expect(response.status).to eq(200)
#       expect(response.body[0]).to eq({})
#     end
#   end

#   it "returns 200 and non-empty object with nil inspect_config" do
#     load_temporary "app.rb" do
#       response = request([[
#         "foo",
#         nil,
#         deidentify_config
#       ]])
#       expect(response.status).to eq(200)
#       expect(response.body[0]).to eq({})
#     end
#   end

#   it "returns 200 and non-empty object with nil deidentify_config" do
#     load_temporary "app.rb" do
#       response = request([[
#         "foo",
#         inspect_config,
#         nil
#       ]])
#       expect(response.status).to eq(200)
#       expect(response.body[0]).to eq({})
#     end
#   end


  it "returns 200 and non-empty object with empty input text" do
    load_temporary "app.rb" do
      response = request([[
        "",
        inspect_config,
        deidentify_config
      ]])
      expect(response.status).to eq(500)
      expect(response.body).to eq("foo")
    end
  end

  # it "returns 200 and non-empty object with non-empty non-whitespace input" do
  #   load_temporary "app.rb" do
  #     response = request([["foo"]])
  #     expect(response.status).to eq(200)
  #     expect(response.body[0]).to eq({})
  #   end
  # end

  # it "Initialises profanities" do
  #   load_temporary "app.rb" do
  #     response = request([[
  #       "No profanity",
  #       inspect_config,
  #       deidentify_config,
  #       "govuk-knowledge-graph-staging",
  #       "govuk-knowledge-graph-staging-lib",
  #       "profane_words.txt"
  #     ]])
  #     expect(response.body[0]).to eq({"item" => {"value" => "No profanity"}, "overview" => {}})
  #   end
  # end
end
