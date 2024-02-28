require "rspec"
require "functions_framework/testing"

# Submit an http request, return an http response, with the body parsed into an
# array of JSON objects.
#
# @param body [array] of arrays, one array per call to the function, where each
# array has elements corresponding to the arguments of the function
# parse_html().
def request(calls)
  body = { "calls" => calls }
  url = ""
  headers = ["Content-Type: application/json"]
  body = body.to_json.to_s
  request = make_post_request url, body, headers
  response = call_http "parse_html", request
  response.body = JSON.parse(response.body[0])["replies"]
  response
end

describe "parse_html() function" do
  include FunctionsFramework::Testing

  it "returns 200 with nil input" do
    load_temporary "app.rb" do
      response = request([[nil, nil]])
      expect(response.status).to eq(200)
    end
  end

  it "returns 200 with blank input" do
    load_temporary "app.rb" do
      response = request([["", ""]])
      expect(response.status).to eq(200)
    end
  end

  it "returns 200 with html input" do
    load_temporary "app.rb" do
      response = request([["<p>text</p>, ", ""]])
      expect(response.status).to eq(200)
    end
  end

  it "extracts hyperlinks" do
    load_temporary "app.rb" do
      response = request([["<a href=\"https://www.gov.uk\">link text</a>", ""]])
      expect(response.body[0]["hyperlinks"][0]).to eq({
        "link_text" => "link text",
        "link_url" => "https://www.gov.uk",
        "link_url_bare" => "https://www.gov.uk",
      })
    end
  end

  it "removes newline characters from hyperlinks" do
    load_temporary "app.rb" do
      response = request([["<a href=\"https://www.gov\n.uk\">link text</a>", ""]])
      expect(response.body[0]["hyperlinks"][0]).to eq({
        "link_text" => "link text",
        "link_url" => "https://www.gov.uk",
        "link_url_bare" => "https://www.gov.uk",
      })
    end
  end

  it "strips parameters from URLs" do
    load_temporary "app.rb" do
      response = request([[
        "<a href=\"https://www.gov.uk/foo?param=bar\">link text</a>",
        "https://www.gov.uk",
      ]])
      expect(response.body[0]["hyperlinks"][0]).to eq({
        "link_text" => "link text",
        "link_url" => "https://www.gov.uk/foo?param=bar",
        "link_url_bare" => "https://www.gov.uk/foo",
      })
    end
  end

  it "strips anchors from URLs" do
    load_temporary "app.rb" do
      response = request([[
        "<a href=\"https://www.gov.uk#foo\">link text</a>",
        "https://www.gov.uk",
      ]])
      expect(response.body[0]["hyperlinks"][0]).to eq({
        "link_text" => "link text",
        "link_url" => "https://www.gov.uk#foo",
        "link_url_bare" => "https://www.gov.uk",
      })
    end
  end

  it "resolves relative links to the given domain" do
    load_temporary "app.rb" do
      response = request([[
        "<a href=\"/foo\">link text</a>",
        "https://www.gov.uk",
      ]])
      expect(response.body[0]["hyperlinks"][0]).to eq({
        "link_text" => "link text",
        "link_url" => "https://www.gov.uk/foo",
        "link_url_bare" => "https://www.gov.uk/foo",
      })
    end
  end

  it "resolves anchor links to the given domain" do
    load_temporary "app.rb" do
      response = request([[
        "<a href=\"#foo\">link text</a>",
        "https://www.gov.uk",
      ]])
      expect(response.body[0]["hyperlinks"][0]).to eq({
        "link_text" => "link text",
        "link_url" => "https://www.gov.uk#foo",
        "link_url_bare" => "https://www.gov.uk",
      })
    end
  end

  it "does not resolve absolute links to the given domain" do
    load_temporary "app.rb" do
      response = request([[
        "<a href=\"https://www.example.co.uk\">link text</a>",
        "https://www.gov.uk",
      ]])
      expect(response.body[0]["hyperlinks"][0]).to eq({
        "link_text" => "link text",
        "link_url" => "https://www.example.co.uk",
        "link_url_bare" => "https://www.example.co.uk",
      })
    end
  end

  it "extracts abbreviations" do
    load_temporary "app.rb" do
      response = request([[
        "<abbr title=\"Government Digital Service\">GDS</abbr>",
        "",
      ]])
      expect(response.body[0]["abbreviations"][0]).to eq({
        "text" => "GDS",
        "title" => "Government Digital Service",
      })
    end
  end
end
