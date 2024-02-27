require "rspec"
require "functions_framework/testing"

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
  response = call_http "html_to_text", request
  response.body = JSON.parse(response.body[0])["replies"]
  response
end

describe "html_to_text() function" do
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

  it "returns plain text from HTML" do
    load_temporary "app.rb" do
      response = request([["<p>text</p>"]])
      expect(response.body[0]).to eq("text")
    end
  end

  it "returns plain text from multiple HTML strings" do
    load_temporary "app.rb" do
      response = request([["<p>text1</p>"], ["<p>text2</p>"]])
      expect(response.body).to eq(%w[text1 text2])
    end
  end

  it "substitutes literal newline characters with a space" do
    load_temporary "app.rb" do
      response = request([%W[line1\n\nline2]])
      expect(response.body[0]).to eq("line1 line2")
    end
  end

  it "substitutes <div> with a newline" do
    load_temporary "app.rb" do
      response = request([["line1<div>line2"]])
      expect(response.body[0]).to eq("line1\nline2")
    end
  end

  it "puts headings into their own line" do
    load_temporary "app.rb" do
      response = request([["<h1>heading</h1>content"]])
      expect(response.body[0]).to eq("heading\ncontent")
    end
  end
end
