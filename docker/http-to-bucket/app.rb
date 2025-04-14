#!/usr/bin/env ruby

require "functions_framework"
require "google/cloud/storage"
require 'json'

# DO NOT perform initialization here because this could get run at build time.

# Instead initialize in an on_startup block, which is executed only when a
# runtime server is starting up.
FunctionsFramework.on_startup do
  # Perform initialization here.
  require "net/http"
  require "google/cloud/storage"
end

# Validates the presence of required parameters.
def validate_parameters(params)
  required_params = %w[project_id bucket_name object_name]
  missing = required_params.reject { |param| params.key?(param) }
  return if missing.empty?
  [400, { "content-type" => "application/text" }, ["Missing required parameters: #{missing.join(', ')}"]]
end

# Forwards the incoming HTTP request to the target URL.
def forward_request(request, endpoint_url, headers)
  puts endpoint_url

  uri = URI(endpoint_url)
  uri.query = URI.encode_www_form(request.params)

  new_request = Net::HTTP::Get.new(uri.request_uri)

  headers.split("\r\n").each do |header|
    name, value = header.split(": ")
    new_request[name] = value
  end

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == "https"
  http.request(new_request)
end

# Uploads the HTTP response to Google Cloud Storage.
def upload_response(project_id, bucket_name, object_name, http_response)
  storage = Google::Cloud::Storage.new project: project_id
  bucket = storage.bucket bucket_name
  body = JSON.parse(http_response.body).map { |response| response.to_json }.join("\n")
  object = StringIO.new(body)
  bucket.create_file object, object_name
end

# Handles errors and returns a 500 response.
def handle_error(error)
  return [500, { "Content-Type" => "application/text" }, ["Error in the Cloud Run function: #{error.message}"]]
end

FunctionsFramework.http "http_to_bucket" do |request|
  request.logger.info "Request received."

  # Extract parameters
  endpoint_url = request.params["endpoint_url"]
  headers = request.params["headers"]
  project_id = request.params["project_id"]
  bucket_name = request.params["bucket_name"]
  object_name = request.params["object_name"]
  request.logger.info "Parameters extracted"

  # Validate parameters
  validation_error = validate_parameters(request.params)
  return validation_error if validation_error
  request.logger.info "Parameters are valid"

  # Remove parameters from the request URL
  request.logger.info "Removing certain parameters"
  request.delete_param("endpoint_url")
  request.delete_param("headers")
  request.delete_param("project_id")
  request.delete_param("bucket_name")
  request.delete_param("object_name")
  request.logger.info "Certain parameters removed"

  begin
    # Forward the request
    request.logger.info "Forwarding the request."
    http_response = forward_request(request, endpoint_url, headers)
    request.logger.info "Received a response."

    if http_response.is_a?(Net::HTTPSuccess)
      request.logger.info "Response successful. Uploading."
      # Upload the successful response
      upload_response(project_id, bucket_name, object_name, http_response)
    else
      request.logger.info "Response unsuccessful."
      # Return the unsuccessful response as is
      return [http_response.code, http_response.each_header.to_h, [http_response.body]]
    end
  rescue Exception => e
    # Handle any errors
    return handle_error(e)
  end

  return [200, { "Content-Type" => "application/text" }, ["Success"]]
end
