require "connect-proxy"
require "http/headers"
require "http/request"
require "uri"

require "./constants"
require "./errors"
require "./config"
require "./api/**"

module OpenAI
  # OpenAI client
  class Client
    getter config : Config
    @http : ConnectProxy::HTTPClient

    def initialize(@config)
      uri = URI.parse(@config.api_base)
      @http = ConnectProxy::HTTPClient.new(uri)
      if use_proxy = @config.proxy
        proxy = ConnectProxy.new(use_proxy.proxy_url, use_proxy.proxy_port, {username: use_proxy.user, password: use_proxy.password})
        @http.set_proxy(proxy)
      end
    end

    def self.new(api_key : String? = nil, proxy : ProxyConfig? = nil)
      new(Config.default(api_key, proxy))
    end

    def self.azure(api_key : String?, api_endpoint : String, proxy : ProxyConfig? = nil)
      new(Config.azure(api_key, api_endpoint, proxy: proxy))
    end

    #######################
    #  Audio API
    #######################

    # API call to transcribe audio into the input language.
    def transcription(req : TranscriptionRequest) : TranscriptionResponse
      multipart_api("/audio/transcriptions", req.model.to_s, TranscriptionResponse) { |builder|
        req.build_metada(builder)
      }
    end

    # API call to translate audio into English.
    def translation(req : TranscriptionRequest) : TranscriptionResponse
      multipart_api("/audio/translations", req.model.to_s, TranscriptionResponse) { |builder|
        req.build_metada(builder)
      }
    end

    #######################
    #  Chat API
    #######################

    # API call to Create a completion for the chat message.
    def chat_completion(req : ChatCompletionRequest) : ChatCompletionResponse
      raise OpenAIError.new("streaming is not supported with this method, please use `#chat_completion_stream`") if req.stream
      suffix = "/chat/completions"
      raise OpenAIError.new("model '#{req.model}' is not supported with this method, please use `#completion` method instead") unless OpenAI.endpoint_supports_model?(suffix, req.model)

      req = new_request("POST", instance_url(suffix, req.model)) { |arg| arg.body = req.to_json }
      send_request(req, ChatCompletionResponse)
    end

    # API call to create a chat completion w/ streaming support. It sets whether to stream back partial progress. If set, tokens will be
    # sent as data-only server-sent events as they become available, with the
    # stream terminated by a data: [DONE] message.
    def chat_completion_stream(req : ChatCompletionRequest) : ChatCompletionStream
      suffix = "/chat/completions"
      raise OpenAIError.new("model '#{req.model}' is not supported with this method, please use `#completion` method instead") unless OpenAI.endpoint_supports_model?(suffix, req.model)

      req.stream = true
      req = new_request("POST", instance_url(suffix, req.model)) { |arg| arg.body = req.to_json }
      send_request_stream(req, ChatCompletionStream)
    end

    #######################
    #  Completions API
    #######################

    # API call to create a completion. This is the main endpoint of the API. Returns new text as well
    # as, if requested, the probabilities over each alternative token at each position.
    #
    # If using a fine-tuned model, simply provide the model's ID in the CompletionRequest object,
    # and the server will use the model's parameters to generate the completion.
    def completion(req : CompletionRequest) : CompletionResponse
      raise OpenAIError.new("streaming is not supported with this method, please use `#completion_stream`") if req.stream
      suffix = "/completions"
      raise OpenAIError.new("model '#{req.model}' is not supported with this method, please use `#chat_completion` method instead") unless OpenAI.endpoint_supports_model?(suffix, req.model)

      req = new_request("POST", instance_url(suffix, req.model)) { |arg| arg.body = req.to_json }
      send_request(req, CompletionResponse)
    end

    # API call to create a completion w/ streaming
    # support. It sets whether to stream back partial progress. If set, tokens will be
    # sent as data-only server-sent events as they become available, with the
    # stream terminated by a data: [DONE] message.
    def completion_stream(req : CompletionRequest) : CompletionStream
      suffix = "/completions"
      raise OpenAIError.new("model '#{req.model}' is not supported with this method, please use `#chat_completion` method instead") unless OpenAI.endpoint_supports_model?(suffix, req.model)

      req.stream = true
      req = new_request("POST", instance_url(suffix, req.model)) { |arg| arg.body = req.to_json }
      send_request_stream(req, CompletionStream)
    end

    #######################
    #  Embeddings API
    #######################

    # Creates an embedding vector representing the input text.
    def embeddings(req : EmbeddingRequest) : EmbeddingResponse
      req = new_request("POST", instance_url("/embeddings", req.model.to_s)) { |arg| arg.body = req.to_json }
      send_request(req, EmbeddingResponse)
    end

    #######################
    #  Fine-tuning API
    #######################

    # Creates a job that fine-tunes a specified model from a given dataset.
    #
    # Response includes details of the enqueued job including job status and the name of the fine-tuned models once complete.
    def create_fine_tuning_job(job : FineTuningJobRequest) : FineTuningJob
      req = new_request("POST", instance_url("/fine_tuning/jobs")) { |arg| arg.body = job.to_json }
      send_request(req, FineTuningJob)
    end

    # Get info about a fine-tuning job.
    def get_fine_tuning_job(job_id : String) : FineTuningJob
      req = new_request("GET", instance_url("/fine_tuning/jobs/#{job_id}"))
      send_request(req, FineTuningJob)
    end

    # Immediately cancel a fine-tune job.
    def cancel_fine_tuning_job(job_id : String) : FineTuningJob
      req = new_request("POST", instance_url("/fine_tuning/jobs/#{job_id}/cancel"))
      send_request(req, FineTuningJob)
    end

    # List your organization's fine-tuning jobs
    # `after` : Identifier for the last job from the previous pagination request.
    # `limit` : Number of fine-tuning jobs to retrieve.
    def list_fine_tuning_jobs(after : String? = nil, limit : Int32 = 20) : FineTuningJobEventList
      hash = {"limit" => limit.to_s}
      hash["after"] = after unless after.nil?
      params = URI::Params.encode(hash)
      req = new_request("GET", instance_url("/fine_tuning/jobs?#{params}"))
      send_request(req, FineTuningJobEventList)
    end

    # Get status updates for a fine-tuning job.
    # `after` : Identifier for the last job from the previous pagination request.
    # `limit` : Number of fine-tuning jobs to retrieve.
    def list_fine_tuning_events(job_id : String, after : String? = nil, limit : Int32 = 20) : FineTuningJobEventList
      hash = {"limit" => limit.to_s}
      hash["after"] = after unless after.nil?
      params = URI::Params.encode(hash)
      req = new_request("GET", instance_url("/fine_tuning/jobs/#{job_id}/events?#{params}"))
      send_request(req, FineTuningJobEventList)
    end

    #######################
    #  Files API
    #######################

    # Returns a list of files that belong to the user's organization.
    def list_files : Array(FileResponse)
      req = new_request("GET", instance_url("/files"))
      send_request(req, List(FileResponse)).data
    end

    # Delete a file
    def delete_file(file_id : String) : FileDeletionStatus
      req = new_request("DELETE", instance_url("/files/#{file_id}"))
      send_request(req, FileDeletionStatus)
    end

    # Upload a file that contains document(s) to be used across various endpoints/features.
    # Currently, the size of all the files uploaded by one organization can be up to 1 GB. Please contact OpenAI if you need to increase the storage limit.
    def upload_file(req : FileRequest) : FileResponse
      multipart_api("/files", nil, FileResponse) { |builder|
        req.build_metada(builder)
      }
    end

    # Retrieve a file
    def get_file(file_id : String) : FileResponse
      req = new_request("GET", instance_url("/files/#{file_id}"))
      send_request(req, FileResponse)
    end

    # Returns the contents of the specified file.
    def get_file_contents(file_id : String) : IO
      req = new_request("GET", instance_url("/files/#{file_id}/content"))
      send_request_raw(req)
    end

    #######################
    #  Images API
    #######################

    #  API call to create an image. This is the main endpoint of the DALL-E API.
    def create_image(req : ImageRequest) : ImageResponse
      req = new_request("POST", instance_url("/images/generations")) { |arg| arg.body = req.to_json }
      send_request(req, ImageResponse)
    end

    # Creates an edited or extended image given an original image and a prompt.
    def create_image_edit(req : ImageEditRequest) : ImageResponse
      multipart_api("/images/edits", nil, ImageResponse) { |builder|
        req.build_metada(builder)
      }
    end

    # Creates a variation of a given image.
    def create_image_variation(req : ImageVariationRequest) : ImageResponse
      multipart_api("/images/variations", nil, ImageResponse) { |builder|
        req.build_metada(builder)
      }
    end

    #######################
    #  Models API
    #######################

    # Lists currently available models, and provide basic information
    # about each model
    def models : Array(Model)
      req = new_request("GET", instance_url("/models"))
      send_request(req, List(Model)).data
    end

    # Retrieves a model instance, providing basic information about the model
    def model(id : String) : Model
      req = new_request("GET", instance_url("/models/#{id}"))
      send_request(req, Model)
    end

    #######################
    #  Moderation API
    #######################

    # Performs a moderation api call
    def moderation(req : ModerationRequest) : ModerationResponse
      req = new_request("POST", instance_url("/moderations", req.model.to_s)) { |arg| arg.body = req.to_json }
      send_request(req, ModerationResponse)
    end

    #######################
    #  Engines API
    #######################

    # Lists the currently available engines, and provides basic
    # information about each option such as the owner and availability.
    def engines : Array(Engine)
      req = new_request("GET", instance_url("/engines"))
      send_request(req, List(Engine)).data
    end

    # Retrieves an engine instance, providing basic information about
    #  such as the owner and availability.
    def engine(id : String) : Engine
      req = new_request("GET", instance_url("/engines/#{id}"))
      send_request(req, Engine)
    end

    private class ReqSettings
      property body : String | Bytes | IO | Nil = nil
      property headers : HTTP::Headers = HTTP::Headers.new
    end

    private def new_request(method : String, url : String, & : ReqSettings -> _) : HTTP::Request
      args = ReqSettings.new
      yield args
      config.req_headers.each { |h| args.headers.add(*h) }
      HTTP::Request.new(method, url, args.headers, args.body)
    end

    private def new_request(method : String, url : String) : HTTP::Request
      new_request(method, url) { }
    end

    private def send_request(req : HTTP::Request, clz : T.class) : T forall T
      req.headers.add("Accept", "application/json; charset=utf-8")

      # Check whether Content-Type is already set, Upload Files API requires
      # Content-Type set to multipart/form-data
      req.headers.add("Content-Type", "application/json; charset=utf-8") unless req.headers["Content-Type"]?

      resp = @http.exec(req)
      return T.from_json(resp.body) if resp.success?
      handle_error(resp)
    end

    private def send_request_raw(req : HTTP::Request) : IO
      resp = @http.exec(req)
      return (resp.body_io? || IO::Memory.new(resp.body)) if resp.success?
      handle_error(resp)
    end

    private def send_request_stream(req : HTTP::Request, clz : T) forall T
      req.headers.add("Content-Type", "application/json")
      req.headers.add("Accept", "text/event-stream")
      req.headers.add("Cache-Control", "no-cache")
      req.headers.add("Connection", "keep-alive")

      resp = @http.exec(req)
      return clz.new(config.empty_msg_limit, resp.body_io? || resp.body, resp) if resp.success?
      handle_error(resp)
    end

    private def instance_url(suffix : String, model : String? = nil) : String
      base = config.api_base.rstrip('/')
      if config.api_type.azure?
        # if suffix is /models change to {endpoint}/openai/models?api-version=2022-12-01
        # https://learn.microsoft.com/en-us/rest/api/cognitiveservices/azureopenaistable/models/list?tabs=HTTP
        if suffix.includes?("/models")
          "#{base}/#{AZURE_API_PREFIX}#{suffix}?api-version=#{config.api_version}"
        else
          azure_deployment_name = (m = model.presence) ? config.azure_deployment_by_model(m) : "UNKNOWN"
          "#{base}/#{AZURE_API_PREFIX}/#{AZURE_DEPLOYMENT_PREFIX}/#{azure_deployment_name}#{suffix}?api-version=#{config.api_version}"
        end
      else
        "#{base}#{suffix}"
      end
    end

    private def multipart_api(url : String, model : String?, clz : T, &) forall T
      IO.pipe do |reader, writer|
        content_type = "multipart/form-data"
        HTTP::FormData.build(writer) do |builder|
          yield builder
          content_type = builder.content_type
        end
        writer.close
        req = new_request("POST", instance_url(url, model)) do |arg|
          arg.body = reader
          arg.headers.add("Content-Type", content_type)
        end
        send_request(req, clz)
      end
    end

    private def handle_error(resp)
      begin
        res_err = ResponseError.from_json(resp.body)
        if res = res_err.error
          raise APIError.new(resp.status_code, res)
        end
      rescue ex : APIError
        raise ex
      rescue ex : JSON::ParseException
        raise RequestError.new(resp.status_code, Exception.new(resp.body))
      rescue e
        raise RequestError.new(resp.status_code, e)
      end

      if res = res_err.error
        raise APIError.new(resp.status_code, res)
      else
        raise OpenAIError.new("Unknown error received from server")
      end
    end
  end
end
