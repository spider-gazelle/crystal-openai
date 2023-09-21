require "json"
require "time"

module OpenAI
  # Usage statistics for the total token usage per completion request
  struct Usage
    include JSON::Serializable

    # Number of tokens in the prompt.
    getter prompt_tokens : Int32 = 0

    # Number of tokens in the generated completion.
    getter completion_tokens : Int32 = 0

    # Total number of tokens used in the request (prompt + completion).
    getter total_tokens : Int32 = 0

    def initialize(@prompt_tokens, @completion_tokens, @total_tokens)
    end
  end
end
