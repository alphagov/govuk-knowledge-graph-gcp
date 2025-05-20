#!/usr/bin/env ruby
require "functions_framework"

# DO NOT perform initialization here because this could get run at build time.

# Instead initialize in an on_startup block, which is executed only when a
# runtime server is starting up.
FunctionsFramework.on_startup do
  # Perform initialization here.
  require "json"
  require "google/cloud/dlp/v2"

  $dlp = ::Google::Cloud::Dlp::V2::DlpService::Client.new
  $project_id = ENV["PROJECT_ID"]
end

# https://cloud.google.com/functions/docs/create-deploy-http-ruby
FunctionsFramework.http "data_loss_prevention" do |request|
  # The request parameter is a Rack::Request object.
  # See https://www.rubydoc.info/gems/rack/Rack/Request
  begin
    calls = JSON.parse(request.body.read)["calls"]

    rows = []

    _, inspect_config, deidentify_config = calls[0]

    calls.map do |row|
      rows << {"values" => [{"string_value" => row[0]}]}
    end

    # schema: https://cloud.google.com/dlp/docs/reference/rest/v2/ContentItem#Table
    table = {}
    table["headers"] = [{"name": "text"}]
    table["rows"] = rows
    item = {"table": table}

    config = {
      "parent": "projects/#{$project_id}/locations/europe-west2",
      "inspect_config": inspect_config,
      "deidentify_config": deidentify_config,
      "item": item
    }

    response = $dlp.deidentify_content config.to_h

    # Return a string, a Rack::Response object, a Rack response array, or
    # a hash which will be JSON-encoded into a response.
    return_values = []
    response.item.table.rows.map do |row|
      return_values << row.values[0].to_h[:string_value]
    end

    return { "replies" => return_values }

  rescue => e
    # Return a 200 code to prevent BigQuery from resubmitting the request.
    return [400, { 'Content-Type' => 'application/json' }, [{ "replies" => [{ "error_code" => e.code, "error" => e.message }]}]]
  end
end
