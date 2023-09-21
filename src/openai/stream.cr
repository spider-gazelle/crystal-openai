require "http/client/response"
require "./errors"

module OpenAI
  # :nodoc:
  class StreamReader(T)
    include Iterator(T)

    @empty_msgs_limit : Int32
    getter? finished : Bool
    getter reader : IO
    getter response : HTTP::Client::Response?
    getter error_accumulator : ErrorAccumulator

    def initialize(@empty_msgs_limit, io : IO | String, @response = nil)
      @reader = io.is_a?(IO) ? io : IO::Memory.new(io)
      @finished = @reader.closed?
      @error_accumulator = ErrorAccumulator.new
    end

    def next
      return stop if finished?
      process_lines
    end

    private def process_lines
      prefix_error = false
      empty_msg_count = 0

      loop do
        if (line = reader.gets.try &.strip) && !prefix_error
          prefix_error = line.starts_with?("data: {\"error\":")

          if !line.starts_with?("data: ") || prefix_error
            line = line.lchop("data: ") if prefix_error
            error_accumulator.write(line.to_slice)
            empty_msg_count += 1

            raise OpenAIError.new("stream has sent too many empty messages") if empty_msg_count > @empty_msgs_limit
            next
          end
          line = line.lchop("data: ").strip
          if line == "[DONE]"
            @finished = true
            return
          end
          begin
            return T.from_json(line)
          rescue ex : JSON::ParseException
            raise OpenAIError.new(ex.message || "Unknown exception occurred")
          end
        else
          return if error_accumulator.empty?
          error_accumulator.rewind
          begin
            res_err = ResponseError.from_json(error_accumulator.gets_to_end)
            if err = res_err.try &.error
              raise APIError.new(0, err)
            end
          rescue ex
            raise OpenAIError.new(ex.message || "Unknown exception occurred")
          end
        end
      end
    end
  end
end
