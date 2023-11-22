#!/usr/bin/env ruby
require "functions_framework"
require 'json'
require 'govspeak'

TIMEOUT_SECONDS = 10 # How long to wait for each govspeak string to render

# https://cloud.google.com/functions/docs/create-deploy-http-ruby
FunctionsFramework.http "govspeak_to_html" do |request|
  # The request parameter is a Rack::Request object.
  # See https://www.rubydoc.info/gems/rack/Rack/Request
  begin
    # You return a string, a Rack::Response object, a Rack response array, or
    # a hash which will be JSON-encoded into a response.
    return { "replies" => JSON.parse(request.body.read)["calls"].map {
      |row| render(row[0])
    } }
  rescue => e
    return [500, { 'Content-Type' => 'application/text' }, [ e.message ]]
  end
end

# Render a single govspeak string to HTML.
#
# Time out if rendering freezes, as it does in the following example.
#
# govspeak = <<-END_GOVSPEAK
# $LegislativeList
# * Item
#   $EndLegislativeList
# END_GOVSPEAK
# Govspeak::Document.new(govspeak).to_html
def render(govspeak)
  html = nil
  begin
    Timeout::timeout(TIMEOUT_SECONDS) do
      html = Govspeak::Document.new(govspeak).to_html
    end
  rescue Timeout::Error => e
    error_message = "Conversion from govspeak to HTML timed out after #{TIMEOUT_SECONDS} seconds"
  rescue => e
    error_message = e
  end
  return { "html" => html, "error" => error_message }
end
