require "json"

module OpenAI
  class OpenAIError < Exception
  end

  class APIError < OpenAIError
    getter code : Int32
    getter api_error : String?

    def initialize(@code, err : APIErrorModel)
      @api_error = err.error_msg
      super(@code > 0 ? "ERROR: status code: #{code}, message: #{api_error}" : "ERROR: message: #{api_error}")
    end
  end

  class InvalidAPIType < OpenAIError
  end

  class AuthenticationError < OpenAIError
  end

  class RequestError < OpenAIError
    def initialize(code : Int32, err : Exception)
      message = code > 0 ? "ERROR: status code #{code}, message: #{err.message}" : "ERROR: message: #{err.message}"
      super(message)
    end
  end

  record APIErrorModel, code : JSON::Any?, message : String? | Array(String)?, param : String?, type : String?, innererror : InnerError? do
    include JSON::Serializable
    include JSON::Serializable::Unmapped

    def error_msg : String?
      case message
      when String        then message.as(String)
      when Array(String) then message.as(Array(String)).join(",")
      else
        nil
      end
    end
  end

  record InnerError, code : String?, content_filter_result : JSON::Any? do
    include JSON::Serializable
    include JSON::Serializable::Unmapped
  end

  record ResponseError, error : APIErrorModel? do
    include JSON::Serializable
    include JSON::Serializable::Unmapped
  end

  class ErrorAccumulator
    @buffer : IO::Memory

    forward_missing_to @buffer

    def initialize
      @buffer = IO::Memory.new
    end
  end
end
