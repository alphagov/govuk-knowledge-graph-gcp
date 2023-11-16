#!/usr/bin/env ruby
require "functions_framework"
require 'json'
require 'govspeak'

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

def render(govspeak)
  begin
    return {
      "html" => Govspeak::Document.new(govspeak).to_html(),
      "error" => nil
    }
  rescue => e
    return {
      "html" => nil,
      "error" => e.message
    }
  end
end
