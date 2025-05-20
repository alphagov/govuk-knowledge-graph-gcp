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
      # cell_val, inspect_config, deidentify_config = row

      # if cell_val.nil?
      #   next {
      #     "item" => {"value" => nil},
      #     "overview" => {}
      #   }
      # end

      # if text == "" || inspect_config.nil? || deidentify_config.nil?
      #   next {
      #     "item" => {"value" => text},
      #     "overview" => {}
      #   }
      # end

      rows << {"values" => [{"string_value" => row[0]}]}
    end

    # Construct the `table`. For more details on the table schema, please see
    # https://cloud.google.com/dlp/docs/reference/rest/v2/ContentItem#Table
    table = {}
    table["headers"] = [{"name": "text"}]
    table["rows"] = rows
    item = {"table": table}

    config = {
      "parent": "projects/govuk-knowledge-graph-dev/locations/europe-west2",
      "inspect_config": inspect_config,
      "deidentify_config": deidentify_config,
      "item": item
    }

    response = $dlp.deidentify_content config.to_h

    # begin
    # rescue Google::Cloud::InvalidArgumentError => e
      # return { "error" => e }
    # TODO: rescue whatever other API errors can be returned, especially resource limit exceeded (600 requests per minute)
    # end

    # You return a string, a Rack::Response object, a Rack response array, or
    # a hash which will be JSON-encoded into a response.
      # TODO: default the inspect_config, deidentify_config and profanities_uri

    return_values = []
    response.item.table.rows.map do |row|
      return_values << row.values[0].string_value
    end

    return { "replies" => return_values }
    # return config

  rescue => e
    # TODO: choose an appropriate error code to prevent BigQuery from
    # resubmitting the request.
    return [500, { 'Content-Type' => 'application/json' }, [{ "replies" => [{"error" => e.message }]}]]
  end
end
