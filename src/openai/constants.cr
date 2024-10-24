require "./errors"
require "file"

module OpenAI
  API_KEY                = ENV["OPENAI_API_KEY"]?
  API_KEY_PATH           = ENV["OPENAI_API_KEY_PATH"]?
  ORGANIZATION           = ENV["OPENAI_ORGANIZATION"]? || ""
  OPENAI_API_DEFAULT_URL = "https://api.openai.com/v1"
  API_BASE               = ENV["OPENAI_API_BASE"]?
  API_TYPE               = ApiType.parse(ENV["OPENAI_API_TYPE"]? || "open_ai")
  API_VERSION            = ENV["OPENAI_API_VERSION"]? || begin
    AZURE_API_VERSION if API_TYPE.azure?
  end

  AZURE_API_VERSION       = "2023-05-15"
  AZURE_API_PREFIX        = "openai"
  AZURE_API_HEADER        = "api-key"
  AZURE_DEPLOYMENT_PREFIX = "deployments"
  EMPTY_MESSAGES_LIMIT    = 300

  def self.default_apikey : String
    result = if path = API_KEY_PATH
               api_key = ::File.read(path)
               raise ArgumentError.new("Malformed API key in #{path}") unless api_key.starts_with?("sk-")
               api_key
             else
               API_KEY if API_KEY.presence
             end

    raise AuthenticationError.new(<<-MSG
        No API key provided. You can set the environment variable OPEN_API_KEY=<API-KEY>.
        If your API key is stored in a file, set the environment variable OPENAI_API_KEY_PATH=<PATH>
        You can generate API keys in the OpenAI web interface. See https://platform.openai.com/account/api-keys for details.
      MSG
    ) unless result || API_BASE
    result || ""
  end

  # GPT3 Defines the models provided by OpenAI to use when generating
  # completions from OpenAI.
  # GPT3 Models are designed for text-based tasks. For code-specific
  # tasks, please refer to the Codex series of models.
  GPT432K0613           = "gpt-4-32k-0613"
  GPT432K0314           = "gpt-4-32k-0314"
  GPT432K               = "gpt-4-32k"
  GPT40613              = "gpt-4-0613"
  GPT40314              = "gpt-4-0314"
  GPT4                  = "gpt-4"
  GPT41106              = "gpt-4-1106-preview"
  GPT3Dot5Turbo0613     = "gpt-3.5-turbo-0613"
  GPT3Dot5Turbo0301     = "gpt-3.5-turbo-0301"
  GPT3Dot5Turbo16K      = "gpt-3.5-turbo-16k"
  GPT3Dot5Turbo16K0613  = "gpt-3.5-turbo-16k-0613"
  GPT3Dot5Turbo         = "gpt-3.5-turbo"
  GPT3Dot5TurboInstruct = "gpt-3.5-turbo-instruct"
  GPT3Dot5Turbo1106     = "gpt-3.5-turbo-1106"

  # Deprecated: Will be shut down on January 04, 2024. Use gpt-3.5-turbo-instruct instead.
  GPT3TextDavinci003 = "text-davinci-003"

  # Deprecated: Will be shut down on January 04, 2024. Use gpt-3.5-turbo-instruct instead.
  GPT3TextDavinci002 = "text-davinci-002"

  # Deprecated: Will be shut down on January 04, 2024. Use gpt-3.5-turbo-instruct instead.
  GPT3TextCurie001 = "text-curie-001"

  # Deprecated: Will be shut down on January 04, 2024. Use gpt-3.5-turbo-instruct instead.
  GPT3TextBabbage001 = "text-babbage-001"

  # Deprecated: Will be shut down on January 04, 2024. Use gpt-3.5-turbo-instruct instead.
  GPT3TextAda001 = "text-ada-001"

  # Deprecated: Will be shut down on January 04, 2024. Use gpt-3.5-turbo-instruct instead.
  GPT3TextDavinci001 = "text-davinci-001"

  # Deprecated: Will be shut down on January 04, 2024. Use gpt-3.5-turbo-instruct instead.
  GPT3DavinciInstructBeta = "davinci-instruct-beta"

  GPT3Davinci    = "davinci"
  GPT3Davinci002 = "davinci-002"

  # Deprecated: Will be shut down on January 04, 2024. Use gpt-3.5-turbo-instruct instead.
  GPT3CurieInstructBeta = "curie-instruct-beta"

  GPT3Curie      = "curie"
  GPT3Curie002   = "curie-002"
  GPT3Ada        = "ada"
  GPT3Ada002     = "ada-002"
  GPT3Babbage    = "babbage"
  GPT3Babbage002 = "babbage-002"

  # Codex Defines the models provided by OpenAI.
  # These models are designed for code-specific tasks, and use
  # a different tokenizer which optimizes for whitespace.
  CodexCodeDavinci002 = "code-davinci-002"
  CodexCodeCushman001 = "code-cushman-001"
  CodexCodeDavinci001 = "code-davinci-001"

  class_getter(disabled_models_for_endpoints) { {
    "/completions" => [
      GPT3Dot5Turbo,
      GPT3Dot5Turbo0301,
      GPT3Dot5Turbo0613,
      GPT3Dot5Turbo16K,
      GPT3Dot5Turbo16K0613,
      GPT3Dot5Turbo1106,
      GPT4,
      GPT40314,
      GPT40613,
      GPT432K,
      GPT432K0314,
      GPT432K0613,
      GPT41106,
    ],
    "/chat/completions" => [
      CodexCodeDavinci002,
      CodexCodeCushman001,
      CodexCodeDavinci001,
      GPT3TextDavinci003,
      GPT3TextDavinci002,
      GPT3TextCurie001,
      GPT3TextBabbage001,
      GPT3TextAda001,
      GPT3TextDavinci001,
      GPT3DavinciInstructBeta,
      GPT3Davinci,
      GPT3CurieInstructBeta,
      GPT3Curie,
      GPT3Ada,
      GPT3Babbage,
    ],
  } of String => Array(String) }

  def self.endpoint_supports_model?(endpoint : String, model : String) : Bool
    !disabled_models_for_endpoints[endpoint]?.try &.includes?(model) || false
  end

  # :nodoc:
  module StringConverter
    def self.to_json(value, json : JSON::Builder) : Nil
      text = case value
             when String then value.as(String)
             when Path   then value.as(Path).to_s
             when File   then value.path
             else
               value.to_s
             end
      json.string(text)
    end

    def self.from_json(pull : JSON::PullParser) : String
      pull.read_string
    end
  end
end
