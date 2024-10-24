require "./constants"

module OpenAI
  enum ApiType
    Azure
    OpenAI
    AzureAD

    def azure?
      [Azure, AzureAD].includes?(self)
    end

    def to_header(key : String) : Tuple(String, String)
      if [OpenAI, AzureAD].includes?(self)
        {"Authorization", "Bearer #{key}"}
      else
        {AZURE_API_HEADER, key}
      end
    end

    def self.parse(string : String) : self
      {% begin %}
        parse?(string) || raise InvalidAPIType.new("
            Invalid API Type '#{string}' provided. Please select one of the supported
            types: {{@type.constants.map(&.underscore).join(", ").id}}
        ")
      {% end %}
    end

    def to_s(io : IO) : Nil
      io << to_s
    end

    def to_s : String
      super.underscore
    end
  end

  class Client
    record ProxyConfig, user : String?, password : String?, proxy_url : String, proxy_port : Int32

    record Config, api_key : String, api_base : String, org_id : String, api_type : ApiType, api_version : String? = nil,
      empty_msg_limit : Int32 = EMPTY_MESSAGES_LIMIT, model_mapper : Proc(String, String)? = nil, proxy : ProxyConfig? = nil do
      def initialize(@api_key, @api_base, @proxy = nil)
        @api_type = :open_ai
        @org_id = ""
      end

      def self.default(api_key : String? = nil, proxy = nil)
        key = api_key || OpenAI.default_apikey
        new(key, API_BASE || OPENAI_API_DEFAULT_URL, ORGANIZATION, :open_ai, proxy: proxy)
      end

      def self.azure(api_key : String?, api_base : String?, api_type : ApiType = :azure, model_mapper : Proc(String, String)? = nil, proxy = nil)
        key = api_key || OpenAI.default_apikey
        endpoint = api_base || API_BASE || raise OpenAIError.new("Missing Azure API Endpoint. Either set `OPENAI_API_BASE` Env var, or provide via `api_base` param")
        mapper = model_mapper || ->(str : String) { str.gsub(/[.:]/, "") }
        new(key, endpoint, ORGANIZATION, api_type, API_VERSION || AZURE_API_VERSION, model_mapper: mapper, proxy: proxy)
      end

      def req_headers
        result = [] of Tuple(String, String)
        result << api_type.to_header(api_key) unless api_key.blank?
        result << {"OpenAI-Organization", org_id} unless org_id.blank?
        result
      end

      def azure_deployment_by_model(model : String) : String
        model_mapper.try &.call(model) || model
      end

      def to_s(io : IO) : Nil
        io << "<OpenAI API ClientConfig>"
      end
    end
  end
end
