#!/usr/bin/env ruby
require "functions_framework"
require "json"
require "selenium-webdriver"
require "uri"

TIMEOUT_SECONDS = 10 # How long to wait for each HTML string to render

# Start a global instance of Selenium and Chrome
options = Selenium::WebDriver::Chrome::Options.new
options.add_argument("--headless")
options.add_argument("--disable-dev-shm-usage")
options.add_argument("--disable-gpu")
options.add_argument("--no-sandbox")
options.add_argument("--remote-debugging-port=9222")
options.add_argument("--window-size=1920,1080")

# rubocop:disable Style/GlobalVars
# The driver is global so that it can be reused between invocations of
# parse_html(), which will be much more performant.
$driver = Selenium::WebDriver.for(:chrome, options:)

$lock_file_path = Tempfile.new(["lock", ".lock"])

# https://cloud.google.com/functions/docs/create-deploy-http-ruby
FunctionsFramework.http "parse_html" do |request|
  # The request parameter is a Rack::Request object.
  # See https://www.rubydoc.info/gems/rack/Rack/Request

  # The Functions Framework is multithreaded, but we must ensure that the
  # webdriver is used by only a single invocation of this function at a time.
  # We do this be attempting to acquire an exclusive lock on a file in the
  # filesystem.
  #
  # An alternative would be to declare the webdriver instance locally rather
  # than globally, but that would hinder performance, because we would have to
  # restart the webdriver with each invocation of this function, and it takes
  # about a second to do so.
  # begin
  retries = 10
  interval_in_seconds = 0.1
  # Acquire an exclusive lock on the file
  # Open a file in the filesystem for use in controlling concurrency.
  lock_file = File.open($lock_file_path, File::RDWR | File::CREAT)
  until lock_file.flock(File::LOCK_EX | File::LOCK_NB)
    # If the lock cannot be acquired, wait and try again, for a while
    if retries <= 0
      # By raising errors, we encourage BigQuery to create more virtual machines
      # to host this function.
      raise "Function already in progress (max retries exceeded)"
    end

    sleep interval_in_seconds
    retries -= 1
  end

  # Return a string, a Rack::Response object, a Rack response array, or a hash
  # which will be JSON-encoded into a response.
  return { "replies" => JSON.parse(request.body.read)["calls"].map do |row|
    html, url = row
    t = Tempfile.new(["html", ".html"])
    t.write(html)
    t.close
    $driver.get("file:///#{t.path}")
    parse_html(url)
  end }
rescue StandardError => e
  return [500, { "Content-Type" => "application/text" }, [e.message]]
ensure
  # Release the lock, even if an exception occurs
  lock_file.flock(File::LOCK_UN)
end

# Function to extract plain text from HTML with selenium
#
# @param html [String] HTML to parse
# @param url [String] URL of the HTML, so that links to sections within the HTML
#                     can be fully qualified
def parse_html(url)
  text = nil
  hyperlinks = []
  abbreviations = []

  begin
    Timeout.timeout(TIMEOUT_SECONDS) do
      # Extract things from the rendered HTML
      text = extract_plain_text
      hyperlinks = extract_hyperlinks(url)
      abbreviations = extract_abbreviations

      # TODO: extract other things from the HTML
    rescue Timeout::Error
      "HTML parsing timed out after #{TIMEOUT_SECONDS} seconds"
    end
  rescue StandardError => e
    error_message = e
  end

  {
    "text" => text,
    "hyperlinks" => hyperlinks,
    "abbreviations" => abbreviations,
    "error" => error_message,
  }
end

# Function to parse a string of HTML with Selenium and Chromedriver
#
# There is no return value.
#
# A Selinium driver is assumed to exist in the global environment.
# A temporary file will be created, for Chromedriver to load.
#
# @param html [String] HTML to parse
def parse_html_string(html)
  # There isn't a good way to parse HTML from a string.
  # The .get() method is like a search bar in the browser.
  #
  # We write the string to a temporary file and load that.
  #
  # Alternatively we could do:
  #   driver.get("data:text/html;charset=utf-8," + htmlString)
  # but browsers limit how much data they will accept that way.

  t = Tempfile.new(["html", ".html"])
  t.write(html)
  t.close
  $driver.get("file:///#{t.path}")
ensure
  t.delete
end

# A function to extract plain text from a parsed HTML document, as it would
# appear in a browser, i.e. newlines are ignored, <div> elements are rendered as
# newlines, <h1> elements appear on their own line, etc.
#
# A Selinium driver is assumed to exist in the global environment, and to have
# loaded an HTML page.
def extract_plain_text
  $driver.find_element(:css, "*").text
end

# A function to extract hyperlinks from a parsed HTML document.
#
# Returns an array of hashes, one per hyperlink.
#
# A Selinium driver is assumed to exist in the global environment, and to have
# loaded an HTML page.
#
# @# @param url [String] URL of the HTML, so that links to sections within the HTML
#                     can be fully qualified
def extract_hyperlinks(url)
  hyperlinks = []

  # Extract each hyperlink
  #
  # Selenium returns the property (the resolved URL) instead of the
  # attribute (whatever the href is), even though the method is
  # get_attribute.
  # https://github.com/seleniumhq/selenium-google-code-issue-archive/issues/1824
  #
  # Because we load the HTML from a file, Selenium prepends "file://" to
  # relative links.
  #
  # We could do a string replacement of "file://", but what if a link really
  # does start with "file://"?
  #
  # A workaround is to use javascript instead.
  script = <<~SQUIGGLY_HEREDOC
    var elems = document.querySelectorAll(':any-link'); // Select all anchor elements
    var URLs = [];

    [].forEach.call(elems, function (elem) {
    URLs.push({
    href: elem.getAttribute("href"), // Get the unaltered href attribute
    text: elem.textContent // Get the text content of the link
    });
    });
    return URLs
  SQUIGGLY_HEREDOC

  links = $driver.execute_script(script)

  links.each do |link|
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
      "link_text" => link["text"],
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
# A Selinium driver is assumed to exist in the global environment, and to have
# loaded an HTML page.
def extract_abbreviations
  abbreviations = []

  elems = $driver.find_elements(:css, "abbr")
  elems.each do |elem|
    abbreviation_title = elem.attribute("title") # Expansion
    abbreviation_text = elem.text # Abbreviation

    abbreviations.push({
      "title" => abbreviation_title,
      "text" => abbreviation_text,
    })
  end

  abbreviations
end

# rubocop:enable Style/GlobalVars
