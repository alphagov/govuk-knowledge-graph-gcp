#!/usr/bin/env ruby
require "functions_framework"
require 'json'
require 'selenium-webdriver'


TIMEOUT_SECONDS = 10 # How long to wait for each govspeak string to render

# Start a global instance of Selenium and Chrome
options = Selenium::WebDriver::Chrome::Options.new
options.add_argument('--headless')
options.add_argument('--disable-dev-shm-usage')
options.add_argument('--disable-gpu')
options.add_argument('--no-sandbox')
options.add_argument('--remote-debugging-port=9222')
options.add_argument('--window-size=1920,1080')

$driver = Selenium::WebDriver.for(:chrome, options:)

# https://cloud.google.com/functions/docs/create-deploy-http-ruby
FunctionsFramework.http "parse_html" do |request|
  # The request parameter is a Rack::Request object.
  # See https://www.rubydoc.info/gems/rack/Rack/Request

  begin
    # You return a string, a Rack::Response object, a Rack response array, or
    # a hash which will be JSON-encoded into a response.
    return { "replies" => JSON.parse(request.body.read)["calls"].map {
      |row| parse_html(row[0])
    } }
  rescue => e
    return [500, { 'Content-Type' => 'application/text' }, [ e.message ]]
  end
end

# Function to extract plain text from HTML with selenium
def parse_html(html)
  text = nil

  begin

    Timeout::timeout(TIMEOUT_SECONDS) do
      # There isn't a good way to parse HTML from a string.
      # The .get() method is like a search bar in the browser.
      #
      # We write the string to a temporary file and load that.
      #
      # Alternatively we could do:
      #   driver.get("data:text/html;charset=utf-8," + htmlString)
      # but browsers limit how much data they will accept that way.
      t = Tempfile.new(['html', '.html'])
      t.write(html)
      t.close
      $driver.get("file:///" + t.path)

      # Extract plain text, as it would appear in a browse, i.e. newlines are
      # ignored, <div> elements are rendered as newlines, <h1> elements appear
      # on their own line, etc.
      text = $driver.find_element(:css, "*").text

      # TODO: extract other things from the HTML
    rescue Timeout::Error => e
      error_message = "HTML parsing timed out after #{TIMEOUT_SECONDS} seconds"
    ensure
      t.delete
    end

  rescue => e
    error_message = e
  end

  return { "text" => text, "error" => error_message }
end
