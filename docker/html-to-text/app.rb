#!/usr/bin/env ruby
require "functions_framework"
require "json"
require "pandoc-ruby"

TIMEOUT_SECONDS = 10 # How long to wait for each HTML string to render

# https://cloud.google.com/functions/docs/create-deploy-http-ruby
FunctionsFramework.http "html_to_text" do |request|
  # The request parameter is a Rack::Request object.
  # See https://www.rubydoc.info/gems/rack/Rack/Request

  # Return a string, a Rack::Response object, a Rack response array, or a hash
  # which will be JSON-encoded into a response.
  return { "replies" => JSON.parse(request.body.read)["calls"].map do |row|
    Timeout.timeout(TIMEOUT_SECONDS) do
      html = row[0]
      PandocRuby.convert(html, { from: :html, to: :plain }, "--wrap=none").chomp.gsub(/(\r?\n)+/, "\n")
    rescue Timeout::Error
      "HTML parsing timed out after #{TIMEOUT_SECONDS} seconds"
    end
  rescue StandardError => e
    e
  end }
rescue StandardError => e
  return [500, { "Content-Type" => "application/text" }, [e.message]]
end
