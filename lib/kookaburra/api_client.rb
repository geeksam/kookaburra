require 'restclient'
require 'core_ext/object/to_query'
require 'kookaburra/exceptions'

class Kookaburra
  # Communicate with a Web Services API
  #
  # You will create a subclass of {APIClient} in your testing
  # implementation to be used with you subclass of
  # {Kookaburra::APIDriver}. While the {GivenDriver} implements the
  # "business domain" DSL for setting up your application state, the
  # {APIClient} maps discreet operations to your application's web
  # service API and can (optionally) handle encoding input data and
  # decoding response bodies to and from your preferred serialization
  # format.
  class APIClient
    class << self
      # Serializes input data
      #
      # If specified, any input data provided to {APIClient#post},
      # {APIClient#put} or {APIClient#request} will be processed through
      # this function prior to being sent to the HTTP server.
      #
      # @yieldparam data [Object] The data parameter that was passed to
      #             the request method
      # @yieldreturn [String] The text to be used as the request body
      #
      # @example
      #   class MyAPIClient < Kookaburra::APIClient
      #     encode_with { |data| JSON.dump(data) }
      #     # ...
      #   end
      def encode_with(&block)
        define_method(:encode) do |data|
          return if data.nil?
          block.call(data)
        end
      end

      # Deserialize response body
      #
      # If specified, the response bodies of all requests made using
      # this {APIClient} will be processed through this function prior
      # to being returned.
      #
      # @yieldparam data [String] The response body sent by the HTTP
      #             server
      #
      # @yieldreturn [Object] The result of parsing the response body
      #              through this function
      #
      # @example
      #   class MyAPIClient < Kookaburra::APIClient
      #     decode_with { |data| JSON.parse(data) }
      #     # ...
      #   end
      def decode_with(&block)
        define_method(:decode) do |data|
          block.call(data)
        end
      end

      # Set custom HTTP headers
      #
      # Can be called multiple times to set HTTP headers that will be
      # provided with every request made by the {APIClient}.
      #
      # @param [String] name The name of the header, e.g. 'Content-Type'
      # @param [String] value The value to which the header is set
      #
      # @example
      #   class MyAPIClient < Kookaburra::APIClient
      #     header 'Content-Type', 'application/json'
      #     header 'Accept', 'application/json'
      #     # ...
      #   end
      def header(name, value)
        headers[name] = value
      end

      # Used to retrieve the list of headers within the instance. Not
      # intended to be used elsewhere.
      #
      # @private
      def headers
        @headers ||= {}
      end
    end

    # Create a new {APIClient} instance
    #
    # @param [Kookaburra::Configuration] configuration
    # @param [RestClient] http_client (optional) Generally only
    #        overriden when testing Kookaburra itself
    def initialize(configuration, http_client = RestClient)
      @configuration = configuration
      @http_client = http_client
    end

    # Convenience method to make a POST request
    #
    # @see APIClient#request
    def post(path, data = nil, headers = {})
      request(:post, path, data, headers)
    end

    # Convenience method to make a PUT request
    #
    # @see APIClient#request
    def put(path, data = nil, headers = {})
      request(:put, path, data, headers)
    end

    # Convenience method to make a GET request
    #
    # @see APIClient#request
    def get(path, data = nil, headers = {})
      path = add_querystring_to_path(path, data)
      request(:get, path, nil, headers)
    end

    # Convenience method to make a DELETE request
    #
    # @see APIClient#request
    def delete(path, data = nil, headers = {})
      path = add_querystring_to_path(path, data)
      request(:delete, path, nil, headers)
    end

    # Make an HTTP request
    #
    # If you need to make a request other than the typical GET, POST,
    # PUT and DELETE, you can use this method directly.
    #
    # This *will* follow redirects when the server's response code is in
    # the 3XX range. If the response is a 303, the request will be
    # transformed into a GET request.
    #
    # @see APIClient.encode_with
    # @see APIClient.decode_with
    # @see APIClient.header
    # @see APIClient#get
    # @see APIClient#post
    # @see APIClient#put
    # @see APIClient#delete
    #
    # @param [Symbol] method The HTTP verb to use with the request
    # @param [String] path The path to request. Will be joined with the
    #        {Kookaburra::Configuration#app_host} setting to build the
    #        URL unless a full URL is specified here.
    # @param [Object] data The data to be posted in the request body. If
    #        an encoder was specified, this can be any type of object as
    #        long as the encoder can serialize it into a String. If no
    #        encoder was specified, then this can be one of:
    #
    #        * a String - will be passed as is
    #        * a Hash - will be encoded as normal HTTP form params
    #        * a Hash containing references to one or more Files - will
    #          set the content type to multipart/form-data
    #
    # @return [Object] The response body returned by the server. If a
    #         decoder was specified, this will return the result of
    #         parsing the response body through the decoder function.
    #
    # @raise [Kookaburra::UnexpectedResponse] Raised if the HTTP
    #        response received is not in the 2XX-3XX range.
    def request(method, path, data, headers)
      data = encode(data)
      headers = global_headers.merge(headers)
      response = @http_client.send(method, url_for(path), *[data, headers].compact)
      decode(response.body)
    rescue RestClient::Exception => e
      raise_unexpected_response(e)
    end

    private

    def add_querystring_to_path(path, data)
      return path if data.nil? || data == {}
      "#{path}?#{data.to_query}"
    end

    def global_headers
      self.class.headers
    end

    def url_for(path)
      URI.join(base_url, path).to_s
    end

    def base_url
      @configuration.app_host
    end

    def encode(data)
      data
    end

    def decode(data)
      data
    end

    def raise_unexpected_response(exception)
      message = <<-END
      Unexpected response from server: #{exception.message}

      #{exception.http_body}
      END
      new_exception = UnexpectedResponse.new(message)
      new_exception.set_backtrace(exception.backtrace)
      raise new_exception
    end
  end
end
