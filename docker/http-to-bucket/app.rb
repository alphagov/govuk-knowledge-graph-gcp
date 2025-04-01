#!/usr/bin/env ruby

require "functions_framework"

# DO NOT perform initialization here because this could get run at build time.

# Instead initialize in an on_startup block, which is executed only when a
# runtime server is starting up.
FunctionsFramework.on_startup do
  # Perform initialization here.
  require "net/http"
  require "google/cloud/storage"
  require 'json'
end

# Validates the presence of required parameters.
def validate_parameters(params)
  required_params = %w[project_id bucket_name object_name endpoint_url]
  missing = required_params.reject { |param| params.key?(param) }
  return if missing.empty?
  [400, { "content-type" => "application/text" }, ["Missing required parameters: #{missing.join(', ')}"]]
end

# Forwards the incoming HTTP request to the target URL.
def forward_request(request, endpoint_url, headers)
  uri = URI(endpoint_url)
  uri.query = URI.encode_www_form(request.params)

  new_request = Net::HTTP::Get.new(uri.request_uri)

  if headers
    headers.split("\r\n").each do |header|
      name, value = header.split(": ")
      new_request[name] = value
    end
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

FunctionsFramework.http "http_to_bucket" do |request|
  begin
    request.logger.info "Request received"

    # Extract parameters
    endpoint_url = request.params["endpoint_url"]
    headers = request.params["headers"]
    project_id = request.params["project_id"]
    bucket_name = request.params["bucket_name"]
    object_name = request.params["object_name"]

    request.logger.info "Wrapper parameters extracted"

    # Validate parameters
    validation_error = validate_parameters(request.params)
    return validation_error if validation_error

    request.logger.info "Parameters are valid"

    # Remove parameters from the request URL
    request.delete_param("endpoint_url")
    request.delete_param("headers")
    request.delete_param("project_id")
    request.delete_param("bucket_name")
    request.delete_param("object_name")

    request.logger.info "Wrapper parameters removed"

    # Forward the request
    request.logger.info "Forwarding the request"
    http_response = forward_request(request, endpoint_url, headers)

    if http_response.is_a?(Net::HTTPSuccess)
      # Upload the successful response
      request.logger.info "Response successful. Uploading."
      upload_response(project_id, bucket_name, object_name, http_response)
    else
      # Return the unsuccessful response as is
      request.logger.info "Response unsuccessful"
      return [http_response.code, http_response.each_header.to_h, [http_response.body]]
    end
  rescue Exception => error
    # Handle any errors
    # request.logger.info "Error in the Cloud Run function"
    message = "Error in the Cloud Run function: #{error.message.to_s}"
    request.logger.info message
    return [500, {}, [message]]
  end

  # Success
  request.logger.info "Success"
  return [200, { "Content-Type" => "application/text" }, ["Success"]]
end
