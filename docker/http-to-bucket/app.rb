#!/usr/bin/env ruby

require "functions_framework"

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
  [400, { "content-type" => "application/text" }, "Missing required parameters: #{missing.join(', ')}"]
end

# Forwards the incoming HTTP request to the target URL.
def forward_request(request, endpoint_url)
  uri = URI(endpoint_url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == "https"
  new_request = Net::HTTP::Get.new(uri.request_uri)

  request.env.each do |key, value|
    if key.start_with?("HTTP_") && key != "HTTP_HOST"
      header_name = key[5..]
      new_request[header_name] = value
    end
  end

  http.request(new_request)
end

# Uploads the HTTP response to Google Cloud Storage.
def upload_response(project_id, bucket_name, object_name, http_response)
  storage = Google::Cloud::Storage.new project: project_id
  bucket = storage.bucket bucket_name
  file = bucket.create_file StringIO.new({"body" => http_response.body.force_encoding('UTF-8'), "code" => http_response.code, "header" => http_response.each_header.to_h}.to_json), object_name
  [http_response.code, http_response.each_header.to_h, file.media_url]
end

# Handles errors and returns a 500 response.
def handle_error(error)
  [500, { "Content-Type" => "application/text" }, "Error in the Cloud Run function: #{error.message}"]
end

FunctionsFramework.http "http_to_bucket" do |request|
  # Extract parameters
  endpoint_url = request.params["endpoint_url"]
  project_id = request.params["project_id"]
  bucket_name = request.params["bucket_name"]
  object_name = request.params["object_name"]

  # Validate parameters
  validation_error = validate_parameters(request.params)
  return validation_error if validation_error

  # Remove parameters from the request URL
  request.delete_param("endpoint_url")
  request.delete_param("project_id")
  request.delete_param("bucket_name")
  request.delete_param("object_name")

  begin
    # Forward the request
    http_response = forward_request(request, endpoint_url)

    if http_response.is_a?(Net::HTTPSuccess)
      # Upload the successful response
      upload_response(project_id, bucket_name, object_name, http_response)
    else
      # Return the unsuccessful response as is
      [http_response.code, http_response.each_header.to_h, http_response.body]
    end
  rescue StandardError => e
    # Handle any errors
    handle_error(e)
  end
end
