#!/usr/bin/env ruby
require "functions_framework"
require "json"
require "nokogiri"
require "timeout"
require "uri"

TIMEOUT_SECONDS = 10 # How long to wait for each HTML string to render

# https://cloud.google.com/functions/docs/create-deploy-http-ruby
FunctionsFramework.http "parse_html" do |request|
  # The request parameter is a Rack::Request object.
  # See https://www.rubydoc.info/gems/rack/Rack/Request

  # Return a string, a Rack::Response object, a Rack response array, or a hash
  # which will be JSON-encoded into a response.
  return { "replies" => JSON.parse(request.body.read)["calls"].map do |row|
    html, url = row
    parse_html(html, url)
  end }
rescue StandardError => e
  return [500, { "Content-Type" => "application/text" }, [e.message]]
end

# Function to extract plain text from HTML
#
# @param html [String] HTML to parse
# @param url [String] URL of the HTML, so that links to sections within the HTML
#                     can be fully qualified
def parse_html(html, url)
  hyperlinks = []
  abbreviations = []
  images = []
  tables = []

  begin
    Timeout.timeout(TIMEOUT_SECONDS) do
      html_doc = Nokogiri::HTML5.fragment(html)
      # Extract things from the rendered HTML
      hyperlinks = extract_hyperlinks(html_doc, url)
      abbreviations = extract_abbreviations(html_doc)
      tables = extract_tables(html_doc)
      images = extract_images(html_doc)

      # TODO: extract other things from the HTML
    rescue Timeout::Error
      "HTML parsing timed out after #{TIMEOUT_SECONDS} seconds"
    end
  rescue StandardError => e
    error_message = e
  end

  {
    "hyperlinks" => hyperlinks,
    "abbreviations" => abbreviations,
    "tables" => tables,
    "images" => images,
    "error" => error_message,
  }
end

# A function to extract hyperlinks from a parsed HTML document.
#
# Returns an array of hashes, one per hyperlink.
#
# @# @param html_doc A nokokiri HTML document
def extract_hyperlinks(html_doc, url)
  hyperlinks = []

  html_doc.css("a").each do |link|
    # Clean and qualify
    link_href = clean_hyperlink(link["href"], url)

    # Remove URL parameters and anchors
    bare_href = URI.parse(link_href)
    bare_href.query = nil
    bare_href.fragment = nil
    bare_href = bare_href.to_s

    hyperlinks.push({
      "link_url" => link_href,
      "link_url_bare" => bare_href,
      "link_text" => link.text,
    })
  end

  hyperlinks
end

# Function to clean and fully qualify relative links and anchor links
#
# @param href [String] URL to qualify
# @param from_url [String] URL of page where the href is
def clean_hyperlink(href, from_url)
  # Remove newlines from within a URL, such as in the page
  # https://www.gov.uk/guidance/2016-key-stage-2-assessment-and-reporting-arrangements-ara/section-13-legal-requirements-and-responsibilities
  # Which ontainins a link that is split over two lines:
  #   https://www.gov.uk/government/publications/teacher-assessment-
  #   moderation-requirements-for-key-stage-2\
  href = href.gsub("\r", "").gsub("\n", "")

  # If the link is relative, make it absolute in the GOV.UK domain.
  if href[0] == "/"
    return "https://www.gov.uk#{href}"
  end

  # If the link is to an anchor within the page, make it absolute.
  # domain.
  if href[0] == "#"
    return from_url + href
  end

  href
end

# A function to extract <abbr> elements from a parsed HTML document.
#
# Returns an array of hashes, one per <abbr> element.
#
# @param html_doc A nokokiri HTML document
def extract_abbreviations(html_doc)
  abbreviations = []

  html_doc.css("abbr").each do |abbreviation|
    abbreviations.push({
      "title" => abbreviation.attribute("title"), # Expansion
      "text" => abbreviation.text, # Abbreviation
    })
  end

  abbreviations
end

# A function to extract <img> elements from a parsed HTML document.
#
# Returns an array of hashes, one per <img> element. Each hash contains a "src"
# key, with a string value that is the URL of the image, and an
# "alt" key, with a string value that is the alt-text of the image.
#
# @param html_doc A nokokiri HTML document
# @param url [String] URL of the HTML document
def extract_images(html_doc)
  images = []

  html_doc.css("img").each do |img|
    images.push({
      "src" => img.attribute("src").to_s,
      "alt" => img.attribute("alt").to_s,
    })
  end

  images
end

# A function to extract <table> elements from a parsed HTML document.
#
# Returns an array of hashes, one per <table> element. Each hash contains a
# "table" key, with a string value that is the HTML of the table.
#
# @param html_doc A nokokiri HTML document
def extract_tables(html_doc)
  tables = []

  html_doc.css("table").each do |table|
    tables.push({
      "html" => table.to_s, # html string of the table tag
    })
  end

  tables
end
