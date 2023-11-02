require "json"
require "time"

module OpenAI
  struct List(Type)
    include JSON::Serializable

    getter object : String
    getter data : Array(Type)
  end

  # GET https://api.openai.com/v1/models
  struct Model
    include JSON::Serializable

    # The model identifier, which can be referenced in the API endpoints.
    getter id : String

    # The object type, which is always "model".
    getter object : String

    # The Unix timestamp (in seconds) when the model was created.
    @[JSON::Field(converter: Time::EpochConverter)]
    getter created : Time

    # The organization that owns the model.
    getter owned_by : String

    getter permission : Array(Permission)?
    getter root : String?
    getter parent : String?
  end

  # OpenAPI permission
  struct Permission
    include JSON::Serializable

    getter id : String
    getter object : String
    @[JSON::Field(converter: Time::EpochConverter)]
    getter created : Time
    getter? allow_create_engine : Bool
    getter? allow_sampling : Bool
    getter? allow_logprobs : Bool
    getter? allow_search_indices : Bool
    getter? allow_view : Bool
    getter? allow_fine_tuning : Bool
    getter organization : String
    getter group : JSON::Any
    getter? is_blocking : Bool
  end

  # OpenAPi Engine
  record Engine, id : String, object : String, owner : String, ready : Bool do
    include JSON::Serializable
  end
end
