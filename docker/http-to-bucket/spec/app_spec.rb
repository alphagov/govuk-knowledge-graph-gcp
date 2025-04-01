# spec/app_spec.rb
require "functions_framework/testing"
require "net/http"
require "google/cloud/storage"
require "json"
require "stringio"
require "uri" # Needed for URI encoding

# Load the function code
require_relative "../app"

RSpec.describe "Google Cloud Function: http_to_bucket" do
  include FunctionsFramework::Testing

  # --- Test Data ---
  let(:project_id) { "test-project" }
  let(:bucket_name) { "test-bucket" }
  let(:object_name) { "test-object.jsonl" }
  let(:target_endpoint_url) { "https://example.com/api/data" }

  let(:required_function_params) do
    {
      "project_id" => project_id,
      "bucket_name" => bucket_name,
      "object_name" => object_name,
      "endpoint_url" => target_endpoint_url
    }
  end
  let(:forwarded_api_query_params) { { "param1" => "value1", "param2" => "value2" } }
  let(:forwarded_header_param) { { "headers" => "Authorization: Bearer token123\r\nContent-Type: application/json" } }
  let(:all_incoming_params) { required_function_params.merge(forwarded_api_query_params).merge(forwarded_header_param) }

  # --- Helper to build URL with query string for the incoming request ---
  def build_request_url(path = "/", params = {})
    uri = URI(path)
    uri.query = URI.encode_www_form(params) unless params.empty?
    uri.to_s
  end

  # Expected URI object for the *outgoing* Net::HTTP request to the target API
  let(:expected_target_uri) do
    URI(target_endpoint_url).tap do |uri|
      uri.query = URI.encode_www_form(forwarded_api_query_params)
    end
  end

  let(:expected_upload_body) { "{\"id\":1,\"name\":\"Item 1\"}\n{\"id\":2,\"name\":\"Item 2\"}" }
  let(:api_response_body_json) { [{ id: 1, name: "Item 1" }, { id: 2, name: "Item 2" }].to_json }

  # --- Mocks ---
  let(:mock_http) { instance_double(Net::HTTP, "Mock HTTP Client") }
  let(:mock_get_request) { instance_double(Net::HTTP::Get, "Mock HTTP GET Request") }
  let(:mock_storage_client) { instance_double(Google::Cloud::Storage::Project, "Mock GCS Project Client") }
  let(:mock_bucket) { instance_double(Google::Cloud::Storage::Bucket, "Mock GCS Bucket") }
  let(:mock_file) { instance_double(Google::Cloud::Storage::File, "Mock GCS File") }

  # --- Stub Common Behavior ---
  before do
    # Stub Net::HTTP chain (remains the same)
    allow(Net::HTTP).to receive(:new).with(expected_target_uri.host, expected_target_uri.port).and_return(mock_http)
    allow(mock_http).to receive(:use_ssl=)
    allow(Net::HTTP::Get).to receive(:new).with(expected_target_uri.request_uri).and_return(mock_get_request)
    allow(mock_get_request).to receive(:[]=) # Allow setting headers

    # Stub Google::Cloud::Storage chain (remains the same)
    allow(Google::Cloud::Storage).to receive(:new).with(project: project_id).and_return(mock_storage_client)
    allow(mock_storage_client).to receive(:bucket).with(bucket_name).and_return(mock_bucket)
    allow(mock_bucket).to receive(:create_file).and_return(mock_file)
  end

  # --- Test Cases ---

  context "when required parameters are missing" do
    let(:incomplete_params) { { "project_id" => project_id } }
    let(:request_url) { build_request_url("/", incomplete_params) }
    let(:function_required_keys) { ["bucket_name", "object_name", "endpoint_url"] }

    it "returns a 400 Bad Request response" do
      request = make_get_request request_url # Pass URL with query string
      response = call_http "http_to_bucket", request

      expect(response.status).to eq(400)
      expect(response.headers["content-type"]).to eq("application/text")
      expect(response.body.join).to satisfy("include all required parameter names") do |body|
        function_required_keys.all? { |key| body.include?(key) } && body.include?("Missing required parameters")
      end
    end
  end # context "when required parameters are missing"

  context "when all required parameters are provided" do
    # --- Mocks for HTTP Responses (remain the same) ---
    let(:mock_http_success_response) do
      instance_double(Net::HTTPSuccess, "Mock HTTP Success Response").tap do |resp|
        allow(resp).to receive(:body).and_return(api_response_body_json)
        allow(resp).to receive(:code).and_return("200")
        allow(resp).to receive(:message).and_return("OK")
        allow(resp).to receive(:is_a?) do |klass|
           klass == Net::HTTPSuccess
        end
        allow(resp).to receive(:each_header).and_return({"content-type" => "application/json"})
      end
    end

    let(:mock_http_error_response) do
      instance_double(Net::HTTPNotFound, "Mock HTTP Not Found Response").tap do |resp|
        allow(resp).to receive(:body).and_return("{\"error\":\"Resource not found\"}")
        allow(resp).to receive(:code).and_return("404")
        allow(resp).to receive(:message).and_return("Not Found")
        allow(resp).to receive(:is_a?) do |klass|
           klass == Net::HTTPNotFound
        end
        allow(resp).to receive(:each_header).and_return({"content-type" => "application/json", "x-request-id" => "abc-123"})
      end
    end

    # --- Common setup for valid parameter tests ---
    # Define the request URL with all parameters for these contexts
    let(:request_url_with_all_params) { build_request_url("/", all_incoming_params) }
    # Define the request URL with only required + API params (no headers param)
    let(:request_url_no_headers_param) { build_request_url("/", required_function_params.merge(forwarded_api_query_params)) }
    # Define the request URL with only required params
    let(:request_url_required_only) { build_request_url("/", required_function_params) }


    context "and the forwarded HTTP request is successful" do
      before do
        allow(mock_http).to receive(:request).with(mock_get_request).and_return(mock_http_success_response)
      end

      it "builds the target URI correctly (verified by `before` block stubs)" do
        request = make_get_request request_url_with_all_params
        # Triggering the call ensures the stubs with specific arguments are met
        expect { call_http "http_to_bucket", request }.not_to raise_error
      end

      it "sets headers on the forwarded request based on the 'headers' parameter" do
        expect(mock_get_request).to receive(:[]=).with("Authorization", "Bearer token123").ordered
        expect(mock_get_request).to receive(:[]=).with("Content-Type", "application/json").ordered

        request = make_get_request request_url_with_all_params
        call_http "http_to_bucket", request
      end

      it "configures Net::HTTP for SSL because the endpoint URL is https" do
        expect(mock_http).to receive(:use_ssl=).with(true)

        request = make_get_request request_url_with_all_params
        call_http "http_to_bucket", request
      end

      it "uploads the processed JSONL response body to Google Cloud Storage" do
        expect(mock_bucket).to receive(:create_file) do |io_arg, obj_name_arg|
          expect(io_arg).to be_a(StringIO)
          expect(io_arg.read).to eq(expected_upload_body)
          expect(obj_name_arg).to eq(object_name)
          mock_file
        end

        request = make_get_request request_url_with_all_params
        call_http "http_to_bucket", request
      end

      it "returns a 200 OK success response" do
        request = make_get_request request_url_with_all_params
        response = call_http "http_to_bucket", request

        expect(response.status).to eq(200)
        expect(response.headers["Content-Type"]).to eq("application/text")
        expect(response.body.join).to eq("Success")
      end

      context "when the 'headers' parameter is not provided" do
         it "does not attempt to set any headers on the forwarded request" do
           expect(mock_get_request).not_to receive(:[]=)

           request = make_get_request request_url_no_headers_param # Use URL without 'headers' param
           call_http "http_to_bucket", request
         end

         it "still succeeds and uploads the data" do
            expect(mock_bucket).to receive(:create_file).with(instance_of(StringIO), object_name).and_return(mock_file)

            request = make_get_request request_url_no_headers_param
            response = call_http "http_to_bucket", request

            expect(response.status).to eq(200)
            expect(response.body.join).to eq("Success")
         end
      end # context "when the 'headers' parameter is not provided"

      context "when the API response body is not valid JSON" do
        let(:invalid_api_response_body) { "This is not JSON" }
        let(:mock_http_success_response_invalid_json) do
          instance_double(Net::HTTPSuccess, "Mock HTTP Success Response (Invalid JSON)").tap do |resp|
            allow(resp).to receive(:body).and_return(invalid_api_response_body)
            allow(resp).to receive(:code).and_return("200")
            allow(resp).to receive(:message).and_return("OK")
            allow(resp).to receive(:is_a?) do |klass|
               klass == Net::HTTPSuccess
            end
            allow(resp).to receive(:each_header)
          end
        end

        before do
          allow(mock_http).to receive(:request).with(mock_get_request).and_return(mock_http_success_response_invalid_json)
        end

        it "catches the JSON parser error and returns a 500 Internal Server Error" do
          request = make_get_request request_url_with_all_params # Still need all params for the function call itself
          response = call_http "http_to_bucket", request

          expect(response.status).to eq(500)
          expect(response.headers).to eq({})
          expect(response.body.join).to include("Error in the Cloud Run function: ")
          expect(response.body.join).to include("unexpected character:")
        end

        it "does not attempt to upload to Google Cloud Storage" do
          expect(mock_bucket).not_to receive(:create_file)

          request = make_get_request request_url_with_all_params
          call_http "http_to_bucket", request # Call should trigger the error handling
        end
      end # context "when the API response body is not valid JSON"

    end # context "and the forwarded HTTP request is successful"

    context "and the forwarded HTTP request fails (e.g., 404 Not Found)" do
      before do
        allow(mock_http).to receive(:request).with(mock_get_request).and_return(mock_http_error_response)
      end

      it "does not attempt to use the Google Cloud Storage client" do
        expect(Google::Cloud::Storage).not_to receive(:new)
        expect(mock_storage_client).not_to receive(:bucket)
        expect(mock_bucket).not_to receive(:create_file)

        request = make_get_request request_url_required_only
        call_http "http_to_bucket", request
      end

      it "returns the exact status, headers, and body from the failed API response" do
        allow(Net::HTTP::Get).to receive(:new).and_return(mock_get_request)

        request = make_get_request request_url_required_only
        response = call_http "http_to_bucket", request

        expect(response.status).to eq(404)
        expect(response.headers).to include("content-type" => "application/json", "x-request-id" => "abc-123")
        expect(response.body.join).to eq("{\"error\":\"Resource not found\"}")
      end
    end # context "and the forwarded HTTP request fails"

    context "and an unexpected error occurs during processing (e.g., GCS error)" do
      let(:error_message) { "GCS bucket access denied!" }
      let(:gcs_error) { StandardError.new(error_message) }

      before do
        allow(mock_http).to receive(:request).with(mock_get_request).and_return(mock_http_success_response)
        # Stub GCS interaction to raise an error *after* the HTTP call
        allow(mock_storage_client).to receive(:bucket).with(bucket_name).and_raise(gcs_error)
      end

      it "catches the exception and returns a 500 Internal Server Error" do
        request = make_get_request request_url_with_all_params
        response = call_http "http_to_bucket", request

        expect(response.status).to eq(500)
        expect(response.headers).to eq({})
        expect(response.body.join).to include("Error in the Cloud Run function: ")
        expect(response.body.join).to include(error_message)
      end
    end # context "and an unexpected error occurs"

  end # context "when all required parameters are provided"
end # RSpec.describe
