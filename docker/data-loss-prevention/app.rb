#!/usr/bin/env ruby
require "functions_framework"

# DO NOT perform initialization here because this could get run at build time.

# Instead initialize in an on_startup block, which is executed only when a
# runtime server is starting up.
FunctionsFramework.on_startup do
  # Perform initialization here.
  require "json"
  require "google/cloud/storage"
  require "google/cloud/dlp/v2"

  $storage # Google::Cloud::Storage
  $profanities_project_name # string
  $profanities_bucket_name # string
  $profanities_object_name # string
  $profanities = [] # array of string


  $dlp = ::Google::Cloud::Dlp::V2::DlpService::Client.new
end

# https://cloud.google.com/functions/docs/create-deploy-http-ruby
FunctionsFramework.http "data_loss_prevention" do |request|
  # The request parameter is a Rack::Request object.
  # See https://www.rubydoc.info/gems/rack/Rack/Request
  begin
    # You return a string, a Rack::Response object, a Rack response array, or
    # a hash which will be JSON-encoded into a response.
    return { "replies" => JSON.parse(request.body.read)["calls"].map do |row|
      # TODO: default the inspect_config, deidentify_config and profanities_uri
      text, inspect_config, deidentify_config, profanities_project_name, profanities_bucket_name, profanities_object_name = row

      if text.nil?
        next {
          "item" => {"value" => nil},
          "overview" => {}
        }
      end

      if text == "" || inspect_config.nil? || deidentify_config.nil?
        next {
          "item" => {"value" => text},
          "overview" => {}
        }
      end

      initialise_profanities(profanities_project_name, profanities_bucket_name, profanities_object_name)

      config = {
        "parent": "projects/govuk-knowledge-graph-dev/locations/europe-west2",
        "inspect_config": inspect_config,
        "deidentify_config": deidentify_config,
        "item": {
          "value": text
        }
      }

      begin
        response = $dlp.deidentify_content config.to_h
      rescue Google::Cloud::InvalidArgumentError => e
        next { "error" => e }
      end

      response
    end }

  rescue => e
    return [500, { 'Content-Type' => 'application/text' }, [ e.message ]]
  end
end

def initialise_profanities(project_name, bucket_name, object_name)
  if project_name.nil? || bucket_name.nil? || object_name.nil?
    return
  end

  if $profanities_project_name == project_name && $profanities_bucket_name == bucket_name && $profanities_object_name == object_name
    return
  end

  $profanities_project_name = project_name
  $profanities_bucket_name = bucket_name
  $profanities_object_name = object_name

  $storage = Google::Cloud::Storage.new project: $profanities_project_name

  bucket = $storage.bucket $profanities_bucket_name
  object = bucket.file $profanities_object_name

  downloaded = object.download
  downloaded.rewind

  $profanities = downloaded.readlines
end
